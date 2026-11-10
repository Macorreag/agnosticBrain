# wiki/index.md — Catálogo de MOCs

> Punto de entrada obligatorio. Leer completo antes de cualquier query o ingest.
> Mantenido por el LLM. Actualizar en cada ingest, curate y archive.

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

## Mapas de Contenido (moc) — puerta de cada dominio

> [!important] Navegación MOC-first (kernel v2.3 · REGLA 8)
> Este índice es un **catálogo de MOCs**, no de notas sueltas. Cada MOC es la puerta de un
> dominio: enlaza y ordena sus átomos con una línea de contexto cada uno. El agente entra
> por el MOC y navega los enlaces tipados hasta el átomo exacto.

<!-- Un MOC por dominio activo: - [[wiki/moc-<dominio>]] — alcance del dominio -->

---

## Notas sin MOC (transitorio)

> Solo para el cold start o para átomos que todavía no tienen dominio. Si esta sección
> crece, falta crear el MOC del dominio. Formato: `- [[wiki/nota]] — descripción`.

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

- MOC primero: `- [[wiki/moc-<dominio>]] — alcance`; el MOC enlaza sus átomos.
- Nota sin MOC: `- [[wiki/nombre-nota]] — descripción` (solo transitorio).
- Nota curada: `- [CURATED] [[curated/nombre-nota]] — descripción`.
- Nota archivada: ~~`- [[wiki/nombre-nota]]`~~ `[ARCHIVADO YYYY-MM-DD]`.
- El LLM actualiza este archivo y los MOCs afectados en cada ingest, curate y archive.
- El LLM NO actualiza este archivo durante query ni lint (solo reporta).
