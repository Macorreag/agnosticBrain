# SKILL: /query — Consultar la wiki

> La wiki es la fuente de verdad compilada. Responder desde ella, no desde memoria del modelo.
> El index es la puerta. Las páginas wiki/ son el contenido. curated/ es contexto adicional.

---

## Cuándo usar

- El humano hace cualquier pregunta sobre su dominio: conocimiento, patrones, entidades, casos pasados
- Al inicio de una tarea donde necesita contexto del dominio
- Durante un incidente, decisión o análisis, para obtener contexto rápido de un caso o patrón previo

---

## Protocolo paso a paso

### Paso 1 — Entrar por el MOC del dominio
```
Leer wiki/index.md completo.
Identificar el MOC del dominio relevante (moc-<dominio>) — es la puerta de navegación.
Si no hay MOC del dominio, identificar las páginas relevantes por título + descripción.
Si el index referencia notas curated/ relacionadas, anotarlas también.
```

### Paso 2 — Navegar el grafo hasta el átomo
```
Abrir el MOC y leer los átomos que enlaza relevantes a la pregunta.
Seguir los enlaces TIPADOS (## Relacionado / related[]) hasta el nodo exacto que responde:
  → depende-de / define → bajar a la entidad/concepto definitorio
  → instancia-de / afecta-a → ir del incidente al patrón o a la entidad impactada
Recuperar el ÁTOMO preciso, no documentos enteros. La red existe para no leer notas de 50 KB.
Leer páginas curated/ referenciadas por el index o por los átomos para contexto adicional.
```

### Paso 2.5 — Fallback: búsqueda de texto completo
```
(SOLO si la navegación de Pasos 1–2 no encontró un átomo relevante)

Antes de concluir que la wiki no tiene la respuesta, correr una búsqueda de texto
completo por los términos clave de la pregunta. Un hecho puede vivir en el CUERPO de
un átomo cuyo título/descripción NO lo sugieren y que ningún MOC obvio enlaza — la
navegación por título/descripción no lo alcanza, pero un grep sí.

  grep -rilE "término1|término2" wiki/    # notas que mencionan cualquiera de los términos
  grep -rinE "término" wiki/              # línea + nº de línea de cada match (contexto)
  grep -rilE "término" raw/               # opcional: ampliar a las fuentes crudas si wiki/ queda vacío

Probar sinónimos/alias del término (una entidad puede figurar por su alias coloquial).

→ Si hay match → volver al Paso 2/3: abrir esos átomos, leerlos y sintetizar desde ahí
  (y si el dato debió estar enlazado desde un MOC pero no lo estaba → señal de grafo, ver abajo).
→ Solo si la búsqueda de texto completo TAMBIÉN queda vacía → recién ahí pasar a
  "Cuando la wiki no tiene la respuesta".
```

### Paso 3 — Sintetizar respuesta
```
Componer respuesta basada SOLO en lo que está en wiki/ y curated/.
Si la wiki no tiene la respuesta → decirlo explícitamente.
NO inventar información que no está en las páginas leídas.
```

### Paso 3.5 — Auto-verificación (patrón CRITIC: releer antes de entregar)
```
El riesgo real no es que una página de wiki/ esté mal citada (eso ya lo garantiza /ingest
y verify_citations.sh) — es que la SÍNTESIS de /query agregue algo que ninguna página dice
tal cual, sin marcarlo. Releer el borrador AFIRMACIÓN POR AFIRMACIÓN (no de un vistazo
global) y clasificar cada una:

  ¿Está dicho en sustancia en una página consultada (wiki/ o curated/)?
    SÍ → queda tal cual (respaldada por la cita de esa página).
    NO, pero es una combinación/deducción razonable de ≥2 páginas consultadas
      → marcar [INFERIDO] en esa frase, ANTES de entregar. No dejarla implícita.
    NO, y tampoco se puede sustentar con lo consultado
      → eliminarla de la respuesta. No "suavizarla" con un hedge en vez de sacarla.

NO LAVAR marcas ya existentes: si una página citada tenía la afirmación marcada
[FUENTE NO PERSISTIDA] o [INFERIDO] en su propio texto, la respuesta que la repite
hereda esa misma marca — repetirla en una respuesta nueva no la vuelve un hecho firme.

CHECKLIST DE AUDITORÍA — ejecutar OBLIGATORIAMENTE antes de entregar cualquier respuesta:
  □ ¿Cada afirmación de hecho aparece, en sustancia, en alguna página de "Páginas consultadas"?
  □ ¿Alguna frase combina información de ≥2 páginas de forma que el resultado no está dicho
    explícitamente en ninguna? → marcarla [INFERIDO].
  □ ¿Alguna afirmación viene en realidad del conocimiento general del modelo, no de wiki/
    ni curated/? → sacarla, o declararla explícitamente como no validada (ver más abajo).
  □ ¿La respuesta combina ≥2 páginas y tiene CERO marcas [INFERIDO]? → sospechoso: la
    síntesis casi siempre agrega algo no textual; releer de nuevo antes de asumir que no hay.
  □ ¿Alguna cita heredaba [FUENTE NO PERSISTIDA]/[INFERIDO] de la página original? → conservar
    la marca en la respuesta, no presentarla como hecho firme.

Si el checklist no encuentra nada que corregir: entregar la respuesta tal cual.
Si encuentra algo: corregirlo (marcar o eliminar) ANTES de mostrarla — nunca corregir después.
```

> [!example] Antes / después de la auto-verificación
> Borrador antes de verificar: *"elemento-a depende de elemento-b, y por eso cualquier demora en elemento-b se convierte en un problema de cascada en todo el dominio."*
> Al releer: "elemento-a depende de elemento-b" está en [[wiki/elemento-a]]. Pero "por eso... cascada en todo el dominio" no está dicho en ninguna página consultada — es una conclusión propia combinando el patrón de dependencia con el patrón de repetición-en-cascada.
> Respuesta corregida: *"elemento-a depende de elemento-b [[wiki/elemento-a]]. Combinando esto con el patrón de repetición en cascada, es razonable esperar que una demora en elemento-b afecte a todo el dominio [INFERIDO]."*

### Paso 4 — Citar fuentes
```
Al final de la respuesta, listar las páginas consultadas:
"Páginas consultadas: [[wiki/nombre1]], [[wiki/nombre2]], [[curated/nombre3]]"
```

---

## Reglas durante query

- ❌ NUNCA modificar ningún archivo durante una query
- ❌ NUNCA responder con información que no está en wiki/ o curated/
- ❌ NUNCA entregar una respuesta sin haber corrido el checklist de auto-verificación (Paso 3.5)
- ❌ NUNCA corregir una afirmación después de haberla mostrado al humano — verificar ANTES
- ✅ Declarar explícitamente cuando la wiki no tiene respuesta
- ✅ Sugerir `/ingest` si la pregunta revela un gap en la wiki
- ✅ Citar siempre las páginas consultadas
- ✅ Marcar `[INFERIDO]` toda combinación/deducción que la síntesis agregue y que ninguna página consultada dijera tal cual

---

## Cuando la wiki no tiene la respuesta

> Precondición: llegar aquí solo tras agotar el **Paso 2.5** — navegación (MOC / título / descripción) **y** búsqueda de texto completo (`grep`) sin resultado. Si no corriste el grep, todavía no podés afirmar que la wiki no lo tiene.

```
"No encontré información sobre [tema] en wiki/ ni curated/.

Opciones:
1. /ingest [fuente relevante] — para agregar ese conocimiento al sistema
2. Responder desde conocimiento general del LLM (fuera de la wiki)
   → En ese caso, la respuesta NO está validada por el sistema"
```

---

## Señal de calidad de la wiki (detectar durante query)

Si durante una query notas:
- Información stale o contradictoria → sugerir `/lint` al final
- Gap importante no documentado → sugerir `/ingest` de la fuente correspondiente
- Propuesta pendiente relevante en `_proposed/` → mencionarla al humano
- **Nota gigante que tuviste que leer entera para extraer un dato** → señal de fan-in excesivo: sugerir `/lint` (salud del grafo) o split
- **Entidad sin nota propia** que tuviste que reconstruir desde una guía → sugerir `/ingest` para extraer el nodo-hub
