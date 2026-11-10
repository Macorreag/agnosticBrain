# SKILL: /accept-proposal — Cerrar el ciclo de una propuesta

> Convierte una propuesta de `wiki/_proposed/` en un cambio aplicado a `curated/`.
> **Lo hace el LLM, no un script:** lee, compara, muestra el diff, pide aprobación y
> aplica solo el delta. Las únicas herramientas son `diff`, `sha256sum`/`shasum` y `mv`.

---

## Cuándo usar

- El humano dice "aplica la propuesta de `_proposed/...`", `/accept-proposal ...` o "cerrá esa propuesta".
- El humano ya aplicó una propuesta v1 a mano y quiere archivarla/limpiar la bandeja.
- `/lint` o `/status` muestran propuestas viejas y el humano pide revisarlas.

---

## Protocolo paso a paso

### Paso 0 — Ver la bandeja

```bash
ls -1 wiki/_proposed/*.md 2>/dev/null
```

Para cada archivo, leer el frontmatter (`target_note`, `created`, `status`, `target_sha256`).
Ordenar por antigüedad (la más vieja primero). Ignorar `_proposed/archive/`.
No hace falta una herramienta: el agente lee los archivos y resume en una tabla.

### Paso 1 — Reconstruir el diff (dry-run)

1. Leer la propuesta completa y la nota curada destino.
2. Ubicar la sección afectada (por el encabezado citado o por `target_section`).
3. Construir el **antes vs. después** exacto: la sección actual completa y la propuesta.
   Si hay bloques `brainai:replace`, usarlos como guía de qué reemplazar; si no, inferir
   la sección del texto de la propuesta.
4. Mostrar el diff al humano. No escribir nada todavía.

### Paso 2 — Guardia de hash (si existe)

```bash
sha256sum curated/<nota>.md          # Linux
shasum -a 256 curated/<nota>.md      # macOS
```

Si `target_sha256` existe y no coincide, **abortar**: la nota curada cambió después de
crear la propuesta. Pedir que se regenere; no aplicar sobre una base vieja.

### Paso 3 — Confirmación humana explícita

Mostrar:

- qué nota curada se toca,
- qué sección se reemplaza,
- el diff exacto,
- si hay hash drift o ambigüedad.

Preguntar: **"¿Aplico este diff a `curated/<nota>`?"**. No continuar sin un "sí" explícito.

### Paso 4 — Aplicar el delta

Con la herramienta de edición del agente:

1. Reemplazar **solo la sección aprobada** (encabezado incluido o no, según el diff acordado).
2. Actualizar `last_human_edit: YYYY-MM-DD` en el frontmatter de `curated/`.
3. Marcar la propuesta `status: applied` y agregar `applied: YYYY-MM-DD`.
4. Crear `wiki/_proposed/archive/` si falta y moverla allí con `mv`.
5. Append a `wiki/log.md`: `## [FECHA] proposal-applied | curated/<nota> — <propuesta>`.
6. Actualizar `wiki/index.md`: quitar la fila de la propuesta y ajustar el contador.

### Paso 5 — Propuestas v1 (texto libre)

Mismo flujo, con más cuidado: el diff lo construye el agente, no un parser. Si la
propuesta es ambigua, pedir al humano que aclare qué sección y qué texto reemplaza.
Nunca aplicar "lo que parece".

### Paso 6 — Reportar

```
✓ curated/<nota> actualizada — sección «## ...»
✓ propuesta archivada en wiki/_proposed/archive/
✓ last_human_edit: YYYY-MM-DD · log e índice actualizados
```

Sugerir `/status` para confirmar que la bandeja bajó.

---

## Formato de la propuesta (guía, no contrato de parser)

El formato recomendado sigue siendo:

```markdown
---
target_note: curated/<nota>.md
target_sha256: "<sha256 al crear la propuesta>"   # opcional
created: YYYY-MM-DD
status: pending
motivated_by: <fuente>
---

# Propuesta: actualización para curated/<nota>

## Sección afectada
> [cita textual de la sección actual]

## Cambio propuesto
[texto nuevo completo de la sección]

## Justificación
[por qué]
```

Los bloques `<!-- brainai:replace:start section="..." --> ... <!-- end -->` son una
ayuda de exactitud para el LLM: delimitan qué reemplazar. No hay un parser que los exija.

---

## Reglas

- ❌ NUNCA aplicar sin aprobación humana explícita del diff mostrado.
- ❌ NUNCA aplicar si el hash no coincide; regenerar la propuesta.
- ❌ NUNCA editar secciones distintas a la aprobada "de paso".
- ✅ Leer la nota completa antes de tocar una sola línea.
- ✅ Si la propuesta está vencida o el target ya no existe: no aplicar; reportar y
  proponer regenerarla o descartarla.
- ✅ `curated/` solo se toca por esta vía, `/curate` o `/uncurate` (REGLA 1).
- ✅ Si hay dudas de sección o de texto, preguntar; no adivinar.
