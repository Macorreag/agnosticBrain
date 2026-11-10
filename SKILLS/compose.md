# SKILL: /compose — Composición autónoma continua

> La operación que permite **dejar el cerebro compilando por horas y que mejore en cada ciclo**.
> No es una pasada única: es un **loop convergente** que reduce la deuda del grafo hasta un punto fijo.
> Cierra el principio de composición incremental de la REGLA 8 (kernel v2.3).

---

## Modelo mental: loop convergente, no pasada única

```
        ┌─────────────────────────────────────────────┐
        │  CICLO (repetir hasta punto fijo o presupuesto)│
        │                                               │
  raw/ →│ 1. cola de ingest   → /ingest (extrae+enlaza) │
        │ 2. diagnóstico      → salud del grafo (/lint) │
        │ 3. UN refactor seguro (el de mayor impacto)   │
        │ 4. verificar citas  → verify_citations.sh     │
        │ 5. log del ciclo (qué métrica bajó)           │
        └───────────────┬───────────────────────────────┘
                        │ ¿bajó alguna métrica de deuda?
                 sí ────┘ no → PUNTO FIJO → detenerse
```

> [!important] Qué lo distingue de `/ingest`
> `/ingest` compila **una fuente**. `/compose` mejora **todo el grafo** de forma iterativa: parte notas-cubo, extrae nodos faltantes, densifica enlaces, crea MOCs — y lo repite hasta que no queda deuda. Es lo que convierte "una pasada que no aporta" en "un cerebro que compone y mejora".

---

## Cuándo usar

- El humano quiere dejar el sistema mejorando solo durante un rato largo (`/compose --hasta-limpio`).
- Después de cargar varias fuentes nuevas en `raw/` de golpe.
- Tras un `/lint` que reveló deuda de grafo (centralización, huérfanas, entidades sin nodo).
- Como mantenimiento periódico del cerebro (mensual).

---

## Política de autonomía

> [!important] Sin human-in-the-loop, pero con barandas duras
> El LLM toma todas las decisiones. **Nunca** pausa para consultar. Respeta TODO el ownership:
> nunca toca `raw/`, `curated/` (→ `/propose`) ni `archivo/`. Dudas N1 → brechas (REGLA 7, ≤3 por ciclo de ingest).

| Situación | Default autónomo |
|---|---|
| ¿Por dónde empezar el ciclo? | → El item de deuda de **mayor impacto** (fan-in excesivo primero — es la centralización). |
| ¿Refactor ambiguo o riesgoso? | → Elegir el refactor **más conservador que preserve toda la información**; si ninguno es seguro, emitir brecha y saltar. |
| ¿El split afectaría una nota `curated/`? | → No tocar → `/propose`. |
| ¿No bajó ninguna métrica este ciclo? | → **Punto fijo**: detenerse y reportar. No forzar cambios cosméticos. |
| ¿Se agotó el presupuesto (ciclos/tiempo)? | → Cerrar limpio: verificar citas, loguear estado, reportar deuda restante. |
| ¿Se nota un patrón entre ≥3 notas ya compiladas que ninguna dice por separado? | → **Nunca crear la nota** → emitir GAP `patron-candidato` (mismo tope de REGLA 7) y seguir con el refactor normal del ciclo. |

---

## Métricas de deuda del grafo (el "termómetro")

El loop se apoya en un instrumento **objetivo y repetible** — sin él, "mejoró" sería una opinión. Usar siempre el script oficial:

```bash
bash scripts/graph_health.sh           # reporte legible + DEUDA total + listas priorizadas
bash scripts/graph_health.sh --score   # una línea para comparar entre ciclos:
# DEUDA=86 | cubos=12 huerfanas=1 subenlazadas=5 dom_sin_moc=2 monocultivo=92% (guide) notas=25
```

> [!important] La regla de oro del loop autónomo
> **Medí DEUDA antes y después de cada ciclo.** Si bajó → el ciclo mejoró (probado, no supuesto). Si no bajó o subió → revertí/ajustá ese refactor. `DEUDA=0` = punto fijo → detenerse. Esto es lo que hace seguro dejarlo correr horas: el progreso es verificable cada vuelta.

El índice DEUDA pondera: `5·notas-cubo + 3·huérfanas + 1·sub-enlazadas + 4·dominios-sin-MOC + 10·(monocultivo>70%)`.

| Métrica | Umbral de deuda | Refactor que la baja |
|---|---|---|
| Fan-in | >12 fuentes raw **o** >150 líneas | split + MOC |
| Huérfana de salida | 0 enlaces salientes | enlazar / extraer nodo |
| Sub-enlazada | <2 enlaces tipados (no moc/entity nueva) | enlazar |
| Entidad sin nodo | mencionada repetida sin nota `entity` | extraer hub |
| Dominio sin MOC | ≥3 átomos del dominio, sin `moc-<dominio>` | crear MOC |
| Monocultivo | un `type` > 70% de las notas | extraer entity/concept |

---

## Protocolo paso a paso (un ciclo)

### Paso 0 — Presupuesto y baseline
```
Fijar presupuesto: N ciclos, "--hasta-limpio" (punto fijo), T minutos y un tope de costo
(--max-tokens estimado o --max-minutos). Sin tope de costo, no dejarlo correr horas.

Leer wiki/index.md.
bash scripts/graph_health.sh --score   → guardar DEUDA inicial del ciclo. Loguear el baseline.

Utilidad (si hay benchmark, EVALUACION.md):
  Correr 3–5 preguntas conocidas antes/después. Si no hay benchmark, decirlo:
  DEUDA mide estructura, no calidad de respuesta.
```

### Paso 1 — Cola de ingest (stale + nuevas)
```
bash scripts/stale_sources.sh     → fuentes raw/ modificadas DESDE su último ingest (stale).
bash scripts/pending_sources.sh   → fuentes raw/ que NUNCA se compilaron (nuevas).
(Ambos ya filtran wiki/.skip-sources.md: las fuentes vetadas no entran a la cola · ver AGENTS.md "Mecanismo de ignore".)

Prioridad de procesamiento:
  1. Stale con nota curated/ afectada  → /ingest inmediato (el cambio generará _proposed/).
  2. Stale sin curated/ afectada       → /ingest si el cambio parece sustantivo (no solo formato).
  3. Nuevas (pending)                  → /ingest como siempre.

Si ninguna cola tiene fuentes → pasar directo al refactor (Paso 2).
Absorber primero brechas respondidas (SKILLS/gaps.md), como en /ingest Paso 0.
Si vetás una fuente nueva (vacía/duplicado/fuera-de-alcance): agregala a wiki/.skip-sources.md
con formato completo y REPORTALA en el log del ciclo (Paso 5). Nunca vetar en silencio.
```

> [!note] El `/ingest` interno deja su propio rastro completo
> Cuando este paso dispara un `/ingest` (stale o pending), ese `/ingest` sigue su propio
> protocolo completo (`SKILLS/ingest.md`) y **además** de que el ciclo registre "Acción: ingest raw/x"
> en su línea de log (Paso 5), el `/ingest` interno apenda su propia entrada `## [...] ingest | ...`
> con la línea `Fuentes: \`raw/x.md\` (sha256:…)` en `wiki/log.md`, igual que si se hubiera invocado
> suelto. Sin esa línea, `stale_sources.sh` queda ciego para esa fuente (MODO HASH no se activa).

### Paso 2 — Diagnóstico
```
bash scripts/graph_health.sh   → reporte con listas priorizadas. Ordenar la deuda por impacto:
  1º fan-in excesivo (centralización)  2º entidades sin nodo  3º dominios sin MOC
  4º huérfanas/sub-enlazadas  5º monocultivo
Elegir UN item (el de mayor impacto resoluble de forma segura este ciclo).
```

### Paso 2.5 — Patrón candidato (detección, nunca creación)
```
Mientras leés las notas del diagnóstico (Paso 2), podés notar algo que NINGUNA nota
dice por separado: un tema recurrente entre ≥3 átomos del mismo dominio/MOC, una
observación de 2º orden que emerge de verlos juntos.

REGLA DURA: nunca crear la nota. Esto sería sintetizar conocimiento SIN una fuente
raw/ puntual nueva — el agente es recolector, no autor (AGENTS.md REGLA 7). La única
salida permitida es una BRECHA:

  1. Verificar que el patrón califica: ≥3 notas wiki/ ya compiladas lo sugieren,
     y se puede formular como pregunta concreta (mismo filtro de calidad que
     cualquier GAP — SKILLS/gaps.md §Filtro de calidad).
  2. Emitir GAP tipo patron-candidato en wiki/_gaps.md:
       - Nota afectada: "N/A — candidata a nota nueva"
       - Notas que lo sugieren: las ≥3 notas que lo motivan
       - Disparado por: "/compose ciclo N"
       - Pregunta: "¿Es un patrón real que merece nota propia (type sugerido:
         concept|pattern|summary), o es coincidencia?"
  3. Cuenta contra el MISMO tope ≤3/ciclo de REGLA 7 — no es un pool aparte de los
     gaps que ya emite /ingest.
  4. NO bloquea el ciclo: seguí al Paso 3 con el refactor de mayor impacto normal.
     La eventual nota nueva nace recién cuando /gaps absorbe una confirmación
     (protocolo completo: SKILLS/gaps.md, caso especial patron-candidato).

Por qué esto no rompe la convergencia del loop: detectar un patrón candidato no es
un "refactor" (no cambia estructura ni baja DEUDA) — es una emisión de señal, igual
que cualquier GAP. El invariante de DEUDA del Paso 4 sigue midiendo solo los
refactors estructurales del catálogo de abajo.
```

### Paso 3 — Un refactor seguro (ver catálogo abajo)
```
Aplicar SOLO un refactor por ciclo (mantiene el loop trazable y reversible).
Regla de oro del refactor: PRESERVAR toda la información.
  → Citas [[raw/...]] y enlaces se REESCRIBEN a su nueva ubicación, nunca se borran.
  → raw/ permanece intacto: si algo sale mal, la nota es recompilable.
```

### Paso 4 — Verificar (doble gate: citas + deuda)
```
bash scripts/verify_citations.sh        → citas íntegras (todas las notas tocadas).
bash scripts/graph_health.sh --score    → DEUDA post-ciclo.
No cerrar el ciclo si:
  - hay citas rotas (el refactor las rompió → arreglar antes de seguir), o
  - DEUDA no bajó / subió (el refactor no mejoró → revertir o ajustar; nunca dejar un ciclo neutro o peor).
Actualizar index.md y los MOCs afectados.
```

### Paso 5 — Log del ciclo y decisión de continuar
```
Append a wiki/log.md (ver formato). Registrar DEUDA: antes → después (evidencia objetiva).
  ¿DEUDA bajó Y queda presupuesto?         → siguiente ciclo (Paso 1)
  ¿DEUDA=0, o no hay refactor seguro que la baje, o presupuesto agotado?  → terminar y reportar.
```

---

## Catálogo de refactors seguros

### A. Split de nota-cubo (el refactor estrella anti-centralización)

```
ENTRADA: wiki/<cubo>.md con >12 fuentes raw o >150 líneas, varios sujetos mezclados.

1. Identificar los sujetos distintos dentro del cubo (cada uno = un átomo futuro).
2. Por cada entidad/concepto → crear wiki/<sujeto>.md (type: entity/concept) con:
   → su contenido movido tal cual (con sus citas [[raw/...]] intactas)
   → frontmatter completo + related[] hacia los átomos vecinos
3. Reducir el cubo a un ORQUESTADOR:
   → si era una guide → queda como guide corta que ENLAZA a los átomos extraídos
   → si no aporta valor propio → convertir en moc-<dominio> (índice del dominio)
4. Reescribir TODOS los enlaces entrantes al cubo que ahora apuntan mejor a un átomo.
5. Verificar citas. Ninguna cita [[raw/...]] se pierde: se movió con su sujeto.
```

> [!warning] El split nunca destruye
> Mover ≠ borrar. Cada hecho citado sigue citado, ahora en el átomo correcto. Si dudás de dónde va un hecho, va al átomo más específico, y el orquestador lo enlaza.

### B. Extracción de nodo-hub
```
Entidad/concepto mencionado N veces sin nota propia →
  crear wiki/<entidad>.md (type: entity/concept), compilando lo disperso + citas,
  y reapuntar las menciones a [[wiki/<entidad>]].
```

### C. Densificación de enlaces
```
Nota huérfana de salida o sub-enlazada →
  añadir ≥2 enlaces tipados reales (define/depende-de/instancia-de/afecta-a/ver-también)
  hacia átomos relacionados. Si no hay candidatos → suele faltar un nodo (aplicar B).
  Agregar recíprocos para relaciones fuertes (bidireccionalidad).
```

### D. Creación de MOC
```
Dominio con ≥3 átomos y sin moc →
  crear wiki/moc-<dominio>.md (type: moc) enlazando sus átomos con una línea de contexto c/u,
  y registrarlo en index.md bajo "Mapas de Contenido".
```

---

## Convergencia y seguridad — por qué es seguro dejarlo correr solo

| Propiedad | Garantía |
|---|---|
| **Convergente** | Cada ciclo baja deuda; la deuda es finita → alcanza punto fijo. Sobre un grafo sano, no cambia nada. |
| **Idempotente** | Re-correr `/compose` sin fuentes nuevas sobre un grafo limpio = no-op. No oscila. |
| **Monótono** | Nunca empeora una métrica para mejorar otra (regla del invariante). |
| **No destructivo** | Splits reescriben, no borran. `raw/` intacto → todo recompilable. |
| **Acotado** | Presupuesto explícito de ciclos/tiempo/**costo**; ≤3 brechas por ciclo de ingest. |
| **No Goodhart** | DEUDA es estructural. Sin benchmark, no se declara mejora semántica; con benchmark, se mide recuperación. |
| **Trazable** | Cada ciclo y cada refactor al log, con la métrica que mejoró. |
| **Respeta ownership** | Nunca toca `raw/`, `curated/` (→ /propose), `archivo/`. |

---

## Formato de log

```markdown
## [YYYY-MM-DD HH:MM] compose | ciclo N/<presupuesto>
Acción: <ingest raw/x | split wiki/cubo | extraer entity:Y | crear moc-Z | densificar wiki/W>
DEUDA: <antes> → <después>   (cubos A→B | huérfanas C→D | dom_sin_moc E→F | monocultivo G%→H%)
Notas creadas: [lista] | Notas reescritas: [lista] | MOCs tocados: [lista]
Citas verificadas: OK (M citas) | Brechas emitidas/absorbidas: [ids]
Estado: continúa | PUNTO FIJO (DEUDA=0) | presupuesto agotado (deuda restante: N)
```

---

## Prompt reutilizable — dejar componiendo por horas

```text
Corré /compose sobre el cerebro siguiendo SKILLS/compose.md (loop convergente, REGLA 8).

PRESUPUESTO: --hasta-limpio (o N ciclos / T minutos si lo indico).

CADA CICLO:
0. Medí baseline: bash scripts/graph_health.sh --score  → guardá DEUDA inicial.
1. bash scripts/stale_sources.sh → fuentes modificadas post-compilación; si ⚠️ curated/ afectada → /ingest urgente (→ _proposed/).
   bash scripts/pending_sources.sh → fuentes nuevas; si hay → /ingest (extrae nodos + enlaza). Absorbé brechas respondidas primero.
2. bash scripts/graph_health.sh → elegí el item de mayor impacto (notas-cubo primero).
2.5. Si notás un patrón entre ≥3 notas ya compiladas que ninguna dice por separado: NO crees la
     nota — emití GAP patron-candidato (SKILLS/gaps.md) preguntando si es real. Mismo tope de REGLA 7.
3. Aplicá UN refactor seguro (split de nota-cubo > extraer hub > crear MOC > densificar enlaces).
4. Verificá: bash scripts/verify_citations.sh (citas) + bash scripts/graph_health.sh --score (DEUDA). Actualizá index.md y MOCs.
5. Logueá DEUDA antes→después. Si bajó y queda presupuesto → siguiente ciclo.

INVARIANTE (verificado por script): cada ciclo BAJA DEUDA. Si no baja o sube → revertí/ajustá. DEUDA=0 → PUNTO FIJO, terminá.
NO DESTRUCTIVO: los splits reescriben citas/enlaces, no los borran. Nunca toques raw/, curated/ (→ /propose), archivo/.
BARANDAS: ≤3 brechas por ciclo de ingest; respetá todo el ownership del kernel.

ENTREGA FINAL:
- Ciclos corridos y por qué paró (punto fijo / presupuesto)
- Deuda antes → después (tabla de métricas)
- Notas creadas / reescritas / MOCs creados
- Patrones candidatos emitidos (ids), si aplica
- Citas verificadas (resultado verify_citations.sh)
- Deuda restante y siguiente paso sugerido
```
