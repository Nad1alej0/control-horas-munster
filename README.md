# Control de Horas Munster

Aplicación web instalable para registrar jornadas, calcular diferencias semanales y administrar devoluciones de horas del equipo Munster.

Los datos se almacenan en Supabase y el acceso requiere una cuenta autorizada.

## Banco de horas

- Las compensaciones dentro de una misma semana se registran como explicación y no modifican las horas base.
- El uso de saldo confirmado de semanas anteriores reduce automáticamente las horas a cumplir.
- Antes de publicar esta versión, ejecutar `actualizar-banco-horas.sql` una sola vez en Supabase.
- Los informes PDF muestran francos, vacaciones, días pendientes, compensaciones, observaciones y uso del banco.
