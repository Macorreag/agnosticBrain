# wiki/index.md — Catálogo Maestro

> Punto de entrada obligatorio. Leer completo antes de cualquier query o ingest.
> Mantenido por el LLM. Actualizar en cada ingest, curate, y archive.

---

## Estadísticas

| Categoría | Notas |
|---|---|
| wiki/ activas | 0 |
| curated/ | 0 |
| _proposed/ pendientes | 0 |
| _gaps abiertas | 0 |
| _gaps sin respuesta (archivadas) | 0 |
| archivo/ | 0 |
| Última operación | _(vacío — se actualiza en el primer ingest)_ |

---

## Índice por dominio

> [!important] Navegación MOC-first (kernel v2.2 · REGLA 8)
> Este índice es un **catálogo de Mapas de Contenido (MOC)**, no de notas sueltas. Para consultar un dominio, entrar por su MOC y navegar los enlaces tipados hasta el átomo exacto. Las secciones por tipo de abajo son el inventario plano de respaldo mientras se completa el backfill de MOCs.

### Mapas de Contenido (moc) — puerta de cada dominio
<!-- Un MOC por dominio activo: enlaza y ordena los átomos del dominio. Formato: - [[wiki/moc-<dominio>]] — alcance del dominio -->

### Entidades (entity)
<!-- Nodos-hub: apps, servicios, sistemas, personas. Máxima prioridad de extracción (REGLA 8). -->

### Conceptos (concept)
<!-- Nodos-hub: patrones teóricos, principios, técnicas reutilizables. -->

### Patrones (pattern)
<!-- Patrones de incidentes, soluciones recurrentes, anti-patrones -->

### Guías (guide)
<!-- How-tos, procedimientos, runbooks -->

### Incidentes (incident)
<!-- RCAs, post-mortems, análisis de alertas -->

### Comparaciones (comparison)
<!-- A vs B, trade-offs, decisiones de arquitectura -->

### Síntesis (summary)
<!-- Síntesis transversal de varios átomos (rara) -->

---

## Notas Curadas (`curated/`)

| Nota | Tema | Curada |
|---|---|---|

> Las notas curadas son de solo lectura para el LLM.
> Para proponer actualizaciones → ver `wiki/_proposed/`

---

## Propuestas pendientes (`wiki/_proposed/`)

| Propuesta | Nota curada afectada | Fecha |
|---|---|---|

---

## Convenciones del index

- Formato de entrada: `- [[wiki/nombre-nota]] — descripción en una línea`
- MOC primero: cada dominio entra por `- [[wiki/moc-<dominio>]] — alcance`; el MOC enlaza sus átomos
- Notas curadas: `- [CURATED] [[curated/nombre-nota]] — descripción`
- Notas archivadas: ~~`- [[wiki/nombre-nota]]`~~ `[ARCHIVADO YYYY-MM-DD]`
- El LLM actualiza este archivo y los MOCs afectados en cada ingest, curate, y archive
- El LLM NO actualiza este archivo durante query ni lint (solo reporta)
