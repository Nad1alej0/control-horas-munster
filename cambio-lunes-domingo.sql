-- Ejecutar una sola vez para convertir las semanas existentes
-- de domingo-sábado a lunes-domingo.
update public.semanas
set fecha_inicio = fecha_inicio + 1,
    fecha_fin = fecha_fin + 1
where extract(isodow from fecha_inicio) = 7;

-- Asegurar una base de 40 horas para cualquier moza que todavía
-- no tenga horas esperadas guardadas en una semana existente.
insert into public.horas_esperadas
  (semana_id, moza_id, minutos_esperados, cantidad_francos)
select s.id, m.id, 2400, 2
from public.semanas s
cross join public.mozas m
where m.activa = true
on conflict (semana_id, moza_id) do nothing;
