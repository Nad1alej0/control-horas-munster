-- Permisos para las dos encargadas que iniciarán sesión en la aplicación.
grant usage on schema public to authenticated;
grant select on public.mozas to authenticated;
grant select, insert, update, delete on public.semanas to authenticated;
grant select, insert, update, delete on public.horas_esperadas to authenticated;
grant select, insert, update, delete on public.registros_horarios to authenticated;
grant select, insert, update, delete on public.movimientos_horas to authenticated;
grant select, insert on public.auditoria to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- La aplicación pública no puede consultar los datos sin iniciar sesión.
revoke all on public.mozas from anon;
revoke all on public.semanas from anon;
revoke all on public.horas_esperadas from anon;
revoke all on public.registros_horarios from anon;
revoke all on public.movimientos_horas from anon;
revoke all on public.auditoria from anon;
