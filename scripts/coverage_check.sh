#!/bin/bash
# coverage_check.sh — Cobertura bidireccional: gap↔nota, MOC↔nota (SKILLS/lint.md §Paso 3.55)
# Uso: bash scripts/coverage_check.sh
#
# Mecánico: automatiza la parte determinística del Paso 3.55 de /lint (cobertura CRUZADA entre
# capas, no salud de una nota aislada — análogo a la matriz de /speckit.analyze: todo requisito
# → ≥1 tarea, toda tarea → ≥1 requisito, huérfanos en ambos sentidos):
#
#   (a) Brecha resuelta → nota que la absorbió (REGLA 7): para cada GAP con status: resolved en
#       wiki/_gaps.md, ¿su id aparece citado en la "Nota afectada"? Grep de un identificador
#       dentro de un archivo conocido — mismo tipo de operación que verify_citations.sh hace
#       con wikilinks, aplicado a un GAP-id en vez de a un [[raw/...]].
#   (b) Entrada de MOC → nota con sustancia (REGLA 8): para cada nota type: moc, sus wikilinks
#       salientes ¿resuelven a una nota con description no vacío Y cuerpo con contenido real
#       (no un stub)? La existencia del archivo y el frontmatter son 100% mecánicos; "sustancia
#       real" se aproxima con un umbral de líneas no vacías tras el frontmatter — es una
#       heurística declarada, no un juicio semántico (ver más abajo).
#
# Lo que este script NO reemplaza: la calificación fina de "¿esta nota es corta a propósito o es
# un stub de relleno?" sigue siendo criterio del agente durante /lint — el umbral de líneas es una
# señal, no una sentencia. Tampoco decide si una brecha "resuelta de palabra" fue mala fe o una
# redacción legítima que no repitió el string del GAP-id: eso también queda para /gaps.
#
# Se ignoran wikilinks/citas dentro de bloques de código cercados (```), spans inline (`...`) y
# comentarios HTML (<!-- ... -->) — mismo criterio que verify_citations.sh / verify_wikilinks.sh.
#
# Read-only: nunca modifica ningún archivo. Exit 0 = sin hallazgos; Exit 1 = hay ≥1 candidato a
# revisar (nunca se auto-corrige: reportar, sugerir /gaps o /ingest, como indica el Paso 3.55).

VAULT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WIKI_DIR="$VAULT_DIR/wiki"
CURATED_DIR="$VAULT_DIR/curated"
GAPS_FILE="$WIKI_DIR/_gaps.md"
TODAY=$(date '+%Y-%m-%d %H:%M:%S')
BODY_LINES_MIN=3   # umbral de "sustancia": líneas no vacías tras el frontmatter

echo "=================================================="
echo " BrainAI — Cobertura bidireccional (gap↔nota, MOC↔nota)"
echo " $TODAY"
echo "=================================================="
echo ""

# ── Helpers ──────────────────────────────────────────────────────────────────

# Extrae wikilinks [[wiki/...]] / [[curated/...]] de un archivo, ignorando código/comentarios.
extract_wikilinks() {
  awk '
    BEGIN { in_fence = 0; in_comment = 0 }
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
      while (match(line, /\[\[(wiki|curated)\/[^]#|]+/)) {
        link = substr(line, RSTART + 2, RLENGTH - 2)
        print link
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$1" 2>/dev/null
}

# Resuelve un path relativo (sin .md) a un archivo real dentro del vault, o vacío si no existe.
resolve_note() {
  local rel="$1"
  if [[ -f "$VAULT_DIR/${rel}.md" ]]; then
    echo "$VAULT_DIR/${rel}.md"
  fi
}

# description del frontmatter (línea "description: ..."), vacío si ausente o vacía.
frontmatter_description() {
  awk '
    /^---[ \t]*$/ { n++; next }
    n == 1 && /^description:[ \t]*/ {
      val = $0
      sub(/^description:[ \t]*/, "", val)
      gsub(/^["'\'']|["'\'']$/, "", val)
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      print val
      exit
    }
    n >= 2 { exit }
  ' "$1"
}

# Cuenta líneas no vacías del cuerpo (después del segundo delimitador --- del frontmatter).
body_nonempty_lines() {
  awk '
    /^---[ \t]*$/ { n++; next }
    n < 2 { next }
    NF > 0 { c++ }
    END { print c + 0 }
  ' "$1"
}

# ── (a) Brechas resueltas → cita verificable en la nota afectada ────────────────
echo "── (a) Brechas resueltas sin absorción verificable ────────────"
printf "| %-24s | %-38s | %-10s |\n" "GAP" "Nota afectada" "Estado"
echo "|--------------------------|----------------------------------------|------------|"

GAP_TOTAL=0
GAP_UNVERIFIED=0

if [[ ! -f "$GAPS_FILE" ]]; then
  echo "| (sin wiki/_gaps.md)      |                                        |            |"
else
  # Emite pares "gap_id<TAB>nota_path" para cada bloque "### GAP-... · status: resolved".
  pairs=$(awk '
    BEGIN { FS="" }
    /^### GAP-[0-9A-Za-z-]+[ \t]*·[ \t]*status:[ \t]*resolved/ {
      if (gap != "") print gap "\t" nota
      line = $0
      sub(/^### /, "", line)
      sub(/[ \t]*·.*/, "", line)
      gap = line
      nota = ""
      next
    }
    /^### GAP-/ || /^## / {
      if (gap != "") print gap "\t" nota
      gap = ""; nota = ""
      next
    }
    gap != "" && /\*\*Nota afectada:\*\*/ {
      line = $0
      if (match(line, /\[\[[^]]+\]\]/)) {
        nota = substr(line, RSTART + 2, RLENGTH - 4)
        sub(/\|.*/, "", nota)
      }
    }
    END { if (gap != "") print gap "\t" nota }
  ' "$GAPS_FILE")

  if [[ -z "$pairs" ]]; then
    echo "| (sin brechas resolved)   |                                        |            |"
  else
    while IFS=$'\t' read -r gap_id nota_rel; do
      [[ -z "$gap_id" ]] && continue
      ((GAP_TOTAL++))
      note_file=$(resolve_note "$nota_rel")
      if [[ -z "$note_file" ]]; then
        printf "| %-24s | %-38s | %-10s |\n" "${gap_id:0:24}" "${nota_rel:0:38}" "✗ no existe"
        ((GAP_UNVERIFIED++))
        continue
      fi
      if grep -q "$gap_id" "$note_file"; then
        printf "| %-24s | %-38s | %-10s |\n" "${gap_id:0:24}" "${nota_rel:0:38}" "✓ citado"
      else
        printf "| %-24s | %-38s | %-10s |\n" "${gap_id:0:24}" "${nota_rel:0:38}" "✗ sin cita"
        ((GAP_UNVERIFIED++))
      fi
    done <<< "$pairs"
  fi
fi

echo ""

# ── (b) Entradas de MOC → nota con sustancia ────────────────────────────────────
echo "── (b) Entradas de MOC sin sustancia ───────────────────────────"
printf "| %-24s | %-30s | %-16s |\n" "MOC" "Entrada" "Estado"
echo "|--------------------------|--------------------------------|------------------|"

MOC_ENTRIES=0
MOC_STUBS=0

mocs=$(grep -l "^type:[ \t]*moc[ \t]*$" "$WIKI_DIR"/*.md 2>/dev/null | sort)

if [[ -z "$mocs" ]]; then
  echo "| (sin notas type: moc)   |                                 |                  |"
else
  while IFS= read -r moc_file; do
    [[ -z "$moc_file" ]] && continue
    moc_name=$(basename "$moc_file" .md)
    links=$(extract_wikilinks "$moc_file" | sed 's/#.*//' | sort -u)
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      [[ "$rel" == "$moc_name" || "wiki/$moc_name" == "$rel" ]] && continue
      ((MOC_ENTRIES++))
      target=$(resolve_note "$rel")
      if [[ -z "$target" ]]; then
        continue  # link roto: competencia de verify_wikilinks.sh, no de este script
      fi
      desc=$(frontmatter_description "$target")
      body_lines=$(body_nonempty_lines "$target")
      if [[ -z "$desc" || "$body_lines" -lt "$BODY_LINES_MIN" ]]; then
        printf "| %-24s | %-30s | %-16s |\n" "${moc_name:0:24}" "${rel:0:30}" "✗ posible stub"
        ((MOC_STUBS++))
      fi
    done <<< "$links"
  done <<< "$mocs"
  [[ "$MOC_ENTRIES" -eq 0 ]] && echo "| (MOCs sin wikilinks)    |                                 |                  |"
fi

echo ""
echo "=================================================="
echo " Resumen:"
echo "   Brechas resolved evaluadas   : $GAP_TOTAL"
echo "   Sin absorción verificable    : $GAP_UNVERIFIED"
echo "   Entradas de MOC evaluadas    : $MOC_ENTRIES"
echo "   Posibles stubs (sin sustancia): $MOC_STUBS"
echo ""

TOTAL_ISSUES=$((GAP_UNVERIFIED + MOC_STUBS))
if [[ $TOTAL_ISSUES -eq 0 ]]; then
  echo " ✓ Cobertura bidireccional sin hallazgos"
  echo "=================================================="
  exit 0
else
  echo " ✗ [AGENTE] $TOTAL_ISSUES candidato(s) a revisar — no auto-corregir: reportar en"
  echo "   lint-YYYY-MM-DD.md y sugerir /gaps (brechas) o /ingest (MOCs) según corresponda."
  echo "=================================================="
  exit 1
fi
