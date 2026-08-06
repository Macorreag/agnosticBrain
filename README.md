---
tags: [indice, ia, activo]
date: 2026-08-05
---

# BrainAI — LLM Wiki

> Base de conocimiento compilada por IA. Inspirada en el patrón LLM Wiki de Andrej Karpathy (abril 2026), extendida con tres capas de ownership y protección granular de notas curadas.

---

## El problema que este sistema resuelve

Los sistemas de conocimiento con IA tienen un punto ciego: no distinguen entre conocimiento generado automáticamente y conocimiento refinado por el humano. El LLM, durante un `ingest` o `lint`, puede sobrescribir silenciosamente ediciones manuales que costaron horas construir.

Este sistema resuelve eso con **tres capas de ownership** en lugar de dos.

---

## Estructura

```
BrainAI/
├── SKILLS/           ← Protocolos de operación (solo lectura para el LLM)
│   ├── format.md     ← Formato Obsidian — leer SIEMPRE antes de escribir nota
│   ├── ingest.md
│   ├── query.md
│   ├── lint.md
│   ├── archive.md
│   ├── curate.md
│   ├── propose.md
│   ├── status.md
│   ├── gaps.md
│   └── compose.md    ← Composición autónoma continua (auto-mejora del grafo)
│
├── raw/              ← Fuentes crudas. El humano escribe. LLM solo lee. INMUTABLE.
│
├── wiki/             ← Conocimiento compilado. LLM es el dueño. No editar a mano.
│   ├── index.md      ← Catálogo maestro — leer siempre primero
│   ├── log.md        ← Historial append-only de operaciones
│   └── _proposed/   ← Propuestas de cambio para curated/ pendientes del humano
│
├── curated/          ← Notas refinadas manualmente. LLM solo lee. NUNCA modifica.
│
├── archivo/          ← Notas obsoletas. Solo se entra, nunca se sale.
│
├── Templates/        ← Plantillas de captura (Templater). Fuera del pipeline raw/.
│
├── AGENTS.md         ← Kernel canónico multi-agente — FUENTE DE VERDAD (Codex, Cursor, Claude)
├── CLAUDE.md         ← Puntero a AGENTS.md para Claude Code (@AGENTS.md)
└── README.md         ← Este archivo
```

### Plugins de Obsidian requeridos

| Plugin | Tipo | Propósito |
|---|---|---|
| **Templater** (v2.x) | Comunidad | Generación de notas estructuradas desde `Templates/`. Sin él, las plantillas son solo texto estático. |
| Daily Notes | Core (incluido) | Creación de la daily del día con nombre `YYYY-MM-DD`. |
| Templates | Core (incluido) | Integración base; Templater lo extiende. |

> Instalación de Templater: Ajustes → Plugins de la comunidad → Examinar → *Templater*. Ver configuración completa en `MANUAL.md § Captura con plantillas`.

---

> **Fuente de verdad única:** el kernel (reglas, operaciones, schemas, políticas) vive solo en `AGENTS.md`. `CLAUDE.md` lo importa con `@AGENTS.md`; Codex y Cursor lo leen nativo. Editar el kernel = editar `AGENTS.md`, nunca duplicarlo.

## Ownership — La regla de oro

| Directorio | Quién escribe | Quién lee | Regla crítica |
|---|---|---|---|
| `raw/` | Humano | Todos | LLM nunca modifica |
| `wiki/` | LLM | Todos | el humano no edita a mano |
| `curated/` | Humano | Todos | LLM **NUNCA** modifica |
| `archivo/` | Sistema | Todos | Solo se entra, orden del humano |

> **Si lo editaste a mano y no quieres perderlo → va en `curated/`, no en `wiki/`.**
> El `wiki/` es tierra del LLM. Editar `wiki/` a mano es como editar un archivo generado por tu compilador: el próximo ingest te lo puede sobrescribir.

---

## Las 9 operaciones

| Operación | Cómo invocar | Qué hace |
|---|---|---|
| `/ingest` | `/ingest [fuente]` | Compila una fuente en átomos enlazados; extrae nodos `entity`/`concept` |
| `/query` | `/query [pregunta]` | Consulta navegando por el MOC del dominio y los enlaces tipados |
| `/lint` | `/lint` | Health-check + salud del grafo (fan-in, huérfanas, monocultivo, MOCs) |
| `/archive` | `/archive [nota]` | Mueve nota a `archivo/` — solo por orden explícita |
| `/curate` | `/curate [nota]` | Congela nota de `wiki/` a `curated/` |
| `/propose` | Auto durante ingest | Crea propuesta de cambio para nota curada |
| `/status` | `/status` | Dashboard: conteo de notas, log reciente, propuestas pendientes |
| `/gaps` | `/gaps` | Absorbe brechas respondidas (feedback loop) |
| `/compose` | `/compose [--hasta-limpio]` | **Composición autónoma continua**: mejora el grafo en loop por horas hasta punto fijo |

---

## Cómo usar el sistema

### Agregar nueva información
1. Guarda el artículo/nota/transcripción en `raw/`
2. Invoca `/ingest raw/nombre-archivo.md`
3. El LLM actualiza `wiki/` automáticamente

### Hacer una pregunta
1. Invoca `/query ¿cómo funciona X?`
2. El LLM navega `wiki/index.md` y responde con citas

### Proteger una nota que refinaste
1. Mueve o edita la nota en `wiki/` hasta que esté como quieres
2. Invoca `/curate wiki/nombre-nota.md`
3. El LLM la mueve a `curated/` y no volverá a tocarla

### Archivar conocimiento obsoleto
1. Invoca `/archive wiki/nombre-nota.md — [razón]`
2. El LLM la mueve a `archivo/` y actualiza el index

### Ver estado del sistema
1. Invoca `/status`
2. Ver conteo de notas, últimas operaciones, propuestas pendientes de revisión

---

## Por qué `wiki/_proposed/`

Cuando el LLM procesa nuevo conocimiento que debería actualizar una nota en `curated/`, no puede tocarla. En cambio, crea una propuesta en `wiki/_proposed/` con el diff exacto. El humano revisa periódicamente, aprueba los que corresponde, y aplica manualmente los cambios a `curated/`.

Es el mecanismo que cierra el loop de aprendizaje sin sacrificar la protección del conocimiento curado.

---

## Principios de diseño

1. **Texto plano forever**: markdown puro, sin dependencias de apps
2. **Compilar, no recuperar**: la wiki sintetizada supera al RAG para corpus personal
3. **Ownership explícito**: cada directorio tiene un dueño claro y reglas no-negociables
4. **El index es la puerta**: `wiki/index.md` es el cerebro navegable del sistema — un catálogo de MOCs, no una lista plana
5. **Log como memoria del sistema**: `wiki/log.md` registra todo — el sistema recuerda lo que hizo
6. **Proponer sobre `curated/`**: el LLM nunca actúa unilateralmente sobre conocimiento humano
7. **Red de átomos, no archivador** (REGLA 8, kernel v2.2): una nota = un sujeto; entidades y conceptos se extraen como nodos-hub y se enlazan con relaciones tipadas; cada `/ingest` mejora el grafo (más nodos, mejores enlaces, menos centralización) en vez de engordar pocas notas gigantes. El cerebro compone, no acumula.
8. **Fuente única sin generación, no un compilador multi-agente**: a diferencia de [GitHub Spec-Kit](https://github.com/github/spec-kit), que compila un artefacto de comando distinto por cada uno de sus 30+ agentes soportados (un adaptador por agente, con build y riesgo de drift), `AGENTS.md` no genera nada — es autónomo y lo leen sin transformación los 3 agentes reales de este vault. Decisión deliberada: sin argumentos tipados ni decenas de sintaxis que reconciliar, un generador agregaría complejidad para un problema que este vault no tiene.
9. **Anti-"vibe knowledge" — eje ortogonal al anterior**: "vibe coding" es escribir código confiando en que "se ve bien" sin spec ni verificación; acá el equivalente es prosa que suena compilada sin ser citable. Este SÍ es el eje donde tomamos de Spec-Kit — no su arquitectura de distribución (punto 8), sino sus mecanismos anti-alucinación, adaptados de requisitos de software a notas citadas: checklist de calidad textual (`SKILLS/format.md §17`), cobertura bidireccional gap↔nota (`SKILLS/lint.md §Paso 3.55`), gate de REGLA 8 pre-escritura (`SKILLS/ingest.md §Paso 3.68`) y taxonomía + priorización de ambigüedad (`SKILLS/gaps.md`). Los dos ejes son independientes: se puede tomar uno sin el otro.

---

## Basado en

- [LLM Wiki gist — Andrej Karpathy (abril 2026)](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- Investigación sobre protección de notas curadas (jun 2026)
- Patrón extendido con tercera capa `curated/` + operaciones `/archive` y `/curate`
