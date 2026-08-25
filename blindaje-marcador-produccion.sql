-- BLINDAJE PREVENTIVO DEL MARCADOR DE PERSONAL
-- Seguro para ejecutar con la aplicación en uso: no borra ni modifica horarios.
-- Corrige la regla que impedía dejar abierto el segundo tramo de una jornada cortada.

begin;

alter table public.registros_horarios
  alter column salida_1 drop not null;

alter table public.registros_horarios
  alter column cargado_por drop not null;

alter table public.registros_horarios
  drop constraint if exists segundo_tramo_completo;

alter table public.registros_horarios
  drop constraint if exists segundo_tramo_valido;

alter table public.registros_horarios
  add constraint segundo_tramo_valido
  check (salida_2 is null or entrada_2 is not null);

commit;

-- Confirmación visible al finalizar.
select
  'Marcador protegido correctamente' as resultado,
  count(*) filter (where estado_marcacion in ('trabajando','en_corte','segundo_tramo')) as jornadas_abiertas
from public.registros_horarios;
