# wiki/_gaps.md — Registro de Brechas (Gap Ledger)

> Capa de persistencia + resolución del **feedback loop** de compilación.
> El agente **emite** brechas (preguntas N1 al humano) durante `/ingest` y las **absorbe** durante `/gaps` o el siguiente `/ingest`.
> El humano solo escribe el campo **`Respuesta del humano`**. Todo lo demás lo administra el agente.
> Gobernado por **REGLA 7** del kernel (`AGENTS.md`). Protocolo: `SKILLS/gaps.md` · Plantilla de ejemplo: `SKILLS/gaps-ejemplo.md`.

---

## Cómo funciona el lazo

1. **Emisión** (`/ingest` · Paso 3.8) — al compilar, una duda **N1** sin resolver (que el pipeline ya detecta como `[INFERIDO]`, `[FUENTE NO PERSISTIDA]` o `> [!warning] Contradicción`) se persiste aquí como brecha `status: open` y deja un `> [!question] GAP-…` inline en la nota afectada. Tope **≤3 por ingest**.
2. **Respuesta** — el humano escribe en el campo `Respuesta del humano` de la brecha. Es lo único que toca.
3. **Absorción** (`/gaps` o `/ingest` · Paso 0.5) — el agente toma esa respuesta como **fuente nueva**, enriquece la nota afectada con su cita, marca la brecha `resolved` y la mueve al histórico. Si la nota es de `curated/` → `/propose` (REGLA 6).

El lazo se cierra solo: el humano responde en este archivo y la próxima compilación lo lleva al conocimiento.

---

## Esquema de una brecha

```text
### GAP-YYYY-MM-DD-NNN · status: open
- **Nota afectada:** [[wiki/<nota>]]            (si es curated/ → se resuelve vía /propose)
- **Disparado por:** /ingest de [[raw/<fuente>]]
- **Tipo:** inferencia-critica | fuente-no-persistida | contradiccion | definicion-faltante | verificacion-baja-confianza | revision-independiente
- **Pregunta:** ¿...?
- **Por qué importa (N1):** ...
- **Impacto al resolver:** enriquece wiki/<nota> · (candidata a /propose / a /curate)
- **Respuesta del humano:** _(vacío — el humano escribe aquí)_
```

> [!example] Plantilla poblada de punta a punta
> Para ver el formato con un caso concreto (los tres estados + callout inline + `raw/feedback/`): `SKILLS/gaps-ejemplo.md`.

### Ciclo de vida del `status`

| status | Significado | Quién lo pone |
|---|---|---|
| `open` | Esperando respuesta del humano | agente (emisión) |
| `resolved` | Respondida y absorbida al conocimiento | agente (absorción) |
| `stale` | `open` > 14 días sin responder | agente (`/lint`) |
| `unanswered` | Sin respuesta > umbral adicional (**> 60 días desde emisión**, ≈45 días en `stale`) → movida a "## Brechas sin respuesta (archivadas)" | agente (`/lint` o `/gaps`), reportándolo |
| `dropped` | Ya no es relevante (fuente archivada, pregunta superada) | agente, reportándolo |

> [!info] Techo del registro — brechas sin respuesta se archivan (visible · reversible · reportado)
> Mismo patrón de gobernanza que `wiki/.skip-sources.md`: para que "## Brechas abiertas" no crezca sin techo, una brecha que sigue **sin respuesta** pasado un umbral adicional tras volverse `stale` (**> 60 días desde su emisión**, ≈45 días en `stale`) pasa a `status: unanswered` y se **mueve** a "## Brechas sin respuesta (archivadas)". El agente lo hace por su criterio durante `/lint` (o `/gaps`), **sin borrar nada**, y siempre de forma transparente: lo **reporta** en la ENTREGA, lo **loguea** en `wiki/log.md` y queda contado en `/status`.
> **Reversible a mano:** el humano la reactiva moviéndola de vuelta a "## Brechas abiertas", o simplemente respondiéndola donde esté — la absorción toma cualquier brecha con `Respuesta del humano` no vacía sin importar la sección. Archivar aquí es higiene interna de `wiki/_gaps.md`; **no** es REGLA 3 (`/archive` → `archivo/`), no toca ese directorio.

> [!warning] Anti-fatiga (lo que mantiene útil el registro)
> Solo se emiten brechas **N1** (Pirámide de señal), tope **≤3 por ingest**, y cada una debe tener
> pregunta concreta + por qué importa + qué desbloquea. Lo que no califica queda como
> `[INFERIDO]`/`[FUENTE NO PERSISTIDA]` en la nota, recuperable luego por `/lint`. Nunca se pregunta por un detalle N3.

### Procedencia de la respuesta (Opción C — híbrida)

La respuesta del humano es conocimiento tácito hecho explícito → es una fuente. Al absorber:

| Valor de la respuesta | Dónde vive | Regla |
|---|---|---|
| **Durable / alto valor** (decisión, threshold, definición reusable, candidata a `curated/`) | `raw/feedback/YYYY-MM-DD.md` (el agente lo propone, **el humano confirma la escritura**) → cita a `raw/feedback/YYYY-MM-DD#GAP-NNN` | REGLA 2 (excepción acotada) |
| **Efímero** | inline en la nota como `[FUENTE NO PERSISTIDA: feedback del humano GAP-…]` | sin cambios de regla |

---

## Brechas abiertas

_(sin brechas — el registro arranca vacío)_

## Brechas sin respuesta (archivadas)

> [!note] Brechas `unanswered` — sin respuesta pasado el umbral, movidas aquí para mantener liviana la sección activa.
> Visibles y reversibles: el humano las reactiva moviéndolas de vuelta a "## Brechas abiertas" o respondiéndolas en el sitio. Nunca se borran (REGLA 7). Cada entrada archivada lleva una línea `- **Archivada:** YYYY-MM-DD · sin respuesta hace N días desde emisión · <agente>`.

_(sin brechas — el registro arranca vacío)_

## Brechas resueltas (histórico)

_(sin brechas — el registro arranca vacío)_
