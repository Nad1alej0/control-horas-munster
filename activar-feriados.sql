-- FERIADO COMPLETO Y FERIADO PARCIAL
-- Ejecutar una sola vez en Supabase > SQL Editor antes de subir la actualización.

alter table public.registros_horarios
  drop constraint if exists registros_horarios_estado_dia_check;

alter table public.registros_horarios
  add constraint registros_horarios_estado_dia_check
  check (estado_dia in (
    'trabajo','franco','ausente','licencia','vacaciones',
    'feriado_completo','feriado_parcial'
  ));

-- Un feriado parcial programado aparece como disponible para marcar entrada.
create or replace function public.listar_mozas_fichaje(p_token text)
returns table(moza_id bigint,nombre text,estado text) language plpgsql security definer set search_path=public,extensions as $$
declare v_hoy date := (now() at time zone 'America/Argentina/Catamarca')::date;
begin
  if not exists(select 1 from public.dispositivos_fichaje where token_hash=extensions.digest(p_token,'sha256') and activo=true)
    then raise exception 'Computadora no autorizada'; end if;
  return query
  select m.id,m.nombre,
    case when r.estado_dia='feriado_parcial' and r.minutos_trabajados=0
      and r.entrada_1='00:00'::time and r.salida_1='00:00'::time
      then 'sin_entrada' else coalesce(r.estado_marcacion,'sin_entrada') end
  from public.mozas m
  left join lateral (
    select rh.estado_dia,rh.minutos_trabajados,rh.entrada_1,rh.salida_1,rh.estado_marcacion
    from public.registros_horarios rh
    where rh.moza_id=m.id and
      (rh.fecha=v_hoy or (rh.fecha=v_hoy-1 and rh.estado_marcacion in ('trabajando','en_corte','segundo_tramo')))
    order by case when rh.estado_marcacion in ('trabajando','en_corte','segundo_tramo') then 0 else 1 end,rh.fecha desc limit 1
  ) r on true where m.activa=true order by m.id;
end; $$;

create or replace function public.marcar_fichaje(p_token text,p_moza_id bigint,p_pin text,p_accion text)
returns jsonb language plpgsql security definer set search_path=public,extensions as $$
declare
  v_device public.dispositivos_fichaje%rowtype; v_cred public.credenciales_fichaje%rowtype;
  v_reg public.registros_horarios%rowtype; v_hoy date := (now() at time zone 'America/Argentina/Catamarca')::date;
  v_hora time := (now() at time zone 'America/Argentina/Catamarca')::time(0); v_min integer; v_msg text;
  v_parcial_programado boolean := false;
begin
  select * into v_device from public.dispositivos_fichaje where token_hash=extensions.digest(p_token,'sha256') and activo=true;
  if not found then return jsonb_build_object('ok',false,'mensaje','Computadora no autorizada'); end if;
  if p_accion not in ('entrada','salida','salida_corte','regreso') then return jsonb_build_object('ok',false,'mensaje','Acción inválida'); end if;
  select * into v_cred from public.credenciales_fichaje where moza_id=p_moza_id for update;
  if not found then return jsonb_build_object('ok',false,'mensaje','Todavía no tenés un PIN configurado'); end if;
  if v_cred.bloqueado_hasta is not null and v_cred.bloqueado_hasta>now() then
    return jsonb_build_object('ok',false,'mensaje','PIN bloqueado temporalmente. Avisá a una encargada');
  end if;
  if v_cred.bloqueado_hasta is not null and v_cred.bloqueado_hasta<=now() then
    update public.credenciales_fichaje set intentos_fallidos=0,bloqueado_hasta=null where moza_id=p_moza_id;
    v_cred.intentos_fallidos:=0; v_cred.bloqueado_hasta:=null;
  end if;
  if extensions.crypt(p_pin,v_cred.pin_hash)<>v_cred.pin_hash then
    update public.credenciales_fichaje set intentos_fallidos=intentos_fallidos+1,
      bloqueado_hasta=case when intentos_fallidos+1>=5 then now()+interval '10 minutes' else null end where moza_id=p_moza_id;
    insert into public.marcaciones_fichaje(moza_id,dispositivo_id,accion,resultado,detalle)
      values(p_moza_id,v_device.id,p_accion,'rechazada','PIN incorrecto');
    return jsonb_build_object('ok',false,'mensaje','PIN incorrecto');
  end if;
  update public.credenciales_fichaje set intentos_fallidos=0,bloqueado_hasta=null where moza_id=p_moza_id;

  select * into v_reg from public.registros_horarios where moza_id=p_moza_id and
    (fecha=v_hoy or (fecha=v_hoy-1 and estado_marcacion in ('trabajando','en_corte','segundo_tramo')))
    order by case when estado_marcacion in ('trabajando','en_corte','segundo_tramo') then 0 else 1 end,fecha desc limit 1 for update;
  v_parcial_programado := found and v_reg.fecha=v_hoy and v_reg.estado_dia='feriado_parcial'
    and v_reg.minutos_trabajados=0 and v_reg.entrada_1='00:00'::time and v_reg.salida_1='00:00'::time;

  if p_accion='entrada' then
    if found and not v_parcial_programado then return jsonb_build_object('ok',false,'mensaje',case when v_reg.estado_marcacion='finalizada' then 'La jornada de hoy ya fue finalizada' else 'Ya tenés una entrada marcada' end); end if;
    if v_parcial_programado then
      update public.registros_horarios set entrada_1=v_hora,salida_1=null,entrada_2=null,salida_2=null,
        minutos_trabajados=0,observacion='Feriado parcial - marcación automática',modificado_el=now(),
        origen='marcador',estado_marcacion='trabajando' where id=v_reg.id returning * into v_reg;
    else
      insert into public.registros_horarios(moza_id,fecha,estado_dia,entrada_1,salida_1,entrada_2,salida_2,minutos_trabajados,observacion,cargado_por,modificado_el,origen,estado_marcacion)
      values(p_moza_id,v_hoy,'trabajo',v_hora,null,null,null,0,'Marcación automática',null,now(),'marcador','trabajando') returning * into v_reg;
    end if;
    v_msg:='Entrada registrada a las '||to_char(v_hora,'HH24:MI');
  elsif not found then return jsonb_build_object('ok',false,'mensaje','No hay una entrada pendiente');
  elsif p_accion='salida_corte' and v_reg.estado_marcacion='trabajando' then
    v_min:=public.minutos_entre(v_reg.entrada_1,v_hora);
    update public.registros_horarios set salida_1=v_hora,minutos_trabajados=v_min,estado_marcacion='en_corte',modificado_el=now() where id=v_reg.id returning * into v_reg;
    v_msg:='Salida al corte registrada a las '||to_char(v_hora,'HH24:MI');
  elsif p_accion='regreso' and v_reg.estado_marcacion='en_corte' then
    update public.registros_horarios set entrada_2=v_hora,estado_marcacion='segundo_tramo',modificado_el=now() where id=v_reg.id returning * into v_reg;
    v_msg:='Regreso registrado a las '||to_char(v_hora,'HH24:MI');
  elsif p_accion='salida' and v_reg.estado_marcacion in ('trabajando','segundo_tramo') then
    if v_reg.estado_marcacion='trabajando' then
      v_min:=public.minutos_entre(v_reg.entrada_1,v_hora);
      update public.registros_horarios set salida_1=v_hora,minutos_trabajados=v_min,estado_marcacion='finalizada',modificado_el=now() where id=v_reg.id returning * into v_reg;
    else
      v_min:=public.minutos_entre(v_reg.entrada_1,v_reg.salida_1)+public.minutos_entre(v_reg.entrada_2,v_hora);
      update public.registros_horarios set salida_2=v_hora,minutos_trabajados=v_min,estado_marcacion='finalizada',modificado_el=now() where id=v_reg.id returning * into v_reg;
    end if;
    v_msg:='Salida registrada a las '||to_char(v_hora,'HH24:MI');
  else return jsonb_build_object('ok',false,'mensaje','Esa marcación no corresponde al estado actual');
  end if;
  insert into public.marcaciones_fichaje(moza_id,registro_id,dispositivo_id,accion,resultado,detalle)
    values(p_moza_id,v_reg.id,v_device.id,p_accion,'aceptada',v_msg);
  update public.dispositivos_fichaje set ultimo_uso=now() where id=v_device.id;
  return jsonb_build_object('ok',true,'mensaje',v_msg);
end; $$;

revoke all on function public.listar_mozas_fichaje(text) from public;
revoke all on function public.marcar_fichaje(text,bigint,text,text) from public;
grant execute on function public.listar_mozas_fichaje(text) to anon,authenticated;
grant execute on function public.marcar_fichaje(text,bigint,text,text) to anon,authenticated;
