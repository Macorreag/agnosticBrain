#!/bin/bash
# verify_wikilinks.sh — Verifica integridad de enlaces internos [[wiki/...]] y [[curated/...]]
# Uso: bash scripts/verify_wikilinks.sh [wiki/NOTA.md | curated/NOTA.md | --all]
#
# Mecánico: hermano de verify_citations.sh, pero apuntando al GRAFO INTERNO (wiki/ + curated/)
# en vez de a raw/. Recorre wiki/ y curated/, extrae cada enlace [[wiki/nota]] / [[curated/nota]]
# y valida que el archivo destino existe; si el enlace trae #sección, valida que ese encabezado
# exista en el destino. Cubre el Paso 2 de /lint ("todos los [[wikilinks]] apuntan a páginas
# existentes"), que hoy es 100% manual pese a ser la misma lógica que verify_citations.sh.
#
# Diferencias con verify_citations.sh (raw/ es INMUTABLE; wiki/ y curated/ son MUTABLES):
#   - Valida destinos en wiki/ y curated/, no en raw/.
#   - Los #^block-id SÍ son válidos aquí (raw/ los prohíbe): se aceptan, no se marcan como violación.
#   - Las citas [[raw/...]] NO son competencia de este script (ver verify_citations.sh).
#
# Se ignoran los enlaces dentro de: bloques de código cercados (```), spans de código inline (`...`)
# y comentarios HTML (<!-- ... -->). Así los ejemplos de formato del index/plantillas (que escriben
# [[wiki/nombre-nota]] como muestra) no generan falsos positivos.
#
# Read-only: nunca modifica ningún archivo. Exit 0 = todo resuelve; Exit 1 = hay enlaces rotos.

VAULT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WIKI_DIR="$VAULT_DIR/wiki"
CURATED_DIR="$VAULT_DIR/curated"
TODAY=$(date '+%Y-%m-%d %H:%M:%S')

echo "=================================================="
echo " BrainAI — Verificación de wikilinks internos (grafo)"
echo " $TODAY"
echo "=================================================="

# ── Scope ─────────────────────────────────────────────────────────────────────
if [[ "$1" == "--all" || -z "$1" ]]; then
  FILES=$( { find "$WIKI_DIR" -name "*.md" -not -path "*/_proposed/*" 2>/dev/null; \
             find "$CURATED_DIR" -name "*.md" 2>/dev/null; } | sort )
  echo " Scope: todas las notas en wiki/ y curated/"
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

TOTAL_LINKS=0
BROKEN_FILE=0
BROKEN_SECTION=0

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

echo "── Enlaces problemáticos ──────────────────────────"
printf "| %-22s | %-32s | %-14s |\n" "Nota origen" "Enlace" "Estado"
echo "|------------------------|----------------------------------|----------------|"

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  note_name=$(basename "$file" .md)

  # Extraer enlaces [[wiki/...]] y [[curated/...]] ignorando código y comentarios HTML
  links=$(awk '
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
      # extraer enlaces internos
      while (match(line, /\[\[(wiki|curated)\/[^]]+\]\]/)) {
        link = substr(line, RSTART + 2, RLENGTH - 4)
        print link
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$file" 2>/dev/null)

  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    ((TOTAL_LINKS++))

    # Normalizar: quitar backslashes de pipe escapada (\|) en tablas
    link="${link//\\/}"
    # Quitar alias (|...) -> queda wiki/nota#sección
    target="${link%%|*}"
    # Separar archivo y fragmento
    path_part="${target%%#*}"
    frag_part=""
    [[ "$target" == *"#"* ]] && frag_part="${target#*#}"

    target_file="$VAULT_DIR/${path_part}.md"

    if [[ ! -f "$target_file" ]]; then
      printf "| %-22s | %-32s | %-14s |\n" "${note_name:0:22}" "${link:0:32}" "✗ archivo"
      ((BROKEN_FILE++))
      continue
    fi

    [[ -z "$frag_part" ]] && continue

    # Validar cada segmento de encabezado (#a#b -> a, b)
    IFS='#' read -ra segments <<< "$frag_part"
    for seg in "${segments[@]}"; do
      [[ -z "$seg" ]] && continue
      # #^block-id: válido en wiki/ y curated/ (mutables) — a diferencia de raw/. Se acepta.
      [[ "$seg" == ^* ]] && continue
      if ! section_exists "$target_file" "$seg"; then
        printf "| %-22s | %-32s | %-14s |\n" "${note_name:0:22}" "${link:0:32}" "✗ sección"
        ((BROKEN_SECTION++))
      fi
    done
  done <<< "$links"
done <<< "$FILES"

echo ""
echo "=================================================="
echo " Resumen:"
echo "   Enlaces verificados       : $TOTAL_LINKS"
echo "   Archivos inexistentes     : $BROKEN_FILE"
echo "   Secciones inexistentes    : $BROKEN_SECTION"
echo ""

TOTAL_ISSUES=$((BROKEN_FILE + BROKEN_SECTION))
if [[ $TOTAL_ISSUES -eq 0 ]]; then
  echo " ✓ Todos los wikilinks internos resuelven correctamente"
  echo "=================================================="
  exit 0
else
  echo " ✗ [AGENTE] $TOTAL_ISSUES enlace(s) interno(s) roto(s) — corregir en wiki/ (curated/ → /propose)"
  echo "=================================================="
  exit 1
fi
