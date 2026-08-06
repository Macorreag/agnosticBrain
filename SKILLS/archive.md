# SKILL: /archive — Declarar nota obsoleta

> Mueve una nota al cementerio controlado. Preserva el contenido original. No se puede deshacer sin orden explícita.
> Solo ejecutar con orden directa del humano.

---

## Cuándo usar

SOLO cuando el humano dice explícitamente:
- "archiva [nota]"
- "mueve [nota] a archivo"
- "esa nota está obsoleta, archívala"

**NUNCA archivar por iniciativa propia.** Ni durante lint, ni durante ingest, ni por inferencia.

---

## Protocolo paso a paso

### Paso 1 — Confirmar
```
Confirmar con el humano:
"¿Confirmas que quieres archivar [[<nota>]]?
Razón: [razón que dio el humano]"

Esperar confirmación antes de proceder.
```

### Paso 2 — Leer la nota
```
Leer la nota completa para verificar que es la correcta.
Nota la ubicación original (debe ser wiki/ — ver Reglas: curated/ no se archiva directamente).
```

### Paso 3 — Actualizar frontmatter
```
Agregar al frontmatter:
archived_date: YYYY-MM-DD
archived_reason: <razón que dio el humano>
original_location: wiki/<nombre-nota>
```

### Paso 4 — Mover a archivo/
```
Mover wiki/<nombre-nota>.md → archivo/<nombre-nota>.md
Verificar que:
  - El archivo existe en archivo/
  - El archivo YA NO existe en su ubicación original
```

### Paso 5 — Actualizar index
```
En wiki/index.md:
  → Remover la entrada de la nota
  → O marcar: ~~[[wiki/nombre-nota]]~~ [ARCHIVADO YYYY-MM-DD — <razón breve>]
  → Actualizar estadísticas (archivo/ +1, wiki/ -1)
```

### Paso 6 — Log
```
Append a wiki/log.md:
## [YYYY-MM-DD HH:MM] archive | <origen>/<nota> → archivo/<nota>
Razón: <razón del humano>
```

### Paso 7 — Confirmar
```
"✅ [[<nota>]] archivada en archivo/<nombre-nota>.md
Ya no aparece en el index activo.
Si necesitas recuperarla en el futuro, dímelo."
```

---

## Reglas

- ❌ NUNCA archivar sin orden explícita del humano
- ❌ NUNCA archivar directamente desde `curated/` (REGLA 1 del kernel): primero `/uncurate`, luego `/archive` desde `wiki/`
- ❌ NUNCA archivar durante lint ni ingest por iniciativa propia
- ❌ NUNCA eliminar el contenido de la nota archivada
- ✅ Preservar frontmatter original + agregar campos de archivo
- ✅ Confirmar siempre antes de ejecutar

---

## Recuperar una nota archivada

Si el humano pide: "recupera archivo/<nombre>"

```
1. Leer la nota archivada
2. Remover campos: archived_date, archived_reason (o dejarlos como historia)
3. Devolver a wiki/ (curated/ solo se alcanza vía /curate; si el humano la quiere curada, ejecutar /curate luego)
4. Mover a wiki/<nota>
5. Actualizar index
6. Log: ## [FECHA] unarchive | archivo/<nota> → <destino>/<nota>
```
