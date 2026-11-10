# wiki/_proposed/ — Propuestas pendientes de revisión

> Aquí viven las propuestas de cambio que el LLM generó para notas en `curated/`.
> El LLM escribe aquí. El humano revisa y aprueba. Nadie aplica cambios a `curated/` sin aprobación.

## Cómo funcionan las propuestas

Cuando el LLM procesa información nueva que es relevante para una nota curada:
1. NO toca la nota curada
2. Crea un archivo aquí con el diff exacto propuesto
3. Notifica al humano

## Cómo revisar una propuesta

1. Ver la bandeja: listar `_proposed/*.md` y leer el frontmatter (`target_note`, `created`,
   `status`, `target_sha256`). El agente lo resume en una tabla ordenada por antigüedad.
2. Abrir `_proposed/YYYY-MM-DD-<nombre-nota>.md` y leer la sección afectada + el cambio propuesto.
3. Pedirle al LLM "mostrame el diff de esta propuesta": lee la nota curada y construye el
   antes/después exacto, sin escribir nada.
4. Decidir:
   - **Aprobada**: "aplica la propuesta ..." y el agente corre `SKILLS/accept-proposal.md`
     (diff + confirmación + delta exacto + archivo + log).
   - **Rechazada**: eliminar el archivo (o pedirle al LLM que la rechace).
   - **Modificar y aplicar**: editar el cambio propuesto y recién entonces aplicar.
5. Guardia de hash: si la propuesta trae `target_sha256`, el agente compara con
   `sha256sum curated/<nota>.md` (macOS: `shasum -a 256`). Si no coincide, la nota cambió:
   regenerar la propuesta antes de aplicar.

No hay script de merge: el agente lee, compara y aplica con confirmación humana.

## Formato recomendado

```markdown
---
target_note: curated/<nota>.md
target_sha256: "<sha256 al crear la propuesta>"   # opcional, recomendado
created: YYYY-MM-DD
status: pending
motivated_by: <fuente>
---

# Propuesta: actualización para curated/<nota>

## Sección afectada
> [cita textual de la sección actual]

## Cambio propuesto
<!-- brainai:replace:start section="## Decisión" -->
## Decisión

Contenido nuevo completo de la sección, encabezado incluido.
<!-- brainai:replace:end -->

## Justificación
[por qué]
```

- El contenido reemplaza la sección entera, no un fragmento.
- Varios bloques = varias secciones, en orden.
- Los bloques son una guía de exactitud; no hay parser que los exija.

## Convención de nombres

`YYYY-MM-DD-<nombre-nota-curada>.md`

Si hay múltiples propuestas para la misma nota en el mismo día, el LLM las consolida en
el mismo archivo (varios bloques) — no crea duplicados.

## Limpieza periódica

Las propuestas aplicadas se mueven a `_proposed/archive/` con `status: applied`.
Durante `/lint` se listan las que llevan más de 14 días pendientes y se marcan como
urgentes. `/status` muestra la bandeja; no hace falta una herramienta aparte.
