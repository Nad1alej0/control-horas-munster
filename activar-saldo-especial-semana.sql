-- CREDITO ESPECIAL, SOLO PARA LA SEMANA 17/08/2026 AL 23/08/2026
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- Nadia recibe 4 horas. Tiara, Angie, Cele, Lore y Mili reciben 2 horas.
-- La aplicacion usa solamente lo necesario al cerrar la semana y vence el sobrante.

insert into public.movimientos_horas
  (moza_id, semana_id, fecha, minutos, minutos_referencia, tipo, modalidad, observacion, cargado_por)
select
  m.id,
  s.id,
  date '2026-08-17',
  case when lower(trim(m.nombre)) = 'nadia' then 240 else 120 end,
  case when lower(trim(m.nombre)) = 'nadia' then 240 else 120 end,
  'ajuste',
  'Crédito especial semanal',
  'Crédito temporal del 17/08/2026 al 23/08/2026; el sobrante vence al cerrar la semana',
  (select id from auth.users order by created_at limit 1)
from public.mozas m
join public.semanas s
  on s.fecha_inicio = date '2026-08-17'
 and s.fecha_fin = date '2026-08-23'
where m.activa = true
  and lower(trim(m.nombre)) in ('nadia','tiara','angie','angy','cele','lore','mili')
  and not exists (
    select 1
    from public.movimientos_horas mh
    where mh.moza_id = m.id
      and mh.semana_id = s.id
      and mh.modalidad = 'Crédito especial semanal'
  );

