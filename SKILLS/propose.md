# SKILL: /propose — Proponer actualización a nota curada

> El único mecanismo para que el LLM "comunique" información nueva relevante para curated/.
> El LLM propone. El humano decide. Nadie sobreescribe curated/ sin aprobación humana.

---

## Cuándo usar

- Durante /ingest, cuando nueva información es relevante para una nota en curated/
- Durante /lint, cuando se detecta que curated/ tiene información stale
- Cuando el humano pide sugerir una actualización sin aplicarla todavía

---

## Protocolo paso a paso

### Paso 1 — Identificar la nota curada afectada
```
¿Qué nota en curated/ se ve afectada por la nueva información?
Leer esa nota curada completa.
Identificar exactamente qué sección o claim necesita actualización.
```

### Paso 2 — Construir el diff propuesto
```
No incluir el archivo completo.
Solo la sección afectada + qué cambiaría.
Formato:

Sección actual:
> [cita textual de curated/<nota>, sección específica]

Propuesta de cambio:
[texto propuesto — solo el delta, no toda la nota]

Justificación:
[por qué esta información es más correcta o más completa]
```

### Paso 3 — Crear archivo de propuesta
```
Crear wiki/_proposed/YYYY-MM-DD-<nombre-nota>.md

Si ya existe una propuesta para esa nota:
  → Agregar la nueva propuesta al mismo archivo (append, no sobrescribir)
  → No crear archivo duplicado
```

### Paso 4 — Actualizar index
```
En wiki/index.md, sección "Propuestas pendientes":
  → Agregar entrada: wiki/_proposed/YYYY-MM-DD-<nota>.md | curated/<nota> | YYYY-MM-DD
  → Actualizar estadísticas (_proposed/ +1)
```

### Paso 5 — Log
```
Append a wiki/log.md:
## [YYYY-MM-DD HH:MM] proposed | curated/<nota> — pendiente revisión el humano
Motivado por: <fuente o contexto>
```

### Paso 6 — Notificar al humano
```
Si la propuesta se crea durante un ingest:
"⚠️ Información nueva en <fuente> es relevante para curated/<nota>.
Creé una propuesta en wiki/_proposed/YYYY-MM-DD-<nota>.md.
Cuando quieras revisarla, puedo mostrarte el diff o aplicarlo si lo apruebas."
```

---

## Formato completo del archivo de propuesta

```markdown
---
target_note: curated/<nombre-nota>
created: YYYY-MM-DD
status: pending
motivated_by: <fuente>
---

# Propuesta: actualización para curated/<nombre-nota>

**Motivado por:** <nombre de fuente o contexto>
**Fecha:** YYYY-MM-DD
**Estado:** pendiente revisión

---

## Sección afectada en la nota curada

> [cita textual exacta de la sección actual en curated/<nota>]

## Cambio propuesto

[texto propuesto — solo el delta]

## Justificación

[por qué esta información supera o complementa lo existente]
[referencia a la fuente]

---

*(Si hay múltiples propuestas para esta nota, se agregan abajo como secciones adicionales)*
```

---

## Formato recomendado — para que el LLM aplique sin ambigüedad

El formato de arriba (v1) sigue siendo válido. Para que el cierre sea más seguro, agregá
`target_sha256` y, si querés, delimitá la sección con bloques:

```markdown
---
target_note: curated/<nombre-nota>
target_sha256: "<sha256 de curated/<nota> al crear la propuesta>"
created: YYYY-MM-DD
status: pending
motivated_by: <fuente>
---

# Propuesta: actualización para curated/<nombre-nota>

## Sección afectada
> [cita textual exacta de la sección actual]

## Cambio propuesto

<!-- brainai:replace:start section="## Sección afectada" -->
## Sección afectada

[contenido nuevo COMPLETO de la sección — encabezado incluido]
<!-- brainai:replace:end -->

## Justificación

[por qué esta información supera o complementa lo existente]
```

Reglas:

- El contenido reemplaza la sección **entera**, no un fragmento.
- Puede haber varios bloques; el agente los aplica en orden.
- `target_sha256` se calcula con `sha256sum curated/<nota>.md` (macOS: `shasum -a 256`).
  Si no coincide al aplicar, la propuesta quedó vieja: regenerarla.
- Los bloques son una **guía de exactitud**, no un formato que un parser imponga.

---

## Aplicar una propuesta aprobada por el humano

Cuando el humano aprueba ("aplica la propuesta de `_proposed/YYYY-MM-DD-<nota>.md`"):

1. Leer la propuesta completa y la nota curada.
2. Construir el diff exacto (sección actual vs. propuesta) y mostrarlo.
3. Verificar `target_sha256` con `sha256sum`/`shasum`; si no coincide, abortar.
4. Pedir confirmación explícita.
5. Aplicar **solo** el delta aprobado, actualizar `last_human_edit`, crear `_proposed/archive/` si falta y archivar la propuesta
   allí con `status: applied`, loguear y actualizar el índice.
6. Si es v1 (texto libre), mismo flujo con más cuidado: el diff lo construye el agente.

Protocolo completo: `SKILLS/accept-proposal.md`. El agente **no decide** el contenido:
solo lee, compara y ejecuta el delta que el humano aprobó.

---

## Reglas

- ❌ NUNCA modificar curated/ sin aprobación explícita del humano
- ❌ NUNCA crear propuesta sin identificar exactamente la nota curada afectada
- ✅ Consolidar múltiples propuestas para la misma nota en un solo archivo
- ✅ Notificar al humano cuando crees una propuesta durante ingest
