# EVALUACIÓN — cómo medir `/query` (y dejar de suponer)

> Hoy el sistema **no tiene evidencia** de que `/query` recupere mejor que un baseline simple.
> Este documento define el mínimo para medirlo sin agregar scripts ni infraestructura.
> Mientras no se corra, la afirmación “compilar supera a RAG” es una hipótesis, no un resultado.

---

## 1. Dataset mínimo (20–30 preguntas)

Guardar en `eval/preguntas.csv` (o Markdown con una tabla equivalente). Una fila por pregunta:

| Campo | Qué va |
|---|---|
| `id` | `Q001`… |
| `pregunta` | La pregunta tal como la haría el humano. |
| `respuesta_esperada` | La respuesta correcta, en 1–3 líneas. |
| `notas_fuente` | Wikilinks de las notas que la contienen (`wiki/...`). |
| `tipo` | `entity`, `concept`, `decision`, `threshold`, `incident`, `comparison`, `multihop`. |
| `dificultad` | `easy`, `medium`, `hard`. |

**Distribución recomendada:** 6 entity, 6 decision/threshold, 4 incident, 4 comparison, 4 multihop, 2 de “no está en la wiki” (para medir alucinación).

**Regla de oro:** la respuesta esperada se escribe **antes** de correr `/query`, leyendo las notas fuente. Si se escribe después, se contamina.

---

## 2. Baselines

| Baseline | Cómo | Qué mide |
|---|---|---|
| **Grep** | `rg -n "<término>" wiki/` y leer los 3 primeros archivos | Piso barato: si `/query` no le gana, no justifica su costo. |
| **Índice + MOC** | Leer `wiki/index.md`, entrar al MOC y leer 2–3 átomos | Recuperación estructural, sin LLM. |
| **RAG/embeddings** (opcional) | Si ya hay un índice vectorial, top-3 chunks | Techo de recuperación densa. No es obligatorio para empezar. |

---

## 3. Métricas por pregunta

| Métrica | Cómo se mide |
|---|---|
| **Correctitud** | `correcta` / `parcial` / `incorrecta` / `no sabe`. |
| **Citas válidas** | ¿Cada cita `[[...]]` existe y respalda la afirmación? `sí/no`. |
| **Trazabilidad** | ¿Marcó `[INFERIDO]` / `[FUENTE NO PERSISTIDA]` cuando correspondía? `sí/no`. |
| **Tokens** | Input + output del proveedor (o estimación `chars/4` si no hay dashboard). |
| **Latencia** | Segundos de la respuesta. |
| **Costo** | Tokens × tarifa del modelo usado. |

**Agregados:** exactitud (`correctas / total`), tasa de citas válidas, tokens promedio por respuesta, costo total del set.

---

## 4. Protocolo de corrida

1. Congelar el vault (mismo commit / mismo estado de `wiki/`).
2. Correr los 3 baselines y `/query` sobre las mismas 20–30 preguntas.
3. Registrar en `eval/resultados.csv`:

```csv
id,metodo,correctitud,citas_ok,tokens_in,tokens_out,latencia_s,notas
Q001,grep,parcial,no,0,0,0.2,"wiki/a.md wiki/b.md"
Q001,query,correcta,si,18200,420,6.1,"wiki/a.md, wiki/c.md"
```

4. No borrar resultados incómodos. El objetivo es decidir, no lucir.
5. Repetir con 2–3 modelos (grande/mediano) para ver si la ventaja depende del modelo.

---

## 5. Criterio de aceptación (sugerido)

| Condición | Umbral |
|---|---|
| Exactitud de `/query` | ≥ 80% (`correcta` + `parcial` cuenta 0.5). |
| Ventaja sobre grep | ≥ +20 puntos de exactitud. |
| Citas válidas | ≥ 90%. |
| Alucinación en “no está en la wiki” | ≤ 10%. |
| Costo por respuesta | Decidido por el humano; registrar, no ocultar. |

Si `/query` no supera a grep + MOC, el problema no es el modelo: es el índice, la granularidad de las notas o el protocolo de recuperación.

---

## 6. Qué hacer con el resultado

- **Gana `/query`:** conservar MOC-first y usar el benchmark como gate de `/compose` (utilidad, no solo DEUDA).
- **Empata:** simplificar (`/query` más barato) o mejorar el MOC; no agregar RAG por reflejo.
- **Pierde:** el problema es de recuperación, no de “más IA”. Revisar atomicidad, descripciones y enlaces antes de meter embeddings.

> Mientras `eval/resultados.csv` no exista, cualquier afirmación de efectividad es una hipótesis.
