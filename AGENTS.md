# BrainAI · Kernel Schema v2.2

> Kernel canónico del LLM Wiki personal del humano — **fuente de verdad única, agnóstica de agente**.
> El agente compila y mantiene `wiki/`. El humano refina y protege `curated/`. Nadie extrae de `archivo/`.

> [!important] Este archivo es la CPU del sistema
> Todo agente de código que opere este repositorio (Codex, Cursor, Claude Code, u otro) lee **este** archivo como contrato único. No hay un kernel paralelo: lo que antes vivía en `CLAUDE.md` ahora vive aquí. `CLAUDE.md` solo importa este archivo.

---

## Núcleo mínimo — si solo leés esto, ya funcionás bien

> El resto de este archivo es la referencia completa (excepciones, formato, casos borde). Esta sección es la idea entera en su forma más chica — fiel al gist original de Karpathy: compilar una vez, no re-derivar en cada consulta.

1. **Tres capas.** `raw/` = fuentes crudas e inmutables (el agente nunca las toca). `wiki/` = lo que el agente compila: notas markdown atómicas y enlazadas. Este archivo = el schema que gobierna cómo se compila.
2. **El loop mínimo son 3 verbos:**
   - **`/ingest <fuente>`** — lee `raw/`, extrae una nota por sujeto (nunca un documento gigante), la enlaza a ≥2 notas existentes con una relación con nombre, cita cada hecho.
   - **`/query <pregunta>`** — nunca re-lee `raw/` desde cero: entra por `wiki/index.md`, navega enlaces, responde con citas.
   - **`/lint`** — chequea que el grafo siga sano (links rotos, huérfanas, contradicciones).
3. **Tres cosas que nunca se negocian:** `raw/` no se edita jamás. El contenido de `curated/` no se edita directo (se propone un cambio). Cada hecho lleva marca de procedencia: citado, `[FUENTE NO PERSISTIDA]`, o `[INFERIDO]`.
4. **Todo lo demás es opcional sobre este loop, no el núcleo:** `/curate` (congelar una nota como canónica, con una línea humana), `/archive`, `/gaps` (el agente pregunta cuando algo importante queda ambiguo), `/compose` (correr el loop varias veces solo). El sistema funciona sin que ninguno de estos se use nunca.

Si una regla detallada más abajo parece contradecir este resumen, la regla detallada gana — esto es un mapa, no el territorio.

---

## Compatibilidad multi-agente

Este kernel está diseñado para rendir **igual en cualquier agente de código**. Cada superficie lo carga distinto, pero el contrato es el mismo.

| Superficie | Cómo carga este kernel | Identificador `last_agent` |
|---|---|---|
| **Codex CLI** | Lee `AGENTS.md` de la raíz del repo de forma nativa. Es su fuente directa. | `codex` |
| **Cursor** | Lee `AGENTS.md` nativo + `.cursor/rules/00-brainai-kernel.mdc` como refuerzo (`alwaysApply`). | `cursor` |
| **Claude Code** | Lo carga vía `@AGENTS.md` importado desde `CLAUDE.md`. | `claude-code` |
| **Otro agente** | Debe leer este archivo completo antes de cualquier operación. | `<nombre-agente>` |

> [!warning] Autonomía del archivo — no usar imports ni symlinks
> Codex y la mayoría de agentes **no expanden** `@imports` ni siguen symlinks de Claude. Por eso este archivo es **autónomo y completo**: no referencia "leer otro archivo para las instrucciones completas". Si agregas contenido al kernel, va aquí, no en `CLAUDE.md`.

### Invocación de operaciones en cualquier superficie

Las 9 operaciones (`/ingest`, `/query`, `/lint`, `/archive`, `/curate`, `/propose`, `/status`, `/gaps`, `/compose`) son **convenciones de lenguaje natural**, no slash-commands nativos de una sola superficie. El usuario las invoca por nombre (`/ingest raw/x.md`) o en lenguaje natural ("ingesta esta fuente"). El agente, habiendo leído este kernel, ejecuta la operación siguiendo el protocolo de `SKILLS/`. Funciona idéntico en Codex, Cursor y Claude.

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
| `curated/` | Humano | ✅ | ❌ contenido · solo `/curate` y `/uncurate` mueven notas (orden explícita) | Notas refinadas manualmente — sagradas |
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
**Única excepción a la prohibición de contenido — aplicar una propuesta aprobada por el humano:** el agente edita en sitio `curated/<nota>` **solo** al aplicar el delta de una propuesta de `wiki/_proposed/` que el humano revisó y aprobó explícitamente ("aplica la propuesta …" · `/propose`), volcando únicamente ese delta y actualizando `last_human_edit`. No es negociar la regla dentro de una operación de conocimiento —eso sigue prohibido—, sino ejecutar una decisión explícita del humano: es la tercera vía de escritura autorizada sobre `curated/`, junto con `/curate` y `/uncurate`. Sin esa aprobación explícita, el contenido es inviolable (REGLA 6).

**REGLA 2 — `raw/` es inmutable**
NUNCA modificar archivos en `raw/`. Solo lectura. El agente los compila pero nunca los altera.
**Única excepción acotada — `raw/feedback/`:** al absorber una brecha (`/gaps`), el agente puede *crear* `raw/feedback/YYYY-MM-DD.md` o *añadirle* una sección `## GAP-…` nueva, **solo tras confirmación explícita del humano** y **sin jamás editar ni borrar** contenido ya escrito. Una vez persistida, esa respuesta es inmutable como el resto de `raw/`.

**REGLA 3 — `archivo/` es append-only**
Solo mover notas HACIA `archivo/`. Nunca extraerlas. Solo cuando el humano lo ordena explícitamente con las palabras "archiva X" o "mueve X a archivo".
**Única excepción — `/unarchive` bajo orden explícita del humano:** una nota *sale* de `archivo/` solo vía `/unarchive` (recuperación de una nota archivada), que la devuelve a `wiki/`. Exige orden y confirmación explícitas del humano ("recupera X" / "recupera archivo/X"); el agente nunca extrae notas de `archivo/` por iniciativa propia ni dentro de otra operación.

**REGLA 4 — Leer `wiki/index.md` primero**
Antes de cualquier operación que lea conocimiento o modifique el índice (`/query`, `/ingest`, `/lint`, `/curate`, `/archive`, `/propose`, `/gaps`): leer el index completo para orientarse. Única excepción: `/status`, que cuenta archivos sin necesidad de leer el index (puede leerlo si quiere validar consistencia).

**REGLA 5 — `wiki/log.md` es append-only**
Solo agregar al final. Nunca borrar ni editar entradas existentes.

**REGLA 6 — Proponer, no imponer, sobre `curated/`**
Si información nueva actualiza o contradice `curated/<nota>`:
→ Crear `wiki/_proposed/YYYY-MM-DD-<nombre-nota>.md` con el diff propuesto.
→ Nunca tocar la nota curada.

**REGLA 7 — `wiki/_gaps.md` es el registro de brechas (feedback loop)**
El agente **emite** brechas (preguntas al humano) durante `/ingest`, y también durante `/compose` cuando detecta un **patrón candidato** al leer varias notas ya compiladas (tipo `patron-candidato` — ver más abajo y `SKILLS/compose.md §Patrón candidato`); las **absorbe** durante `/gaps` o el siguiente `/ingest`. Restricciones:
→ Solo se emiten brechas de nivel **N1** (Pirámide de señal), con tope de **≤3 por `/ingest`** (el ciclo de `/compose` comparte el mismo tope, no un pool aparte), cada una con pregunta concreta + por qué importa + qué desbloquea. Lo que no califica queda como `[INFERIDO]`/`[FUENTE NO PERSISTIDA]`, recuperable luego por `/lint`.
→ **`patron-candidato` es la única vía para que una observación de 2º orden entre al grafo, y nunca sin el humano.** Si el agente, al leer varias notas `wiki/` ya compiladas, nota un patrón que ninguna dice por separado, **no crea una nota nueva** — eso sería sintetizar conocimiento sin una fuente `raw/` puntual, y rompe el principio de que el agente es recolector, no autor. Solo puede emitir un GAP tipo `patron-candidato` preguntando si el patrón es real. Solo puede emitir un GAP tipo `patron-candidato` preguntando si el patrón es real. La nota nueva —si corresponde— nace recién al absorber la confirmación del humano, citándola como fuente (Opción C de `/gaps`, igual que cualquier otra brecha). Si el humano dice que es coincidencia, no se crea nada.
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

## Operaciones Core

### /ingest — Compilar nueva fuente

**Input:** archivo en `raw/` (path) o texto directo del humano
**Autonomía:** operación sin human-in-the-loop — el agente decide todo. Dudas → default conservador (N3 > N2, comprimir > completar). Las dudas **N1** sin resolver se **persisten como brechas** en `wiki/_gaps.md` (no solo se reportan en ENTREGA); las demás quedan como `[INFERIDO]`/`[FUENTE NO PERSISTIDA]`. Nunca pausar para consultar.
**Modelo:** Map-Reduce con procedencia. MAP: extraer cada hecho junto con su `fuente#sección`. REDUCE: sintetizar nota densa conservando esa procedencia como cita inline.
**Proceso:**
0. **Absorción de brechas** (ver `/gaps` · `SKILLS/gaps.md`): si `wiki/_gaps.md` tiene brechas con `Respuesta del humano` no vacía y `status` ∈ {`open`, `stale`, `unanswered`} (incluye las archivadas — responderlas las reactiva), compilarlas **primero** (la respuesta del humano es una fuente nueva), enriquecer la nota afectada con su cita, marcar `resolved` y loguear. Nota afectada en `curated/` → `/propose` (REGLA 6).
1. Leer `wiki/index.md`
2. Leer la fuente completa (MAP: anotar cada hecho como par `{ dato → raw/nota#sección }`)
3. Extraer: entidades, conceptos, patrones, hechos clave, gotchas → filtrar por Pirámide de señal N1/N2/N3 (ver SKILLS/ingest.md §Paso 2.5); solo N1 y top N2 entran al REDUCE.
4. **Descomponer en átomos (REGLA 8).** Antes de escribir, mapear la señal a la red:
   - **Extraer nodos primero:** toda `entity`/`concept` N1 que la fuente describa con sustancia y aún no exista como nota propia → crear su nota (es un hub). No describir una entidad dentro de una guía: crear `entity:<X>` y enlazarla.
   - **Decisión átomo (invierte el default antiguo):** ¿el material es el **mismo sujeto** de una nota existente? → actualizar esa nota. ¿Es un **sujeto nuevo**, aunque el dominio coincida? → **crear nota nueva**. "Mismo dominio" NO justifica engordar una nota; solo "mismo átomo" lo hace.
   - **Guardia de fan-in:** si la nota destino ya tiene **>12 fuentes `raw/` distintas** o **>150 líneas**, no agregar más: extraer el material nuevo a su propio átomo y enlazar. Si la nota ya estaba sobredimensionada, marcarla para split en la ENTREGA.
5. Para cada átomo (creado o actualizado):
   - Existe → actualizar, marcar contradicciones con `> [!warning]`, refrescar `updated`/`last_agent`
   - No existe → crear con el `type` correcto según su rol en el grafo (ver "Modelo de Conocimiento")
   - En ambos casos: verificar nota ≤ 25% de la fuente (§Paso 3.7), correr el checklist de calidad textual (`SKILLS/format.md §17` — vaguedad sin cifra, trazabilidad, síntesis vs. hecho, comparaciones sin criterio, placeholders, alcance ambiguo) y agregar `## Insight` al final.
   - En ambos casos: completar/refrescar `description` (≤1 oración del átomo, plain text); si la fuente provee URL canónica del asset y el `type` es `entity` o `concept`, poblar `resource`; poblar `tags` con etiquetas cross-cutting del dominio (ver taxonomía en SKILLS/format.md §1.0). Si la nota existente no tiene estos campos → poblarlos oportunísticamente.
   - **Antes de ejecutar el `Write`/`Edit` que deja la nota en su versión final: Gate REGLA 8 (checklist pre-Write)** — verificar ≥2 `related` reales (salvo cold-start ya previsto en Política de Enlazamiento), `description` poblada, fan-in de destino dentro de límite y `type` correcto para su rol en el grafo. Convierte REGLA 8 de declarativa a accionable: se chequea ANTES de que el problema exista en el grafo, no después vía `/lint`. Si algún ítem falla y la nota igual se justifica (ej. primera `entity` de un dominio nuevo sin pares posibles todavía) → dejar constancia inline `> [!note] Excepción REGLA 8: <ítem> — <motivo>` en la nota misma (no alcanza con mencionarlo de pasada en la ENTREGA); nunca escribir en silencio, nunca pausar para el humano (autonomía intacta). Si falla sin justificación real → no escribir así, volver a completar lo que falta. Protocolo completo: `SKILLS/ingest.md §Paso 3.68`.
5.5. **Evolución retroactiva acotada (A-MEM · opcional).** Por cada nota en `related[]` directo (un salto, sin transitividad) de un átomo tocado que la fuente recién leída vuelve desactualizada sin mencionarla directamente: refrescar SOLO su `description`/`tags` (checklist de calificación obligatorio, nunca criterio libre), sin tocar `updated:`/`last_agent:` (evita enmascarar staleness real de `/lint`) ni su cuerpo/hechos. Tope ≤5 notas/ingest, siempre reportado en ENTREGA — incluido el caso de 0 candidatas, con motivo — y logueado. Nunca toca `curated/` (→ `/propose`). No es síntesis nueva: sigue atado a la misma fuente `raw/` que se está compilando. Protocolo completo: `SKILLS/ingest.md §Paso 3.65`.
6. **Enlazamiento constructivo (REGLA 8 · Política de Enlazamiento).** Toda nota tocada queda conectada al grafo:
   - Enlazar a **≥2 notas existentes con relación tipada** (`define`, `depende-de`, `instancia-de`, `contradice`, `ver-también`) en una sección `## Relacionado` o inline donde la relación nace.
   - Registrar el átomo en el **MOC de su dominio** (`moc:<dominio>`); si el dominio aún no tiene MOC y ya hay ≥3 átomos del dominio, crearlo.
   - No repetir el mismo wikilink en masa: cada enlace debe conectar un átomo **distinto** y aportar contexto.
7. **Citación granular:** cada hecho verificable queda citado inline `[[raw/nota#sección]]` (fuente en raw/), o `[FUENTE NO PERSISTIDA: <origen>]` (fuente real fuera de raw/), o `[INFERIDO]` (conclusión propia no textual). Solo se citan hechos con prueba directa; la prosa de síntesis no se cita. `raw/` es inmutable → links a nota o `#sección`, nunca block-ids. Consolidar fuentes en `sources[]` y en `## Fuentes`.
8. **Emisión de brechas** (Pirámide de señal · REGLA 7): por cada duda **N1** sin resolver (inferencia crítica, fuente no persistida sobre un hecho N1, contradicción sin dirimir, entidad indefinida, nota `confidence < 0.7`) → registrar brecha en `wiki/_gaps.md` (`status: open`) + dejar un `> [!question] GAP-…` inline en la nota afectada. Tope **≤3 por ingest**; el resto queda como `[INFERIDO]`/`[FUENTE NO PERSISTIDA]`.
8.5. **Revisión independiente** (solo si el ingest tocó >3 átomos o creó una `entity`/`concept` nueva): un segundo agente sin el razonamiento de compilación revisa las notas tocadas contra `raw/` (atomicidad, enlaces semánticos, sobre-inferencia sin marcar, completitud N1). Hallazgos mecánicos se corrigen directo; los ambiguos se registran como GAP (tipo `revision-independiente`, mismo tope ≤3/ingest de REGLA 7 — no un pool aparte). Nunca pausa para el humano. Protocolo completo: `SKILLS/ingest.md` §Paso 3.75.
9. Actualizar `wiki/index.md` y los MOCs afectados (nuevas entradas / modificar existentes · stat de brechas abiertas). Formato de entrada en index: `- [[wiki/nombre-nota]] — <usar el texto del campo `description` del frontmatter>` (no reescribir desde cero; la descripción del index y la del frontmatter deben coincidir).
10. Append a `wiki/log.md`: `## [YYYY-MM-DD HH:MM] ingest | <nombre fuente>` — incluir una línea `Fuentes: \`raw/ruta.md\` (sha256:…)` **por fuente compilada** (fingerprint de contenido para detección de stale; usar `bash scripts/source_hash.sh --line raw/ruta.md`), más nodos extraídos, enlaces creados y notas marcadas para split. El log es append-only (REGLA 5): nunca backfillear hashes en entradas viejas.
11. Si info relevante para `curated/` → ejecutar `/propose` automáticamente
12. **Nunca** tocar `curated/`, `raw/` (salvo la excepción `raw/feedback/` de REGLA 2, con confirmación), ni `archivo/`

---

### /query — Consultar la wiki

**Input:** pregunta del humano
**Proceso:**
1. Leer `wiki/index.md` completo
2. Identificar el **MOC del dominio** relevante (puerta de entrada) y/o las páginas relevantes por título + descripción
3. **Navegar el grafo:** abrir el MOC, leer los átomos que enlaza y seguir sus enlaces tipados (`## Relacionado`) hasta el nodo exacto que responde — recuperar el átomo, no documentos enteros
4. Leer páginas curated/ relacionadas si el index o los átomos las referencian
5. Sintetizar respuesta con citas explícitas `([[página]])`
6. **Auto-verificar (patrón CRITIC) antes de entregar:** releer cada afirmación del borrador — la que no esté dicha en una página consultada se marca `[INFERIDO]` o se elimina; nunca corregir después de mostrar la respuesta. Protocolo completo: `SKILLS/query.md`.

**Output:** respuesta ya auto-verificada + lista de páginas consultadas (incluido el MOC de entrada)

---

### /lint — Health-check del sistema

**Proceso:**
1. Recorrer todas las páginas en `wiki/` (guiarse por index.md)
2. Verificar por cada página:
   - Links rotos → `[[nota]]` que no existe
   - Citas rotas → `[[raw/nota#sección]]` a archivo o sección inexistente (`bash scripts/verify_citations.sh`)
   - Hechos sin trazabilidad → enunciado factual sin cita inline ni marca `[INFERIDO]`
   - Páginas huérfanas → sin links entrantes desde index ni desde otras páginas
   - Contradicciones entre páginas → claims que se niegan mutuamente
   - Stale → `status: stale` o `updated` > 90 días sin revisión
2.5. **Salud del grafo (REGLA 8) — diagnóstico de la red, no solo de cada nota:**
   - **Fan-in excesivo (centralización):** notas con **>12 fuentes `raw/` distintas** o **>150 líneas** → candidatas a split en átomos + MOC.
   - **Huérfanas de salida:** notas con **0 enlaces salientes** a otras notas wiki → no participan del grafo.
   - **Sub-enlazadas:** notas con **<2 enlaces tipados** → violan la densidad mínima de enlazamiento.
   - **Monocultivo de tipo:** si **>70%** de las notas comparten un solo `type` → la extracción de nodos (`entity`/`concept`) está fallando.
   - **Entidades sin nodo:** entidad mencionada con `[[wiki/...]]` o repetidamente por nombre pero **sin nota `entity` propia** → nodo-hub faltante.
   - **Dominios sin MOC:** dominio con **≥3 átomos** y sin `moc:<dominio>` → falta puerta de navegación.
   - **Enlaces repetidos en masa:** mismo wikilink presente en una proporción anómala de notas sin relación tipada → ruido de enlazamiento.
   - **Brechas resueltas sin absorción verificable:** brecha `status: resolved` en `wiki/_gaps.md` cuya nota afectada no cita el GAP (ni como `[[raw/feedback/...#GAP-…]]` ni como `[FUENTE NO PERSISTIDA: feedback el humano GAP-…]`) → cerrada "de palabra", sin que ningún átomo la absorbiera de verdad (REGLA 7).
   - **Entradas de MOC sin sustancia:** wikilink de un `moc:<dominio>` que resuelve a una nota existente pero vacía o stub (sin `description`, sin cuerpo real más allá del frontmatter) → el link no está roto, pero tampoco enseña nada — cobertura de fachada.
3. Verificar `wiki/_proposed/` → listar propuestas pendientes de revisión del humano
4. Verificar `wiki/_gaps.md` → brechas `open` respondidas-sin-procesar (sugerir `/gaps`), `open` > 14 días (marcar `stale`), sin respuesta > 60 días desde emisión (archivar: `unanswered` → mover a "## Brechas sin respuesta (archivadas)", reportándolo), y brechas que apuntan a notas inexistentes
5. Generar `wiki/lint-YYYY-MM-DD.md` con reporte + acciones sugeridas
6. Append a `wiki/log.md`
7. **Nunca** modificar `curated/` durante lint

---

### /archive — Declarar nota obsoleta

**Trigger:** Solo con orden explícita del humano ("archiva X" / "mueve X a archivo")
**Alcance:** opera sobre notas de `wiki/`. Una nota de `curated/` no se archiva directamente (REGLA 1): para jubilarla, primero `/uncurate` (curated→wiki) y luego `/archive` (wiki→archivo), dejando ambos pasos trazados en el log.
**Proceso:**
1. Leer la nota origen
2. Agregar al frontmatter: `archived_date: YYYY-MM-DD`, `archived_reason: <razón>`
3. Mover archivo a `archivo/`
4. Actualizar `wiki/index.md`: remover entrada o marcar `~~[ARCHIVADO]~~`
5. Append a `wiki/log.md`: `## [FECHA] archive | <nombre> — <razón>`
6. Confirmar al humano que el original fue movido y ya no existe en su ubicación original

---

### /curate — Proteger nota como curada

**Trigger:** el humano quiere congelar una nota existente en `wiki/`
**Proceso:**
1. Leer la nota (debe estar en `wiki/`)
2. **Pedir al humano `en_tus_palabras`** (1-2 líneas, la idea central en sus propias palabras — no una copia de `description`). Bloquea el resto del proceso hasta recibirla: es la única fricción intencional del pipeline, a cambio de recuperar parte del aprendizaje-por-escritura justo en las notas que más se van a reusar (ver nota debajo del schema `curated/`).
3. Reescribir el frontmatter al schema `curated/` (cambia `type`→`curated`, `status`→`human-canonical`, agrega `topics` y `en_tus_palabras`; ver Frontmatter Schemas)
4. Mover de `wiki/<nota>.md` a `curated/<nota>.md`
5. Actualizar `wiki/index.md`: marcar entry como `[CURATED] [[curated/nota]]`
6. Append a `wiki/log.md`: `## [FECHA] curate | wiki/<nota> → curated/<nota>`
7. Confirmar al humano — a partir de este momento el agente no modificará esa nota

**Inversa — `/uncurate`:** devuelve una nota de `curated/` a `wiki/` (curated→wiki) reconstruyendo el schema `wiki/`. Junto con `/curate` es la única vía autorizada para mover notas dentro/fuera de `curated/` (REGLA 1). Protocolo en `SKILLS/curate.md` §Reversa.

---

### /propose — Proponer cambio a nota curada

**Trigger:** durante ingest cuando nueva info afecta `curated/<nota>`
**Proceso:**
1. Identificar exactamente qué nota curada se ve afectada
2. Crear `wiki/_proposed/YYYY-MM-DD-<nombre-nota>.md`:
   ```
   # Propuesta: actualización para curated/<nombre-nota>

   **Motivado por:** <fuente>
   **Fecha:** YYYY-MM-DD

   ## Sección afectada
   > [cita de la sección actual en curated/]

   ## Cambio propuesto
   [diff: qué agregar / modificar / aclarar]

   ## Justificación
   [por qué esta información supera o complementa lo existente]
   ```
3. Append a `wiki/log.md`: `## [FECHA] proposed | curated/<nota> — pendiente revisión el humano`
4. **NUNCA** tocar `curated/<nota>`

---

### /gaps — Absorber y reportar brechas

**Qué es:** la capa de persistencia + resolución del feedback loop. Las brechas se **emiten** durante `/ingest` (Paso 6) y se **absorben** aquí (o en `/ingest` Paso 0). Cierra el lazo: el humano responde en `wiki/_gaps.md`, una compilación futura lo lleva al conocimiento (`wiki/`, y si madura → `/curate`).
**Trigger:** el humano invoca `/gaps` (absorber ya, sin esperar un ingest) o pide el estado de brechas. La absorción también corre automática al inicio de cada `/ingest`.
**Proceso (absorción):**
1. Leer `wiki/index.md` y `wiki/_gaps.md`
2. Seleccionar brechas con `Respuesta del humano` no vacía y `status` ∈ {`open`, `stale`, `unanswered`} (responder una brecha archivada la reactiva)
3. Para cada una, tratar la respuesta del humano como **fuente nueva** y compilarla en la nota afectada con su cita:
   - **Durable / alto valor** (decisión, threshold, definición reusable, candidata a `curated/`) → proponer persistir a `raw/feedback/YYYY-MM-DD.md` (el humano confirma la escritura · REGLA 2) y citar `[[raw/feedback/YYYY-MM-DD#GAP-…]]`.
   - **Efímero** → citar `[FUENTE NO PERSISTIDA: feedback el humano GAP-…]`.
   - Nota afectada en `curated/` → **no editar** → `/propose` (REGLA 6).
4. Quitar el `> [!question] GAP-…` inline de la nota afectada (ya resuelto) y marcar la brecha `status: resolved` (mover al histórico de `wiki/_gaps.md`)
5. Actualizar `wiki/index.md` (stat de brechas) y append a `wiki/log.md`: `## [FECHA] gaps | GAP-… resuelto → wiki/<nota>`

**Higiene:** archivar (`unanswered`, mover a "## Brechas sin respuesta (archivadas)") las brechas sin respuesta > 60 días desde emisión — mover, nunca borrar; reportar y loguear cada archivado (techo de stock · REGLA 7).
**Reporte:** si no hay respuestas para absorber, listar brechas abiertas (id, nota, días), cuáles esperan respuesta del humano y cuáles se archivaron. Protocolo completo en `SKILLS/gaps.md`.

---

### /status — Dashboard del sistema

**Proceso:**
1. Contar archivos: wiki/ | curated/ | raw/ | archivo/ | _proposed/
2. Leer últimas 10 entradas de `wiki/log.md`
3. Listar propuestas pendientes en `wiki/_proposed/` (si existen)
4. Contar brechas en `wiki/_gaps.md`: `abiertas: N (M respondidas sin procesar) · sin respuesta (archivadas): A`
5. Contar fuentes vetadas: `bash scripts/skipped_sources.sh --score` → `vetadas (skip): N` (transparencia del Mecanismo de ignore)
6. Reportar estado en formato tabla

---

### /compose — Composición autónoma continua (auto-mejora del grafo)

**Qué es:** la meta-operación que permite **dejar el cerebro compilando por horas y que mejore en cada ciclo** — no una pasada única. Toma el estado actual del grafo y lo deja mejor cada vez, hasta **punto fijo** (nada que mejorar) o agotar el presupuesto. Es el cierre del principio "composición incremental" (REGLA 8). Orquesta las operaciones existentes; no inventa conocimiento.

**Autonomía:** sin human-in-the-loop (como `/ingest`). Respeta TODO el ownership: **nunca** toca `raw/`, `curated/` (→ `/propose`) ni `archivo/`. Las dudas N1 → brechas (REGLA 7, tope ≤3 por ciclo de ingest).

**Invariante de mejora — qué significa "mejor" (medible, no estético):** se mide con `bash scripts/graph_health.sh --score`, que emite un índice **DEUDA** numérico y repetible. Cada ciclo debe **bajar DEUDA** (al menos una métrica baja sin subir otra):
- fan-in excesivo (centralización) ↓
- huérfanas de salida / sub-enlazadas (conectividad) ↓
- entidades sin nodo (cobertura de hubs) ↓
- dominios sin MOC (navegabilidad) ↓
- monocultivo de tipo ↓

> [!success] El loop se auto-verifica
> Correr `graph_health.sh --score` antes y después de cada ciclo **prueba** la mejora (DEUDA bajó) en vez de suponerla. `DEUDA=0` es el punto fijo: el cerebro está sano y `/compose` se detiene solo.

**Loop (cada ciclo):**
0. **Medir baseline:** `bash scripts/graph_health.sh --score` → guardar DEUDA inicial del ciclo.
1. **Cola de entrada:** `bash scripts/stale_sources.sh` → fuentes `raw/` modificadas después de compilar (stale). Si alguna afecta `curated/` → `/ingest` urgente (genera `/propose`). `bash scripts/pending_sources.sh` → fuentes nuevas sin compilar. Procesar stale antes que pending. Si ninguna cola tiene fuentes → saltar al refactor.
2. **Diagnóstico:** `bash scripts/graph_health.sh` → lista priorizada de deuda (notas-cubo, huérfanas, dominios sin MOC…).
2.5. **Patrón candidato (detección, nunca creación).** Si al leer las notas del diagnóstico ≥3 átomos del mismo dominio/MOC sugieren una observación de 2º orden que ninguna dice por separado → **nunca crear la nota**: emitir un GAP tipo `patron-candidato` (mismo tope ≤3/ciclo de REGLA 7, no un pool aparte) preguntando al humano si el patrón es real. No cuenta como refactor ni afecta el invariante de DEUDA del Paso 4; el ciclo sigue con el refactor normal. Protocolo: `SKILLS/compose.md §Patrón candidato`.
3. **Un refactor seguro** (el de mayor impacto):
   - nota-cubo (fan-in excedido) → **split**: extraer `entity`/`concept`, mover cada sujeto a su átomo, dejar la guía como orquestador enlazado.
   - entidad sin nodo → crear el hub `entity` y reapuntar menciones.
   - huérfana / sub-enlazada → añadir enlaces tipados (o extraer el nodo que falta).
   - dominio sin MOC → crear `moc-<dominio>`.
4. **Verificar:** `bash scripts/verify_citations.sh` (citas íntegras) + `bash scripts/graph_health.sh --score` (DEUDA bajó). Si DEUDA no bajó o subió → revertir/ajustar el refactor.
5. **Log del ciclo:** `DEUDA: antes → después` (evidencia objetiva de mejora).
6. **Repetir** hasta punto fijo (`DEUDA=0` o sin movimiento posible) o presupuesto (`--ciclos N` / `--hasta-limpio` / tiempo).

**Garantías (lo que lo hace seguro de dejar corriendo solo):**
- **Convergente / idempotente:** sobre un grafo sano no cambia nada (punto fijo) — no oscila ni "deshace" trabajo.
- **Monótono:** nunca empeora una métrica para mejorar otra.
- **Preserva información:** los splits **reescriben** citas y enlaces, no los borran; y `raw/` permanece intacto, así que todo es reconstruible.
- **Trazable y acotado:** cada refactor al log; presupuesto explícito de ciclos/tiempo.

**Trigger:** el humano invoca `/compose` (opcional `--ciclos N` o `--hasta-limpio`). Protocolo completo en `SKILLS/compose.md`.

---

## Frontmatter Schemas

> El campo `last_agent` registra **el agente que ejecutó la operación**. Valores válidos: `claude-code | codex | cursor` (o el identificador del agente que corra). No es un valor fijo: cada superficie escribe el suyo.

### `wiki/<nota>.md`
```yaml
---
title: ""
type: entity | concept | pattern | summary | comparison | guide | incident | moc
description: ""    # one-liner para agentes/búsqueda/index; ≤1 oración, plain text, sin cita. OKF §4.1.
resource: ""       # URI canónica del asset real (entity/concept). Omitir en moc/summary/comparison/pattern.
domain: ""
tags: []           # cross-cutting ortogonales a domain. ≥2 para entity/concept/pattern. Ver taxonomía en SKILLS/format.md §1.0.
status: active | stale
sources: []        # superset consolidado de todas las citas inline [[raw/...]] de la nota
related: []        # enlaces tipados salientes a otras notas wiki (ver Política de Enlazamiento) — ≥2 salvo MOC/entity nueva
created: YYYY-MM-DD
updated: YYYY-MM-DD
last_agent: claude-code | codex | cursor   # el agente que ejecutó
confidence: 0.0–1.0
---
```

> [!note] `type: moc` y `related[]`
> `moc` es el Mapa de Contenido de un dominio (ver "Modelo de Conocimiento"); su cuerpo es casi todo enlaces a átomos, por eso se exime de la regla de ≥2 `related`. `related[]` lista los enlaces tipados salientes (`relación :: [[wiki/nota]]`) — es el reflejo en frontmatter de la sección `## Relacionado`, espejo de `sources[]` pero hacia el grafo interno en vez de hacia `raw/`.

> [!note] Nuevos campos · OKF §4.1 · 2026-06-18
> - **`description`**: one-liner para agentes/búsqueda/index. ≤1 oración, plain text, sin cita. Distinto del `> [!abstract]` del body (que es para lectura humana en Obsidian).
> - **`resource`**: URI canónica del asset subyacente (repo GitHub, servicio interno, dashboard de métricas, cola/topic de mensajería, etc.). Esperado en `entity`/`concept`; omitir en `moc`, `summary`, `comparison`, `pattern` (tipos abstractos sin asset URL propio).
> - **`tags`**: etiquetas cross-cutting ortogonales a `domain`. Usar la taxonomía de `SKILLS/format.md §1.0`; ≥2 para entity/concept/pattern. Son tags nativos de Obsidian → aparecen automáticamente en el Tag Explorer (comportamiento intencional).
> `tags` en wiki/ ≠ `topics` en curated/ (aunque `topics` se deriva de ellos en `/curate`). `tags` en wiki/ ≠ `tags` en §1.1 (notas generales del vault — taxonomía tipo/area/estado).

> [!note] Qué se toma de OKF y qué se diverge a propósito
> `wiki/` **no** es un bundle conformante a Open Knowledge Format v0.1 ([spec](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing)) — es *inspirado* en su vocabulario de frontmatter, no una implementación. Tres divergencias deliberadas, no pendientes: (1) OKF exige cross-links en markdown estándar `[texto](/ruta.md)`; `wiki/` usa wikilinks `[[nota]]` de Obsidian a propósito, porque Graph View y backlinks nativos dependen de esa sintaxis en el uso diario. (2) OKF deja `type` como string libre sin registro central; `wiki/` lo fija a un enum con rol de grafo (REGLA 8) porque eso es lo que permite que `graph_health.sh` razone sobre la red. (3) OKF exige que los consumidores toleren links rotos/campos desconocidos/tipos desconocidos; `wiki/` falla duro ante eso a propósito (`verify_citations.sh`, `verify_wikilinks.sh`) — la estrictez es la feature, no el defecto, en un sistema de un solo productor+consumidor. `bash scripts/export_okf.sh` traduce `wiki/` a un bundle OKF real (de solo lectura, sin tocar el original) para interoperar puntualmente con herramientas que hablen OKF.

### `curated/<nota>.md`
```yaml
---
# — Núcleo canónico (refinado por el humano; el agente jamás edita su contenido) —
title: ""
type: curated
status: human-canonical
llm_action: read-only
human_curated: true
curated_date: YYYY-MM-DD
last_human_edit: YYYY-MM-DD
topics: []
en_tus_palabras: ""  # OBLIGATORIO · escrito por el humano, nunca por el agente (ver /curate Paso 2)
# — Procedencia heredada (opcional · read-only · preserva trazabilidad hacia raw/) —
sources: []        # superset de citas [[raw/...]] heredado de la nota wiki de origen
# — Passthrough de presentación (heredado de wiki/ · read-only para el agente) —
description: ""    # heredado de wiki/<nota>.description; el humano puede enriquecer manualmente
resource: ""       # heredado de wiki/<nota>.resource; opcional
---
```

> [!note] Modelo de curación — qué se preserva al promover `wiki/` → `curated/`
> `/curate` **congela** la nota: escribe los campos canónicos, **hereda `sources`** (trazabilidad, obligatoria), **hereda `description` y `resource`** como passthrough de presentación. `topics` se deriva de los `tags` de la nota wiki/ (con posible enriquecimiento del humano). La demás telemetría del schema `wiki/` (`domain`, `created`, `updated`, `last_agent`, `confidence`, `tags`) **no se copia** — queda registrada en `wiki/log.md`. Al revertir con `/uncurate`, el agente reconstruye el schema `wiki/` desde `sources`, `description`, `resource` preservados + el contenido (`type`), `topics`→`tags`→`domain` y fechas nuevas. Así la curación nunca rompe la cadena de procedencia hacia `raw/`.
>
> **`en_tus_palabras` es distinto a todo lo demás del schema: el agente lo pide, nunca lo redacta ni lo infiere.** Es la única fricción intencional de todo el pipeline: `wiki/` se sigue compilando a velocidad plena, pero promover algo a `curated/` — el conjunto chico que más se va a reusar — exige 1-2 líneas del humano con la idea central en sus propias palabras, no una copia de `description`. Recupera parcialmente el "generation effect" (Zettelkasten) justo donde más rinde, sin tocar el resto del flujo. Al revertir con `/uncurate`, ese campo no tiene equivalente en el schema `wiki/`: se preserva como callout `> [!quote] En tus palabras: ...` al inicio del body, nunca se descarta.

### `archivo/<nota>.md`
```yaml
---
title: ""
original_location: ""
archived_date: YYYY-MM-DD
archived_reason: ""
---
```

---

## Protocolo de Navegación

```
Operación sobre conocimiento o índice
  └─ Leer wiki/index.md           ← primero (salvo /status)
       ├─ /query   → MOC del dominio → seguir enlaces tipados hasta el átomo → curated si referenciado
       ├─ /ingest  → absorber brechas → extraer nodos → decidir átomo (crear>engordar) → enlazar + MOC → emitir brechas
       ├─ /lint    → todas las páginas wiki + salud del grafo (fan-in, huérfanas, monocultivo, MOCs) + brechas en _gaps
       ├─ /curate  → localizar la nota y su entry → actualizar index
       ├─ /archive → localizar la nota y su entry → actualizar index
       ├─ /propose → localizar en el index la nota curada referida
       ├─ /gaps    → leer wiki/_gaps.md → absorber respondidas → enriquecer nota afectada
       └─ /compose → loop: ingest cola → lint-grafo → 1 refactor seguro → verificar → repetir hasta punto fijo

/status → cuenta archivos por directorio (incl. brechas en _gaps); leer el index es opcional (solo para validar consistencia).
```

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

## Uso de SKILLS/

Cada archivo en `SKILLS/` es el protocolo detallado de una operación (o un **insumo** descubrible de una, como `gaps-ejemplo.md`).
Cuando el humano invoca una operación, leer el SKILL correspondiente antes de ejecutar.
Los SKILLS son de solo lectura — el agente los consume, no los modifica.

| SKILL | Leer cuando... |
|---|---|
| `SKILLS/format.md` | **SIEMPRE antes de crear o modificar cualquier nota** |
| `SKILLS/ingest.md` | Al procesar una fuente nueva |
| `SKILLS/query.md` | Al responder una pregunta contra la wiki |
| `SKILLS/lint.md` | Al hacer health-check del sistema |
| `SKILLS/curate.md` | Al congelar una nota como curada |
| `SKILLS/propose.md` | Al generar propuesta para curated/ |
| `SKILLS/archive.md` | Al mover nota a archivo/ |
| `SKILLS/status.md` | Al reportar estado del sistema |
| `SKILLS/gaps.md` | Al emitir o absorber brechas (feedback loop) |
| `SKILLS/gaps-ejemplo.md` | Insumo de `/gaps`: plantilla poblada de `wiki/_gaps.md` (no es operación) |
| `SKILLS/compose.md` | Al correr la composición autónoma continua (auto-mejora del grafo por horas) |

> ⚠️ `SKILLS/format.md` es transversal: aplicar en cualquier operación que escriba texto.
> Un formato incorrecto rompe links, callouts y tablas en Obsidian silenciosamente.
