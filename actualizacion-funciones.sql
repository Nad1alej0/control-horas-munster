-- Ejecutar una sola vez antes de subir la actualización.
alter table public.registros_horarios
  add column if not exists estado_dia text not null default 'trabajo'
  check (estado_dia in ('trabajo','franco','ausente','licencia','vacaciones'));

grant delete on public.registros_horarios to authenticated;
grant delete on public.movimientos_horas to authenticated;
grant delete on public.horas_esperadas to authenticated;
grant delete on public.semanas to authenticated;
