#!/bin/bash
# entry_orphans.sh — Detecta "huérfanas de ENTRADA": notas de wiki/ sin ninguna referencia entrante.
# Uso: bash scripts/entry_orphans.sh
#
# Mecánico: cubre el Paso 3 de /lint ("cada página wiki/ tiene ≥1 referencia entrante desde el index
# o desde otra página"), hoy 100% manual. Una nota es huérfana de ENTRADA si NINGÚN otro archivo la
# enlaza con [[wiki/nota]] (ni con [[nota]]) — ni el index, ni un MOC, ni otra nota wiki/, ni una
# nota curated/. Es el sentido clásico de "página huérfana" (in-degree 0) que definen tanto AGENTS.md
# (/lint: "sin links entrantes desde index ni desde otras páginas") como SKILLS/lint.md (Paso 3).
#
# Complementa —no duplica— a graph_health.sh, que mide la huérfana de SALIDA (0 enlaces que la nota
# EMITE). Aquí medimos lo inverso: 0 enlaces que la nota RECIBE. Sin este chequeo, si el index o un
# MOC se desactualiza en silencio una entidad existente deja de ser encontrable, y un /ingest futuro
# puede crear un duplicado del mismo sujeto sin que nada lo detecte.
#
# Fuentes de referencia entrante consideradas: wiki/index.md + notas wiki/ (átomos y MOCs) + curated/.
# NO cuentan como fuente los ledgers/históricos/reportes (_gaps, _proposed, log, lint-*), ni las
# autorreferencias de una nota a sí misma. Se ignoran enlaces dentro de bloques de código cercados
# (```), spans inline (`...`) y comentarios HTML (<!-- ... -->), igual que verify_wikilinks.sh.
#
# Read-only: nunca modifica ningún archivo. Exit 0 = sin huérfanas de entrada; Exit 1 = hay ≥1.

VAULT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WIKI_DIR="$VAULT_DIR/wiki"
CURATED_DIR="$VAULT_DIR/curated"
TODAY=$(date '+%Y-%m-%d %H:%M:%S')

echo "=================================================="
echo " BrainAI — Huérfanas de entrada (in-degree 0)"
echo " $TODAY"
echo "=================================================="

# ── Universo de archivos ────────────────────────────────────────────────────────
# Nodos/candidatas = átomos wiki/ planos (como graph_health.sh: wiki/*.md, sin subcarpetas),
# excluyendo index, ledgers (_*), log, reportes lint-* y dotfiles (.skip-sources.md).
# Fuentes de referencia = esas candidatas + wiki/index.md + notas curated/ (excl. README).
SRC=()
while IFS= read -r f; do [[ -n "$f" ]] && SRC+=("$f"); done < <(
  {
    find "$WIKI_DIR" -maxdepth 1 -type f -name "*.md" \
      ! -name "_*" ! -name ".*" ! -name "log.md" ! -name "lint-*.md"
    find "$CURATED_DIR" -maxdepth 1 -type f -name "*.md" ! -name "README.md" ! -name ".*"
  } 2>/dev/null | sort
)

if [[ ${#SRC[@]} -eq 0 ]]; then
  echo " Notas candidatas: 0 — no hay notas wiki/ que evaluar."
  echo "=================================================="
  exit 0
fi

# ── Análisis (una sola pasada awk sobre todas las fuentes) ──────────────────────
# Emite: "META\t<n_candidatas>" y una línea "ORPH\t<nota>" por cada huérfana de entrada.
report="$(awk '
  # ¿es la nota "base" (por FILENAME) el index, un átomo wiki/, o una nota curated/?
  FNR == 1 {
    in_fence = 0; in_comment = 0
    base = FILENAME; sub(/.*\//, "", base); sub(/\.md$/, "", base)
    is_index   = (FILENAME ~ /\/wiki\/index\.md$/)
    is_wiki    = (FILENAME ~ /\/wiki\/[^\/]+\.md$/)
    # candidata = átomo wiki/ que no es el index
    if (is_wiki && !is_index) cand[base] = 1
  }
  {
    line = $0
    if (line ~ /^```/) { in_fence = !in_fence; next }
    if (in_fence) next
    if (in_comment) {
      i = index(line, "-->")
      if (i > 0) { line = substr(line, i + 3); in_comment = 0 }
      else next
    }
    while (match(line, /<!--.*-->/)) line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    i = index(line, "<!--")
    if (i > 0) { line = substr(line, 1, i - 1); in_comment = 1 }
    while (match(line, /`[^`]*`/)) line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    # cualquier enlace [[...]]; normalizamos y quedamos solo con destinos wiki/
    while (match(line, /\[\[[^]]+\]\]/)) {
      t = substr(line, RSTART + 2, RLENGTH - 4)
      line = substr(line, RSTART + RLENGTH)
      gsub(/\\/, "", t)            # pipe escapada en tablas
      sub(/\|.*/, "", t)           # alias
      sub(/#.*/, "", t)            # fragmento / sección
      sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      if (t ~ /^raw\//) continue         # cita a fuente: no es enlace del grafo interno
      if (t ~ /^curated\//) continue     # destino curated/: nunca es candidata a huérfana wiki/
      sub(/^wiki\//, "", t)              # normalizar prefijo opcional
      if (t == "" || t ~ /^_/) continue  # vacío o ledger (_gaps, ...)
      if (t == base) continue            # autorreferencia: no cuenta como entrante
      referenced[t] = 1
    }
  }
  END {
    nc = 0
    for (c in cand) nc++
    print "META\t" nc
    for (c in cand) if (!(c in referenced)) print "ORPH\t" c
  }
' "${SRC[@]}")"

n_cand="$(printf '%s\n' "$report" | awk -F'\t' '$1=="META"{print $2; exit}')"
orphans="$(printf '%s\n' "$report" | awk -F'\t' '$1=="ORPH"{print $2}' | LC_ALL=C sort)"
if [[ -z "$orphans" ]]; then
  n_orph=0
else
  n_orph="$(printf '%s\n' "$orphans" | grep -c .)"
fi

echo " Notas candidatas (wiki/) : ${n_cand:-0}"
echo " Huérfanas de entrada     : $n_orph"
echo "=================================================="
echo ""

if [[ "$n_orph" -eq 0 ]]; then
  echo " ✓ Toda nota wiki/ tiene al menos una referencia entrante (index / MOC / otra nota / curated)"
  echo "=================================================="
  exit 0
else
  echo "── Notas sin referencia entrante ──────────────────"
  while IFS= read -r o; do
    [[ -z "$o" ]] && continue
    echo "   - wiki/${o}.md"
  done <<< "$orphans"
  echo ""
  echo " ✗ [AGENTE] $n_orph nota(s) huérfana(s) de entrada — enlazarlas desde su MOC/index (REGLA 8)"
  echo "=================================================="
  exit 1
fi
