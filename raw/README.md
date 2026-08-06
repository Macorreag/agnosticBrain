# raw/ — Fuentes crudas

> El LLM lee estos archivos pero **nunca los modifica**.
> Son el material de entrada del compilador.

## Qué poner aquí

- Artículos técnicos que quieres ingresar al sistema
- Transcripciones de conversaciones o reuniones importantes
- RCAs de incidentes en texto plano
- Documentación de APIs o servicios que quieres compilar
- Notas rápidas tomadas durante el trabajo

## Cómo usar

1. Guardar el archivo aquí (cualquier nombre descriptivo)
2. Invocar `/ingest raw/<nombre-archivo>.md`
3. El LLM lo procesa y actualiza `wiki/` — el archivo en `raw/` permanece intacto

## Regla de oro

Una vez en `raw/`, el archivo no cambia. Si la fuente original se actualizó, guarda la versión nueva como un archivo separado (ej: `nombre-v2.md`). El LLM maneja las versiones al compilar.
