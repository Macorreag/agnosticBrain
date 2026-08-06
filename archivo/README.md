# archivo/ — Notas obsoletas

> Cementerio controlado. Las notas entran pero no salen (sin orden explícita).
> El contenido se preserva intacto — solo se agrega metadata de archivado.

## Cuándo enviar algo aquí

- La nota describe un sistema que ya no existe
- El conocimiento fue reemplazado por una versión mejor en wiki/ o curated/
- Es una versión antigua de algo que ya tiene una versión actualizada
- Decidiste que ya no es relevante para tu trabajo

## Cómo archivar

Invocar: `/archive wiki/<nombre-nota> — <razón breve>`

El LLM:
1. Agrega `archived_date` y `archived_reason` al frontmatter
2. Mueve el archivo aquí
3. Actualiza el index

## Para recuperar algo archivado

Invocar: `/unarchive archivo/<nombre-nota>`
El LLM preguntará si vuelve a `wiki/` o a `curated/`.

## Regla importante

El LLM **nunca** archiva notas por su cuenta, ni durante lint ni durante ingest. Solo tú puedes declarar que algo es obsoleto.
