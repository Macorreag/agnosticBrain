# Ejemplo semilla — plantilla de `wiki/_gaps.md` (insumo descubrible de `/gaps`)

> Insumo de **SOLO LECTURA** de `SKILLS/gaps.md`, alcanzable por progressive disclosure desde `wiki/_gaps.md` y desde la propia SKILL.
> **NO es el registro real** (ese es `wiki/_gaps.md`, que arranca vacío). Vive en `SKILLS/`, así que el agente **no lo edita** y **no cuenta** sus entradas como brechas reales (`/status` y `/lint` solo miran `wiki/_gaps.md`).
> Propósito: que al navegar hasta acá se entienda, con un caso concreto, cómo se ve una plantilla de gaps de punta a punta — el ledger en sus tres estados, el callout `> [!question]` inline en la nota, y el `raw/feedback/` resultante.

---

## 1. Cómo se ve `wiki/_gaps.md` poblado

El bloque siguiente es el **contenido** del archivo `wiki/_gaps.md` en un momento con tres brechas: una respondida lista para absorber, una esperando respuesta, y una ya resuelta en el histórico.

```markdown
## Brechas abiertas

### GAP-2026-01-15-001 · status: open
- **Nota afectada:** [[wiki/elemento-a-ciclo-repeticion]]
- **Disparado por:** /ingest de [[raw/ejemplo-2026-01-15]]
- **Tipo:** inferencia-critica
- **Pregunta:** ¿El chequeo de "ya resuelto" antes de repetir ya se implementó en elemento-a, o sigue repitiendo sin esperar la resolución anterior?
- **Por qué importa (N1):** decide si el patrón ciclo-de-repetición sigue vivo o ya está mitigado.
- **Impacto al resolver:** enriquece wiki/elemento-a-ciclo-repeticion · candidata a /curate
- **Respuesta del humano:** Sí, implementado el 2026-01-14 (versión 1.42.0). Margen de espera 0-500ms; el ciclo ya no aparece en el panel de seguimiento.

### GAP-2026-01-15-002 · status: open
- **Nota afectada:** [[wiki/dominio-operacion]]
- **Disparado por:** /ingest de [[raw/ejemplo-2026-01-15]]
- **Tipo:** definicion-faltante
- **Pregunta:** ¿Qué es exactamente "el Coordinador" y de qué elemento es responsabilidad?
- **Por qué importa (N1):** aparece como causa en varios análisis pero nunca se definió en wiki/.
- **Impacto al resolver:** enriquece wiki/dominio-operacion
- **Respuesta del humano:** _(vacío — el humano escribe aquí)_

---

## Brechas resueltas (histórico)

### GAP-2026-01-12-001 · status: resolved
- **Nota afectada:** [[wiki/observabilidad-operacion]]
- **Tipo:** verificacion-baja-confianza
- **Pregunta:** ¿El umbral de referencia para la alerta de elemento-a es 5 o 3?
- **Resuelto:** 2026-01-20 — el humano confirmó 3; absorbido en wiki/observabilidad-operacion.
- **Procedencia:** durable → raw/feedback/2026-01-20.md (la nota cita raw/feedback/2026-01-20#GAP-2026-01-12-001).
```

> [!note] Lectura del bloque (los tres estados)
> - **GAP-…-001** está `open` **con** `Respuesta del humano` → `/gaps` la absorbe ahora; `/status` la cuenta como "respondida sin procesar".
> - **GAP-…-002** está `open` **sin** respuesta → espera al humano; si pasa de 14 días, `/lint` la marca `stale`; y si sigue sin respuesta > 60 días desde emisión, se archiva (`unanswered`) a "## Brechas sin respuesta (archivadas)" — visible y reversible (ver `SKILLS/gaps.md §Higiene del registro`).
> - **GAP-…-001 (resolved)** ya fue absorbida y movida al histórico — **nunca se borra** (REGLA 7).

---

## 2. El callout inline en la nota afectada (lo que deja la emisión)

Al emitir `GAP-2026-01-15-001`, en `wiki/elemento-a-ciclo-repeticion.md` queda, justo donde vive la duda:

```markdown
> [!question] GAP-2026-01-15-001 — ¿El chequeo de "ya resuelto" ya está implementado?
> Brecha en [[wiki/_gaps#GAP-2026-01-15-001]]. El humano responde ahí; el próximo /ingest o /gaps la absorbe.
```

Al absorber, ese callout se reemplaza por el hecho ya citado (o se elimina si la respuesta lo desmiente).

---

## 3. El `raw/feedback/` resultante (procedencia durable · Opción C)

Para una respuesta **durable**, tras tu confirmación, se persiste así (create/append, nunca editar lo ya escrito) — REGLA 2:

```markdown
# Feedback del humano — 2026-01-20

## GAP-2026-01-12-001
**Pregunta:** ¿El umbral de referencia para la alerta de elemento-a es 5 o 3?
**Respuesta del humano:** Es 3 desde el ajuste posterior al caso del mes pasado.
**Contexto:** disparada por /ingest de raw/<fuente>; enriquece wiki/observabilidad-operacion.
```

Para una respuesta **efímera**, no se toca `raw/`: la nota cita `[FUENTE NO PERSISTIDA: feedback el humano GAP-…]`.

---

## 4. Anotaciones de la plantilla (qué hace cada parte)

| Parte de la entrada | Para qué | Quién la toca |
|---|---|---|
| `### GAP-AAAA-MM-DD-NNN · status:` | id estable + estado del ciclo de vida | agente |
| `Nota afectada` / `Disparado por` | trazabilidad: a la nota `wiki/` y a la fuente que la disparó | agente |
| `Tipo` | uno de los 6 tipos (ver `SKILLS/gaps.md` §Tipos) | agente |
| `Pregunta` + `Por qué importa (N1)` + `Impacto` | contrato anti-fatiga: sin los tres, **no** es brecha | agente |
| `Respuesta del humano` | **único campo que escribe el humano** | Humano |
| mover a histórico al pasar a `resolved` | append-only: nunca se borra una brecha | agente |

> [!tip] Cómo usar este insumo
> No copies el archivo entero: tomá **una** entrada `### GAP-…` del bloque §1 como molde, ajustá los campos, y pegala bajo `## Brechas abiertas` en `wiki/_gaps.md`. El protocolo de emisión/absorción completo vive en `SKILLS/gaps.md`.
