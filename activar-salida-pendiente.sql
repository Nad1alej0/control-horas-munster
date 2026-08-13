-- Ejecutar una sola vez en Supabase > SQL Editor.
-- Permite guardar una entrada y completar la salida más tarde.
alter table public.registros_horarios
  alter column salida_1 drop not null;
