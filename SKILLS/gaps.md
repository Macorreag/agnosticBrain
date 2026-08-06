# SKILL: /gaps — Feedback loop de brechas (emisión + absorción)

> Hace **durables** las dudas que el pipeline ya genera y hoy descarta, y **cierra el lazo**:
> el humano responde una vez, una compilación futura lleva esa respuesta al conocimiento.
> Registro: `wiki/_gaps.md`. Gobernado por **REGLA 7** del kernel (`AGENTS.md`).
> Plantilla poblada de punta a punta (insumo descubrible): `SKILLS/gaps-ejemplo.md`.

---

## Modelo mental: no es detección nueva, es enrutamiento

El `/ingest` ya detecta cada duda relevante — la marca `[INFERIDO]`, `[FUENTE NO PERSISTIDA]` o `> [!warning] Contradicción` y la reporta en ENTREGA, donde **se evapora al cerrar la sesión**. `/gaps` no inventa detección: toma esas señales **N1**, las persiste como preguntas concretas al humano, y absorbe sus respuestas de vuelta al `wiki/`.

```
/ingest detecta duda N1 ──emisión──▶ wiki/_gaps.md (status: open) + > [!question] inline
                                          │
                                   el humano responde (único campo que toca)
                                          │
wiki/<nota> enriquecida ◀──absorción── /gaps  (o /ingest Paso 0.5)
   (cita: raw/feedback/ · o [FUENTE NO PERSISTIDA] · o /propose si es curated/)
```

> [!tip] Dónde madura el conocimiento
> Brecha → el humano responde → absorbida en `wiki/` con cita → si madura, candidata a `/curate`.
> Como **el humano literalmente escribió la respuesta**, esa nota es la mejor candidata posible a curación.

---

## Cuándo usar

- **Absorción on-demand:** el humano respondió brechas y quiere llevarlas al conocimiento sin esperar a un `/ingest` ("absorbé los gaps", "/gaps").
- **Reporte:** el humano pregunta qué brechas hay abiertas / qué espera respuesta.
- **Automático:** la fase de Absorción corre al inicio de cada `/ingest` (Paso 0.5) — no requiere invocación.
- **Emisión:** no se invoca sola; ocurre dentro de `/ingest` (Paso 3.8). Este SKILL define su contrato.

---

## Esquema de una brecha (en `wiki/_gaps.md`)

```text
### GAP-YYYY-MM-DD-NNN · status: open
- **Nota afectada:** [[wiki/<nota>]]            (si es curated/ → se resuelve vía /propose; si es `patron-candidato` sin nota aún → "N/A — candidata a nota nueva")
- **Disparado por:** /ingest de [[raw/<fuente>]]   (si es `patron-candidato` → "/compose ciclo N")
- **Tipo:** inferencia-critica | fuente-no-persistida | contradiccion | definicion-faltante | verificacion-baja-confianza | revision-independiente | patron-candidato | atomicidad-difusa | terminologia-inconsistente
- **Notas que lo sugieren:** [[wiki/a]], [[wiki/b]], [[wiki/c]]   (solo aplica a `patron-candidato`)
- **Pregunta:** ¿...?
- **Por qué importa (N1):** ...
- **Impacto al resolver:** enriquece wiki/<nota> · (candidata a /propose / a /curate)   (para `patron-candidato`: "crea wiki/<nota-nueva> si se confirma")
- **Respuesta del humano:** _(vacío — el humano escribe aquí)_
```

- `NNN` = secuencial de 3 dígitos por día (`001`, `002`, …).
- `status`: `open → resolved | stale | unanswered | dropped`. El agente lo administra; **el humano solo escribe `Respuesta del humano`**.
- `unanswered` = brecha sin respuesta pasado el umbral de archivado (ver §Higiene del registro); vive en "## Brechas sin respuesta (archivadas)", no en la sección activa.

> [!example] Plantilla poblada (insumo descubrible vía disclosure)
> `SKILLS/gaps-ejemplo.md` muestra un `wiki/_gaps.md` de punta a punta — brecha respondida lista para absorber, brecha esperando respuesta, y una resuelta en histórico — más el callout `> [!question]` inline y el `raw/feedback/` resultante. Es el molde para copiar una entrada.

---

## Emisión (contrato — ejecuta dentro de /ingest · Paso 3.8)

### Filtro de calidad (lo que evita la fatiga)

Una duda **CALIFICA** como brecha solo si cumple las dos:
1. Es **Nivel 1** en la Pirámide de señal (`SKILLS/ingest.md` §Paso 2.5). N2/N3 nunca generan brecha.
2. Se puede formular como **pregunta concreta** + **por qué importa** + **qué desbloquea**.

Si no cumple ambas → no es brecha: queda como `[INFERIDO]`/`[FUENTE NO PERSISTIDA]` en la nota, recuperable luego por `/lint`.

### Tope y prioridad

```
TOPE: ≤3 brechas por ingest.
Si hay más candidatas N1 → quedarse con las 3 de mayor impacto operativo (ver desempate abajo).
El resto NO se pierde: sigue como [INFERIDO]/[FUENTE NO PERSISTIDA] en la nota.
```

### Desempate — cuáles 3 de N candidatas N1 ocupan el cupo

> [!important] Solo aplica cuando hay más de 3 candidatas N1 en el mismo ingest/ciclo
> El filtro de calidad (arriba) ya redujo el universo a N1 con pregunta+motivo+desbloqueo concretos. Esto NO es una segunda pasada de calidad ni cambia el tope ni el nivel N1 de REGLA 7 — es solo el criterio para elegir cuáles 3, evitando que quede a criterio libre (e inconsistente entre Codex/Cursor/Claude Code).

Priorizar por estas tres señales, en orden — la primera que desempate decide, no se puntúa ni se suman:

1. **Bloquea el grafo, no solo la nota.** La duda impide enlazar, extraer o compilar átomos futuros que dependen de ella (p.ej. una `entity`/`concept` sin definir, de la que ya cuelgan o van a colgar varias notas) — no una oración aislada en una nota-hoja sin nada enlazado todavía.
2. **Nota-hub afectada.** La nota en duda es `entity`/`concept` (alto fan-out esperado, la van a referenciar muchas otras) en vez de `guide`/`incident`/`pattern` de bajo fan-out — un error en un hub se propaga a todo lo que lo enlaza; un error en una hoja se queda ahí.
3. **Ya viaja citada como hecho firme en otra nota.** El dato dudoso ya fue citado como si fuera verdad en ≥1 nota existente — si está mal, el daño ya se propagó silenciosamente y corregirlo después implica tocar más de una nota.

**Exclusión simétrica (no ocupa el cupo aunque sea N1):**
- **Ya resuelta:** otra fuente `raw/` ya compilada la responde (releer antes de emitir en vez de preguntar de nuevo).
- **Cosmética/estilística:** la duda no cambia ningún hecho — solo redacción, formato o preferencia de estilo.
- **No bloquea nada:** queda perfectamente resuelta dejándola como `[INFERIDO]`/`[FUENTE NO PERSISTIDA]` porque ningún enlace, MOC ni átomo futuro depende de dirimirla ahora.

Es el mismo espíritu de "cero vibe-knowledge" del kernel: la fricción humana (el cupo de 3) se gasta donde una respuesta equivocada o ausente se propaga por el grafo — no en dudas que un `/lint` futuro puede recuperar sin costo.

### Tipos y disparador (el pipeline ya los produce)

| Tipo | Señal que ya emite el kernel | Pregunta al humano |
|---|---|---|
| `inferencia-critica` | `[INFERIDO]` sobre un hecho N1 | "Confirmá o corregí esta inferencia" |
| `fuente-no-persistida` | `[FUENTE NO PERSISTIDA]` sobre un hecho N1 | "¿Esto debería entrar a `raw/`?" |
| `contradiccion` | `> [!warning] Contradicción` sin dirimir | "¿Cuál versión es la vigente?" |
| `definicion-faltante` | entidad referida pero nunca definida | "¿Qué es X?" |
| `verificacion-baja-confianza` | nota con `confidence < 0.7` | "El agente está adivinando acá — ¿es correcto?" |
| `revision-independiente` | hallazgo ambiguo de un revisor sin el contexto de compilación (`SKILLS/ingest.md` §Paso 3.75) | "El revisor marcó esto como `<categoría>` — confirmá o corregí" |
| `patron-candidato` | `/compose` detecta ≥3 notas ya compiladas del mismo dominio/MOC que sugieren una observación de 2º orden sin nota propia | "¿Es un patrón real que merece nota propia, o es coincidencia?" |
| `atomicidad-difusa` | categoría "atomicidad difusa" de la taxonomía de ambigüedad (`SKILLS/ingest.md` §Paso 2.5): no está claro si el material es un solo átomo o dos | "¿Esto es una sola nota, o debería partirse en dos?" |
| `terminologia-inconsistente` | categoría "terminología inconsistente" de la taxonomía de ambigüedad (`SKILLS/ingest.md` §Paso 2.5): mismo concepto con nombre distinto entre la fuente nueva y notas ya compiladas | "¿`<término A>` y `<término B>` son el mismo concepto, o son cosas distintas?" |

> [!tip] De dónde salen `atomicidad-difusa` y `terminologia-inconsistente`
> No son señales nuevas del pipeline (como sí lo son `[INFERIDO]` o `> [!warning] Contradicción`) — son las dos categorías de la **taxonomía de tipo de ambigüedad** (`SKILLS/ingest.md` §Paso 2.5) que no tenían un `Tipo` de GAP propio. Las otras cuatro categorías de esa taxonomía (identidad difusa, contradicción, dato operativo no sustentado, relación tipada dudosa) ya mapean 1:1 a un `Tipo` existente de esta tabla — ver la columna "Tipo de GAP si escala" en `SKILLS/ingest.md` §Paso 2.5. El objetivo de la taxonomía es que dos agentes distintos (Codex, Claude Code, Cursor) lleguen al mismo nivel N1/N2/N3 ante la misma duda, no agregar un pool de brechas aparte — sigue compitiendo por el mismo tope ≤3/ingest de REGLA 7.

> [!warning] `patron-candidato` es la única vía para síntesis nueva — y exige confirmación antes de existir
> A diferencia de los demás tipos (que enriquecen una nota YA existente con una fuente puntual), `patron-candidato` es la única vía por la que una observación de 2º orden —sintetizada leyendo varias notas `wiki/` ya compiladas, sin una fuente `raw/` puntual nueva— puede llegar a convertirse en nota. El agente **nunca** crea esa nota por su cuenta: solo emite la pregunta. La nota nace recién si el humano confirma, y en ese caso la respuesta del humano ES la fuente (Opción C, igual que cualquier otra brecha). Si el humano dice que es coincidencia → `status: dropped`, nunca se crea nada. Ver `AGENTS.md` REGLA 7 (patrón candidato y su gate humano obligatorio).

### Pasos de emisión

```
1. Registrar la entrada en wiki/_gaps.md bajo "## Brechas abiertas" (status: open, esquema de arriba).
2. Dejar el callout inline en la nota afectada, justo donde vive la duda:
      > [!question] GAP-YYYY-MM-DD-NNN — <pregunta corta>
      > Brecha en [[wiki/_gaps#GAP-YYYY-MM-DD-NNN]]. El humano responde ahí; el próximo /ingest o /gaps la absorbe.
3. NO bloquear la compilación: la nota se publica con la duda visible, no se espera respuesta.
```

---

## Absorción (protocolo principal de /gaps)

### Pasos

```
1. Leer wiki/index.md y wiki/_gaps.md.
2. Seleccionar brechas con "Respuesta del humano" NO vacía y status ∈ {open, stale, unanswered}
   (cualquier brecha aún no resolved/dropped que el humano respondió — sin importar en qué sección viva).
   Responder una brecha archivada (unanswered) es la vía de reversión: la absorción la reactiva y resuelve.
3. Por cada una:
   a. Leer la nota afectada.
   b. Tratar la respuesta del humano como FUENTE NUEVA y compilarla en la nota (densa, citada),
      reemplazando/upgradeando la marca original:
        - el [INFERIDO] dudoso pasa a hecho citado (o se corrige),
        - el [FUENTE NO PERSISTIDA] pasa a cita firme,
        - la contradicción se resuelve marcando la versión vigente.
   b-bis. CASO ESPECIAL `patron-candidato`: no hay "nota afectada" que enriquecer — hay que decidir si se CREA:
        - Si el humano CONFIRMÓ el patrón: crear wiki/<nota-nueva>.md con el mismo estándar de
          calidad de /ingest (type correcto: concept|pattern|summary; description; tags ≥2;
          ≥2 enlaces tipados hacia las notas listadas en "Notas que lo sugieren"; registrarla
          en el MOC del dominio). Citar la respuesta del humano como fuente de la síntesis
          (Opción C: durable → raw/feedback/ con confirmación; efímera → [FUENTE NO PERSISTIDA]).
          Actualizar related[] de las notas que lo sugirieron con el enlace recíproco hacia la
          nota nueva (bidireccionalidad).
        - Si el humano NEGÓ el patrón ("es coincidencia"): NO crear nada. Marcar status: dropped
          (no resolved) y mover al histórico con la razón.
   c. Decidir PROCEDENCIA (ver tabla Opción C abajo).
   d. Quitar el callout > [!question] GAP-… inline de la nota (ya resuelto).
   e. Actualizar updated: + last_agent: en el frontmatter de la nota.
4. Marcar la brecha status: resolved y MOVERLA de "## Brechas abiertas" a "## Brechas resueltas (histórico)"
   en wiki/_gaps.md, anotando fecha y qué nota enriqueció. Nunca borrar la entrada.
5. Actualizar wiki/index.md (stat de brechas abiertas) y verificar citas:
      bash scripts/verify_citations.sh <nota>
6. Append a wiki/log.md:
      ## [YYYY-MM-DD HH:MM] gaps | GAP-… resuelto → wiki/<nota>
      Fuentes: `raw/feedback/YYYY-MM-DD.md` (sha256:<64hex>)   ← OBLIGATORIA solo si la absorción creó/usó ese archivo
```

> [!important] Línea `Fuentes:` cuando la absorción persistió a `raw/feedback/` (detección de compilado)
> Si la procedencia elegida fue **Durable** (Opción C → se creó/añadió `raw/feedback/YYYY-MM-DD.md`), ese archivo es una **fuente nueva en `raw/`**. La entrada de log DEBE incluir una línea `Fuentes:` con su fingerprint — **mismo formato exacto que `/ingest`** (`SKILLS/ingest.md` §Paso 5):
> - **No lo calcules a ojo:** `bash scripts/source_hash.sh --line raw/feedback/YYYY-MM-DD.md` imprime la línea `Fuentes:` ya armada y lista para pegar.
> - **Por qué es obligatoria:** `scripts/pending_sources.sh` arma el set de "ya compilado" leyendo exclusivamente las líneas `^Fuentes:` de `wiki/log.md`. Sin esta línea, cada `raw/feedback/` quedaría marcado como "nunca compilado" **para siempre**, contaminando `/status` y la cola de `/compose`.
> - **Cuándo NO va:** si la respuesta fue **Efímera** (`[FUENTE NO PERSISTIDA]`, sin tocar `raw/`) no se creó archivo → no corresponde línea `Fuentes:`.

### Procedencia de la respuesta — Opción C (híbrida)

La respuesta del humano es conocimiento tácito hecho explícito. **El agente decide por valor; el humano solo confirma cuando hay escritura a `raw/`.**

| Valor | Dónde vive la respuesta | Acción |
|---|---|---|
| **Durable / alto valor** (decisión, threshold, definición reusable, candidata a `curated/`) | `raw/feedback/YYYY-MM-DD.md` | Proponer la escritura, **el humano confirma** (REGLA 2), luego citar `[[raw/feedback/YYYY-MM-DD#GAP-…]]` |
| **Efímero / contextual** | inline en la nota | Citar `[FUENTE NO PERSISTIDA: feedback el humano GAP-…]` — sin tocar `raw/` |
| Nota afectada en **`curated/`** | propuesta | **No editar** la nota → `/propose` (REGLA 6), citando la fuente del feedback |

### Persistir a `raw/feedback/` (única excepción acotada a REGLA 2)

```
Solo con CONFIRMACIÓN EXPLÍCITA del humano. El agente:
  1. Propone: "esta respuesta es durable → la persisto en raw/feedback/YYYY-MM-DD.md, ¿confirmás?"
  2. Con OK → crear el archivo (si no existe) o AÑADIR una sección nueva; nunca editar/borrar lo ya escrito.
  3. Una vez escrita, es inmutable como el resto de raw/.

Formato del archivo raw/feedback/YYYY-MM-DD.md:
```
```markdown
# Feedback del humano — YYYY-MM-DD

## GAP-YYYY-MM-DD-NNN
**Pregunta:** <la pregunta de la brecha>
**Respuesta del humano:** <texto literal del humano>
**Contexto:** disparada por /ingest de raw/<fuente>; enriquece wiki/<nota>.
```

> [!danger] Nunca sin confirmación
> Crear o tocar `raw/feedback/` sin el OK explícito del humano viola REGLA 2. Ante la duda → `[FUENTE NO PERSISTIDA]`.

---

## Higiene del registro — archivado de brechas sin respuesta

> [!abstract] El techo global que le faltaba al `_gaps.md`
> El tope `≤3 por ingest` limita el **flujo**, no el **stock**: sin respuesta humana, las brechas `open` se acumulan sin techo y cada `/ingest` futuro paga leer un registro que solo crece. Este mecanismo pone el techo, calcado del **Mecanismo de ignore** de `wiki/.skip-sources.md` (`AGENTS.md`): autónomo pero **siempre visible**, y **reversible** por el humano.

### Disparador (objetivo y repetible)

```
Una brecha se archiva cuando, SIN respuesta del humano:
  supera > 60 días desde su EMISIÓN (la fecha del id GAP-YYYY-MM-DD-NNN).

  · La emisión está siempre en el id → el umbral es computable sin campos nuevos.
  · 60 días desde emisión ≈ 45 días ya en estado `stale` (stale se marca a los > 14 días),
    dentro del rango "umbral adicional tras stale". Normalmente la brecha ya pasó por `stale`;
    si /lint no llegó a marcarla, el umbral por edad la archiva igual (robusto a que /lint no corra).
```

> [!warning] No cambia el tope de emisión
> Esto NO toca el `≤3 por ingest` (flujo). Es un límite de **stock**: saca de la sección activa lo que lleva demasiado tiempo sin respuesta, sin borrarlo.

### Qué hace el agente al archivar

```
Cuando corre /lint (Paso 5.5) o /gaps y una brecha cumple el disparador:
  1. status: open|stale → unanswered.
  2. MOVER la entrada completa de "## Brechas abiertas" a "## Brechas sin respuesta (archivadas)"
     en wiki/_gaps.md (mover, no copiar; nunca borrar — REGLA 7).
  3. Añadir a la entrada, estilo skip-sources (fecha · razón · agente):
       - **Archivada:** YYYY-MM-DD · sin respuesta hace N días desde emisión · <agente>
  4. Si la nota afectada aún tiene el callout > [!question] GAP-… inline, dejarlo:
     la pregunta sigue viva, solo se aparcó en el ledger.
```

### Transparencia obligatoria (igual que un veto de skip-sources)

- **Reportar** en la ENTREGA de `/lint` (y del `/gaps` de reporte) cada brecha recién archivada: id, nota afectada, días sin respuesta.
- **Loguear** en `wiki/log.md` (append-only, REGLA 5): `## [FECHA] gaps | GAP-… archivada (unanswered) — N días sin respuesta`.
- Quedar contada en `/status` como `sin respuesta (archivadas): N` (ver `SKILLS/status.md`).

### Reversibilidad (decisión del humano)

Un archivado no es sagrado — lo puso el agente por heurística de edad. El humano lo revierte de dos formas, **sin borrar nada**:

| Vía | Efecto |
|---|---|
| **Responder** la brecha archivada (escribir `Respuesta del humano`) | La próxima absorción la toma (selección por respuesta no vacía, cualquier sección) → `resolved`. Es la reversión natural. |
| **Mover** la entrada de vuelta a "## Brechas abiertas" y poner `status: open` | La brecha vuelve a la sección activa como si nada. |

> [!danger] Archivar aquí ≠ REGLA 3
> "Archivar una brecha" es higiene **interna de `wiki/_gaps.md`** (mover entre secciones del mismo archivo). **No** es el `/archive` de REGLA 3 (que mueve **notas** a `archivo/` y es append-only). El archivado de brechas nunca toca `archivo/` ni `raw/`.

---

## Reporte (cuando no hay nada que absorber)

Si el humano invoca `/gaps` y no hay respuestas pendientes, mostrar (no crear archivo):

```text
## Brechas — estado
| Brecha | Nota afectada | Tipo | Días abierta | Estado |
|--------|---------------|------|--------------|--------|
| GAP-… | wiki/<nota> | … | N | esperando respuesta del humano |
| GAP-… | wiki/<nota> | … | N | ✅ respondida — lista para absorber |

Resumen: X abiertas · Y respondidas sin procesar · Z stale (>14d) · W sin respuesta (archivadas).
Sugerencia: responder en wiki/_gaps.md las que esperan, o /gaps para absorber las respondidas.
Si archivaste alguna en esta corrida, reportarla aparte (id, nota, días sin respuesta).
```

---

## Reglas durante /gaps

- ❌ NUNCA editar el contenido de `curated/` → si la nota afectada es curada, `/propose` (REGLA 6).
- ❌ NUNCA escribir en `raw/feedback/` sin confirmación explícita del humano (REGLA 2).
- ❌ NUNCA borrar una brecha → marcar `resolved`/`dropped`/`unanswered` y mover a la sección que corresponda.
- ❌ NUNCA escribir en el campo `Respuesta del humano` (es exclusivo del humano).
- ❌ NUNCA confundir archivar una brecha (mover dentro de `wiki/_gaps.md`) con REGLA 3 (`/archive` → `archivo/`).
- ✅ Absorber toda brecha con respuesta no vacía y `status` ∈ {open, stale, unanswered} (responder revierte un archivado).
- ✅ Archivar (`unanswered`) las brechas sin respuesta > 60 días desde emisión, reportándolas y logueándolas.
- ✅ Verificar citas (`verify_citations.sh`) antes de dar por cerrada la nota enriquecida.
- ✅ Aplicar `SKILLS/format.md` al escribir en la nota afectada y en `wiki/_gaps.md`.
- ✅ Loguear cada absorción en `wiki/log.md` (append-only).
- ✅ Para `patron-candidato` confirmado: crear la nota nueva solo ahora, con el mismo estándar de calidad de `/ingest` (atomicidad, enlaces, frontmatter) — nunca antes de la confirmación del humano.
- ❌ NUNCA crear una nota de `patron-candidato` sin `Respuesta del humano` que confirme el patrón — sin eso, no es conocimiento, es solo una pregunta abierta.

---

## Prompt reutilizable de invocación

```text
Ejecuta /gaps siguiendo SKILLS/gaps.md.

ABSORCIÓN:
- Lee wiki/_gaps.md. Toma las brechas con "Respuesta del humano" no vacía y status ∈ {open, stale, unanswered}
  (responder una brecha archivada la reactiva; se absorbe igual, esté en la sección que esté).
- Por cada una: compila la respuesta del humano como fuente nueva en la nota afectada, con cita.
  Procedencia (Opción C): durable → propone raw/feedback/ (confírmame antes de escribir en raw/);
  efímera → [FUENTE NO PERSISTIDA: feedback el humano GAP-…]; nota curated/ → /propose (no editar curated/).
- Si la brecha es tipo patron-candidato: si confirmaste el patrón, crea la nota nueva ahora (con
  el mismo estándar de calidad de /ingest, enlazada a las notas que lo sugirieron); si dijiste que
  es coincidencia, no crees nada — marca status: dropped.
- Quita el callout > [!question] inline, marca la brecha resolved y muévela al histórico.
- Corre bash scripts/verify_citations.sh <nota>. Actualiza index + log.

Higiene (siempre):
- Archiva (status: unanswered, mueve a "## Brechas sin respuesta (archivadas)") las brechas sin respuesta
  con > 60 días desde su emisión. No borres nada; añade "- **Archivada:** fecha · sin respuesta hace N días · <agente>".
  Reporta y loguea cada archivado.

Si no hay respuestas para absorber:
- Repórtame las brechas abiertas (id, nota, tipo, días), cuáles esperan mi respuesta y cuáles archivaste.
```
