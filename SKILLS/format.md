# SKILL: /format — Guía de formato Obsidian + Markdown

> Referencia obligatoria antes de escribir cualquier nota en wiki/ o curated/.
> Obsidian tiene convenciones específicas que difieren del markdown estándar.
> Aplicar siempre. Sin excepciones.

---

## ⚠️ Regla de oro

**Siempre consultar esta guía antes de crear o modificar cualquier nota.**
Un formato incorrecto rompe links, callouts y tablas en Obsidian silenciosamente.

---

## 1. Frontmatter YAML

> [!important] Dos contratos distintos
> - **Páginas `wiki/` de BrainAI** → usar el **BrainAI wiki schema** (§1.0). Es el contrato del kernel.
> - **Notas generales del vault** (Daily Notes, reuniones, notas sueltas, etc.) → usar el schema general (§1.1) con `tags`/`date`.
> No mezclar ambos: una página `wiki/` no requiere `tags`/`date`; una nota general no requiere `confidence`/`sources`.

### 1.0 BrainAI wiki schema (kernel) — autoritativo para `wiki/`

Contrato único definido en `AGENTS.md`. Estos son los campos del frontmatter de una página `wiki/`:

```yaml
---
title: ""
type: entity | concept | pattern | summary | comparison | guide | incident | moc
description: ""    # one-liner para agentes/búsqueda/index; ≤1 oración, plain text, sin cita
resource: ""       # URI canónica del asset real (entity/concept); omitir en moc/summary/comparison/pattern
domain: ""
tags: []           # cross-cutting ortogonales a domain; ≥2 para entity/concept/pattern (ver taxonomía abajo)
status: active | stale
sources: []          # superset consolidado de todas las citas inline [[raw/...]]
related: []          # enlaces tipados salientes — "relación :: [[wiki/nota]]" — ≥2 (exento: moc, entity nueva)
created: YYYY-MM-DD
updated: YYYY-MM-DD
last_agent: claude-code | codex | cursor   # el agente que ejecutó
confidence: 0.0–1.0
---
```

> [!note] `tags` en wiki/ — parte del contrato del kernel y tags nativos de Obsidian
> `tags` es parte del contrato del kernel para `wiki/` (recomendado ≥2 etiquetas cross-cutting por nota entity/concept/pattern).
> Obsidian lee `tags:` de frontmatter nativamente → las etiquetas aparecen en el **Tag Explorer** del vault automáticamente. Esto es **intencional**: permite filtrar notas wiki/ por contexto operacional (ej. runbook, criticidad, área de negocio) directamente en Obsidian.
>
> **Taxonomía de tags para wiki/** (extensible — los valores de cada categoría son **ejemplos ilustrativos** de un dominio operativo/técnico; reemplazarlos por el vocabulario real del dominio de cada vault):
> ```yaml
> howto | guia | postmortem | checklist            # contexto (ejemplo)
> p1 | p2 | criticidad-alta | criticidad-baja      # criticidad (ejemplo)
> dominio-a | dominio-b | dominio-c                # negocio/dominio (ejemplo — usar el vocabulario real)
> lenguaje-x | infra-y | plataforma-z              # tech (ejemplo — usar el stack real)
> activo | stale | wip | legacy                    # estado operativo
> ```
>
> **Estas 5 categorías no son obligatorias — son la forma que toma un dominio operativo/técnico.** El único requisito real es ≥2 tags cross-cutting por nota `entity`/`concept`/`pattern`; el vocabulario y las categorías son 100% del dominio del vault. Ejemplo de un dominio distinto (investigación/escritura): `hallazgo | hipotesis | borrador` (tipo de contenido), `tema-a | tema-b` (área temática), `validado | por-revisar` (estado de revisión) — misma mecánica, vocabulario completamente distinto.
>
> **IMPORTANTE**: las etiquetas de wiki/ usan taxonomía propia del vault ≠ las de §1.1 (tipo/area/estado para notas generales del vault). Ambas coexisten en el Tag Explorer sin conflicto. `date` sigue siendo legacy/no-usar en wiki/; el campo correcto es `created`/`updated`.

| Campo | Obligatorio | Cuándo poblar | Ejemplo |
|---|---|---|---|
| `description` | Recomendado en todos | Siempre al crear/actualizar | `"Servicio principal de procesamiento batch, corre cada noche."` |
| `resource` | Opcional; esperado en entity/concept | Cuando la fuente provee URL canónica del asset | `"https://github.com/tu-org/tu-repo"` |
| `tags` | Recomendado ≥2 para entity/concept/pattern | Siempre al crear/actualizar | `[runbook, dominio-a, p1]` |

- `related[]` es el espejo en frontmatter de la sección `## Relacionado` (Política de Enlazamiento · REGLA 8). `moc` es el Mapa de Contenido de un dominio.
- Las páginas `curated/` y `archivo/` tienen su propio schema (ver `AGENTS.md`).

### 1.1 Schema general del vault (notas fuera de `wiki/`)

Para notas generales del vault (no compiladas por el kernel), la estructura es:

```yaml
---
title: "Título de la nota"
type: entity | concept | pattern | summary | comparison | guide | incident | curated
domain: "área temática"
status: active | stale | human-canonical
tags: [tipo, area, tech, estado]
date: YYYY-MM-DD
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### Reglas del frontmatter

| Regla | ✅ Correcto | ❌ Incorrecto |
|---|---|---|
| Siempre primero | `---` en línea 1 | Cualquier texto antes del `---` |
| Tags como array | `tags: [proyecto-x, go, activo]` | `tags: proyecto-x, go, activo` |
| Fechas ISO | `date: 2026-06-07` | `date: 07/06/2026` |
| Strings con espacios | `title: "Mi título"` | `title: Mi título` |
| Sin línea vacía interna | bloque `---` continuo | `---` con líneas vacías adentro |
| Cerrar con `---` | tres guiones exactos | `....` u otras variantes |

### Taxonomía de tags (del vault)

```yaml
# tipo (uno obligatorio — extensible; agregar los que falten para tu dominio)
idea | doc | reunion | tarea | analisis | guia | referencia | arquitectura | proyecto | indice

# area (uno o más — ejemplo; reemplazar por los dominios reales del vault)
dominio-a | dominio-b | dominio-c | ia | personal

# tech (opcional — ejemplo; reemplazar por el stack real del vault)
go | sql | infra-x | infra-y | observabilidad

# estado (uno obligatorio)
activo | wip | pendiente | completado | archivado
```

---

## 2. Links internos — OBSIDIAN ESPECÍFICO

| Tipo | Sintaxis correcta | Nunca usar |
|---|---|---|
| Link simple | `[[nombre de nota]]` | `[nombre](ruta.md)` |
| Link con alias | `[[nota\|texto visible]]` | `[texto](nota.md)` |
| Link a sección | `[[nota#Sección]]` | `[texto](nota.md#sección)` |
| Link a bloque | `[[nota^block-id]]` | — |
| Embed de nota | `![[nombre de nota]]` | `![](ruta.md)` |
| Embed de sección | `![[nota#Sección]]` | — |

### ⚠️ Caso especial: pipe en tablas

Dentro de una celda de tabla, la pipe `|` del alias **debe escaparse con backslash**:

```markdown
| Elemento | Referencia |
|---|---|
| elemento-a | [[elemento-a\|Alias]] |
```

❌ `[[elemento-a|Alias]]` dentro de tabla → rompe la tabla
✅ `[[elemento-a\|Alias]]` dentro de tabla → correcto

---

## 3. Callouts — OBSIDIAN ESPECÍFICO

### Sintaxis base

```markdown
> [!tipo] Título opcional
> Contenido del callout.
> Puede tener múltiples líneas.
```

### Tipos disponibles y cuándo usarlos

| Callout | Cuándo usar en BrainAI |
|---|---|
| `> [!note]` | Información adicional contextual |
| `> [!info]` | Contexto útil no obvio |
| `> [!tip]` | Mejores prácticas, shortcuts |
| `> [!warning]` | Gotchas críticos, trampas, errores comunes |
| `> [!danger]` | Riesgo de pérdida de datos, producción |
| `> [!success]` | Confirmación de que algo funciona |
| `> [!question]` | Preguntas abiertas, incertidumbre |
| `> [!abstract]` | Resumen ejecutivo al inicio de nota larga |
| `> [!example]` | Ejemplos concretos |
| `> [!quote]` | Citas textuales de fuentes |

### Callout foldable (empieza cerrado)

```markdown
> [!info]- Título (click para expandir)
> Contenido que empieza oculto.
```

El `-` después del tipo hace el callout colapsable y cerrado por defecto.
El `+` lo hace colapsable pero abierto por defecto.

### Callouts anidados

```markdown
> [!warning] Problema detectado
> Descripción del problema.
>
> > [!tip] Solución
> > Descripción de la solución.
```

### ❌ Anti-patrones de callouts

```markdown
# ❌ Sin el > antes del tipo
[!note] Esto no funciona

# ❌ Espacio extra entre > y [
> [!note]  ← espacio extra antes del tipo no importa, pero ser consistente

# ❌ Contenido sin >
> [!note] Título
Contenido sin > → no forma parte del callout

# ✅ Correcto
> [!note] Título
> Contenido con > → forma parte del callout
```

---

## 4. Encabezados

### Reglas

| Regla | ✅ | ❌ |
|---|---|---|
| Un solo H1 por nota | `# Título` al inicio | Múltiples `#` |
| Jerarquía continua | H1 → H2 → H3 | Saltar a H3 desde H1 |
| Sin punto final | `## Sección` | `## Sección.` |
| Línea vacía antes y después | `\n## Sección\n` | `texto\n## Sección\ntexto` |
| No bold en encabezado | `## Sección` | `## **Sección**` |

### Estructura recomendada para notas wiki/

```markdown
---
[frontmatter]
---

# Título de la nota

> [!abstract] Resumen en una línea (opcional para notas largas)

## Sección principal

### Subsección si es necesario

## Otra sección principal
```

---

## 5. Tablas

### Sintaxis correcta

```markdown
| Columna A | Columna B | Columna C |
|---|---|---|
| valor | valor | valor |
| valor | valor | valor |
```

### Alineación de columnas (opcional)

```markdown
| Izquierda | Centro | Derecha |
|:---|:---:|---:|
| texto | texto | texto |
```

### Reglas de tablas

| Regla | ✅ | ❌ |
|---|---|---|
| Separador obligatorio | `\|---\|` entre header y body | Omitirlo |
| Pipes escapados en wikilinks | `[[nota\|alias]]` | `[[nota|alias]]` |
| Sin HTML en celdas | `texto **bold**` | `texto <b>bold</b>` |
| Celda vacía explícita | `\| \|` o `\| — \|` | Omitir la celda |
| Mínimo dos columnas | `\| A \| B \|` | Tabla de una columna |

---

## 6. Listas

### Reglas

```markdown
# ✅ Lista sin orden — usar guión siempre
- item uno
- item dos
  - subitem (2 espacios de indentación)
    - sub-subitem (4 espacios)

# ❌ No mezclar delimitadores
* item uno
- item dos   ← mezcla de * y - → inconsistente

# ✅ Lista numerada
1. Primer paso
2. Segundo paso
3. Tercer paso

# ✅ Checkboxes de tarea
- [ ] Tarea pendiente
- [x] Tarea completada
- [!] Tarea importante (algunos themes de Obsidian)
```

---

## 7. Bloques de código

### Siempre especificar el lenguaje

```markdown
# ✅ Con lenguaje especificado
```go
func main() { ... }
```

```bash
#!/bin/bash
echo "hola"
```

```yaml
key: value
```

```sql
SELECT * FROM table;
```

# ❌ Sin lenguaje → no hay syntax highlighting
```
código sin lenguaje
```
```

### Lenguajes comunes

| Contexto | Lenguaje a usar |
|---|---|
| Scripts de sistema | `bash` o `shell` |
| Configuración | `yaml` o `json` |
| Consultas | `sql` |
| Código de aplicación | el lenguaje real (`go`, `java`, `python`, …) |
| Comandos CLI | `bash` |
| Markdown de ejemplo | `markdown` |
| Pseudocódigo | `text` o `plaintext` |

### Código inline

```markdown
# ✅ Backtick simple para código inline
El comando `git status` muestra el estado del working tree.

# ❌ Comillas para código
El comando "git status" muestra el estado del working tree.
```

---

## 8. Énfasis de texto

| Tipo | Sintaxis | Cuándo usar |
|---|---|---|
| **Negrita** | `**texto**` | Términos clave, alertas importantes |
| *Itálica* | `*texto*` | Énfasis suave, términos técnicos en primera mención |
| ***Negrita + itálica*** | `***texto***` | Usar con moderación — máximo impacto |
| ~~Tachado~~ | `~~texto~~` | Contenido obsoleto inline, no reemplaza archivar |
| `Código inline` | `` `texto` `` | Comandos, nombres de variables, paths |

### ❌ No usar HTML para énfasis

```markdown
# ❌ HTML inline — no usar
<b>negrita</b>
<i>itálica</i>
<strong>fuerte</strong>

# ✅ Markdown puro
**negrita**
*itálica*
```

---

## 9. Separadores y espaciado

```markdown
# Separador horizontal — línea propia con línea vacía antes y después
texto anterior

---

texto siguiente

# ❌ Sin líneas vacías
texto anterior
---
texto siguiente  ← puede interpretarse como encabezado H2 en algunos parsers
```

---

## 10. Block IDs — OBSIDIAN ESPECÍFICO

Para referenciar un párrafo o item específico desde otra nota:

```markdown
Este es un párrafo importante que quiero poder referenciar. ^id-unico-descriptivo

- Item de lista referenciable ^otro-id
```

**Reglas de block IDs:**
- Solo letras minúsculas, números, y guiones: `^mi-id-123`
- Sin espacios ni caracteres especiales
- Al final de la línea, separado por espacio
- IDs únicos en el archivo

---

## 11. Saltos de línea

```markdown
# En Obsidian, una línea en blanco = nuevo párrafo
Párrafo uno.

Párrafo dos.

# Salto de línea dentro de párrafo (soft break)
Línea uno.  ← dos espacios al final
Línea dos en el mismo párrafo.

# ❌ No usar <br> para saltos
Línea uno.<br>Línea dos.
```

---

## 12. Checklist de validación — Antes de guardar cualquier nota

Verificar cada punto antes de dar por terminada la escritura:

```
FRONTMATTER
□ Existe frontmatter entre --- y ---
□ title: con comillas si tiene espacios
□ status: uno de los valores válidos
□ type: uno de los valores válidos del schema de BrainAI
□ Si es página wiki/ → schema kernel (§1.0): sources, last_agent, confidence presentes
□   description: presente y en ≤1 oración (plain text, sin cita)
□   resource: presente si es entity/concept con URL canónica conocida de la fuente
□   tags: array con ≥2 etiquetas cross-cutting (para entity, concept, pattern) — taxonomía en §1.0
□ Si es nota general del vault → schema §1.1: tags como array [tag1, tag2] y date en YYYY-MM-DD

ESTRUCTURA
□ Un solo # (H1) al inicio, después del frontmatter
□ Jerarquía de encabezados continua (no saltar niveles)
□ Línea vacía antes y después de cada encabezado
□ Línea vacía antes y después de cada tabla
□ Línea vacía antes y después de cada bloque de código

LINKS
□ Todos los links internos usan [[wikilinks]], no [texto](ruta.md)
□ Pipes en wikilinks dentro de tablas escapadas: [[nota\|alias]]
□ No hay paths absolutos ni relativos de filesystem

ATOMICIDAD Y ENLAZAMIENTO (REGLA 8)
□ La nota cubre UN solo sujeto (átomo); no mezcla varias entidades/temas
□ Entidades/conceptos N1 extraídos como notas entity/concept propias, no descritos dentro de una guía
□ ≥2 enlaces tipados a notas existentes en ## Relacionado (relación :: [[wiki/nota]] — por qué) — exento: moc, entity nueva
□ related[] en frontmatter espeja la sección ## Relacionado
□ Enlaces fuertes (depende-de/define/afecta-a) tienen recíproco en la nota destino
□ Registrada en el MOC de su dominio (wiki/moc-<dominio>.md)
□ Fan-in sano: ≤12 fuentes raw distintas y ≤150 líneas
□ Sin enlaces repetidos en masa ni enlaces sin relación tipada

CITACIÓN (progressive disclosure)
□ Cada hecho verificable: cita [[raw/nota#sección]], o [FUENTE NO PERSISTIDA], o [INFERIDO]
□ [INFERIDO] solo para conclusión útil no textual; no para reformulaciones ni fuentes no persistidas
□ Varias inferencias juntas → sección ## Inferencias o callout > [!question]
□ Citas a raw/ usan link a nota o #sección — NUNCA block-id (^id) en raw
□ Tablas con datos de fuente: columna Fuente con pipe escapada si hay alias
□ frontmatter sources[] y ## Fuentes son superset de todas las citas inline

CALIDAD TEXTUAL (unit tests de la nota — ver §17, correr antes de dar el átomo por compilado)
□ Los 6 ítems de §17 corridos: vaguedad, trazabilidad, síntesis vs. hecho, comparaciones sin criterio, placeholders, alcance ambiguo

TABLAS
□ Separador |---|---| presente entre header y body
□ Wikilinks con pipe escapada si aplica
□ Sin HTML en celdas

CALLOUTS
□ Cada línea del callout empieza con >
□ Tipo de callout válido (note/info/tip/warning/danger/success/question/abstract/example/quote)
□ Callouts foldables usan - o + después del tipo

CÓDIGO
□ Todos los bloques de código tienen lenguaje especificado
□ Código inline usa backticks, no comillas

ÉNFASIS
□ Sin HTML inline (<b>, <i>, <strong>)
□ Listas usan - consistentemente (no mezclar con * o +)
□ Checkboxes usan - [ ] y - [x]
```

---

## 13. Patrones de nota bien formada por tipo

### Patrón: `type: pattern` (patrón recurrente)

```markdown
---
title: "Nombre del Patrón"
type: pattern
description: "Descripción en una línea del patrón — qué es y cuándo ocurre."
domain: "<dominio>"
tags: [<contexto>, <negocio>, <tech>]
status: active
sources: []
created: 2026-01-16
updated: 2026-01-16
last_agent: claude-code
confidence: 0.95
---

# Nombre del Patrón

> [!abstract]
> Una línea describiendo el patrón.

## Descripción
[qué es, cuándo ocurre]

## Elementos afectados

| Elemento | Síntoma visible | Causa raíz |
|---|---|---|
| [[wiki/elemento-a\|elemento-a]] | síntoma | causa |

## Señales de alerta

> [!warning] Señal crítica
> Descripción de la señal más importante.

- Señal 1: descripción
- Señal 2: descripción

## Diagnóstico

```bash
# Pasos o comandos de diagnóstico
```

## Solución
[pasos de resolución]

## Fuentes
- [[raw/ejemplo-2026-01-15.md]]
```

### Patrón: `type: entity` (una entidad concreta del dominio — app, servicio, persona, sistema, proceso…)

```markdown
---
title: "Nombre de la Entidad"
type: entity
description: "Qué es o qué hace esta entidad en una línea — su rol en el dominio."
resource: "https://github.com/<tu-org>/<nombre-repo>"    # o cualquier URI canónica del asset real
domain: "<dominio>"
tags: [<contexto>, <negocio>, <tech>, <criticidad>]
status: active
sources: []
created: 2026-01-16
updated: 2026-01-16
last_agent: claude-code
confidence: 0.90
---

# Nombre de la Entidad

> [!abstract]
> Qué es o qué hace esta entidad en una línea.

## Atributos clave

| Atributo | Valor |
|---|---|
| `<atributo-1>` | `<valor>` |
| `<atributo-2>` | `<valor>` |

## Rol en el dominio
[descripción funcional]

## Indicadores clave (si aplica)

| Indicador | Umbral | Qué indica |
|---|---|---|
| `<indicador>` | `<umbral>` | normal |

## Problemas conocidos

> [!danger] Problema conocido
> Descripción del problema.

## Relacionado
- afecta-a :: [[wiki/patron-x]] — esta entidad dispara el patrón bajo cierta condición
- depende-de :: [[wiki/elemento-b]] — la necesita para funcionar
- ver-también :: [[wiki/moc-<dominio>]] — MOC del dominio
```

### Patrón: `type: moc` (Mapa de Contenido de un dominio)

```markdown
---
title: "MOC — <dominio>"
type: moc
description: "Mapa de contenido del dominio <dominio> — puerta de navegación a sus átomos."
domain: "<dominio>"
status: active
sources: []
related: []
created: 2026-01-16
updated: 2026-01-16
last_agent: claude-code
confidence: 0.90
---

# MOC — <dominio>

> [!abstract]
> Puerta de navegación del dominio. Cada enlace lleva una línea de contexto. (Un MOC es casi todo enlaces: exento de la regla ≥2 related.)

## Entidades (nodos-hub)
- [[wiki/elemento-a]] — núcleo del dominio, descripción en una línea
- [[wiki/elemento-b]] — depende-de elemento-a

## Conceptos
- [[wiki/concepto-x]] — principio o técnica reutilizable del dominio

## Patrones e incidentes
- [[wiki/patron-y]] — afecta-a elemento-a, elemento-b
- [[wiki/incidente-ejemplo-2026-01-15]] — instancia-de patron-y

## Guías operativas
- [[wiki/guia-z]] — cómo resolver o prevenir patron-y
```

> [!tip] El MOC reemplaza la nota-guía gigante
> En vez de una guía de 50 KB que describe 8 apps, el MOC enlaza 8 notas `entity` atómicas. El agente entra por el MOC y baja solo al nodo que necesita.

---

## 14. Anti-patrones más frecuentes del LLM — Lista rápida

```
❌ Usar [texto](ruta.md) en lugar de [[nota]]
❌ Olvidar escapar | en wikilinks dentro de tablas
❌ Frontmatter con tags: sin array: tags: a, b en lugar de tags: [a, b]
❌ Múltiples H1 en la misma nota
❌ Saltar niveles: H1 → H3 sin H2
❌ Encabezados sin línea vacía antes/después
❌ Bloques de código sin lenguaje especificado
❌ Usar <br>, <b>, <i>, <strong> — HTML inline
❌ Mezclar - y * en listas del mismo nivel
❌ Callout sin > en cada línea del contenido
❌ Separador --- sin líneas vacías antes/después (puede generar H2 falso)
❌ Fechas en formato DD/MM/YYYY en lugar de YYYY-MM-DD
❌ Strings con espacios en frontmatter sin comillas
❌ Crear block-ids (^id) dentro de raw/ — raw es inmutable
❌ Dejar un hecho factual sin cita ni marca ([[raw/...]] / [FUENTE NO PERSISTIDA] / [INFERIDO])
❌ Marcar [INFERIDO] una fuente real no persistida (es [FUENTE NO PERSISTIDA]) o una reformulación obvia
❌ Citar prosa de síntesis o texto conectivo (solo se citan hechos verificables)
❌ CENTRALIZAR: meter varias entidades/temas en una sola nota (REGLA 8 — debían ser átomos separados)
❌ Describir una entidad/concepto dentro de una guía en vez de extraerla como nota entity/concept
❌ Engordar la "nota del dominio" porque el tema coincide (crear el átomo nuevo, no engordar)
❌ Dejar una nota con 0-1 enlaces tipados (densidad mínima ≥2; exento moc/entity nueva)
❌ Repetir el mismo wikilink en masa o enlazar sin relación tipada (ruido de grafo)
❌ Superar ~12 fuentes raw o ~150 líneas sin partir en átomos + MOC
❌ Omitir description: en una nota nueva — cada átomo debe describirse en ≤1 oración en frontmatter
❌ Crear entity/concept con URL de asset conocida sin resource: en frontmatter (la URL enterrada en body no es queryable por máquina)
❌ tags: como string en vez de array: tags: doc en vez de tags: [doc, p1]
❌ Usar tags de wiki/ con el vocabulario del schema §1.1 (tipo/area/estado) — son taxonomías distintas para propósitos distintos
❌ Usar description: con más de una oración o con citas [[raw/...]] inline — es plain text para agentes, no prose con trazabilidad
```

---

## 15. Citación de fuentes (Progressive Disclosure)

> Cada nota wiki/ es la capa resumen; cada cita inline es un punto de entrada expandible
> hacia la fuente que la fundamenta — igual que un sistema de citas expandibles:

### Regla maestra: trazabilidad de cada hecho

Todo **hecho verificable** (métrica, threshold, config, comando, decisión, gotcha) cae en
uno de tres casos. Nunca un dato factual sin trazabilidad:

| Origen del hecho | Marca |
|---|---|
| Fuente persistida en `raw/` | cita inline `[[raw/nota#sección]]` |
| Fuente real pero no persistida (conversación, doc externo) | `[FUENTE NO PERSISTIDA: <origen>]` |
| Conclusión/deducción propia, no textual en ninguna fuente | `[INFERIDO]` |

> [!warning] No abusar de `[INFERIDO]`
> `[INFERIDO]` es **inferencia del agente**, no "no encontré la cita". Si el dato viene de una
> fuente real que no está en `raw/`, es `[FUENTE NO PERSISTIDA]`, no `[INFERIDO]`.

La prosa de síntesis, el texto conectivo y las definiciones genéricas **no** son hechos
verificables → no llevan cita ni marca.

### Cuándo usar [INFERIDO] (evitar ruido)

- ✅ Solo para una **conclusión útil** que no está textual en la fuente.
- ❌ NO para **reformulaciones obvias** de una fuente ya citada (esas van con su `[[raw/...]]`).
- Si hay **varias inferencias juntas** → agruparlas en una sección `## Inferencias` o en un
  callout `> [!question]`, en vez de salpicar `[INFERIDO]` por toda la nota.

### Sintaxis

| Contexto | Sintaxis correcta | Nunca usar |
|---|---|---|
| Bullet / párrafo | `afirmación. [[raw/nota#sección]]` | cita a mitad de frase |
| Tabla (columna `Fuente`) | `[[raw/nota#sección\|fuente]]` | `[[raw/nota#sección|fuente]]` sin escapar |
| Link a nota completa | `[[raw/nota]]` | `[texto](raw/nota.md)` |
| Fuente real no persistida | `afirmación. [FUENTE NO PERSISTIDA: <origen>]` | marcarlo `[INFERIDO]` |
| Conclusión propia no textual | `afirmación. [INFERIDO]` | dejarlo sin marca |

### ⚠️ raw/ es inmutable

```markdown
# ❌ Prohibido: crear block-ids dentro de archivos de raw/
Algún dato en raw/nota.md ^mi-id    ← raw/ NO se modifica nunca

# ✅ Correcto: enlazar a nota o a sección existente de raw/
... afirmación probada. [[raw/nota#Encabezado existente]]
```

Solo se permiten links a **nota** (`[[raw/nota]]`) o a **sección** (`[[raw/nota#encabezado]]`).
El encabezado debe existir tal cual en la fuente.

### Consolidación

Toda fuente citada inline debe aparecer también en `frontmatter sources: [...]` y en la
sección `## Fuentes` al final de la nota. Esas dos listas son el superset de las citas inline.

---

## 16. Enlazamiento entre notas (REGLA 8 · grafo de conocimiento)

> Si la **cita** conecta la nota con su fuente en `raw/` (procedencia), el **enlace tipado**
> conecta la nota con otro átomo de conocimiento. El cerebro vale por su grafo, no por el tamaño de sus notas.

### Regla maestra: densidad mínima

Toda nota enlaza a **≥2 notas existentes** con relación tipada. Exentos: `moc` (es casi todo
enlaces) y una `entity`/`concept` recién nacida que aún no tiene pares. Si no encontrás a qué
enlazar con sentido → casi siempre **falta extraer un nodo** (`entity`/`concept`): extraerlo es el trabajo.

### Relaciones tipadas (vocabulario base)

| Relación | Significado | Origen → destino típico |
|---|---|---|
| `define` | la nota destino es la definición canónica de un término que esta usa | `guide` → `entity`/`concept` |
| `depende-de` | esta nota necesita a la destino para funcionar | `entity` → `entity` |
| `instancia-de` | esta nota es un caso concreto del patrón/concepto destino | `incident` → `pattern` |
| `afecta-a` | esta nota (patrón/incidente) impacta a la entidad destino | `pattern` → `entity` |
| `contradice` | sostiene algo que niega a la destino (acompañar con `> [!warning]`) | versiones en conflicto |
| `ver-también` | relación lateral útil sin las anteriores | átomos vecinos |

### Sintaxis

```markdown
## Relacionado

- depende-de :: [[wiki/elemento-b]] — la necesita para funcionar
- afecta-a :: [[wiki/patron-x]] — dispara el patrón bajo cierta condición
- ver-también :: [[wiki/moc-<dominio>]] — MOC del dominio
```

Y su espejo en frontmatter:

```yaml
related:
  - "depende-de :: [[wiki/elemento-b]]"
  - "afecta-a :: [[wiki/patron-x]]"
```

### Bidireccionalidad

Para relaciones fuertes (`depende-de`, `define`, `afecta-a`), agregar el enlace recíproco en la
nota destino si no existe (ej. si A `depende-de` B, B gana un `ver-también :: A` o el inverso semántico).
El grafo se navega en ambos sentidos.

### ⚠️ Anti-ruido

```markdown
# ❌ Enlace sin relación (no aporta grafo)
Ver también [[wiki/elemento-a]].

# ❌ Mismo wikilink repetido en masa por toda la nota

# ✅ Enlace tipado que dice por qué conecta
- depende-de :: [[wiki/elemento-a]] — provee el dato o recurso base
```

---

## 17. Checklist de calidad textual — "unit tests" de la nota

> [!abstract] Por qué existe esta sección
> `/lint` y `verify_citations.sh` auditan la salud del GRAFO (links rotos, huérfanas, fan-in) y la integridad MECÁNICA de una cita (¿el link resuelve a una nota/sección real?). Ninguno de los dos audita la calidad TEXTUAL de una nota individual: una nota puede pasar ambos y aun así estar llena de prosa vaga sin métrica ("rápido", "en general", "significativamente") que no aporta señal real — vibe-knowledge con apariencia de estar bien citado. Esta sección es el equivalente de BrainAI al mecanismo `/speckit.checklist` de [GitHub Spec-Kit](https://github.com/github/spec-kit) ("unit tests for English" — `templates/commands/checklist.md`): valida la ESCRITURA de la nota, no si la nota "funciona" ni si el hecho es correcto. No es una operación nueva ni un gate separado — se corre en la cabeza del agente como parte del gate pre-escritura de `/ingest` (`SKILLS/ingest.md` §Paso 3.68), antes de dar el átomo por compilado, igual que el resto del checklist de §12.

**Los 6 ítems (correr sobre cada átomo antes de escribirlo o cerrarlo):**

1. **[Vaguedad]** ¿Hay adjetivos/adverbios de magnitud sin cifra ni umbral que los sustente ("rápido", "robusto", "en general", "comúnmente", "significativo") sin una cita que los respalde? Si no hay cifra citable → reformular con el dato concreto o marcar `[INFERIDO]`.
2. **[Trazabilidad]** ¿Todo hecho verificable de la nota cae en alguno de los tres casos de la Regla maestra de citación (§15) — `[[raw/...]]`, `[FUENTE NO PERSISTIDA]` o `[INFERIDO]` — sin excepción?
3. **[Síntesis vs. hecho]** ¿La prosa de síntesis (conectiva, interpretativa) queda claramente separada del hecho citado, sin mezclar una opinión propia dentro de la misma frase que cita la fuente?
4. **[Comparaciones sin criterio]** ¿Toda afirmación comparativa o de superioridad ("mejor", "más eficiente", "peor que") especifica el criterio y el punto de comparación, o queda como juicio sin base?
5. **[Placeholders]** ¿Quedan placeholders sin resolver (`TODO`, `<completar>`, `TBD`, secciones vacías) en la nota que se está por dar por compilada?
6. **[Alcance ambiguo]** ¿Los cuantificadores vagos ("varios", "algunos", "frecuentemente") tienen un número o alcance concreto citable, o al menos quedan agrupados en `## Inferencias` si son estimación propia (§15)?

> [!note] Diferencia con spec-kit
> Spec-kit valida requisitos de software antes de generar código, con categorías como completitud, claridad, consistencia, medibilidad y cobertura de escenarios (`templates/commands/checklist.md`). BrainAI no tiene "requisitos" — tiene hechos citados sobre un dominio — así que el checklist se reduce a lo que sí tiene equivalente en una nota de conocimiento: vaguedad, trazabilidad y placeholders. No se importan categorías sin equivalente (ej. cobertura de edge cases de UI, consistencia entre secciones de un spec).

> [!warning] No sustituye a la revisión independiente (`SKILLS/ingest.md §Paso 3.75`)
> Este checklist lo corre el MISMO agente que redactó la nota — es barato, siempre corre, y atrapa lo que el autor reconoce como faltante (olvidó una marca, dejó un placeholder). Es estructuralmente ciego a su propio sesgo: si el autor ya creyó que una afirmación no necesitaba `[INFERIDO]`, preguntarse "¿tiene marca?" no lo hace cambiar de opinión. El Paso 3.75 (segundo agente, sin el razonamiento original, releyendo la fuente cruda) es la capa que sí detecta sobre-inferencia que el autor no percibe como tal — no asumir que, por haber corrido §17 limpio, el Paso 3.75 tiene menos que buscar.
