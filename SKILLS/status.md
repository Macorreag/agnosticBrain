# SKILL: /status — Dashboard del sistema

> Vista rápida del estado de BrainAI: cuánto sabe, cuándo se actualizó, qué necesita atención.
> Solo lectura. No modifica nada.

---

## Cuándo usar

- Al inicio de una sesión de trabajo
- Antes de hacer un /lint para ver si vale la pena
- Cuando el humano quiere saber qué propuestas están pendientes
- Periódicamente para monitorear la salud del sistema

---

## Protocolo paso a paso

### Paso 1 — Contar notas y salud de fuentes
```
Contar archivos .md en cada directorio:
  wiki/           → N notas activas (excluir index.md, log.md, lint-*.md, _gaps.md)
  wiki/_proposed/ → N propuestas pendientes
  wiki/_gaps.md   → N brechas abiertas (M respondidas sin procesar) · A sin respuesta (archivadas)
                    "abiertas" = entradas bajo "## Brechas abiertas"; "archivadas" = bajo "## Brechas sin respuesta (archivadas)" (status unanswered)
  curated/        → N notas curadas
  raw/            → N fuentes totales
  archivo/        → N notas archivadas

Correr los scripts de salud de fuentes:
  bash scripts/pending_sources.sh | wc -l  → N fuentes en raw/ nunca compiladas
  bash scripts/stale_sources.sh --score    → STALE=N  (fuentes modificadas post-compilación)
  bash scripts/skipped_sources.sh --score  → SKIP=N   (fuentes vetadas del pipeline · Mecanismo de ignore)

Si STALE > 0 y alguna afecta curated/ → señal de alerta ⚠️ prioritaria.
SKIP es informativo (transparencia): para ver QUÉ está vetado y por qué → bash scripts/skipped_sources.sh
```

### Paso 1.5 — Resurfacing hacia el humano (opcional)
```
graph_health.sh mira la salud del grafo hacia la MÁQUINA. Complementariamente, /status
puede mostrarte 1-2 notas viejas de wiki/ que quizás olvidaste, para reconectarlas con
algo nuevo:

  bash scripts/resurface.sh            → 1-2 notas candidatas + el porqué (antiguedad + aislamiento)
  bash scripts/resurface.sh --score    → RESURFACE=<nota> … (una línea para el dashboard)

Opcional y read-only. Heurística simple (NO repetición espaciada real). Sin trigger
automático: solo aparece si corrés /status. Detalle: bash scripts/resurface.sh --help
```

### Paso 2 — Leer log reciente
```
Leer las últimas 10 entradas de wiki/log.md.
Extraer: última operación, fecha, tipo.
Calcular: días desde el último ingest.
```

### Paso 3 — Propuestas pendientes
```
Si existen archivos en wiki/_proposed/:
  → Listar cada uno: nombre, nota curada afectada, fecha de creación
  → Calcular días pendientes
  → Marcar las que superan 14 días como ⚠️
```

### Paso 4 — Reportar
```
Presentar en formato compacto (no crear archivo, solo mostrar en conversación).
```

---

## Formato del reporte /status

```
## BrainAI — Estado del sistema
Fecha: YYYY-MM-DD HH:MM

### Inventario
| Directorio           | Notas / Estado |
|----------------------|----------------|
| wiki/ (activas)      | N              |
| curated/             | N              |
| raw/ (total)         | N              |
| raw/ (nunca compiladas) | N — bash scripts/pending_sources.sh \| wc -l |
| raw/ (stale ⚠️)      | N — bash scripts/stale_sources.sh --score |
| raw/ (vetadas/skip)  | N — bash scripts/skipped_sources.sh --score |
| archivo/             | N              |
| _proposed/ (⚠️)      | N              |
| _gaps abiertas       | N (M respondidas sin procesar) |
| _gaps sin respuesta (archivadas) | A — status unanswered · reversible |

### Actividad reciente (últimas operaciones)
- [YYYY-MM-DD] ingest | <fuente>
- [YYYY-MM-DD] curate | <nota>
- ...

### Último ingest: N días atrás
### Último lint: N días atrás (o "nunca")

### Propuestas pendientes de revisión
| Propuesta | Nota curada | Días pendiente | Estado |
|-----------|-------------|----------------|--------|
| _proposed/YYYY-MM-DD-nota.md | curated/nota | N | ⚠️ > 14d |

### Brechas abiertas (wiki/_gaps.md)
| Brecha | Nota afectada | Días | Estado |
|--------|---------------|------|--------|
| GAP-YYYY-MM-DD-NNN | wiki/nota | N | esperando respuesta / ✅ respondida sin procesar |
| GAP-YYYY-MM-DD-NNN | wiki/nota | N | 📦 sin respuesta (archivada · unanswered) — reversible |

### Resurfacing (opcional) — 1-2 notas para reconectar
- 🔁 [[wiki/nota-vieja]] — N días sin revisar · B backlinks — ¿reconectar / curar / archivar?
_(salida de `bash scripts/resurface.sh`; omitir la sección si no se corrió)_

### Señales de alerta
- ⚠️ N fuentes stale con nota curated/ afectada → /ingest urgente (generará _proposed/)
- ⚠️ N fuentes stale > 0 → conocimiento desactualizado → sugerir /ingest o /compose
- ⚠️ N propuestas pendientes > 14 días
- ⚠️ N brechas respondidas sin procesar → sugerir /gaps
- ⚠️ N brechas abiertas > 14 días sin responder
- ℹ️ N brechas sin respuesta (archivadas) → revisar si alguna sigue siendo relevante (responder o mover a "## Brechas abiertas")
- ⚠️ Último ingest hace > 30 días
- ⚠️ Lint nunca ejecutado
```

---

## Reglas

- ❌ No modificar ningún archivo durante /status
- ❌ No crear archivos de reporte (solo mostrar en conversación)
- ✅ Mencionar explícitamente si hay propuestas urgentes pendientes
- ✅ Mencionar si hay brechas respondidas sin procesar → sugerir `/gaps`
- ✅ Sugerir acciones si detecta señales de alerta
- ✅ Opcional: mostrar 1-2 notas para resurfacing (`bash scripts/resurface.sh`) — notas viejas/aisladas que quizás valga reconectar con lo nuevo; nunca es obligatorio ni modifica nada
