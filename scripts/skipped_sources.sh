#!/usr/bin/env bash
#
# skipped_sources.sh — Fuentes raw/ VETADAS del pipeline de compilación.
#
# Lista qué archivos de raw/ están en wiki/.skip-sources.md, es decir, fuentes que
# el agente NO indexa ni recompila a propósito (vacías, duplicados exactos, o
# contenido fuera de alcance operativo). Es la cara visible del "mecanismo de
# ignore": responde de un vistazo "¿por qué esta nota no compila?".
#
# Relación con los otros selectores de cola:
#   pending_sources.sh  → nunca compiladas        (entran a la cola)
#   stale_sources.sh    → compiladas y cambiadas  (entran a la cola)
#   skipped_sources.sh  → VETADAS                 (NUNCA entran a la cola)  ← este
#
# Gobernanza (ver AGENTS.md · "Mecanismo de ignore"): el agente puede vetar por su
# criterio, pero SIEMPRE lo reporta, lo loguea y queda visible acá y en /status.
# el humano revierte un veto quitando la línea de wiki/.skip-sources.md (y luego /ingest).
#
# Uso:
#   bash scripts/skipped_sources.sh            # lista "raw/path — razón", ordenada
#   bash scripts/skipped_sources.sh --score    # una línea: SKIP=N   (para /status)
#   bash scripts/skipped_sources.sh --paths     # solo los paths (sin razón, para scripting)
#   bash scripts/skipped_sources.sh --orphans  # vetos que ya no existen en raw/ (limpiables)
#   bash scripts/skipped_sources.sh --help
#
# Read-only: nunca modifica ningún archivo.
#
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  grep '^#' "$0" | sed 's/^# \?//' | head -28
  exit 0
fi

skip_file="wiki/.skip-sources.md"
mode="${1:-report}"

cd "$(dirname "$0")/.." 2>/dev/null || true

if [[ ! -f "$skip_file" ]]; then
  [[ "$mode" == "--score" ]] && echo "SKIP=0" || echo "# wiki/.skip-sources.md no existe — no hay fuentes vetadas"
  exit 0
fi

perl - "$mode" "$skip_file" <<'PERL'
use strict; use warnings;
use utf8;                                  # el literal '—' (em-dash) del regex es char, no bytes
binmode(STDOUT, ':encoding(UTF-8)');       # imprimir razones con tildes sin warnings

my ($mode, $skip_file) = @ARGV;

my @entries;   # { path, reason }
open my $fh, '<:encoding(UTF-8)', $skip_file or die "No se pudo abrir $skip_file: $!";
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*#/;        # comentarios / encabezados
    next if $line =~ /^\s*$/;        # vacías
    # Formato: raw/ruta/archivo.md — razón   (separador - o —, razón opcional)
    if ($line =~ /^\s*(raw\/.*?\.md)\s*(?:[-—]\s*(.*))?$/) {
        my ($p, $r) = ($1, $2 // '');
        $r =~ s/\s+$//;
        push @entries, { path => $p, reason => $r };
    }
}
close $fh;

@entries = sort { $a->{path} cmp $b->{path} } @entries;
my $n = scalar @entries;

if ($mode eq '--score') {
    print "SKIP=$n\n";
    exit 0;
}

if ($mode eq '--orphans') {
    my $found = 0;
    for my $e (@entries) {
        next if -f $e->{path};       # sigue existiendo → no es huérfano
        print "$e->{path}\n";
        $found++;
    }
    print "# No hay vetos huérfanos — todo lo vetado aún existe en raw/\n" unless $found;
    exit 0;
}

if ($n == 0) {
    print "# Sin fuentes vetadas en wiki/.skip-sources.md\n";
    exit 0;
}

if ($mode eq '--paths') {
    print "$_->{path}\n" for @entries;
    exit 0;
}

# report: path — razón
for my $e (@entries) {
    if (length $e->{reason}) {
        print "$e->{path} — $e->{reason}\n";
    } else {
        print "$e->{path}\n";
    }
}
PERL
