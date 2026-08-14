-- BANCO DE HORAS, COMPENSACIONES E INFORMES
-- Ejecutar una sola vez en Supabase > SQL Editor.

alter table public.movimientos_horas
  add column if not exists minutos_referencia integer not null default 0;

-- Completa el dato auxiliar de las devoluciones que ya existían.
update public.movimientos_horas
set minutos_referencia = abs(minutos)
where tipo = 'devolucion' and minutos_referencia = 0;

grant select, insert, update, delete on public.movimientos_horas to authenticated;
