# SKILL: /ingest — Compilar nueva fuente

> Transforma una fuente cruda en conocimiento compilado dentro de `wiki/`.
> El LLM actúa como compilador: extrae señal, descarta ruido, integra con lo existente.

---

## Modelo mental: Map-Reduce con procedencia

La compilación es un **Map-Reduce de conocimiento** donde la cita es un subproducto, no un paso aparte:

```
raw/ (datos crudos)
   │  MAP    → leer cada fuente, extraer hechos verificables
   │           junto con su procedencia: fuente#sección
   ▼
hechos { dato, raw/nota#sección }
   │  REDUCE → sintetizar nota densa (tablas > listas > prosa)
   │           cada hecho conserva su procedencia como cita inline [[raw/nota#sección]]
   ▼
wiki/ (conocimiento compilado, navegable, con trazabilidad)
```

> [!tip] Progressive disclosure
> La nota wiki/ es la capa resumen. Cada cita inline `[[raw/nota#sección]]` es un punto de entrada que el agente puede expandir bajo demanda hacia la fuente que lo fundamenta — igual que un sistema de citas expandibles.

---

## Cuándo usar

- El humano agrega un archivo a `raw/` y pide procesarlo
- El humano pega texto directamente y pide ingresarlo al sistema
- Al final de un incidente, proyecto o análisis, para documentar lo aprendido
- Después de leer un artículo, libro o documento importante

---

## Política de autonomía

> [!important] Operación sin human-in-the-loop
> Este SKILL corre en background. El LLM toma **todas** las decisiones autónomamente — **nunca** pausa para consultar.
> Las dudas **N1** sin resolver se **persisten como brechas** en `wiki/_gaps.md` (§Paso 3.8) y se reportan en ENTREGA; las demás quedan como `[INFERIDO]`/`[FUENTE NO PERSISTIDA]`, recuperables luego por `/lint`.

| Duda durante compilación | Default autónomo |
|---|---|
| N2 vs N3 | → N3 (regla de corte: si dudás, es N3) |
| ¿Crear nota nueva o actualizar existente? | → **Crear si es un sujeto/átomo nuevo, aunque el dominio coincida.** Actualizar solo si es el MISMO átomo (REGLA 8). "Mismo dominio" ≠ "misma nota". |
| ¿Entidad/concepto N1 descrito con sustancia y sin nota propia? | → **Extraerlo como `entity`/`concept`** (nodo-hub) y enlazarlo; no describirlo dentro de una guía. |
| ¿La nota destino ya tiene >12 fuentes raw o >150 líneas? | → No engordarla: extraer el material nuevo a su propio átomo + enlazar. Marcar la nota para split. |
| ¿Cuánto comprimir si no es claro? | → Errar hacia más compresión |
| ¿Fuente sin headings suficientes? | → Citar nota completa `[[raw/nota]]`, reportar como gap al final |
| ¿Info relevante para curated/? | → Ejecutar /propose automáticamente, nunca tocar curated/ |
| ¿Duda **N1** sin resolver (inferencia crítica, contradicción, entidad indefinida, fuente no persistida)? | → Emitir brecha en `wiki/_gaps.md` (§Paso 3.8), tope ≤3/ingest |
| ¿Ingest grande (>3 átomos tocados) o creó `entity`/`concept` nueva? | → Activar revisión independiente (§Paso 3.75) antes de emitir brechas |
| ¿Una nota en `related[]` directo cumple el checklist de calificación de §Paso 3.65? | → Refrescar SOLO `description`/`tags`, citando la fuente puntual. Tope ≤5/ingest. Nunca tocar su cuerpo, su `updated:`/`last_agent:`, ni crear notas nuevas por esta vía. |
| ¿Ninguna nota calificó para evolución retroactiva? | → Reportar igual "Evolución retroactiva: 0 notas — <motivo>" en ENTREGA (§Paso 3.65) — nunca omitir la línea en silencio. |
| ¿Algún ítem del Gate REGLA 8 (§Paso 3.68) falla antes del `Write`/`Edit` final, pero la nota igual se justifica? | → Escribir igual + callout `> [!note] Excepción REGLA 8: <ítem> — <motivo>` inline en la nota. Nunca en silencio, nunca pausar para el humano. |
| ¿Falla sin justificación real (apuro, no buscó bien)? | → NO escribir así: volver a Paso 3 y completar lo que falta (nodo a extraer, enlace real, description). |

---

## Protocolo paso a paso

### Paso 0 — Triage de compilación (ANTES de leer la fuente)
```
Responder antes de leer:
  1. ¿Qué ÁTOMOS generará esto? Una fuente rica produce VARIAS notas atómicas, no una sola.
     Listar mentalmente los sujetos: entidades, conceptos, patrones, incidentes distintos.
  2. ¿Cuáles de esos sujetos YA existen como nota propia? → a esos se actualiza (mismo átomo).
     ¿Cuáles son nuevos? → se crean, AUNQUE el dominio coincida con una nota existente (REGLA 8).
  3. ¿Qué entidades/conceptos N1 merecen nota-hub propia (entity/concept) y aún no la tienen?
     → extraerlos PRIMERO; el resto del material los enlazará en vez de re-describirlos.
  4. ¿Cuál es el 20% de esta fuente que tiene el 80% del valor operativo?

> Anti-centralización: el default NO es "actualizar la nota del dominio". El default es
> "crear el átomo que falta y enlazarlo". Solo se actualiza cuando es literalmente el mismo sujeto.

Commitment de compresión:
  Cada nota resultante tendrá ≤ 25% de las líneas de la fuente.
  El resto vive en raw/ con su cita; wiki/ no lo repite.

Guardia de fan-in (REGLA 8):
  Ninguna nota debe superar ~12 fuentes raw distintas ni ~150 líneas.
  Si el destino natural ya está en ese límite → extraer a un átomo nuevo + enlazar, no engordar.
```

### Paso 0.5 — Absorción de brechas respondidas (feedback loop)
```
Leer wiki/_gaps.md. Si hay brechas con "Respuesta del humano" NO vacía y status ∈ {open, stale, unanswered}:
  → Incluye las archivadas: responder una brecha unanswered la reactiva y se absorbe igual (esté en la sección que esté).
  → Compilarlas PRIMERO (antes de la fuente nueva): la respuesta del humano es una fuente nueva.
  → Protocolo completo en SKILLS/gaps.md (§Absorción): enriquecer la nota afectada con cita,
    decidir procedencia (raw/feedback/ con confirmación del humano · o [FUENTE NO PERSISTIDA]),
    marcar la brecha resolved, quitar el callout > [!question] inline.
  → Nota afectada en curated/ → /propose (REGLA 6), nunca editar curated/.
Si no hay respuestas pendientes → continuar con la compilación normal.
```

### Paso 1 — Orientación
```
Leer wiki/index.md completo.
Identificar páginas wiki/ existentes relacionadas con el contenido de la fuente.
```

### Paso 2 — Lectura de la fuente (MAP)
```
Leer la fuente completa.
Extraer cada elemento JUNTO CON su procedencia (la sección de la fuente de donde sale):
  - Entidades (apps, servicios, APIs, personas, sistemas)
  - Conceptos (patrones, principios, teorías)
  - Hechos clave (métricas, thresholds, configuraciones)
  - Gotchas (excepciones, trampas, comportamientos no obvios)
  - Contradicciones con lo que ya está en wiki/

Anotar mentalmente cada hecho verificable como par { dato → raw/nota#sección }.
Esa procedencia es la que se persiste luego como cita inline.
```

### Paso 2.5 — Pirámide de señal (filtro pre-REDUCE)
```
Clasificar cada hecho extraído en uno de tres niveles.
Solo Nivel 1 y top Nivel 2 pasan al REDUCE. Nivel 3 queda en raw/ con cita.

NIVEL 1 — siempre compilar (el 20% que tiene el 80% del valor):
  ✅ Patrones recurrentes con nombre ("este comportamiento ocurre cuando...")
  ✅ Gotchas no obvios que muerden silenciosamente
  ✅ Decisiones operativas: "cuando X, hacer Y"
  ✅ Thresholds de acción (números que disparan decisiones)
  ✅ Conexiones cross-dominio (A falla → B se degrada)

NIVEL 2 — compilar solo si frecuencia de consulta ≥ 1/semana:
  ⚠️ Top 3-5 queries/comandos del dominio (no todos)
  ⚠️ Esquema de datos principal (estructura, no campo a campo)
  ⚠️ Rutas de escalación / contactos clave

NIVEL 3 — NUNCA compilar (raw/ + cita es suficiente):
  ❌ Queries SQL o analíticas completas
  ❌ Listas exhaustivas de campos de API (> 5 campos)
  ❌ Procedimientos paso a paso sin variación
  ❌ Configuraciones específicas de un contexto único
  ❌ Descripciones textuales de imágenes o capturas
  ❌ Bloques de código > 15 líneas

Regla de corte: si dudás entre Nivel 2 y Nivel 3 → es Nivel 3.
```

> [!tip] Taxonomía de tipo de ambigüedad — consistencia entre agentes (complementa el nivel, no lo reemplaza)
> La Pirámide de arriba clasifica por IMPORTANCIA (¿es N1, N2 o N3?), pero no dice de qué CLASE de incertidumbre se trata. Sin ese vocabulario compartido, dos agentes (Codex, Claude Code, Cursor) pueden calificar la MISMA duda como N1 o N2 de forma distinta, porque cada uno la mira desde un ángulo distinto. Antes de asignar nivel a una duda candidata a N1, identificá a cuál de estas 6 categorías pertenece — la pregunta guía y el criterio de escalado están pensados para que cualquier agente llegue al mismo nivel ante la misma duda, sin agregar una cuarta categoría de nivel a la Pirámide.
>
> | Categoría | Pregunta guía | Escala a N1 cuando... | Tipo de GAP si escala (§Paso 3.8) |
> |---|---|---|---|
> | **Identidad difusa** — entidad/concepto sin límites claros | ¿El sujeto que describe la fuente es una entidad/concepto ya existente, uno nuevo, o dos mezclados en uno? | Va a ser (o afecta a) un nodo-hub (REGLA 8) que otras notas van a enlazar — un límite mal trazado ahora se propaga después. | `definicion-faltante` |
> | **Contradicción sin dirimir** — dos fuentes chocan | ¿Esta fuente afirma algo que niega lo que ya dice `wiki/` u otra sección de `raw/`? | El hecho en disputa es N1 (threshold, decisión operativa, patrón) y ninguna fuente tiene autoridad obvia por fecha o procedencia. | `contradiccion` |
> | **Atomicidad difusa** — ¿una nota o dos? | ¿El material cubre un solo sujeto atómico, o en realidad son dos sujetos que deberían separarse (o al revés, dos fuentes del mismo sujeto que deberían fusionarse en una)? | La duda decide si se crean 1 o 2 notas — afecta directo el fan-in (REGLA 8) y a qué enlaza cada sujeto después. | `atomicidad-difusa` *(nuevo)* |
> | **Dato operativo no sustentado** — threshold/config/métrica sin fuente firme | ¿El número o decisión que estoy por citar tiene una fuente `raw/` puntual, o lo estoy completando por contexto? | El dato ya calificó N1 en la Pirámide (threshold/decisión de acción) y su única base hoy es `[INFERIDO]` o `[FUENTE NO PERSISTIDA]`. | `inferencia-critica` / `fuente-no-persistida` |
> | **Terminología inconsistente** — mismo concepto, nombre distinto | ¿La fuente nueva usa un término distinto al que ya usan las notas compiladas para (aparentemente) el mismo concepto? | No queda claro si son sinónimos, una evolución del término, o conceptos distintos — riesgo de duplicar el nodo-hub bajo dos nombres. | `terminologia-inconsistente` *(nuevo)* |
> | **Relación tipada dudosa** — qué relación corresponde entre dos átomos | ¿La relación que le voy a poner (`depende-de`/`afecta-a`/`instancia-de`/`ver-también`) es la que la fuente realmente describe, o es la que "suena bien"? | El enlace conecta dos nodos-hub (`entity`/`concept`) y una relación mal tipada distorsiona la navegación del grafo (mismo riesgo que el hallazgo ENLACE-SEMANTICO-INCORRECTO de §Paso 3.75). | `inferencia-critica` |
>
> **Qué NO cambia esta taxonomía:** no agrega un cuarto nivel a la Pirámide, no toca el tope de ≤3 brechas/ingest (REGLA 7) ni el criterio N1/N2/N3 — es un filtro previo que estandariza CÓMO dos agentes llegan al mismo nivel ante la misma duda, no un criterio de nivel nuevo. Una duda puede caer en una de estas categorías y aun así quedar en N2/N3 si el hecho de fondo no califica en la Pirámide de arriba.

### Paso 3 — Descomponer en átomos y escribir wiki/ (REGLA 8)
```
PRIMERO — extraer nodos-hub (orden de prioridad):
  → Por cada entidad/concepto N1 descrito con sustancia y SIN nota propia:
       crear wiki/<entidad>.md (type: entity) o wiki/<concepto>.md (type: concept).
  → Estos son los hubs del grafo. Lo demás los ENLAZA, no los re-describe.

Para cada átomo (sujeto distinto) de la fuente:

  ¿Es el MISMO sujeto de una nota existente?  (no "mismo dominio" — mismo átomo)
    SÍ → actualizar esa nota:
       → Integrar nueva información
       → Si contradice algo existente: > [!warning] Contradicción: ... (+ relación `contradice`)
       → Refrescar `updated` y `last_agent`
       → Si la nota no tiene description/resource/tags → poblarlos oportunísticamente ahora.
       → GUARDIA DE FAN-IN: si la nota ya tiene >12 fuentes raw o >150 líneas,
         NO agregar más → extraer el material nuevo a su propio átomo + enlazar.
         Marcar la nota saturada para split en la ENTREGA.
    NO (sujeto nuevo) → crear wiki/<nombre-descriptivo>.md:
       → type según su ROL en el grafo (entity/concept = hub; pattern/incident/guide/comparison; moc = índice)
       → description: <esencia del átomo en ≤1 oración — plain text, sin cita, para índice/búsqueda de agentes>
       → Si type entity|concept Y la fuente provee URL canónica del asset → resource: <URI>
          (repos GitHub, servicios internos, dashboards de métricas, colas/topics de mensajería, sistemas de tickets, etc.)
       → tags: [...] (≥2 etiquetas cross-cutting: negocio/tech/criticidad/contexto-operativo — ver taxonomía SKILLS/format.md §1.0)
       → Contenido: solo Nivel 1 y top Nivel 2 (§Paso 2.5). Tablas ≤8 filas, bullets, prosa solo si aclara.
       → Nivel 3 nunca se copia: [[raw/nota#sección]] + una línea de lectura operativa.

  SI información es relevante para nota en curated/:
    → NO tocar curated/  →  Ejecutar /propose automáticamente
```

### Paso 3.6 — Enlazamiento constructivo + MOC (REGLA 8 · Política de Enlazamiento)
```
Ningún átomo queda suelto. Por cada nota creada o tocada:

  1. ENLAZAR a ≥2 notas existentes con relación TIPADA (define | depende-de | instancia-de |
     afecta-a | contradice | ver-también). Ubicación:
       → inline donde la relación nace (preferido), y/o
       → sección ## Relacionado al final: `- depende-de :: [[wiki/nota]] — por qué`
       → reflejar en frontmatter related: [...]
     Si no hay a qué enlazar con sentido → probablemente falta extraer un nodo (volver al inicio del Paso 3).

  2. BIDIRECCIONALIDAD: para relaciones fuertes (depende-de, define, afecta-a),
     agregar el enlace recíproco en la nota destino si no existe.

  3. MOC del dominio:
       → Registrar el átomo en wiki/moc-<dominio>.md (su entrada con una línea de contexto).
       → Si el dominio no tiene MOC y ya hay ≥3 átomos del dominio → crear el MOC (type: moc).

  ANTI-RUIDO: cada enlace conecta un átomo DISTINTO y dice por qué. No repetir el mismo
  wikilink en masa ni enlazar por cumplir el número.
```

### Paso 3.5 — Citación granular (Progressive Disclosure)
```
Al escribir el cuerpo (REDUCE), cada hecho verificable (métrica, threshold, config,
comando, decisión, gotcha) cae en UNO de tres casos. Nunca un dato factual sin trazabilidad:

  1. Fuente persistida en raw/ → CITAR inline
       <afirmación>. [[raw/nota#sección]]
     → raw/ es inmutable: link a nota o a #sección, NUNCA block-ids (^id) en raw.
     → En tablas: columna final `Fuente`, pipe escapada: [[raw/nota#sección\|fuente]]

  2. Fuente real pero NO persistida (conversación, doc externo, fuente no en raw/)
       <afirmación>. [FUENTE NO PERSISTIDA: <origen breve>]
     → NO usar [INFERIDO]: no es inferencia, es una fuente que existe pero no es citable.
     → Reportarlo como gap al final (ver Entrega del prompt).

  3. Conclusión/deducción del agente, no textual en ninguna fuente → [INFERIDO]

Cuándo [INFERIDO] (evitar ruido):
  ✅ Solo para una conclusión ÚTIL que no está textual en la fuente.
  ❌ NO para reformulaciones obvias de una fuente ya citada (esas van con su cita).
  → Si hay varias inferencias juntas: agruparlas en una sección `## Inferencias`
    o en un callout `> [!question]`, en vez de salpicar [INFERIDO] por toda la nota.

ANTI-PATRÓN CRÍTICO — [[raw/...]] [INFERIDO] mezclados en la misma afirmación:
  ❌ NUNCA: <afirmación>. [[raw/nota#sección]] [INFERIDO]
     → nadie sabe qué parte es la fuente y qué la deducción; es un hedge de incerteza, no procedencia.
  ✅ CORRECTO — separar en dos afirmaciones distintas:
       <lo que dice la fuente textualmente>. [[raw/nota#sección]]
       <lo que concluís de eso que va más allá de lo textual>. [INFERIDO]
  → [INFERIDO] = conclusión propia, no marca de incerteza sobre la fuente.
  → La incerteza sobre cómo interpretar un hecho de la fuente NO es [INFERIDO]: es candidata a GAP (§Paso 3.8).
  → Si la deducción propia es sobre un hecho N1 operativo → GAP (§Paso 3.8), no [INFERIDO].
  → Si no podés separar cita de deducción → la fuente no tiene headings suficientes: citar nota completa
    [[raw/nota]] y reportarlo como gap de citación en la ENTREGA.

  ❌ NO citar: prosa de síntesis, texto conectivo, definiciones genéricas
     (no son hechos verificables → no requieren cita ni marca).

Consolidar: todas las fuentes citadas inline deben aparecer en
frontmatter sources:[...] y en la sección ## Fuentes (superset).
```

### Paso 3.65 — Evolución retroactiva acotada (A-MEM)
```
Modelo mental: la fuente que acabás de compilar puede volver desactualizada una nota
EXISTENTE que ni menciona directamente — no solo la nota del mismo átomo (Paso 5).
A-MEM (arXiv:2502.12110) llama a esto "memory evolution": una memoria nueva puede
refrescar retroactivamente el contexto de memorias viejas relacionadas.

QUÉ SE PERMITE TOCAR (acotado a propósito — el agente es recolector, no autor):
  ✅ description y tags de una nota wiki/ existente — SOLO si la fuente recién
     compilada los vuelve inexactos o incompletos (ej.: la entidad cambió de estado,
     un tag ya no aplica). tags nuevos siguen la misma taxonomía de SKILLS/format.md
     §1.0 que en la creación (Paso 3) — no se inventa vocabulario nuevo acá.
  ❌ NUNCA el cuerpo/hechos de la nota, NUNCA sources[]/related[] por esta vía —
     eso sigue siendo "actualizar el átomo" (Paso 5) y exige su propia cita completa.
  ❌ NUNCA una nota en curated/ — si aplica, es /propose (REGLA 6), no edición directa.
  ❌ NUNCA crear una nota nueva por esta vía — evolución retroactiva solo TOCA
     metadata de notas que YA existen. Sintetizar una nota nueva sin fuente puntual
     es "patrón candidato" (SKILLS/compose.md §Patrón candidato), un mecanismo
     distinto con gate humano obligatorio.
  ❌ NUNCA refrescar updated: ni last_agent: de la nota vecina — es un retoque de
     metadata, no una revisión de contenido. Tocar esas fechas enmascararía la
     detección de staleness real de /lint (una nota con el CUERPO vencido podría
     evadir status: stale indefinidamente solo por vecindad a ingests ajenos).
     El rastro de que hubo un retoque vive en el callout inline (paso 2 de abajo)
     y en wiki/log.md — no hace falta frontmatter para eso.

ALCANCE DE BÚSQUEDA (acotado — no es una relectura del vault):
  Revisar ÚNICAMENTE las notas en related[] DIRECTO (un salto, sin transitividad)
  de los átomos tocados en este ingest (Paso 3-3.6). NO recorrer el MOC completo
  del dominio ni notas de segundo grado — related[] directo ya está acotado por la
  densidad mínima de enlazamiento (REGLA 8, ≥2 por nota), así que el costo de esta
  búsqueda es proporcional a lo que el propio ingest ya tocó, no al tamaño del vault.

CHECKLIST DE CALIFICACIÓN (ejecutar por cada nota en related[] directo — nunca
criterio libre; una candidata debe cumplir las TRES):
  ✅ Es una nota EXISTENTE en related[] directo de un átomo tocado en este ingest.
  ✅ La fuente recién leída contiene una AFIRMACIÓN PUNTUAL y citable sobre el
     sujeto de esa nota vecina (aunque no la mencione por su [[wikilink]]) —
     no una inferencia de segundo grado ni una relación temática difusa.
  ✅ Esa afirmación vuelve inexacto o incompleto algo que description/tags
     de la nota vecina afirman hoy (ej.: dice "activo" y la fuente dice que
     fue reemplazado; falta un tag que ahora es cross-cutting relevante).
  Si falta CUALQUIERA de las tres → NO calificar. "Mismo dominio" o "tema
  relacionado" sin afirmación puntual NUNCA alcanza.

CÓMO EJECUTAR (cuando hay candidata real):
  1. Refrescar description/tags de la nota vecina (solo esos dos campos).
  2. Dejar registro de por qué en el cuerpo de la nota (no es un campo estándar de
     frontmatter): agregar o extender su sección ## Relacionado con un callout:
       > [!info] description/tags refrescados a la luz de [[raw/nueva-fuente#sección]]
  3. La afirmación que motivó el refresco debe poder rastrearse a
     [[raw/nueva-fuente#sección]] igual que cualquier hecho (§Paso 3.5) — nunca un
     refresco sin fuente puntual.

TOPE Y TRANSPARENCIA (transparencia, calcado del Mecanismo de ignore / REGLA 7):
  ≤5 notas retocadas por evolución retroactiva, por ingest.
  Reportar SIEMPRE en ENTREGA, sin excepción:
    - Si hubo candidatas: "Evolución retroactiva: N notas — [[wiki/nota]] (razón breve), ..."
    - Si NO hubo candidatas: "Evolución retroactiva: 0 notas — <motivo>" (ej.: "ningún
      átomo tocado tenía related[] con afirmación puntual en esta fuente", o "sin
      notas vecinas que revisar"). NUNCA SILENCIO: la ausencia debe estar
      justificada, igual que la ausencia de brechas en §Paso 3.8 — omitir la línea
      por completo no es una opción.
  Loguear en wiki/log.md, dentro de la misma entrada del ingest:
    "Evolución retroactiva: [[wiki/nota]] ← [[raw/fuente#sección]]" (una línea por
    nota retocada, o "Evolución retroactiva: 0 notas — <motivo>" si no hubo).

INTERACCIÓN CON REVISIÓN INDEPENDIENTE (§Paso 3.75):
  Las notas tocadas SOLO por evolución retroactiva NO cuentan para el umbral
  átomos_tocados > 3 que activa la revisión independiente (son retoques de
  metadata, no átomos compilados — ver la definición en §Paso 3.75).
  PERO si la revisión independiente YA se activó por otra razón (átomos_tocados
  reales > 3, o se creó una entity/concept nueva), agregar también las notas
  retocadas por evolución retroactiva a la lista de paths que revisa el agente
  independiente — auditoría gratis del único paso de compilación cuyo checklist
  sigue siendo semántico (afirmación puntual, no un umbral numérico como fan-in),
  sin bajar el umbral de activación.

POR QUÉ NO ES "REFLECTION" NI FABRICACIÓN:
  Cada refresco sigue atado a una fuente raw/ real que acaba de entrar al sistema —
  el agente NUNCA inventa una síntesis nueva a partir de solo leer sus propias notas
  (eso está prohibido — ver AGENTS.md REGLA 7 y SKILLS/compose.md §Patrón candidato).
  Esto es ancho de compilación ampliado sobre la MISMA fuente, no una operación nueva
  de generación de conocimiento.
```

### Paso 3.68 — Gate REGLA 8 (checklist pre-Write)

> [!important] Por qué este paso existe
> "Criterios de calidad para páginas wiki/" (más abajo) ya listaba estos mismos 4 atributos —
> pero como checklist DECLARATIVO, sin un punto fijo del protocolo que obligara a correrlo. En
> la práctica el agente confiaba en seguirlo al escribir, y solo `/lint` lo detectaba *después*,
> cuando la nota mal formada ya vive en el grafo (fan-in ya excedido, huérfana ya sin enlaces).
> Este paso convierte los mismos 4 criterios en un GATE: se corren ANTES del `Write`/`Edit` que
> deja la nota en su versión final — la misma idea del "Constitution Check" de spec-kit (gate
> previo a generar `tasks.md` que obliga a justificar cualquier violación en una sección de
> "Complexity Tracking" en vez de dejarla pasar en silencio). No agrega una operación nueva ni
> pausa la autonomía de `/ingest`: es un checkpoint dentro del mismo paso de escritura.

```
Correr este checklist, por cada nota creada o actualizada, INMEDIATAMENTE ANTES de persistirla
(después de haber decidido su type y description en Paso 3, sus enlaces en Paso 3.6 y sus citas
en Paso 3.5 — pero antes de dar la nota por escrita):

  □ ¿≥2 `related` reales a notas EXISTENTES del vault? (salvo cold-start ya previsto en
    Política de Enlazamiento: `moc`, o `entity`/`concept` recién nacida sin pares aún)
  □ ¿`description` queda poblada (≤1 oración, plain text, sin cita)?
  □ ¿La nota (si es actualización) se mantiene ≤12 fuentes raw distintas y ≤150 líneas tras
    este cambio? (si es creación, ¿no nace ya sobredimensionada por una fuente enorme?)
  □ ¿El `type` elegido corresponde a su ROL real en el grafo — hub (`entity`/`concept`) vs.
    orquestador (`guide`) vs. evento puntual (`incident`) vs. patrón (`pattern`) vs. índice
    (`moc`) — y no es una `guide` que en realidad describe una entidad que debía extraerse?

SI LOS 4 ÍTEMS PASAN → escribir la nota normalmente, seguir a Paso 3.7.

SI ALGÚN ÍTEM FALLA pero la nota igual se justifica (caso legítimo — ej.: primera `entity`
de un dominio nuevo sin ningún par posible todavía en el vault):
  → Escribir la nota IGUAL (nunca pausar para el humano — autonomía de /ingest intacta).
  → Dejar CONSTANCIA EXPLÍCITA INLINE en el cuerpo de la nota, junto a la sección o campo
    afectado:
      > [!note] Excepción REGLA 8: <ítem que falló> — <motivo concreto>.
    No alcanza con mencionarlo de pasada en la ENTREGA del ingest — eso no deja rastro en el
    grafo. El callout vive en la nota misma: visible para cualquiera que la abra, y para
    `/lint` en una pasada futura (equivalente a la sección "Complexity Tracking" de spec-kit,
    pero dentro de la nota en vez de un documento aparte).
  → Mencionar TAMBIÉN la excepción en la ENTREGA (transparencia doble, igual que el Mecanismo
    de ignore o la evolución retroactiva) — pero el callout inline es la constancia
    OBLIGATORIA; la mención en ENTREGA es adicional, nunca sustituta.

SI ALGÚN ÍTEM FALLA y NO hay justificación real (el agente no buscó bien un segundo enlace,
o no armó la description por apuro):
  → NO escribir la nota así. Volver a Paso 3: probablemente falta extraer un nodo, buscar un
    enlace real, o completar el campo — el Gate existe para forzar ese trabajo ANTES de que
    el archivo exista, no para documentarlo después.

Diferencia con Paso 3.7 (verificación de compresión): 3.7 corre DESPUÉS de escrita la nota y
mide un atributo del archivo ya persistido (líneas vs. fuente). Este Gate corre ANTES: es la
última decisión de diseño de la nota, no una medición de lo ya escrito.
```

### Paso 3.7 — Verificación de compresión
```
Estimar líneas de la fuente (leída en §Paso 2). Contar líneas generadas.

  nota ≤ 25% de la fuente  →  ✅ continuar.
  nota > 25% de la fuente  →  identificar secciones Nivel 3 y reemplazarlas
                               por [[raw/nota#sección]] + lectura operativa de una línea.

La pregunta real detrás del número:
  "¿Hay algo aquí que no merezca vivir separado de raw/?"
```

### Paso 3.75 — Revisión independiente (ingests grandes)
```
ACTIVAR si, al llegar acá, se cumple CUALQUIERA de:
  (a) átomos_tocados > 3
  (b) se creó ≥1 nota nueva con type: entity o type: concept

  átomos_tocados = |Páginas creadas| + |Páginas actualizadas| (la misma lista que ya
  armás para el ENTREGA y para wiki/log.md §Paso 5 — no es un conteo nuevo).
  NO cuentan: wiki/index.md, wiki/_gaps.md, un MOC tocado solo para agregar una línea
  (housekeeping), ni las notas tocadas SOLO por evolución retroactiva (§Paso 3.65 —
  son retoques de metadata, no átomos compilados). Un moc: creado por primera vez
  SÍ cuenta (es una nota nueva).

Si NINGUNA se cumple → seguir directo al Paso 3.8. Comportamiento idéntico al actual.

Por qué (b) además de (a): un ingest chico que crea una entity/concept nueva tiene
blast-radius alto igual — REGLA 8 la trata como nodo-hub que todo lo demás enlazará
después; un error ahí se propaga aunque el ingest sea de pocos átomos.
```

> [!info] Qué hueco cierra
> `verify_citations.sh` valida que una cita `[[raw/nota#sección]]` resuelva a un archivo y sección que existen — un chequeo SINTÁCTICO. No valida que la sección citada realmente respalde lo que la nota afirma — eso es SEMÁNTICO, y hoy nadie lo revisa salvo el mismo agente que escribió la nota (sesgo de auto-revisión). Este paso agrega, solo para ingests grandes, un segundo agente que lee todo desde cero — sin el razonamiento con el que se compiló — y juzga fidelidad, no solo sintaxis.
>
> **No lo reemplaza el checklist de calidad textual (`SKILLS/format.md §17`).** Ese checklist lo corre el mismo agente que escribió la nota en el Paso 5 — barato, siempre corre, atrapa lo obvio (marca olvidada, placeholder). Este paso es la capa cara y condicional para lo que un autor no puede ver de sí mismo: no bajar el estándar de revisión acá asumiendo que §17 "ya limpió" la nota — un ítem de §17 marcado OK por el autor no dice nada sobre si esa misma afirmación sobre-infiere respecto de la fuente.

**Cómo invocarlo:**
```
1. Armar la lista explícita de paths: fuente(s) raw/ compiladas + notas wiki/
   creadas/actualizadas en este ingest (ya la tenés del Paso 3/3.6). Si §Paso 3.65
   (evolución retroactiva) retocó alguna nota, agregarla TAMBIÉN a esta lista —
   no cuenta para decidir si este paso se activa, pero si ya se activó por otra
   razón, queda dentro del alcance del revisor (auditoría gratis del retoque).

2. Spawnear un agente independiente con este prompt (ajustar los paths marcados):

   ---
   Sos un revisor independiente de compilación de conocimiento. NO tenés ni vas a
   tener el razonamiento con el que se compiló esto — tu única fuente de verdad es
   leer los archivos de cero.

   Antes de revisar, leé AGENTS.md (REGLA 8 — criterio de atomicidad y enlazamiento)
   y SKILLS/format.md §15-16 (modelo de citación de 3 vías: cita/[FUENTE NO
   PERSISTIDA]/[INFERIDO]; vocabulario de relaciones tipadas: define/depende-de/
   instancia-de/afecta-a/contradice/ver-también) — son las convenciones de este
   kernel; tu criterio de revisión se basa en ellas, no en tu juicio genérico.

   Fuente(s) cruda(s) a leer completas: <paths de raw/>
   Nota(s) wiki/ a revisar contra esa fuente: <paths de wiki/>

   Para cada nota, buscá específicamente:
   - ATOMICIDAD-ROTA: ¿la nota mezcla ≥2 sujetos que debían ser átomos separados?
   - ENLACE-SEMANTICO-INCORRECTO: ¿alguna relación tipada (## Relacionado) no
     corresponde a lo que la fuente describe (ej. dice "depende-de" pero la fuente
     describe una contradicción)?
   - SOBRE-INFERENCIA-SIN-MARCAR: ¿alguna afirmación sin marca [INFERIDO] extiende,
     generaliza o combina lo que la fuente dice, en vez de restablecerlo tal cual?
     (Una cita puede resolver sintácticamente y aun así no respaldar la afirmación
     completa que la acompaña — leé la sección citada y compará el texto real.)
   - COMPLETITUD-N1-FALTANTE: ¿hay un hecho N1 evidente en la fuente (patrón con
     nombre, gotcha, threshold, decisión operativa) que no aparece en ninguna nota
     ni quedó marcado como brecha en wiki/_gaps.md?

   Reportá máximo 5 hallazgos, priorizados por riesgo semántico (sobre-inferencia y
   enlaces incorrectos primero). Si no encontrás nada, decilo explícitamente.

   Formato de salida (markdown plano):

   ## Revisión independiente — /ingest <fuente(s)>
   Notas revisadas: [[wiki/...]], ...
   Fuentes verificadas: raw/...

   ### Hallazgos (máx. 5)
   1. **[CATEGORÍA]** · severidad: alta|media|baja
      - Nota: [[wiki/...]]
      - Cita en la nota: "<texto exacto>" [[raw/...#sección]]
      - Lo que la fuente dice en realidad: "<cita textual>"
      - Discrepancia: <una línea>

   ### Sin hallazgos
   (si aplica) "Revisión limpia — 0 hallazgos sobre N notas / M fuentes."
   ---

3. En Claude Code: usar la herramienta Agent con subagent_type=general-purpose
   (arranca sin memoria de esta conversación — asimetría real). En otra superficie:
   usar su mecanismo equivalente de sub-sesión con memoria fresca (exec aislado,
   sub-chat nuevo, lo que exista).

4. FALLBACK (solo si NINGUNA forma de sesión fresca existe): el mismo agente hace
   la revisión, releyendo raw/ y wiki/ SIN consultar su propio razonamiento de
   compilación de este turno. El reporte debe decir explícitamente
   "Revisor: mismo-agente (fallback sin asimetría real)" — nunca presentarlo como
   equivalente a una revisión independiente real.

5. Si el mecanismo de sub-sesión no está disponible en absoluto (ninguna de las 3
   capas es viable): OMITIR este paso y reportarlo omitido en la ENTREGA. Nunca
   bloquear /ingest por esto.
```

**Qué hacer con cada hallazgo — nunca pausar para el humano:**

| Clase de hallazgo | Acción |
|---|---|
| Mecánico / bajo riesgo de juicio (relación mal etiquetada, sujetos obviamente fusionados, hecho N1 omitido trivial de agregar con su cita) | Corregir **directo** en la nota, correr `verify_citations.sh` de nuevo, documentar el fix en el log. |
| Ambiguo / juicio genuino (¿sobre-extensión real o compresión válida N2→N1?, desacuerdo sobre si algo era N1 o N3) | Convertir en **GAP** — tipo `revision-independiente` (ver `SKILLS/gaps.md`). Compite por el MISMO tope ≤3/ingest de REGLA 7 junto con los GAPs que el Paso 3.8 ya genera — **no** es un pool adicional. |

Si sobran hallazgos ambiguos y el tope de 3 ya está lleno: **nunca se descartan en silencio** — se reportan en ENTREGA como "hallazgo de revisión no absorbido (cap de gaps lleno)", igual que ya se hace con `wiki/.skip-sources.md` y brechas archivadas.

Cotas: el revisor corre **una vez por ingest** (no por átomo); **no hay re-revisión de la corrección** (detectar ≠ iterar hasta cero defectos — es un trade-off explícito para acotar costo, no un descuido). El compilador evalúa los hallazgos críticamente — no los aplica ciegamente: si al releer confirma que un hallazgo no es real, lo descarta y registra por qué, en vez de introducir un cambio innecesario.

### Paso 3.8 — Emisión de brechas (feedback loop · REGLA 7)
```
Tras compilar, revisar las dudas N1 que quedaron sin resolver. Una duda CALIFICA como brecha solo si:
  ✅ Es Nivel 1 (Pirámide de señal §Paso 2.5) — N2/N3 NUNCA generan brecha.
  ✅ Se puede formular como pregunta concreta + por qué importa + qué desbloquea al resolverse.

Tipos típicos (lo que el pipeline ya detecta y hoy descarta):
  - inferencia-critica          → un [INFERIDO] sobre un hecho N1 dudoso ("confirmá o corregí")
  - fuente-no-persistida        → un [FUENTE NO PERSISTIDA] sobre un hecho N1 ("¿esto entra a raw/?")
  - contradiccion               → un > [!warning] Contradicción sin dirimir ("¿cuál versión vige?")
  - definicion-faltante         → entidad referida pero nunca definida ("¿qué es X?")
  - verificacion-baja-confianza → nota con confidence < 0.75 ("el agente está adivinando acá")
  - revision-independiente      → hallazgo ambiguo del revisor independiente (§Paso 3.75) ("el revisor marcó esto como <categoría> — confirmá o corregí")
  - atomicidad-difusa           → duda "atomicidad difusa" de la taxonomía de §Paso 2.5: no está claro si el material es un solo átomo o dos ("¿esto es una nota o son dos?")
  - terminologia-inconsistente  → duda "terminología inconsistente" de la taxonomía de §Paso 2.5: mismo concepto con nombre distinto entre la fuente nueva y notas ya compiladas ("¿son sinónimos o conceptos distintos?")

CHECKLIST DE AUDITORÍA — ejecutar OBLIGATORIAMENTE antes de emitir (o declarar ausencia de) brechas:
  □ ¿Hay afirmaciones con [[raw/...]] [INFERIDO] mezclados? → separar (ver §Paso 3.5 anti-patrón);
    si la deducción propia es sobre un hecho N1 operativo → GAP, no [INFERIDO].
  □ ¿Hay incerteza sobre cómo interpretar un hecho N1 de la fuente? → GAP (no [INFERIDO]).
    [INFERIDO] = conclusión propia. Incerteza sobre la fuente = candidata a GAP.
  □ ¿La nota compilada tiene >3 [INFERIDO] sobre hechos operativos? → el más crítico de ellos → GAP.
  □ ¿Hay [FUENTE NO PERSISTIDA] sobre un hecho N1 (threshold, config, decisión reusable)? → GAP.
  □ ¿confidence < 0.75? → emitir al menos 1 GAP de tipo verificacion-baja-confianza.
  □ ¿Alguna duda N1 cae en "atomicidad difusa" o "terminología inconsistente" de la taxonomía
    de §Paso 2.5, sin resolver? → GAP con ese tipo (evita que dos agentes decidan distinto
    si algo era una nota o dos, o si dos nombres son el mismo concepto).
  Si el checklist no produjo GAPs: reportar explícitamente en ENTREGA → "No se emitieron GAPs: [razón]".
  Nunca silencio — el ausentismo de brechas debe ser justificado, no asumido.

Por cada brecha que califica (TOPE ≤3 por ingest — quedarse con las de mayor impacto operativo):
  → Registrar entrada en wiki/_gaps.md (status: open) con el esquema del registro.
  → Dejar un callout inline en la nota afectada, justo donde está la duda:
        > [!question] GAP-YYYY-MM-DD-NNN — <pregunta corta>
        > Brecha en [[wiki/_gaps#GAP-YYYY-MM-DD-NNN]]. El humano responde ahí; el próximo /ingest o /gaps la absorbe.
  → El resto de dudas (no-N1 o sin pregunta clara) NO genera brecha: queda como
    [INFERIDO]/[FUENTE NO PERSISTIDA], recuperable luego por /lint.

Anti-fatiga: si un ingest produciría > 3 brechas, emitir solo las 3 de mayor impacto.
Protocolo completo: SKILLS/gaps.md (§Emisión).
```

### Paso 4 — Actualizar el MOC (y el index solo si corresponde)
```
Para cada página wiki/ creada o modificada:
  → Registrar/actualizar el átomo en el MOC de su dominio:
    - [[wiki/nombre-nota]] — descripción en una línea
  → Si el dominio aún no tiene MOC y ya hay ≥3 átomos, crearlo.
  → En wiki/index.md solo se agrega el MOC (o la nota en "Notas sin MOC" si es transitorio).
  → Actualizar estadísticas (conteo de notas activas y de brechas abiertas en _gaps)
```

### Paso 5 — Log
```
Append a wiki/log.md:
## [YYYY-MM-DD HH:MM] ingest | <nombre de la fuente>
Fuentes: `raw/ruta/fuente.md` (sha256:<64hex>)   ← una línea por fuente compilada
Páginas creadas: [lista]
Páginas actualizadas: [lista]
Evolución retroactiva: [[wiki/nota]] ← [[raw/fuente#sección]], ... (si aplica, ≤5)
Propuestas generadas: [lista si aplica]
Brechas emitidas: [ids si aplica] | Brechas absorbidas: [ids si aplica]
Revisión independiente: activada (N notas, M fuentes) | desactivada (bajo umbral)   ← solo si aplica §Paso 3.75
Hallazgos: X corregidos-directo · Y → GAP-… · Z no-absorbidos (cap lleno)            ← solo si se activó
```

> [!important] Fingerprint de contenido en la línea `Fuentes:` (detección de stale)
> Cada fuente compilada se registra con su hash de contenido `(sha256:…)` **inmediatamente después** del path entre backticks. Esto habilita el MODO HASH de `scripts/stale_sources.sh`: detecta cuándo una fuente `raw/` cambió de verdad, inmune al ruido de `mtime` que mete la sincronización en la nube.
> - **No lo calcules a ojo:** `bash scripts/source_hash.sh --line raw/ruta/fuente.md` imprime la línea `Fuentes:` ya armada y lista para pegar (misma definición de hash que usa el lector → comparación confiable).
> - Si compilaste varias fuentes, una línea `Fuentes:` por cada una (o pásalas todas: `bash scripts/source_hash.sh raw/a.md raw/b.md`).
> - Un paréntesis descriptivo libre puede ir **después** del `(sha256:…)`; solo el prefijo `sha256:` cuenta como fingerprint, lo demás no interfiere.
> - **Nunca** reescribas líneas `Fuentes:` viejas para agregarles hash: el log es append-only (REGLA 5) y backfillear un hash sería declarar falsamente "este era el contenido al compilar". Los hashes se pueblan solos en cada compilación nueva.

---

## Reglas durante ingest

- ❌ NUNCA modificar `curated/`
- ❌ NUNCA modificar `raw/` (excepción acotada: crear/añadir en `raw/feedback/` solo al absorber una brecha y con confirmación del humano · REGLA 2)
- ❌ NUNCA mover archivos a `archivo/` sin orden explícita
- ✅ Crear páginas wiki/ nuevas si hacen falta
- ✅ Actualizar páginas wiki/ existentes
- ✅ Crear propuestas en `wiki/_proposed/` si aplica
- ✅ Absorber brechas respondidas (Paso 0.5) y emitir brechas N1 ≤3 (Paso 3.8) en `wiki/_gaps.md`
- ✅ Activar revisión independiente cuando corresponda (§Paso 3.75); resolver sus hallazgos directo o vía GAP, nunca pausar para el humano
- ✅ Evolución retroactiva acotada (§Paso 3.65): refrescar description/tags de notas en related[] directo que cumplan el checklist de calificación, con cita puntual y tope ≤5/ingest
- ✅ Reportar "Evolución retroactiva: 0 notas — <motivo>" en ENTREGA cuando ninguna nota calificó — nunca omitir la línea
- ❌ NUNCA crear una nota nueva por evolución retroactiva, ni tocar su cuerpo/hechos ni su `updated:`/`last_agent:` — eso es "actualizar el átomo" (Paso 5) o "patrón candidato" (SKILLS/compose.md), no esta vía
- ✅ Correr el Gate REGLA 8 (§Paso 3.68) antes de cada `Write`/`Edit` final de nota — excepciones documentadas inline con `> [!note] Excepción REGLA 8: ...`, nunca en silencio, nunca pausando para el humano

---

## Criterios de calidad para páginas wiki/

> [!info] Relación con el Gate REGLA 8 (§Paso 3.68)
> Los primeros 4 criterios de esta lista (atomicidad, nodos extraídos, fan-in, enlazada) ya no son solo una referencia post-hoc para `/lint`: se verifican también ANTES de escribir, como Gate obligatorio en §Paso 3.68. Esta lista sigue sirviendo de checklist de referencia completo.

```
✅ ATOMICIDAD: la nota cubre UN solo sujeto (REGLA 8). Si describe varias entidades → debían ser notas separadas.
✅ NODOS EXTRAÍDOS: las entidades/conceptos N1 son notas entity/concept propias, no secciones dentro de una guía.
✅ FAN-IN sano: ≤12 fuentes raw distintas y ≤150 líneas. Si lo supera → split + MOC.
✅ ENLAZADA: ≥2 enlaces tipados a notas existentes (## Relacionado + related[]); registrada en su MOC. (Exento: moc, entity recién nacida sin pares.)
✅ Sin párrafos de introducción genéricos ("Este documento explica...")
✅ Tablas para datos comparativos
✅ Bullets para listas de hechos
✅ > [!warning] para gotchas críticos
✅ > [!info] para contexto útil no obvio
✅ [[wikilinks]] tipados para referencias a otras páginas (no enlaces repetidos en masa)
✅ Citación granular: cada hecho verificable citado [[raw/nota#sección]], o marcado [FUENTE NO PERSISTIDA], o [INFERIDO]
✅ [INFERIDO] solo para conclusiones útiles no textuales; agrupar varias en ## Inferencias o > [!question]
✅ Citas a nota o #sección de raw/ — nunca block-ids (^id) en raw (es inmutable)
✅ Fuentes consolidadas en frontmatter sources[] y en ## Fuentes (superset de las citas inline)
✅ Confianza explícita en frontmatter confidence: 0.0–1.0
✅ description: presente y concisa (≤1 oración, plain text, sin cita)
✅ resource: presente para entity/concept con URL canónica del asset conocida
✅ tags: array de ≥2 etiquetas cross-cutting (entity, concept, pattern — ver taxonomía §1.0)
✅ Pirámide de señal aplicada: solo Nivel 1 y top Nivel 2 en el cuerpo (§Paso 2.5)
✅ Nota ≤ 25% de líneas de la fuente — §Paso 3.7 verificado
✅ Nivel 3 reemplazado por cita [[raw/nota#sección]], nunca copiado
✅ ## Insight al final: 2-3 bullets de síntesis del LLM (prosa sin citas)
✅ Si el ingest calificó para revisión independiente (§Paso 3.75): corrió, y sus hallazgos quedaron resueltos (directo) o convertidos en GAP — nunca silenciados
```

---

## Ejemplo de página wiki/ bien formada

```markdown
---
title: "Patrón Ciclo-de-Repetición — <dominio>"
type: pattern
description: "Ciclo que se autoalimenta cuando un elemento tarda en responder y el que depende de él repite la solicitud sin esperar la resolución."
domain: <dominio>
tags: [runbook, p1, dominio-a]
status: active
sources: [raw/ejemplo-2026-01-15.md]
created: 2026-01-16
updated: 2026-01-16
last_agent: claude-code
confidence: 0.95
---

# Patrón Ciclo-de-Repetición

## Descripción
Ciclo donde un elemento repite una solicitud antes de que la anterior termine de resolverse, lo que aumenta la carga sobre el elemento del que depende y empeora la demora original.

## Elementos afectados
| Elemento | Síntoma visible | Causa raíz | Fuente |
|---|---|---|---|
| elemento-a | Cola creciente, capacidad ociosa | Recibe solicitudes repetidas de elemento-b | [[raw/ejemplo-2026-01-15#Causa raíz\|ejemplo]] |
| elemento-b | Demora elevada | Repite antes de tiempo | [[raw/ejemplo-2026-01-15#Alcance\|ejemplo]] |

## Señales de alerta
- Capacidad ociosa + cola creciente = NO es más demanda real, es repetición. [[raw/ejemplo-2026-01-15#Diagnóstico]]
- Ratio solicitudes-repetidas/solicitudes-nuevas > 0.99 = son las mismas solicitudes repitiéndose. [[raw/ejemplo-2026-01-15#Métricas]]
- El ciclo suele dispararse tras un cambio en elemento-a. [INFERIDO]

## Solución
[acciones de resolución...]

## Insight
- El patrón central: sin un chequeo de "¿ya se resolvió?" antes de repetir, cualquier demora de elemento-a se convierte en un ciclo que se alimenta solo.
- La señal que se pierde: mirar el promedio no alcanza — cuando el problema es repetición (no demora real), hay que mirar el conteo total de solicitudes.
- El arreglo estructural: esperar con un margen creciente antes de repetir, no repetir de inmediato.

## Fuentes
- [[raw/ejemplo-2026-01-15]]
```

> [!info] Lectura del ejemplo
> Las filas/bullets con prueba directa terminan en `[[raw/...#sección]]`. La conclusión propia no textual va `[INFERIDO]`. Un hecho de fuente real no persistida iría `[FUENTE NO PERSISTIDA: <origen>]`. La prosa conectiva no lleva cita.

---

## Prompt reutilizable de invocación

Copiar y pegar para pedir una compilación con citas:

```text
Compila las fuentes indicadas en wiki/ siguiendo el SKILL /ingest (Map-Reduce con procedencia).

ATOMICIDAD Y ENLAZAMIENTO (REGLA 8) — el cerebro es una red, no un archivador:
- Descompón la fuente en ÁTOMOS (un sujeto por nota). Una fuente rica produce varias notas, no una gigante.
- Extrae entidades/conceptos N1 como notas-hub propias (type: entity/concept) y enlázalas; no las describas dentro de una guía.
- Default ante "¿actualizar o crear?": CREA el átomo nuevo aunque el dominio coincida. Actualiza solo el mismo sujeto.
- Fan-in: ninguna nota >12 fuentes raw ni >150 líneas. Si el destino está lleno → átomo nuevo + enlace; marca el saturado para split.
- Enlaza cada nota a ≥2 notas existentes con relación TIPADA (define/depende-de/instancia-de/afecta-a/contradice/ver-también) en ## Relacionado + related[]. Bidireccional para relaciones fuertes.
- Registra cada átomo en el MOC de su dominio (wiki/moc-<dominio>.md, type: moc); créalo si hay ≥3 átomos del dominio y no existe.
- No repitas el mismo wikilink en masa: conecta átomos distintos.

TRAZABILIDAD — cada hecho verificable cae en uno de tres casos:
- Fuente persistida en raw/ → cita inline [[raw/nota#sección]] (solo prueba directa).
- Fuente real no persistida (conversación, doc externo) → [FUENTE NO PERSISTIDA: <origen>]. No uses [INFERIDO].
- Conclusión propia no textual → [INFERIDO], solo si es útil; agrupa varias en ## Inferencias o > [!question].
No cites prosa de síntesis ni texto conectivo. No marques [INFERIDO] reformulaciones obvias de algo ya citado.

FORMATO:
- En tablas usa columna `Fuente` con el wikilink (pipe escapada: [[raw/nota#sección\|fuente]]).
- raw/ es inmutable: links a nota o a #sección, nunca block-ids.
- Si una fuente no tiene headings suficientes, cita a nota completa [[raw/nota]] y repórtalo como gap.
- Frontmatter: completa sources: (superset de citas), confidence:, description: (≤1 oración del átomo, plain text), tags: (≥2 cross-cutting · ver taxonomía en SKILLS/format.md §1.0) y resource: si type entity/concept con URL canónica conocida. Consolida sources: también en ## Fuentes.

COMPRESIÓN — Pirámide de señal (§Paso 2.5 + §Paso 3.7):
- N1 (compilar siempre): patrones recurrentes, gotchas no obvios, decisiones operativas, thresholds, conexiones cross-dominio.
- N2 (compilar si ≥ 1/semana): top 3-5 queries/comandos, esquema de datos principal (no campo a campo), escalación.
- N3 (NUNCA compilar — citar raw/): queries SQL completas, listas exhaustivas de campos, procedimientos sin variación, código > 15L, descripciones de capturas.
- Nota ≤ 25% de líneas de la fuente. Si > 25%: identificar N3 y reemplazar por [[raw/nota#sección]] + lectura operativa.
- ## Insight al final: 2-3 bullets de síntesis del LLM (sin citas).

EVOLUCIÓN RETROACTIVA (§Paso 3.65, A-MEM):
- Revisá SOLO las notas en related[] directo de los átomos tocados (nunca el MOC completo ni 2+ saltos).
  Aplicá el checklist de calificación (nota existente en related[] directo + afirmación puntual y citable
  sobre su sujeto + eso vuelve inexacto su description/tags actual) — las tres o no califica.
- Si califica: refrescá SOLO description/tags (nunca el cuerpo, nunca updated:/last_agent:), citando la
  fuente puntual. Tope ≤5 notas/ingest. Nunca crees una nota nueva por esta vía.
- Reportá siempre en ENTREGA, incluso "0 notas — <motivo>" si ninguna calificó. Nunca omitas la línea.

BRECHAS (feedback loop · REGLA 7):
- Al inicio, absorbe brechas respondidas de wiki/_gaps.md (compílalas primero).
- Al final, emite ≤3 brechas N1 sin resolver a wiki/_gaps.md (status: open) + callout > [!question] inline. No emitas N2/N3.

ANTES DE FINALIZAR:
- Antes de cada Write/Edit final de nota: corré el Gate REGLA 8 (§Paso 3.68) — ≥2 related reales,
  description poblada, fan-in dentro de límite, type correcto para su rol en el grafo. Si algún
  ítem falla y se justifica igual, escribí la nota con `> [!note] Excepción REGLA 8: <ítem> —
  <motivo>` inline (no alcanza con mencionarlo solo en la ENTREGA). Si falla sin justificación
  real, no escribas así: volvé a completar lo que falta.
- Corre: bash scripts/verify_citations.sh <nota>  (no cierres con citas rotas).
- Si tocaste >3 átomos o creaste una entity/concept nueva: activá la revisión independiente
  (§Paso 3.75) — es automática por umbral, no la pidas ni la ofrezcas como opcional.

ENTREGA (reporta al final):
- Páginas creadas (marca cuáles son nodos-hub entity/concept extraídos)
- Páginas actualizadas
- Enlaces tipados creados (origen → relación → destino) + MOCs tocados/creados
- Excepciones al Gate REGLA 8 (si hubo): nota + ítem que falló + motivo (la constancia obligatoria ya vive en el callout inline de la nota; esta línea es solo la referencia en ENTREGA)
- Evolución retroactiva: notas retocadas (description/tags) y la fuente que motivó cada refresco, o "0 notas — <motivo>" si ninguna calificó
- Notas marcadas para split (fan-in excedido)
- Fuentes usadas
- Fuentes vetadas (si agregaste alguna a wiki/.skip-sources.md): path · categoría (vacía|duplicado|fuera-de-alcance) · razón. NUNCA vetar en silencio — el Mecanismo de ignore es autónomo pero siempre visible (ver AGENTS.md).
- Citas verificadas (resultado de verify_citations.sh)
- Inferencias agregadas
- Brechas emitidas (ids) / Brechas absorbidas (ids)
- Dudas abiertas / gaps (incl. fuentes no persistidas y notas sin headings suficientes)

Fuentes a compilar:
- <pegar paths de raw/>
```
