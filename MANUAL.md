# BrainAI — Manual del humano

> Este documento es para vos, no para el agente.
> Los protocolos técnicos viven en `AGENTS.md` y `SKILLS/`. Este manual explica el sistema desde tu perspectiva: qué ganás, qué hacés vos, qué hace el agente solo.

---

## ¿Qué es esto y qué te da?

BrainAI es tu cerebro digital personal. No es un repositorio de documentos — es un grafo de conocimiento que:

- **Recuerda por vos** lo que investigaste, los análisis que hiciste, los patrones de falla, los datos reales que validaste.
- **Conecta lo disperso** — cuando aparece un caso nuevo en un sistema que ya conocés, el cerebro ya sabe que ese patrón ocurrió antes, con qué firma y qué hiciste.
- **Te pregunta cuando no sabe algo importante** en vez de inventar — y cuando respondés, lo incorpora como conocimiento citable.
- **Protege lo que validaste** — las notas que marcás como curadas nunca se sobreescriben sin tu aprobación.

La diferencia práctica: cuando lo necesitás, en vez de buscar en tu memoria, le preguntás al cerebro y te proporciona información exacta con evidencia histórica.

---

## La magia — lo que ocurre cuando usás el sistema

```
Vos agregás una nota de trabajo a raw/
           ↓
El agente la compila en wiki/ como átomos enlazados
(patrón, entidad afectada, threshold, gotcha)
           ↓
Si tiene dudas sobre algo crítico → te hace una pregunta (GAP)
"¿El plazo acordado con el proveedor X es de 30 o 45 días?"
           ↓
Vos respondés en _gaps.md
           ↓
El agente lo incorpora con cita propia tuya
           ↓
Próxima vez que alguien (o vos) preguntan sobre ese timeout:
el cerebro responde con fuente citable, no con inferencia
```

Cada ciclo el cerebro sabe más. Cada GAP que respondés convierte conocimiento tácito tuyo en conocimiento durable del sistema.

---

## Lo que VOS hacés (nadie más puede)

Hay 5 acciones que solo vos podés ejecutar. El agente no puede hacerlas solo.

### 1 — Agregar fuentes a `raw/`

Cualquier cosa que vale la pena recordar va a `raw/`:

- Notas de trabajo, RCAs, análisis de incidentes
- Decisiones de arquitectura, thresholds validados, configuraciones reales
- Reuniones de contexto, spikes, resultados de investigación
- Artículos o docs externos que usás frecuentemente

**Cómo (libre):** creá un archivo `.md` en `raw/` con el contenido. El agente lo compila cuando le pedís `/ingest`.

**Cómo (asistido):** usá una de las 4 plantillas de Templater — la nota nace ya estructurada, con frontmatter y secciones correctas, lista para ingestar. Para la daily, abrila desde Calendar/Daily Notes y Templater la arma automáticamente. Ver sección "Captura con plantillas (Templater)" más abajo.

> El contenido de `raw/` es inmutable — el agente nunca lo modifica. Es tu fuente de verdad.

---

### 2 — Invocar las operaciones

El cerebro no actúa solo. Vos lo activás con estos comandos:


| Comando                   | Cuándo usarlo                                            |
| ------------------------- | -------------------------------------------------------- |
| `/ingest raw/<archivo>`   | Acabás de agregar o modificar algo en raw/               |
| `/query <pregunta>`       | Querés saber algo que el cerebro debería tener           |
| `/gaps`                   | Querés responder preguntas pendientes o ver las abiertas |
| `/status`                 | Ver el estado general del sistema                        |
| `/lint`                   | Health-check periódico (cada 2-3 semanas)                |
| `/curate wiki/<nota>`     | Querés congelar una nota como canónica                   |
| `/archive wiki/<nota>`    | Declarás obsoleta una nota — solo vos podés ordenarlo    |
| `/compose --hasta-limpio` | Dejar el cerebro auto-mejorando solo un rato             |


---

### 3 — Responder los GAPs

Los GAPs son preguntas del agente que no pudo resolver compilando. Las vas a ver en dos lugares:

**En `wiki/_gaps.md`** — cada brecha abierta tiene este formato:

```
### GAP-2026-06-11-002 · status: open
- Pregunta: ¿Cuál es el plazo real acordado con el proveedor X?
- Por qué importa: es el dato central de la propuesta TICKET-1234...
- Respuesta del humano: ← vos escribís aquí
```

**En las notas wiki/** — como callouts:

```
> [!question] GAP-2026-06-11-002 — ¿Cuál es el timeout real...?
```

**Para responder:** abrís `wiki/_gaps.md`, buscás las brechas con `status: open` y escribís tu respuesta en el campo `Respuesta del humano`. Luego invocás `/gaps` y el agente la absorbe al conocimiento.

> Tu respuesta se convierte en una fuente citable. Si es un threshold o decisión importante, el agente te pedirá confirmación para persistirla en `raw/feedback/` — ahí vivirá para siempre como conocimiento tuyo, citable por cualquier nota futura.

> [!info] Un tipo especial de GAP: "¿es un patrón real?"
> A veces, corriendo `/compose`, el agente nota que varias notas ya compiladas sugieren algo en conjunto que ninguna dice por separado — pero **nunca** lo escribe solo. Te lo deja como GAP tipo `patron-candidato`: "¿esto que veo entre estas notas es un patrón real, o coincidencia?". Si confirmás, ahí sí nace la nota nueva, citando tu respuesta. Si decís que es coincidencia, no se crea nada. Es la única forma en que una nota nueva puede nacer sin que vos le hayas dado una fuente directa — y por eso siempre pasa por tu confirmación primero.

---

### 4 — Decidir cuándo curar una nota

Curar = declarar que una nota es canónica y que no querés que el agente la modifique solo.

**Señales de que una nota merece curación:**

- La consultás de forma recurrente en tu trabajo
- La refinaste manualmente y quedó exactamente como querés
- Contiene decisiones de diseño o thresholds validados
- Es la referencia maestra de un sistema o proceso central

**Cómo:** simplemente decís `/curate wiki/<nombre-de-la-nota>`. El agente te va a pedir una cosa antes de mover la nota: **1-2 líneas tuyas con la idea central, en tus propias palabras** (no vale repetir la descripción que ya escribió el LLM). Es la única fricción de todo el sistema — y es a propósito.

Desde ese momento:

- El agente **nunca** la modifica directamente
- Si un nuevo ingest trae info que la actualizaría → el agente crea una propuesta en `wiki/_proposed/` y te avisa
- Vos revisás la propuesta y decidís si la incorporás

> Curar poco y bien es mejor que curar todo. Empezá con las notas que más consultás y los patrones centrales de tu trabajo.

> [!abstract] Por qué te pide reformular en vez de solo aprobar
> BrainAI resuelve a propósito la tensión entre velocidad y aprendizaje a favor de la **velocidad de recuperación** — el objetivo del sistema es que consultes rápido cuando lo necesites, no que estudies. Eso significa que compilar `wiki/` no te exige escribir nada: el LLM sintetiza y vos accedés. Pero eso también resigna el "generation effect" (aprender reformulando con tus propias palabras) que es el corazón de Zettelkasten. La única palanca que se activa para recuperarlo, sin frenar el resto del flujo, es `/curate`: como es un conjunto chico y deliberado — las notas que más vas a reusar — pedirte una línea propia ahí es barato y de alto valor. El resto de la wiki sigue siendo 100% compilación.

> [!info] El contrapeso de curar: `/archive`
> Cuando una nota de `wiki/` queda obsoleta (no curada — para eso primero `/uncurate`), decís `/archive wiki/<nota> — [razón]` y el agente la mueve a `archivo/`. Es, de las 9 operaciones, la que el kernel más blinda: el agente **nunca** archiva por iniciativa propia (ni durante `/lint` ni `/ingest`) — solo por tu orden explícita.

---

### 5 — Revisar propuestas en `wiki/_proposed/`

Cuando el agente encuentra info nueva que contradice o enriquece una nota curada, en vez de modificarla crea una propuesta:

```
wiki/_proposed/2026-06-15-nombre-de-la-nota.md
```

Esa propuesta tiene:

- La sección afectada (cómo está hoy en curated/)
- El cambio propuesto (qué agregaría o modificaría)
- La justificación (de dónde viene la info nueva)

**Vos decidís:** si la info es correcta y vale incorporarla, ejecutás `/curate` sobre la nota curada con los cambios. Si no, borrás la propuesta.

---

## Captura con plantillas (Templater)

El vault incluye 4 plantillas en `Templates/`. Con el plugin **Templater** instalado, cada plantilla hace preguntas al crearla (ticket, título, área, severidad) y **autonombra el archivo** con el patrón correcto — sin que tengas que recordar convenciones de nombres ni formato.

> [!warning] Dependencia del vault
> Templater es un plugin de la comunidad de Obsidian. Debe estar instalado y configurado para que las plantillas funcionen. Sin él, `Templates/` es solo una carpeta de texto — las notas no se auto-estructuran.

### Las 4 plantillas

| Plantilla | Cuándo usarla | Carpeta destino | Nombre resultante |
|---|---|---|---|
| **Daily Note** | Cada día laboral | `raw/Daily Notes/` | `DD-MM-YYYY` (auto) |
| **Análisis / Postmortem** | Investigaciones, decisiones, retros de proyecto | `raw/Analisis/` | `<referencia> - título` (o solo `título` si no hay referencia) |
| **Reunión** | Reuniones de contexto, charlas, sincs | `raw/Notas/` | `YYYY-MM-DD - Reunión - tema` |
| **Nota general** | Análisis, docs de trabajo | `raw/Notas/` | `<título>` |

### Daily Note — Calendar + Templater

La daily funciona con dos piezas:

- **Calendar / Daily Notes** crea o abre la nota del día en `raw/Daily Notes/`.
- **Templater** detecta que la nota nueva cayó en esa carpeta y aplica `Templates/Daily Note.md`.

Flujo normal:

1. En Obsidian, abrís el panel **Calendar**.
2. Hacés clic en el día que querés llevar.
3. Si la nota no existe, Obsidian la crea en `raw/Daily Notes/`.
4. Templater se ejecuta automáticamente, pregunta un **Título** opcional y renombra la nota a `DD-MM-YYYY`.
5. Si ya existía una daily para esa fecha, Templater abre la existente y descarta la nota duplicada.

También podés usar el comando *Open today's daily note*. El resultado es el mismo: la daily nace estructurada y lista para anotar el día. Nace con:

```
# DD-MM-YYYY

<< [[ayer]] | [[mañana]] >>

## Ultima nota - DD-MM-YYYY

![[raw/Daily Notes/DD-MM-YYYY#HOY]]

## HOY
- [ ]

### Blockers

### Notes
```

La navegación `<< ayer | mañana >>` usa la fecha del nombre del archivo. Si la daily anterior o siguiente ya existe, enlaza al archivo real; si no existe, deja listo el enlace para crearla después. La sección **Ultima nota** embebe el bloque `## HOY` de la última daily anterior encontrada, no necesariamente la de ayer; así sirve también si hubo fines de semana, feriados o días sin nota.

Al terminar de crearla, Templater deja el cursor en la primera tarea de `## HOY` para que puedas escribir de inmediato.

### Reglas para que la daily no se rompa

- Mantener la carpeta exacta: `raw/Daily Notes/`.
- Mantener el nombre canónico que deja Templater: `DD-MM-YYYY`, por ejemplo `14-06-2026.md`.
- No renombrar una daily a texto libre. Si necesitás contexto, ponelo como título interno o en `### Notes`, no en el nombre del archivo.
- No cambiar el heading `## HOY`: la plantilla lo usa para embeber la última nota y el agente lo usa como señal estable.
- No mover `Templates/Daily Note.md` ni cambiar su nombre sin actualizar Templater.
- Si Calendar pregunta antes de crear la daily, confirmá solo cuando realmente querés crear esa fecha.

### Análisis/Postmortem, Reunión y Nota general — invocación manual

1. Creás una nota nueva en la carpeta destino
2. `Ctrl/Cmd+P` → *Templater: Open insert template modal* (o el hotkey que asignaste)
3. Elegís la plantilla
4. Respondés los prompts (referencia, título, prioridad…)
5. El archivo se renombra solo y queda con frontmatter + secciones listas

**Flujo típico — un caso que requiere análisis (sirve igual para un incidente técnico, una investigación o una decisión):**

```
1. Caso detectado (incidente, hallazgo, decisión a documentar…)
2. Nota nueva en raw/Analisis/
3. Templater → Analisis-Postmortem
4. Referencia: TICKET-1234 · Título: plazo del proveedor X · Prioridad: alta
5. Archivo renombrado a "TICKET-1234 - plazo del proveedor X.md"
   Frontmatter + tabla + secciones Qué pasó/Análisis/Conclusión listas
6. Completás el análisis durante o después del caso
7. /ingest raw/Analisis/TICKET-1234 - plazo del proveedor X.md
```

### Configuración inicial (una sola vez, desde la UI de Obsidian)

> [!info] El agente no puede hacer esto — es configuración del cliente Obsidian

1. **Instalar:** Ajustes → Plugins de la comunidad → Examinar → *Templater* → Instalar → Habilitar
2. **Ajustes → Templater:**
   - *Template folder location* = `Templates/`
   - *Trigger Templater on new file creation* = **ON** (requerido para que Daily Note sea automática)
   - *User System Command Functions (shell)* = **OFF**
3. **Folder Templates** (mismo panel de Templater): habilitar → mapear `raw/Daily Notes/` → `Templates/Daily Note.md`
4. **Folder Templates adicional:** mapear `raw/` → `Templates/Nota-general.md` para capturas rápidas generales.
5. **Ajustes → Daily notes:** formato `DD-MM-YYYY` · carpeta `raw/Daily Notes/` · *Template file location* = `Templates/Daily Note.md`.
6. **Ajustes → Calendar:** plugin habilitado; *Confirm before creating new note* puede quedar **ON** para evitar dailies accidentales.
7. *(Opcional)* asignar hotkey a *Templater: Open insert template modal*

> [!note] Propiedad de `Templates/`
> Las plantillas viven fuera de `raw/`, así que el kernel BrainAI no las compila ni las indexa. Son herramienta de captura del humano, no conocimiento del agente. `bash scripts/pending_sources.sh` no las lista.

---

## Lo que el agente hace solo

No tenés que preocuparte por esto — el agente lo maneja:

- Descomponer fuentes en notas atómicas (una por sujeto)
- Enlazar notas con relaciones tipadas al grafo
- Registrar en MOCs (mapas de contenido por dominio)
- Citar cada hecho con su fuente exacta en `raw/`
- Detectar contradicciones entre notas y marcarlas
- Partir notas que crecieron demasiado (fan-in excesivo)
- Crear MOCs nuevos cuando hay ≥3 átomos de un dominio nuevo
- Detectar fuentes `raw/` modificadas (`stale_sources.sh`)
- Medir la salud del grafo (`graph_health.sh`)
- En ingests grandes (o que crean una entidad/concepto nueva): pedirle a un segundo agente, sin el contexto de cómo se escribió, que revise el trabajo contra la fuente cruda antes de cerrar — como un code review, pero de notas

---

## Flujo de una semana típica

```
LUNES — después de un caso que requirió análisis
  → Nota nueva en raw/Analisis/ → plantilla Analisis-Postmortem → completar análisis
  → /ingest raw/Analisis/<nombre>.md
  → El agente compila + emite GAPs si algo no quedó claro

MIÉRCOLES — 5 minutos
  → /status   (ver si hay GAPs respondidos pendientes o stale)
  → Si hay GAPs abiertos: abrís wiki/_gaps.md, respondés
  → /gaps     (el agente absorbe tus respuestas)

VIERNES — opcional
  → bash scripts/stale_sources.sh --full
  → Si hay fuentes stale relevantes: /ingest raw/<archivo>

MENSUAL — dejar corriendo
  → /compose --hasta-limpio
  → El agente optimiza el grafo solo hasta punto fijo

CUANDO QUIERAS
  → /query "¿cuál es el distinguidor entre el patrón A y el patrón B?"
  → El cerebro navega el grafo y responde con citas
```

---

## Consultar el cerebro

El comando más importante del sistema es el más simple:

```
/query <tu pregunta en lenguaje natural>
```

Ejemplos de preguntas reales:

```
/query ¿Cuáles son las señales de que el elemento-A entró en un ciclo que se autoalimenta?

/query ¿Qué decidimos la última vez que evaluamos esta opción?

/query ¿Cuál es la diferencia entre el enfoque A y el enfoque B que ya analizamos?

/query ¿Qué plazo quedó acordado con el proveedor X?

/query Resume los hallazgos y decisiones de junio 2026
```

El agente va a:

1. Leer el índice (`wiki/index.md`) para orientarse
2. Entrar por el MOC del dominio relevante
3. Navegar los enlaces tipados hasta el átomo exacto
4. Responderte con citas a las fuentes que lo fundamentan
5. **Releer su propia respuesta antes de mostrártela** — cualquier frase que no esté dicha tal cual en esas fuentes se marca `[INFERIDO]` o se saca de la respuesta. Nunca te muestra algo y lo corrige después.

Si la respuesta tiene `[INFERIDO]` → es una deducción del agente, no un hecho verificado. Si tenés dudas, preguntale de dónde lo infirió.

---

## Cómo saber que el sistema está funcionando bien

Señales de salud:


| Señal                                                    | Qué indica                                    |
| -------------------------------------------------------- | --------------------------------------------- |
| GAPs se emiten en cada ingest                            | El agente está siendo honesto sobre sus dudas |
| GAPs respondidos → conocimiento enriquecido              | El feedback loop está cerrando                |
| `bash scripts/graph_health.sh --score` → `DEUDA=0`       | El grafo está bien conectado                  |
| `bash scripts/stale_sources.sh --score` → `STALE=0`      | Todo lo que cambiaste ya fue compilado        |
| Notas curadas reciben `_proposed/` cuando hay info nueva | El sistema protege lo que validaste           |


Señales de que algo necesita atención:


| Señal                                       | Qué hacer                                  |
| ------------------------------------------- | ------------------------------------------ |
| GAPs sin responder > 14 días                | Abrí `_gaps.md` y respondé — son 5 minutos |
| `STALE > 0` con nota curated/ afectada      | `/ingest` urgente — generará `_proposed/`  |
| `/compose` nunca corrió en más de 30 días   | Corré `/compose --ciclos 5`                |
| Notas en `_proposed/` sin revisar > 14 días | Revisalas — el agente las está esperando   |


---

## El principio central del sistema

> **El agente compila. Vos validás.**

El agente es el compilador: extrae señal de fuentes crudas, enlaza, sintetiza, emite dudas. Pero la validación de si algo es correcto, si un threshold es el real, si una decisión es la vigente — eso siempre es tuyo. Los GAPs son el mecanismo por el que el cerebro te pide esa validación. Sin tus respuestas, el cerebro sabe mucho pero confía en inferencias. Con tus respuestas, convierte conocimiento tácito tuyo en conocimiento durable y citable.

La inversión es asimétrica: 5 minutos tuyos respondiendo un GAP pueden valer meses de contexto compilado disponible para cualquier consulta futura, en cualquier incidente, en cualquier handoff de trabajo.

---

## Referencia rápida

```bash
# Agregar fuente nueva al cerebro
/ingest raw/<path>

# Consultar el cerebro
/query <pregunta>

# Ver y responder preguntas abiertas
/gaps

# Estado del sistema
/status

# Ver fuentes modificadas post-compilación
bash scripts/stale_sources.sh --full

# Ver fuentes nunca compiladas
bash scripts/pending_sources.sh

# Salud del grafo
bash scripts/graph_health.sh --score

# Congelar una nota como canónica
/curate wiki/<nombre>

# Dejar el cerebro mejorando solo
/compose --hasta-limpio

# Health-check periódico
/lint
```

---
