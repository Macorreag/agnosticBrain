# curated/ — Conocimiento refinado por el humano

> **El LLM NUNCA modifica archivos en este directorio.**
> Todo lo que está aquí fue curado manualmente y es de solo lectura para cualquier agente.

## Qué poner aquí

- Scripts refinados durante días de prueba en producción
- Guías de operación con conocimiento empírico que no está en ninguna fuente
- Configuraciones exactas que tardaste en encontrar, con el porqué
- Notas de referencia que son tu modelo mental de un sistema
- Cualquier conocimiento que construiste iterativamente y no quieres perder

## Cómo llega una nota aquí

**Opción A (recomendada):** Crear la nota en `wiki/` primero, refinarla con el LLM, y cuando esté lista invocar `/curate wiki/<nota>`. El LLM la moverá aquí y marcará el frontmatter.

**Opción B (directo):** Crear el archivo directamente aquí con el frontmatter correcto:
```yaml
---
title: ""
type: curated
status: human-canonical
llm_action: read-only
human_curated: true
curated_date: YYYY-MM-DD
last_human_edit: YYYY-MM-DD
topics: []
en_tus_palabras: ""   # la idea central en tus propias palabras — obligatorio, lo escribís vos
---
```

## Si el LLM tiene información nueva relevante para una nota aquí

No te preocupes — el LLM creará una propuesta en `wiki/_proposed/` sin tocar tu nota. Tú decides si aplicar el cambio o no.

## Para editar una nota curada

Hazlo directamente en Obsidian o con cualquier editor. Solo actualiza `last_human_edit` en el frontmatter. El sistema respeta que tú eres el dueño.
