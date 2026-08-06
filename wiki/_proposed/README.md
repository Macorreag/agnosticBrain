# wiki/_proposed/ — Propuestas pendientes de revisión

> Aquí viven las propuestas de cambio que el LLM generó para notas en `curated/`.
> El LLM escribe aquí. El humano revisa. Nadie aplica cambios a `curated/` sin aprobación.

## Cómo funcionan las propuestas

Cuando el LLM procesa información nueva que es relevante para una nota curada:
1. NO toca la nota curada
2. Crea un archivo aquí con el diff exacto propuesto
3. Notifica al humano

## Cómo revisar una propuesta

1. Abrir el archivo `_proposed/YYYY-MM-DD-<nombre-nota>.md`
2. Leer la sección afectada + el cambio propuesto
3. Decidir:
   - **Aprobada**: decirle al LLM "aplica la propuesta de _proposed/YYYY-MM-DD-<nota>.md"
   - **Rechazada**: eliminar el archivo (o decirle al LLM que la rechace)
   - **Modificar y aplicar**: editar el diff propuesto manualmente y aplicarlo a `curated/`

## Convención de nombres

`YYYY-MM-DD-<nombre-nota-curada>.md`

Si hay múltiples propuestas para la misma nota en el mismo día, el LLM las consolida en el mismo archivo (no crea duplicados).

## Limpieza periódica

Durante `/lint`, el LLM lista las propuestas con más de 14 días pendientes y las marca como urgentes. Revisar con `/status` para ver el inventario actual.
