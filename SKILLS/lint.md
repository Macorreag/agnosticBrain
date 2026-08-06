# SKILL: /lint — Health-check del sistema

> Auditoría periódica de la wiki. Detecta inconsistencias, gaps, y contenido obsoleto.
> Genera reporte para el humano. NUNCA modifica curated/. Puede proponer correcciones en wiki/.

---

## Cuándo usar

- Periódicamente (semanal o mensual)
- Cuando se sospecha información contradictoria entre páginas
- Antes de una sesión de trabajo importante que depende de la wiki
- Cuando hay muchas propuestas pendientes en `_proposed/`

---

## Protocolo paso a paso

### Paso 1 — Inventario
```
Leer wiki/index.md completo.
Contar: páginas wiki/ activas, curated/, propuestas pendientes en _proposed/, brechas abiertas en _gaps.
Anotar páginas con status: stale o updated > 90 días.
```

### Paso 2 — Verificar links
```
Para cada página wiki/:
  → Verificar que todos los [[wikilinks]] apuntan a páginas existentes
  → Si link roto: marcar en el reporte
  → Verificación mecánica (delegable): bash scripts/verify_wikilinks.sh
    (recorre wiki/ y curated/, valida [[wiki/...]] y [[curated/...]] — archivo destino y,
    si hay #sección, que el encabezado existe; ignora código/comentarios, igual que verify_citations.sh)
```

### Paso 2.5 — Integridad de citas (Progressive Disclosure)
```
Verificación mecánica (delegable al script):
  → Correr: bash scripts/verify_citations.sh
  → El script recorre wiki/*.md, extrae las citas [[raw/...]] fuera de bloques de código
    y valida que el archivo destino existe en raw/ y, si hay #sección, que ese encabezado existe.
  → Marcar en el reporte cada cita rota (archivo o sección inexistente).

Verificación semántica (la hace el agente):
  → Detectar hechos factuales (métricas, thresholds, configs, comandos, decisiones, gotchas)
    que NO tienen ninguna marca: ni cita [[raw/...]], ni [FUENTE NO PERSISTIDA], ni [INFERIDO].
  → Detectar abuso de [INFERIDO]: reformulaciones obvias de algo ya citado, o fuentes reales
    no persistidas marcadas como [INFERIDO] (deberían ser [FUENTE NO PERSISTIDA]).
  → Es heurístico: reportar candidatos, no aplicar cambios sin confirmación.
```

### Paso 3 — Detectar páginas huérfanas
```
Para cada página wiki/:
  → Verificar que tiene al menos una referencia entrante (desde index o desde otra página)
  → Si huérfana: marcar en el reporte (no eliminar)
  → Verificación mecánica (delegable): bash scripts/entry_orphans.sh
    (huérfanas de entrada, in-degree 0 — complementa a graph_health.sh, que mide huérfanas de salida)
```

### Paso 3.5 — Salud del grafo (REGLA 8)
```
Diagnóstico de la RED, no solo de cada nota. Medición OFICIAL (objetiva y repetible):

  bash scripts/graph_health.sh          → reporte: DEUDA total + listas priorizadas
  bash scripts/graph_health.sh --score  → una línea comparable entre corridas

El script ya calcula y clasifica:
  FAN-IN EXCESIVO   → notas con >12 fuentes raw distintas O >150 líneas (centralización).
                      Acción: split en átomos (extraer entity/concept) + crear MOC.
  HUÉRFANAS SALIDA  → notas con 0 enlaces [[wiki/...]] salientes.
  SUB-ENLAZADAS     → notas (no moc) con exactamente 1 enlace saliente (densidad mínima = 2).
  DOMINIOS SIN MOC  → dominio con ≥3 átomos y sin wiki/moc-<dominio>.md.
  MONOCULTIVO       → un `type` > 70% de las notas → la extracción de nodos falla.

Complementar a mano (el script no lo cubre):
  ENTIDADES SIN NODO     → entidad mencionada repetida por nombre, sin nota entity propia → /ingest.
  ENLACES REPETIDOS MASA → mismo wikilink en proporción anómala sin relación tipada → ruido.

Reportar la DEUDA y los candidatos con acción sugerida. No aplicar splits aquí: eso es /compose o /ingest.
```

### Paso 3.55 — Cobertura bidireccional (gap↔nota, MOC↔nota)
```
Diagnóstico de cobertura CRUZADA entre capas — no la salud de una nota aislada, sino si lo que el
registro dice que pasó, pasó de verdad. Análogo a la matriz de cobertura bidireccional de
spec-kit (/speckit.analyze cruza spec↔plan↔tasks: todo requisito → ≥1 tarea, toda tarea → ≥1
requisito, y reporta huérfanos en ambos sentidos).

La parte mecánica (grep de un id, existencia de description, conteo de líneas de cuerpo) la
corre `bash scripts/coverage_check.sh` — sin flags, recorre wiki/_gaps.md y las notas type: moc.
Lo que el script NO decide, y sigue siendo criterio del agente al leer su salida: si una brecha
"sin cita" fue mala fe o una redacción legítima que no repitió el string del GAP-id, y si una
entrada de MOC marcada "posible stub" es realmente un stub o una nota corta a propósito — el
umbral de líneas es una señal, no una sentencia. En eso sigue siendo heurístico, igual que la
verificación semántica del Paso 2.5.

(a) Brecha resuelta → nota que la absorbió (REGLA 7):
  scripts/coverage_check.sh reporta, para cada entrada "## Brechas resueltas (histórico)" de
  wiki/_gaps.md (status: resolved), si su "Nota afectada" cita el id del GAP en algún hecho
  ([[raw/feedback/...#GAP-YYYY-MM-DD-NNN]] o [FUENTE NO PERSISTIDA: feedback el humano GAP-…]).
  Si el script marca "✗ sin cita": no revertir el status ni tocar la nota — requiere criterio
  humano (pudo absorberse con otra redacción legítima) → sugerir /gaps para revisar o re-citar.

(b) Entrada de MOC → nota con sustancia (REGLA 8):
  scripts/coverage_check.sh reporta, para cada nota type: moc, qué wikilinks salientes resuelven
  a una nota sin description o con muy poco cuerpo tras el frontmatter ("✗ posible stub" —
  el link no está roto, eso ya lo cubre verify_wikilinks.sh, pero tampoco enseña nada: cobertura
  de fachada). Confirmar leyendo la nota señalada antes de actuar; si es un stub real, sugerir
  /ingest para completarla.

Ninguno de los dos aplica corrección automática, ni el script ni el agente: son candidatos que
requieren criterio humano o una compilación real (/gaps, /ingest). Reportar, no auto-resolver.
```

### Paso 3.6 — Completitud de schema (soft checks · nuevos campos)
```
Para cada página wiki/ (excluyendo moc, summary, comparison):
  → description vacío o ausente → soft warning: "sin description"
  → tags vacío o ausente (array vacío []) → soft warning: "sin tags"
  → type: entity|concept Y resource vacío o ausente → soft warning: "entity/concept sin resource"

NO bloquear por esto — los campos son recomendados, no requeridos.
Reportar como sección separada "Notas con schema incompleto: N" en el reporte.
No marcar como error ni aplicar correcciones automáticas — solo listar y sugerir.
```

### Paso 4 — Detectar contradicciones
```
Comparar páginas relacionadas por dominio:
  → ¿Alguna afirma X y otra afirma ¬X?
  → Si contradicción: marcar en el reporte con las páginas y los claims específicos
  → Proponer resolución pero no aplicarla sin confirmación del humano
```

### Paso 5 — Revisar propuestas pendientes
```
Listar todos los archivos en wiki/_proposed/:
  → Nombre, fecha, nota curada afectada
  → Calcular cuántos días llevan pendientes
  → Marcar las que llevan > 14 días como "requieren atención"
```

### Paso 5.5 — Revisar brechas (wiki/_gaps.md)
```
Recorrer las brechas del registro:
  → status: open CON "Respuesta del humano" → "respondida sin procesar": sugerir /gaps para absorberla.
  → status: open SIN respuesta > 14 días → marcar `stale` (envejecida sin responder).
  → SIN respuesta > 60 días desde emisión (fecha del id GAP-YYYY-MM-DD-NNN) → ARCHIVAR:
        status: open|stale → unanswered; MOVER la entrada de "## Brechas abiertas" a
        "## Brechas sin respuesta (archivadas)"; añadir "- **Archivada:** fecha · sin respuesta hace N días · <agente>".
        Es el techo global del registro (protocolo: SKILLS/gaps.md §Higiene del registro). Mover, no borrar (REGLA 7).
        NO es REGLA 3 (/archive → archivo/): solo mueve entre secciones del mismo wiki/_gaps.md.
  → Brecha que apunta a una nota afectada inexistente (borrada/archivada) → marcar para revisión.
  → No borrar ninguna brecha ni absorberla (absorber es /gaps): solo reportar y actualizar status.
  → Reportar en la ENTREGA cada brecha recién archivada (id, nota, días sin respuesta) — transparencia obligatoria.
```

### Paso 6 — Generar reporte
```
Crear wiki/lint-YYYY-MM-DD.md con:
  - Resumen ejecutivo (tabla de issues por categoría)
  - Detalle de cada issue con acción sugerida
  - Lista de propuestas pendientes
  - Acciones que el LLM puede aplicar directamente vs. requieren aprobación del humano
```

### Paso 7 — Log
```
Append a wiki/log.md:
## [YYYY-MM-DD HH:MM] lint | <N> issues encontrados
Links rotos: X | Citas rotas: X | Sin trazabilidad: X | Huérfanas: X | Contradicciones: X | Stale: X | Fan-in excesivo: X | Huérfanas de salida: X | Sub-enlazadas: X | Entidades sin nodo: X | Dominios sin MOC: X | Schema incompleto: X | Brechas resueltas sin absorción: X | Entradas MOC sin sustancia: X | Propuestas pendientes: X | Brechas: abiertas X / respondidas-sin-procesar X / stale X / archivadas X (nuevas-en-esta-corrida X)
```

---

## Reglas durante lint

- ❌ NUNCA modificar `curated/`
- ❌ NUNCA eliminar páginas (solo marcar en reporte)
- ❌ NUNCA aplicar correcciones sin mencionarlas al reporte
- ✅ Corregir links rotos menores directamente en wiki/
- ✅ Actualizar `status: stale` en frontmatter si corresponde
- ✅ Crear propuestas en `_proposed/` si lint revela info nueva para curated/
- ✅ Marcar brechas `stale` en `wiki/_gaps.md` y señalar las respondidas-sin-procesar (no absorber: eso es `/gaps`)
- ✅ Archivar brechas sin respuesta > 60 días (status `unanswered`, mover a "## Brechas sin respuesta (archivadas)"), reportándolo — mover, nunca borrar (REGLA 7); no es REGLA 3
- ✅ Reportar brechas `resolved` sin absorción verificable y entradas de MOC sin sustancia (Paso 3.55) — heurístico, no auto-corregir ni cambiar `status`

---

## Formato del reporte lint-YYYY-MM-DD.md

```markdown
# Reporte Lint — YYYY-MM-DD

## Resumen

| Issue | Cantidad | Acción |
|---|---|---|
| Links rotos | X | [lista] |
| Citas rotas (raw/ inexistente) | X | [lista] |
| Hechos sin trazabilidad | X | [lista] |
| Páginas huérfanas (sin entrante) | X | [lista] |
| Contradicciones | X | [lista] |
| Contenido stale | X | [lista] |
| **Fan-in excesivo (centralización)** | X | [split + MOC] |
| **Huérfanas de salida (0 enlaces)** | X | [enlazar / extraer nodo] |
| **Sub-enlazadas (<2 tipados)** | X | [enlazar] |
| **Monocultivo de tipo (>70%)** | sí/no | [extraer entity/concept] |
| **Entidades sin nodo** | X | [/ingest extraer hub] |
| **Dominios sin MOC** | X | [crear MOC] |
| Schema incompleto (sin description/tags/resource) | N | [lista — soft warning, no bloquea] |
| **Brechas resueltas sin absorción verificable** | X | [ver tabla de cobertura — revisar /gaps] |
| **Entradas de MOC sin sustancia** | X | [ver tabla de cobertura — completar con /ingest] |
| Propuestas pendientes | X | [lista] |
| Brechas respondidas sin procesar | X | [/gaps] |
| Brechas stale (> 14d sin responder) | X | [lista] |
| Brechas archivadas (unanswered · > 60d sin responder) | X | [movidas a "sin respuesta" — reversible] |

## Issues detallados

### Links rotos
- [[wiki/pagina]] → link `[[destino]]` no existe

### Citas rotas
- [[wiki/pagina]] → cita `[[raw/nota#sección]]` apunta a archivo o sección inexistente

### Hechos sin trazabilidad
- [[wiki/pagina]] → enunciado factual sin marca ([[raw/...]] / [FUENTE NO PERSISTIDA] / [INFERIDO])

### Páginas huérfanas
- [[wiki/pagina]] — sin referencias entrantes

### Salud del grafo (REGLA 8)
- Fan-in excesivo: [[wiki/pagina]] — N fuentes raw / M líneas → sugerir split + MOC
- Huérfana de salida: [[wiki/pagina]] — 0 enlaces salientes
- Sub-enlazada: [[wiki/pagina]] — N enlaces tipados (<2)
- Monocultivo de tipo: type X = N% de las notas (umbral 70%)
- Entidad sin nodo: "X" referida N veces, sin nota entity propia
- Dominio sin MOC: <dominio> tiene N átomos y no tiene moc-<dominio>

### Cobertura bidireccional (gap↔nota, MOC↔nota)

**Brechas resueltas → nota que las absorbió:**

| Brecha | Nota afectada | Absorción verificada | Estado |
|---|---|---|---|
| GAP-YYYY-MM-DD-NNN | [[wiki/nota]] | sí/no | ✅ absorbida / ⚠️ SIN ABSORCIÓN VERIFICABLE |

**MOC → nota con sustancia:**

| MOC | Entrada | Existe | Sustancia | Estado |
|---|---|---|---|---|
| [[wiki/moc-dominio]] | [[wiki/nota]] | sí/no | sí/no | ✅ ok / ⚠️ SIN SUSTANCIA (stub) |

### Contradicciones
- [[wiki/pagina-a]] afirma: X
  [[wiki/pagina-b]] afirma: ¬X
  Recomendación: [...]

### Propuestas pendientes
- wiki/_proposed/YYYY-MM-DD-nota.md — curated/<nota> — N días pendiente

### Brechas (wiki/_gaps.md)
- GAP-YYYY-MM-DD-NNN — wiki/<nota> — respondida sin procesar → sugerir /gaps
- GAP-YYYY-MM-DD-NNN — wiki/<nota> — N días sin responder (stale)
- GAP-YYYY-MM-DD-NNN — wiki/<nota> — N días sin responder → ARCHIVADA (unanswered) esta corrida — reversible a mano

## Acciones aplicadas directamente
[lista de correcciones menores ya aplicadas]

## Acciones que requieren aprobación del humano
[lista de cambios sugeridos pero no aplicados]
```
