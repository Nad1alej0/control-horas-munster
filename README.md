# Control de Horas Munster

Aplicación web instalable para registrar jornadas, calcular diferencias semanales y administrar devoluciones de horas del equipo Munster.

Los datos se almacenan en Supabase y el acceso requiere una cuenta autorizada.

## Banco de horas

- Las compensaciones dentro de una misma semana se registran como explicación y no modifican las horas base.
- El uso de saldo confirmado de semanas anteriores reduce automáticamente las horas a cumplir.
- Antes de publicar esta versión, ejecutar `actualizar-banco-horas.sql` una sola vez en Supabase.
- Los informes PDF muestran francos, vacaciones, días pendientes, compensaciones, observaciones y uso del banco.

## Feriados

- **Feriado completo:** computa 8 horas y no consume horas del banco.
- **Feriado parcial:** puede programarse antes de conocer el horario. El marcador conserva las horas reales trabajadas y la aplicación computa 8 horas cuando se trabajaron hasta 8.
- Un feriado parcial no genera faltantes ni excedentes mientras la jornada real no supere las 8 horas. Solamente el tiempo trabajado por encima de 8 horas genera saldo a favor.
- Los francos normales se mantienen: un feriado no reemplaza el franco semanal.
- Antes de publicar esta versión, ejecutar activar-feriados.sql una sola vez en Supabase.

## Revisiones de jornadas cortas

- Las jornadas normales finalizadas con menos de 8 horas aparecen únicamente a las encargadas en Revisiones pendientes.
- Se pueden resolver como Compensar con horas de esta misma semana, Usar horas del banco anterior, Dejar como diferencia semanal o Corregir la marcación.
- El marcador del personal solo confirma la salida y no muestra ninguna revisión interna.

## Información y pendientes

- La sección **Información** reúne días anteriores sin marcaciones, jornadas abiertas y jornadas cortas por revisar.
- Un día vacío puede resolverse como franco, vacaciones, feriado completo, ausencia o licencia y queda registrado automáticamente.
- Si fue feriado parcial u olvidó marcar, la aplicación abre directamente la carga manual de horarios en la fecha correcta.
- El día actual no se considera vacío mientras todavía puede estar desarrollándose la jornada.
- La semana no puede cerrarse hasta que sus siete días estén definidos para cada moza y no queden pendientes.

## Crédito especial del 17/08/2026 al 23/08/2026

- Ejecutar `activar-saldo-especial-semana.sql` una sola vez en Supabase.
- Nadia recibe 4 horas; Tiara, Angie, Cele, Lore y Mili reciben 2 horas.
- Al cerrar, primero se compensan las horas de más y de menos realizadas en la misma semana.
- Después se usa automáticamente solamente el crédito especial necesario.
- El crédito especial que no se utilice vence al cerrar y no pasa a la semana siguiente.
- En el marcador de personal, el horario cortado se muestra como `Cortado · tramo 1` y `Cortado · tramo 2`.
