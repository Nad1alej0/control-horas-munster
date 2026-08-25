-- CORREGIR EL INICIO DEL SEGUNDO TRAMO DEL HORARIO CORTADO
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- No borra registros, usuarios, PIN ni saldos.

alter table public.registros_horarios
  drop constraint if exists segundo_tramo_completo;

alter table public.registros_horarios
  drop constraint if exists segundo_tramo_valido;

alter table public.registros_horarios
  add constraint segundo_tramo_valido
  check (salida_2 is null or entrada_2 is not null);

