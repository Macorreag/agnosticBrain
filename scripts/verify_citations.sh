#!/bin/bash
# verify_citations.sh — Verifica integridad de citas [[raw/...]] en notas wiki/
# Uso: bash scripts/verify_citations.sh [wiki/NOTA.md | --all]
#
# Mecánico: valida que cada cita [[raw/nota#sección]] resuelve a un archivo de raw/
# existente y, si incluye #sección, que ese encabezado existe en la fuente.
# Se ignoran las citas dentro de: bloques de código cercados (```), spans de código
# inline (`...`) y comentarios HTML (<!-- ... -->) — mismo criterio que verify_wikilinks.sh,
# para no marcar como rotos los ejemplos de formato (p.ej. `[[raw/nota#sección]]` documentado
# en AGENTS.md/SKILLS/format.md) si algún día se citan igual dentro de una nota wiki/.
# raw/ es inmutable: las citas con #^block-id se reportan como violación de política.

VAULT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WIKI_DIR="$VAULT_DIR/wiki"
TODAY=$(date '+%Y-%m-%d %H:%M:%S')

echo "=================================================="
echo " BrainAI — Verificación de citas (Progressive Disclosure)"
echo " $TODAY"
echo "=================================================="

# ── Scope ─────────────────────────────────────────────────────────────────────
if [[ "$1" == "--all" || -z "$1" ]]; then
  FILES=$(find "$WIKI_DIR" -name "*.md" -not -path "*/_proposed/*" 2>/dev/null | sort)
  echo " Scope: todas las notas en wiki/"
elif [[ -f "$VAULT_DIR/$1" ]]; then
  FILES="$VAULT_DIR/$1"
  echo " Scope: $1"
elif [[ -f "$1" ]]; then
  FILES="$1"
  echo " Scope: $1"
else
  echo " ERROR: archivo no encontrado: $1"
  exit 1
fi
echo "=================================================="
echo ""

TOTAL_CITES=0
BROKEN_FILE=0
BROKEN_SECTION=0
BLOCKID_VIOLATION=0

# Comprueba si un encabezado existe en un archivo (case-insensitive, trim)
section_exists() {
  awk -v h="$2" '
    BEGIN { gsub(/^[ \t]+|[ \t]+$/, "", h); h = tolower(h); found = 0 }
    /^#{1,6}[ \t]+/ {
      t = $0
      sub(/^#{1,6}[ \t]+/, "", t)
      gsub(/^[ \t]+|[ \t]+$/, "", t)
      if (tolower(t) == h) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$1"
}

echo "── Citas problemáticas ────────────────────────────"
printf "| %-22s | %-32s | %-14s |\n" "Nota origen" "Cita" "Estado"
echo "|------------------------|----------------------------------|----------------|"

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  note_name=$(basename "$file" .md)

  # Extraer citas [[raw/...]] ignorando código y comentarios HTML
  cites=$(awk '
    BEGIN { in_fence = 0; in_comment = 0 }
    {
      line = $0
      # bloques de código cercados (```): la línea marcadora nunca se escanea
      if (line ~ /^```/) { in_fence = !in_fence; next }
      if (in_fence) next
      # comentario HTML multilínea: continuación de una apertura previa
      if (in_comment) {
        i = index(line, "-->")
        if (i > 0) { line = substr(line, i + 3); in_comment = 0 }
        else next
      }
      # comentarios HTML completos dentro de la misma línea
      while (match(line, /<!--.*-->/)) line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
      # apertura de comentario sin cierre: el resto de la línea es comentario
      i = index(line, "<!--")
      if (i > 0) { line = substr(line, 1, i - 1); in_comment = 1 }
      # spans de código inline (`...`)
      while (match(line, /`[^`]*`/)) line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
      while (match(line, /\[\[raw\/[^]]+\]\]/)) {
        link = substr(line, RSTART + 2, RLENGTH - 4)
        print link
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$file" 2>/dev/null)

  while IFS= read -r cite; do
    [[ -z "$cite" ]] && continue
    ((TOTAL_CITES++))

    # Normalizar: quitar backslashes de pipe escapada (\|) en tablas
    cite="${cite//\\/}"
    # Quitar alias (|...) -> queda raw/nota#sección
    target="${cite%%|*}"
    # Separar archivo y fragmento
    path_part="${target%%#*}"
    frag_part=""
    [[ "$target" == *"#"* ]] && frag_part="${target#*#}"

    target_file="$VAULT_DIR/${path_part}.md"

    if [[ ! -f "$target_file" ]]; then
      printf "| %-22s | %-32s | %-14s |\n" "${note_name:0:22}" "${cite:0:32}" "✗ archivo"
      ((BROKEN_FILE++))
      continue
    fi

    [[ -z "$frag_part" ]] && continue

    # Validar cada segmento de encabezado (#a#b -> a, b)
    IFS='#' read -ra segments <<< "$frag_part"
    for seg in "${segments[@]}"; do
      [[ -z "$seg" ]] && continue
      if [[ "$seg" == ^* ]]; then
        printf "| %-22s | %-32s | %-14s |\n" "${note_name:0:22}" "${cite:0:32}" "✗ block-id raw"
        ((BLOCKID_VIOLATION++))
        continue
      fi
      if ! section_exists "$target_file" "$seg"; then
        printf "| %-22s | %-32s | %-14s |\n" "${note_name:0:22}" "${cite:0:32}" "✗ sección"
        ((BROKEN_SECTION++))
      fi
    done
  done <<< "$cites"
done <<< "$FILES"

echo ""
echo "=================================================="
echo " Resumen:"
echo "   Citas verificadas         : $TOTAL_CITES"
echo "   Archivos inexistentes     : $BROKEN_FILE"
echo "   Secciones inexistentes    : $BROKEN_SECTION"
echo "   Block-ids en raw (prohib.): $BLOCKID_VIOLATION"
echo ""

TOTAL_ISSUES=$((BROKEN_FILE + BROKEN_SECTION + BLOCKID_VIOLATION))
if [[ $TOTAL_ISSUES -eq 0 ]]; then
  echo " ✓ Todas las citas resuelven correctamente"
  echo "=================================================="
  exit 0
else
  echo " ✗ [AGENTE] $TOTAL_ISSUES cita(s) con problema — corregir antes de dar por compilada la nota"
  echo "=================================================="
  exit 1
fi
