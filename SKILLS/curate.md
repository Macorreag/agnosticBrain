# SKILL: /curate — Proteger nota como curada

> Congela una nota de wiki/ en curated/. A partir de ese momento el LLM no la puede modificar.
> Este es el mecanismo principal de protección del conocimiento refinado manualmente.

---

## Cuándo usar

- El humano refinó manualmente una nota de wiki/ y no quiere que el LLM la sobreescriba
- Una nota contiene scripts, configuraciones, o conocimiento empírico que costó tiempo construir
- Una nota es la referencia maestra de un sistema y debe mantenerse estable

---

## Protocolo paso a paso

### Paso 1 — Verificar
```
Confirmar que la nota está en wiki/ (no en otra ubicación).
Leer la nota completa para confirmar que está en el estado que el humano quiere congelar.
Preguntar al humano si confirma que quiere curarla en su estado actual.
```

### Paso 2 — Pedir `en_tus_palabras` (única fricción intencional del pipeline)
```
Preguntar al humano: "¿cuál es la idea central de esta nota, en tus propias palabras?"
(1-2 líneas). NO aceptar como respuesta una copia o parafraseo trivial de `description`
o del primer párrafo — si lo que responde es demasiado cercano al texto ya existente,
pedir que lo repita con sus palabras. El agente NUNCA redacta ni sugiere esta línea:
si el humano pide que se la escribas, recordale que el valor está en que la escriba él
(generation effect — ver AGENTS.md, nota bajo el schema curated/).

Bloqueante: no continuar al Paso 3 sin este campo. Es la ÚNICA fricción de todo el
pipeline — wiki/ se sigue compilando a velocidad plena; esto aplica solo al conjunto
chico y deliberado que se promueve a curated/.
```

### Paso 3 — Reescribir frontmatter al schema curated/
```
La nota llega con el schema wiki/ (type: entity|concept|…, domain, sources,
confidence, created, updated, last_agent). Reescribir su frontmatter para que
cumpla EXACTAMENTE el schema curated/ del kernel:

title: <conservar el de la nota wiki>
type: curated              # reemplaza el type anterior (entity|concept|…)
status: human-canonical    # reemplaza status: active
llm_action: read-only
human_curated: true
curated_date: YYYY-MM-DD
last_human_edit: YYYY-MM-DD
topics: [<heredar directamente de wiki/<nota>.tags — ya existen en el schema>]
         # el humano puede enriquecer manualmente al curar; topics ≥ tags de wiki/
en_tus_palabras: "<la respuesta literal del humano del Paso 2 — nunca editada por el agente>"
sources: [<heredar tal cual de la nota wiki — preserva la trazabilidad hacia raw/>]
description: <heredar de wiki/<nota>.description — passthrough de presentación, read-only>
resource: <heredar de wiki/<nota>.resource si existe, o "" si no aplica>

La demás telemetría del schema wiki (domain, created, updated, last_agent,
confidence, tags) NO se copia al frontmatter curated/: queda registrada en wiki/log.md.
`sources`, `description` y `resource` SÍ se heredan; `topics` se deriva de los
`tags` de la nota wiki/ (trazabilidad + presentación, obligatorias por la Política de Citación).
`en_tus_palabras` es el único campo de todo el schema curated/ que el agente NUNCA redacta,
infiere ni edita — es texto propio del humano, capturado literal.
La cita granular del cuerpo (## Fuentes) se conserva intacta.

Nota: desde la actualización del schema (2026-06-18), wiki/ tiene tags:, description: y
resource: reales. topics = tags de wiki/ (con posible enriquecimiento del humano).
description y resource se copian como passthrough read-only — el agente NO los edita en curated/.
```

### Paso 4 — Mover a curated/
```
Mover wiki/<nombre-nota>.md → curated/<nombre-nota>.md
Verificar que el archivo existe en curated/ y ya no existe en wiki/.
```

### Paso 5 — Actualizar index
```
En wiki/index.md:
  → Cambiar entry de wiki/<nota> a [CURATED] [[curated/<nota>]] — descripción
  → Actualizar sección "Notas Curadas" del index con la nueva entrada
  → Actualizar estadísticas (wiki/ activas -1, curated/ +1)
```

### Paso 6 — Log
```
Append a wiki/log.md:
## [YYYY-MM-DD HH:MM] curate | wiki/<nota> → curated/<nota>
Razón: [razón que dio el humano o "refinamiento manual"]
```

### Paso 7 — Confirmar al humano
```
"✅ La nota [[curated/<nombre>]] está ahora protegida.
El LLM no la modificará en futuros ingest ni lint.
Si hay información nueva relevante para ella, crearé una propuesta en wiki/_proposed/."
```

---

## Reglas

- ❌ NUNCA curar una nota sin confirmación explícita del humano
- ❌ NUNCA curar directamente desde raw/ (solo desde wiki/)
- ❌ NUNCA redactar, sugerir o completar `en_tus_palabras` en lugar del humano — ni aunque lo pida
- ❌ NUNCA mover la nota a curated/ sin haber recibido `en_tus_palabras` (Paso 2 es bloqueante)
- ✅ Si el humano pide curar y la nota tiene información desactualizada, mencionarlo antes de proceder
- ✅ Confirmar siempre que el archivo fue movido exitosamente

---

## Reversa: des-curar una nota

Si el humano quiere que el LLM vuelva a mantener una nota curada:
```
El humano: "des-cura curated/<nombre>"
1. Leer la nota
2. Reconstruir el frontmatter al schema wiki/:
   type (entity|concept|… según el contenido),
   description (desde campo description de curated/ si existe; si no, reconstruir desde [!abstract] del body),
   resource (desde campo resource de curated/ si existe; si no, ""),
   domain (desde topics — primer o más relevante tag de topics),
   tags (desde topics de curated/ — mapping inverso),
   status: active, sources (heredar del campo `sources` preservado),
   last_agent: claude-code, created/updated, confidence;
   remover llm_action/human_curated/curated_date/last_human_edit
   `en_tus_palabras` no tiene campo equivalente en el schema wiki/: NUNCA se descarta —
   se preserva insertando `> [!quote] En tus palabras: <texto literal>` como primera línea
   del body, antes de cualquier otro contenido.
3. Mover curated/<nota> → wiki/<nota>
4. Actualizar index
5. Log: ## [FECHA] uncurate | curated/<nota> → wiki/<nota>
```
