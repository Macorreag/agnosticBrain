# BrainAI · Kernel — Claude Code

> La **fuente de verdad** de este sistema es `AGENTS.md` (kernel canónico, agnóstico de agente).
> Este archivo solo lo importa y agrega lo específico de Claude Code. **No dupliques el kernel aquí: edítalo en `AGENTS.md`.**

@AGENTS.md

---

## Específico de Claude Code

- **Invocación de operaciones:** el usuario invoca las operaciones como `/ingest`, `/query`, `/lint`, `/archive`, `/curate`, `/propose`, `/status`, `/gaps` o en lenguaje natural. Cada una sigue su protocolo en `SKILLS/` — leer el SKILL correspondiente antes de ejecutar, y `SKILLS/format.md` **siempre** antes de escribir cualquier nota.
- **`last_agent`:** al crear o actualizar una nota `wiki/`, registrar `last_agent: claude-code`.
- **MCP / herramientas externas:** si hay un MCP filesystem del vault disponible, respeta igual la tabla de ownership de `AGENTS.md` — nunca escribir en `raw/` ni `curated/`.
- **Memoria / contexto adicional:** las instrucciones globales del usuario viven en `~/.claude/CLAUDE.md`; este archivo solo gobierna el kernel de BrainAI.
