# BrainAI · Kernel Schema v2.3

> Kernel canónico del LLM Wiki personal del humano — **fuente de verdad única, agnóstica de agente**.
> El agente compila y mantiene `wiki/`. El humano refina y protege `curated/`. Nadie extrae de `archivo/`.
>
> **v2.3 — LLM-first:** el agente lee, compara, propone y aplica con herramientas nativas.
> Sin scripts nuevos: `/accept-proposal` y `/lint` son protocolos en `SKILLS/`, apoyados en
> los scripts mecánicos que ya existían. Menos tooling, más criterio del modelo.

> [!important] Este archivo es la CPU del sistema
> Todo agente de código que opere este repositorio (Codex, Cursor, Claude Code, u otro) lee **este** archivo como contrato único. No hay un kernel paralelo: lo que antes vivía en `CLAUDE.md` ahora vive aquí. `CLAUDE.md` solo importa este archivo.

---

## Mapa mínimo — el sistema en 4 puntos

> El resto de este archivo es la referencia completa (excepciones, formato, casos borde). Esta sección es el **mapa mínimo**: alcanza para entender el sistema, no para operar sin leer las REGLAS CRÍTICAS y el SKILL de la operación. Si hay conflicto, gana la regla detallada.

1. **Tres capas.** `raw/` = fuentes crudas e inmutables (el agente nunca las toca). `wiki/` = lo que el agente compila: notas markdown atómicas y enlazadas. Este archivo = el schema que gobierna cómo se compila.
2. **El loop mínimo son 3 verbos:**
   - **`/ingest <fuente>`** — lee `raw/`, extrae una nota por sujeto (nunca un documento gigante), la enlaza a ≥2 notas existentes con una relación con nombre, cita cada hecho.
   - **`/query <pregunta>`** — nunca re-lee `raw/` desde cero: entra por `wiki/index.md`, navega enlaces, responde con citas.
   - **`/lint`** — chequea que el grafo siga sano (links rotos, huérfanas, contradicciones).
3. **Tres cosas que nunca se negocian:** `raw/` no se edita jamás. El contenido de `curated/` no se edita directo (se propone un cambio). Cada hecho lleva marca de procedencia: citado, `[FUENTE NO PERSISTIDA]`, o `[INFERIDO]`.
4. **Todo lo demás es opcional sobre este loop, no el núcleo:** `/curate` (congelar una nota como canónica, con una línea humana), `/archive`, `/gaps` (el agente pregunta cuando algo importante queda ambiguo), `/compose` (correr el loop varias veces solo). El sistema funciona sin que ninguno de estos se use nunca.

---

## Compatibilidad multi-agente

Este kernel está diseñado para rendir **igual en cualquier agente de código**. Cada superficie lo carga distinto, pero el contrato es el mismo.

| Superficie | Cómo carga este kernel | Identificador `last_agent` |
|---|---|---|
| **Codex CLI** | Lee `AGENTS.md` de la raíz del repo de forma nativa. Es su fuente directa. | `codex` |
| **Cursor** | Lee `AGENTS.md` nativo + `.cursor/rules/00-brainai-kernel.mdc` como refuerzo (`alwaysApply`). | `cursor` |
| **Claude Code** | Lo carga vía `@AGENTS.md` importado desde `CLAUDE.md`. | `claude-code` |
| **Otro agente** | Debe leer este archivo completo antes de cualquier operación. | `<nombre-agente>` |

> [!warning] Autonomía del contrato — sin imports ni symlinks
> Codex y la mayoría de agentes **no expanden** `@imports` ni siguen symlinks de Claude. Por eso este archivo no usa imports ni symlinks y contiene el **contrato completo** (ownership, reglas, schema, políticas). Los **procedimientos** de cada operación viven en `SKILLS/` y se leen al ejecutar: no son un kernel paralelo, son la referencia detallada de cada branch. Regla nueva de contrato → acá; paso nuevo de operación → SKILL.

### Invocación de operaciones en cualquier superficie

Las 10 operaciones (`/ingest`, `/query`, `/lint`, `/archive`, `/curate`, `/propose`, `/accept-proposal`, `/status`, `/gaps`, `/compose`) son **convenciones de lenguaje natural**, no slash-commands nativos de una sola superficie. El usuario las invoca por nombre (`/ingest raw/x.md`) o en lenguaje natural ("ingesta esta fuente"). El agente, habiendo leído este kernel, ejecuta la operación siguiendo el protocolo de `SKILLS/`. Funciona idéntico en Codex, Cursor y Claude.

### Glosario

- **"el agente"** = el agente de código que ejecuta (Claude Code, Codex, Cursor…). Los `SKILLS/` usan "el LLM" como sinónimo neutral.

---

## Arquitectura — Tabla de Ownership

| Directorio | Dueño | Agente lee | Agente escribe | Propósito |
|---|---|---|---|---|
| `raw/` | Humano | ✅ | ❌ nunca | Fuentes crudas e inmutables |
| `raw/feedback/` | Humano | ✅ | ⚠️ solo *crear/añadir* respuestas a brechas, con confirmación explícita del humano (única excepción acotada a REGLA 2 · ver `/gaps`) | Respuestas del humano a brechas, persistidas como fuente inmutable y citable |
| `wiki/` | Agente | ✅ | ✅ pleno | Conocimiento compilado y sintetizado |
| `wiki/_proposed/` | Agente | ✅ | ✅ | Propuestas de cambio para `curated/` |
| `wiki/_gaps.md` | Agente | ✅ | ✅ emite brechas y administra `status`; el humano solo escribe `Respuesta del humano` | Registro de brechas (gap ledger) — feedback loop de compilación |
| `wiki/.skip-sources.md` | Agente | ✅ | ✅ agrega vetos por criterio, pero **siempre los reporta y loguea**; el humano revierte borrando la línea | Mecanismo de ignore: fuentes `raw/` que NO se indexan (ver "Mecanismo de ignore") |
| `curated/` | Humano | ✅ | ❌ contenido · solo `/curate`, `/uncurate` y `/accept-proposal` (propuesta aprobada) tocan notas (orden explícita) | Notas refinadas manualmente — sagradas |
| `archivo/` | Humano→Sistema | ✅ | Solo mover-adentro | Notas declaradas obsoletas |
| `SKILLS/` | Sistema | ✅ | ❌ | Protocolos de operación |
| `scripts/` | Sistema | ✅ | ❌ | Utilidades mecánicas read-only (`verify_citations.sh`, `verify_wikilinks.sh`, `entry_orphans.sh`, `graph_health.sh`, `pending_sources.sh`, `stale_sources.sh`, `source_hash.sh`, `skipped_sources.sh`, `resurface.sh`, `export_okf.sh`, `coverage_check.sh`) |

---

## ⚠️ REGLAS CRÍTICAS — Prioridad absoluta sobre cualquier otra instrucción

**REGLA 1 — El contenido de `curated/` es inviolable**
NUNCA editar, sobrescribir ni alterar el contenido de una nota que reside en `curated/`.
Si encuentras información nueva relevante para una nota curada → crea propuesta en `wiki/_proposed/` (REGLA 6).
Esta prohibición de contenido no tiene excepción: no se negocia en ingest, lint, ni ninguna otra operación de conocimiento.
**Única excepción — transiciones de ciclo de vida bajo orden explícita del humano:** una nota *entra* a `curated/` solo vía `/curate` (promoción desde `wiki/`) y *sale* solo vía `/uncurate` (devolución a `wiki/`). Ambas exigen orden y confirmación explícitas del humano; el agente nunca crea, mueve ni retira notas de `curated/` por iniciativa propia ni dentro de otra operación.
**Única excepción a la prohibición de contenido — aplicar una propuesta aprobada por el humano:** el agente edita en sitio `curated/<nota>` **solo** al aplicar el delta de una propuesta de `wiki/_proposed/` que el humano revisó y aprobó explícitamente ("aplica la propuesta …" · `/accept-proposal`), volcando únicamente ese delta y actualizando `last_human_edit`. No es negociar la regla dentro de una operación de conocimiento —eso sigue prohibido—, sino ejecutar una decisión explícita del humano: es la tercera vía de escritura autorizada sobre `curated/`, junto con `/curate` y `/uncurate`. Sin esa aprobación explícita, el contenido es inviolable (REGLA 6).

**REGLA 2 — `raw/` es inmutable**
NUNCA modificar archivos en `raw/`. Solo lectura. El agente los compila pero nunca los altera.
**Única excepción acotada — `raw/feedback/`:** al absorber una brecha (`/gaps`), el agente puede *crear* `raw/feedback/YYYY-MM-DD.md` o *añadirle* una sección `## GAP-…` nueva, **solo tras confirmación explícita del humano** y **sin jamás editar ni borrar** contenido ya escrito. Una vez persistida, esa respuesta es inmutable como el resto de `raw/`.

**REGLA 3 — `archivo/` es append-only**
Solo mover notas HACIA `archivo/`. Nunca extraerlas. Solo cuando el humano lo ordena explícitamente con las palabras "archiva X" o "mueve X a archivo".
**Única excepción — `/unarchive` bajo orden explícita del humano:** una nota *sale* de `archivo/` solo vía `/unarchive` (recuperación de una nota archivada), que la devuelve a `wiki/`. Exige orden y confirmación explícitas del humano ("recupera X" / "recupera archivo/X"); el agente nunca extrae notas de `archivo/` por iniciativa propia ni dentro de otra operación.

**REGLA 4 — Leer `wiki/index.md` primero**
Antes de cualquier operación que lea conocimiento o modifique el índice (`/query`, `/ingest`, `/lint`, `/curate`, `/archive`, `/propose`, `/accept-proposal`, `/gaps`): leer el index completo para orientarse. Única excepción: `/status`, que cuenta archivos sin necesidad de leer el index (puede leerlo si quiere validar consistencia).

**REGLA 5 — `wiki/log.md` es append-only**
Solo agregar al final. Nunca borrar ni editar entradas existentes.

**REGLA 6 — Proponer, no imponer, sobre `curated/`**
Si información nueva actualiza o contradice `curated/<nota>`:
→ Crear `wiki/_proposed/YYYY-MM-DD-<nombre-nota>.md` con el diff propuesto.
→ Nunca tocar la nota curada.

**REGLA 7 — `wiki/_gaps.md` es el registro de brechas (feedback loop)**
El agente **emite** brechas (preguntas al humano) durante `/ingest`, y también durante `/compose` cuando detecta un **patrón candidato** al leer varias notas ya compiladas (tipo `patron-candidato` — ver más abajo y `SKILLS/compose.md §Patrón candidato`); las **absorbe** durante `/gaps` o el siguiente `/ingest`. Restricciones:
→ Solo se emiten brechas de nivel **N1** (Pirámide de señal), con tope de **≤3 por `/ingest`** (el ciclo de `/compose` comparte el mismo tope, no un pool aparte), cada una con pregunta concreta + por qué importa + qué desbloquea. Lo que no califica queda como `[INFERIDO]`/`[FUENTE NO PERSISTIDA]`, recuperable luego por `/lint`.
→ **`patron-candidato` es la única vía para que una observación de 2º orden entre al grafo, y nunca sin el humano.** Si el agente, al leer varias notas `wiki/` ya compiladas, nota un patrón que ninguna dice por separado, **no crea una nota nueva** — eso sería sintetizar conocimiento sin una fuente `raw/` puntual, y rompe el principio de que el agente es recolector, no autor. Solo puede emitir un GAP tipo `patron-candidato` preguntando si el patrón es real. La nota nueva —si corresponde— nace recién al absorber la confirmación del humano, citándola como fuente (Opción C de `/gaps`, igual que cualquier otra brecha). Si el humano dice que es coincidencia, no se crea nada.
→ El agente administra el campo `status` (`open → resolved | stale | unanswered | dropped`) y todos los campos; **el humano solo escribe `Respuesta del humano`**.
→ **Techo de stock (calcado del Mecanismo de ignore):** el tope `≤3 por ingest` limita el flujo, no el total acumulado. Para que "## Brechas abiertas" no crezca sin techo, una brecha sin respuesta pasado un umbral adicional tras `stale` (**> 60 días desde su emisión**) pasa a `status: unanswered` y se **mueve** a "## Brechas sin respuesta (archivadas)" durante `/lint` (o `/gaps`). Autónomo pero **visible** (reportado en la ENTREGA, logueado, contado en `/status`) y **reversible a mano** por el humano (responder o mover de vuelta). Detalle en `SKILLS/gaps.md §Higiene del registro`.
→ Absorber respeta ownership: si la nota afectada es de `curated/` → `/propose` (REGLA 6, nunca editar curated/); si la respuesta se persiste a `raw/feedback/` → confirmación explícita (REGLA 2).
→ Una entrada nunca se borra: se marca `resolved`/`dropped`/`unanswered` y se mueve a la sección que corresponda (histórico o archivadas). Archivar una brecha es higiene interna de `wiki/_gaps.md`, **no** es REGLA 3 (`/archive` → `archivo/`).

**REGLA 8 — Una nota = un átomo; el cerebro es una red, no un archivador**
El conocimiento se compila como **red de notas atómicas enlazadas**, nunca como pocos documentos temáticos gigantes. De aquí salen cuatro obligaciones no negociables:
→ **Atomicidad:** cada nota cubre **un solo sujeto** (una entidad, un concepto, un patrón, un incidente). Si una fuente toca 5 entidades, produce ~5 notas enlazadas, no 1 nota con 5 secciones.
→ **Extracción de nodos:** las entidades y conceptos reutilizables (N1) se **extraen como notas propias** (`type: entity`/`concept`) y se **enlazan**; nunca se reabsorben dentro de una nota-guía. Son los hubs del grafo.
→ **Anti-centralización (fan-in):** ninguna nota debe acaparar el conocimiento. Una nota que supera **~12 fuentes `raw/` distintas** o **~150 líneas** es señal de fragmentar en átomos + un MOC que los agrupe (ver `/ingest`, `/lint`). El default ante "¿actualizar o crear?" es **crear el átomo que falta**, no engordar el cubo existente.
→ **Enlazamiento constructivo:** toda nota nueva enlaza a **≥2 notas existentes con relación tipada** (ver Política de Enlazamiento) y queda registrada en su MOC. Un enlace repetido en masa o una mención sin relación no cuentan: el valor está en conectar átomos distintos, no en repetir el mismo wikilink.

> [!important] Composición incremental, no pasada única
> Cada `/ingest` **mejora la red**: enlaza lo nuevo con lo existente, extrae nodos que faltaban, parte cubos que crecieron de más. El cerebro se vuelve más útil iteración tras iteración — no es un volcado de una sola pasada. Ver "Modelo de Conocimiento".

---

## Principio LLM-first (v2.3)

> [!important] El modelo hace el juicio; el shell hace lo trivial
> No hay linter ni merge propios. El agente lee las notas, compara secciones, decide y aplica;
> para lo mecánico usa lo que ya existe: `verify_wikilinks.sh`, `verify_citations.sh`,
> `graph_health.sh`, `coverage_check.sh`, `sha256sum`/`shasum` y `git diff`.

- **Menos scripts, más criterio:** cada script nuevo es deuda de mantenimiento. Solo se agrega
  uno si el LLM no puede hacer la tarea de forma fiable y barata.
- **Verificación nativa:** links/citas/grafo con los scripts existentes; hashes con `sha256sum`
  (o `shasum -a 256` en macOS); diffs con `git diff`/`diff -u`; archivo con `mv`.
- **La seguridad no es un script:** el hard-lock real es el sandbox del agente (sin write sobre
  `curated/`) o permisos del SO. La regla de texto + confirmación humana sigue siendo el contrato.
- **Costo:** el chequeo mecánico es barato; el juicio semántico se acota a candidatas
  (`stale`, baja confianza, fan-in, cambios desde el último lint). `/lint --full` es explícito.

---

## Modelo de Conocimiento — Red de átomos enlazados

> [!abstract] El porqué de la REGLA 8
> Un cerebro digital útil para un agente IA no es un conjunto de documentos largos: es un **grafo navegable** donde cada nodo es un átomo recuperable y los enlaces transportan contexto. Notas gigantes obligan al agente a tragar 50 KB para extraer un dato; una red de átomos deja recuperar exactamente el nodo relevante y expandir por sus enlaces.

### Los `type` no son etiquetas: son roles en el grafo

| `type` | Rol en el grafo | Regla de creación |
|---|---|---|
| `entity` | **Nodo-hub.** App, servicio, API, sistema, persona, equipo. Lo que muchas notas referencian. | Una por sujeto. Se crea apenas una fuente la describe con sustancia. Máxima prioridad de extracción. |
| `concept` | **Nodo-hub.** Patrón teórico, principio, técnica reutilizable. | Una por concepto. Se extrae cuando reaparece en ≥2 contextos. |
| `pattern` | Patrón de incidente/solución recurrente con nombre. | Una por patrón. Enlaza a las `entity` afectadas. |
| `incident` | RCA/post-mortem de un evento concreto. | Una por evento. Enlaza a `entity`, `pattern` y `concept` involucrados. |
| `guide` | **Orquestador.** How-to/runbook. **Enlaza** entidades y conceptos; **no** reabsorbe su contenido. | Solo si el procedimiento aporta valor propio. Tiende a ser corta y muy enlazada. |
| `comparison` | A vs B, trade-offs. Enlaza a las `entity`/`concept` comparadas. | Una por decisión comparada. |
| `moc` | **Mapa de Contenido (Map of Content).** Índice navegable de un dominio: enlaza y ordena los átomos del dominio con una línea de contexto cada uno. | Una por dominio activo. Reemplaza el catálogo plano del index. |
| `summary` | Síntesis transversal de varios átomos (rara). | Solo si agrega lectura que los átomos no dan por separado. |

> [!warning] Anti-patrón que originó esta versión del kernel
> La nota-guía gigante que absorbe 20-80 fuentes y menciona todo sin enlazar a nodos propios. Resultado: el conocimiento se centraliza, los enlaces se repiten, el grafo no crece. **Una `guide` que contiene la descripción de sus entidades está mal compilada**: esas entidades debían ser `entity` enlazadas.

### Capa de navegación: MOC-first

```
index.md  (catálogo de MOCs — no de notas sueltas)
   └─ moc:<dominio>        ← un Mapa de Contenido por dominio
        ├─ entity:<app-A>  ← nodos-hub
        ├─ entity:<app-B>
        ├─ concept:<X>
        ├─ pattern:<P>     ← enlaza a entity:<app-A>
        └─ incident:<I>    ← enlaza a pattern:<P> + entity:<app-B>
```

El `index.md` lista **MOCs** (puerta de cada dominio) y los nodos sueltos aún no agrupados. Cada MOC enlaza sus átomos. Un agente que consulta entra por el MOC del dominio y navega enlaces hasta el átomo exacto — no lee notas de 50 KB.

---

## Mecanismo de ignore — `wiki/.skip-sources.md`

> [!important] Qué fuentes de `raw/` NO entran al cerebro — y por qué el humano siempre lo sabe
> No todo lo que vive en `raw/` es conocimiento compilable: hay notas vacías, duplicados exactos y material personal fuera de alcance. Para no re-evaluarlas en cada ciclo, el agente las anota en `wiki/.skip-sources.md`. **`pending_sources.sh` y `stale_sources.sh` filtran esta lista ANTES de armar la cola**, así que una fuente vetada *no compila aunque el humano la edite*. Por eso el mecanismo es **explícito y visible**, nunca silencioso.

**Las tres categorías válidas de veto** (toda entrada cae en una):

| Categoría | Significado | Verificable |
|---|---|---|
| `vacía` | Sin señal compilable (archivo vacío o casi) | Objetiva |
| `duplicado` | Copia exacta de otra fuente ya compilada | Objetiva (byte a byte) |
| `fuera-de-alcance` | No es conocimiento operativo del vault (personal, presupuesto, etc.) | De juicio |

**Gobernanza — autónomo pero siempre visible:** el agente **puede** agregar vetos por su criterio (incluida la categoría de juicio), sin pedir confirmación previa, **a condición de que sea transparente**:
- **Reportar** en la ENTREGA de `/ingest` y `/compose` cada fuente recién vetada, con su categoría y razón ("Vetadas: `raw/x.md` — fuera-de-alcance: …").
- **Loguear** en `wiki/log.md` el veto (`Vetadas: …`).
- Quedar visible en `bash scripts/skipped_sources.sh` y en el conteo de `/status`.
- Escribir la entrada con el formato completo: `raw/ruta.md — <razón> · [categoría] · YYYY-MM-DD · <agente>`.

**Reversibilidad (decisión del humano):** un veto no es sagrado — lo puso el agente por heurística. El humano lo revierte **borrando la línea** de `wiki/.skip-sources.md`; en el próximo `/ingest`/`/compose` la fuente vuelve a la cola. Quitar un veto **nunca** toca `raw/` (sigue siendo inmutable): solo readmite el archivo al pipeline.

**Higiene:** `bash scripts/skipped_sources.sh --orphans` lista vetos cuyo archivo ya no existe en `raw/` (limpiables del skip).

---

## Router de operaciones

> Este archivo define **qué** es válido (ownership, reglas, schema). El **cómo** de cada operación vive en su SKILL y se carga al ejecutar. Si cambia un paso, se edita el SKILL; si cambia una regla, se edita acá.

| Operación | Disparador | Done (criterio de cierre) | Protocolo |
|---|---|---|---|
| `/ingest` | Fuente nueva en `raw/`, stale, o feedback de GAP | Átomos creados/actualizados; ≥2 enlaces; MOC/index/log; GAPs ≤3; `curated/` intacto | `SKILLS/ingest.md` |
| `/query` | Pregunta del humano | Respuesta con citas + páginas consultadas; cada hecho citado o marcado | `SKILLS/query.md` |
| `/lint` | El humano pide `/lint` o revisar salud | Scripts mecánicos corridos; alcance declarado; reporte + log; `curated/` intacto | `SKILLS/lint.md` |
| `/archive` | Orden explícita: "archiva X" | Nota en `archivo/`; índice/log; ya no está en `wiki/` | `SKILLS/archive.md` |
| `/curate` | El humano pide congelar una nota | `en_tus_palabras` recibido; schema `curated/`; índice/log; nota movida | `SKILLS/curate.md` |
| `/propose` | Ingest/lint detecta info que afecta `curated/` | Propuesta con target + diff + justificación; `curated/` intacto | `SKILLS/propose.md` |
| `/accept-proposal` | El humano aprobó una propuesta | Hash verificado; solo la sección aprobada; `last_human_edit`; archivo/log/índice | `SKILLS/accept-proposal.md` |
| `/status` | Inicio de sesión o pedido del humano | Tabla de estado; cero escrituras | `SKILLS/status.md` |
| `/gaps` | El humano pide absorber o ver brechas | Respuestas absorbidas con cita; status/log; `curated/` vía `/propose` | `SKILLS/gaps.md` |
| `/compose` | El humano pide el loop | DEUDA bajó o punto fijo; presupuesto respetado; log; `curated/` intacto | `SKILLS/compose.md` |

**Invariantes de toda operación:** leer `wiki/index.md` primero (REGLA 4, salvo `/status`); respetar ownership (REGLA 1-3); `wiki/log.md` append-only (REGLA 5); leer `SKILLS/format.md` antes de escribir una nota; dudas N1 → GAP, no inventar.

---

## Frontmatter — contrato mínimo

> El schema completo vive en `SKILLS/format.md §1.0` (wiki/), `SKILLS/curate.md`
> (curated/) y `SKILLS/propose.md` (propuestas). Acá queda lo que no se puede olvidar.

**`wiki/`:** `title`, `type` (enum de REGLA 8), `description` (≤1 oración, plain text),
`resource` (entity/concept), `domain`, `tags` (≥2 en entity/concept/pattern),
`status` (active|stale), `sources`, `related` (≥2 salvo moc/entity nueva),
`created`, `updated`, `last_agent`, `confidence`.

**`curated/`:** `title`, `type: curated`, `status: human-canonical`,
`llm_action: read-only`, `human_curated: true`, `curated_date`, `last_human_edit`,
`topics`, `en_tus_palabras` (texto del humano, nunca del agente), `sources`,
`description`, `resource`.

**`archivo/`:** `title`, `original_location`, `archived_date`, `archived_reason`.

**`wiki/_proposed/`:** `target_note`, `target_sha256` (opcional), `created`,
`status: pending`, `motivated_by`. Cuerpo: `## Sección afectada`,
`## Cambio propuesto`, `## Justificación`; los bloques `brainai:replace` son
una guía de exactitud, no un parser.

`type` no es una etiqueta: es el rol del nodo en el grafo (REGLA 8). `last_agent`
registra el agente que ejecutó la operación.

---

## Política de Contradicciones

**Contradicción en `wiki/` (el agente puede resolver):**
- Actualizar página con info más reciente
- Agregar `> [!warning] Contradicción: anteriormente X, nueva fuente indica Y`
- Conservar referencia a fuente anterior

**Contradicción con `curated/` (el agente NO puede resolver directamente):**
- No tocar `curated/`
- Ejecutar `/propose`
- En la página wiki relacionada agregar: `> [!info] Posible actualización pendiente — ver wiki/_proposed/`

---

## Política de Citación / Progressive Disclosure

**Principio:** la nota wiki/ es la capa resumen; cada cita inline es un punto de entrada expandible hacia la fuente que la fundamenta. El agente reconstruye el razonamiento siguiendo esas citas bajo demanda.

**Regla maestra (trazabilidad de cada hecho):** todo hecho verificable (métrica, threshold, config, comando, decisión, gotcha) cae en uno de tres casos:
- **citado inline** `[[raw/nota#sección]]` si la fuente está persistida en `raw/`, o
- **marcado `[FUENTE NO PERSISTIDA: <origen>]`** si la fuente es real pero no está en `raw/` (conversación, doc externo) — **no** es inferencia, no usar `[INFERIDO]`, o
- **marcado `[INFERIDO]`** si es una conclusión/deducción propia, no textual en ninguna fuente.

Nunca un dato factual sin trazabilidad. La prosa de síntesis y el texto conectivo no se citan.

**Uso de `[INFERIDO]` (evitar ruido):** solo para conclusiones útiles no textuales; **no** para reformulaciones obvias de algo ya citado. Si hay varias inferencias juntas, agruparlas en `## Inferencias` o en `> [!question]`.

**Restricciones:**
- `raw/` es inmutable → solo links a nota `[[raw/nota]]` o a sección `[[raw/nota#encabezado]]`, **nunca** block-ids (`^id`) en raw.
- En tablas: columna `Fuente` con pipe escapada (`[[raw/nota#sección\|alias]]`).
- `sources[]` y `## Fuentes` son el superset consolidado de las citas inline.
- Verificación de integridad: `bash scripts/verify_citations.sh` (ver `/lint`).

---

## Política de Enlazamiento (REGLA 8)

**Principio:** si la cita conecta un átomo con su fuente en `raw/` (procedencia), el **enlace tipado** conecta un átomo con otro átomo (conocimiento). El cerebro vale por su grafo: los enlaces transportan el contexto que un agente IA recorre. Un enlace sin relación clara, o el mismo wikilink repetido en masa, es ruido — no señal.

**Densidad mínima:** toda nota (salvo `moc` y una `entity`/`concept` recién nacida sin pares aún) enlaza a **≥2 notas existentes**. Si no hay a qué enlazar, suele faltar extraer un nodo (`entity`/`concept`) — extraerlo es parte del trabajo.

> [!note] Cold start dentro de un mismo `/ingest`
> "Sin pares aún" se evalúa contra **todo el vault en el momento de crear la nota**, no solo contra notas de ingests anteriores. Si un mismo `/ingest` extrae varios átomos de una fuente rica, el primero puede estar exento (nada más existe todavía), pero el segundo y siguientes **ya tienen al primero como par real** — deben enlazarlo (y buscar un segundo enlace si corresponde), no asumir la exención solo por haber nacido en el mismo pase.

**Relaciones tipadas:** cada enlace lleva una relación que dice *por qué* conecta. Vocabulario base (extensible):

| Relación | Significado | Ejemplo |
|---|---|---|
| `define` | A es la definición canónica de un término que B usa | `guide` → `entity` |
| `depende-de` | A necesita a B para funcionar | `entity:A depende-de entity:B` |
| `instancia-de` | A es un caso concreto del patrón/concepto B | `incident` → `pattern` |
| `afecta-a` | A (patrón/incidente) impacta a la entidad B | `pattern` → `entity` |
| `contradice` | A sostiene algo que niega a B (con `> [!warning]`) | dos versiones de un hecho |
| `ver-también` | relación lateral útil sin las anteriores | átomos vecinos |

**Dónde viven los enlaces:**
- **Inline,** donde la relación nace en el texto (preferido para contexto local).
- En una sección **`## Relacionado`** al final, una línea por enlace: `- depende-de :: [[wiki/nota]] — por qué`.
- Reflejados en **`related[]`** del frontmatter (espejo de `## Relacionado`).

**Bidireccionalidad:** al enlazar A→B con una relación fuerte (`depende-de`, `define`, `afecta-a`), agregar el enlace recíproco en B si aún no existe. El grafo se navega en ambos sentidos.

**Anti-ruido:** no enlazar por enlazar. Un MOC que repite el mismo wikilink, o una nota que enlaza 10 veces a la misma entidad, no agregan grafo. Prefiere **conectar átomos distintos**.

---

## SKILLS

Los 10 protocolos operativos viven en `SKILLS/`; el router de arriba dice cuándo leer cada uno. Transversales:

- `SKILLS/format.md` — **siempre** antes de crear o modificar una nota.
- `SKILLS/gaps-ejemplo.md` — insumo de `/gaps` (no es una operación).

Los SKILLS son de solo lectura: el agente los consume, no los modifica.

> ⚠️ Un formato incorrecto rompe links, callouts y tablas en Obsidian silenciosamente.
