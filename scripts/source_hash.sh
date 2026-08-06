#!/usr/bin/env bash
#
# source_hash.sh — Hash canónico de una fuente raw/ para el ledger de compilación.
#
# Imprime el fingerprint de contenido de una fuente, en el formato exacto que se
# embebe en la línea `Fuentes:` de wiki/log.md:
#
#     sha256:<64 hex en minúsculas>
#
# DEFINICIÓN CANÓNICA (no cambiar sin migrar a la vez stale_sources.sh):
#   SHA-256 de los BYTES CRUDOS del archivo, sin ninguna normalización
#   (sin tocar frontmatter, line-endings ni encoding). El archivo raw/ solo lo
#   edita el humano (REGLA 2: raw/ es inmutable para el agente), así que no hay
#   churn auto-inducido: un cambio de hash == un cambio real de contenido.
#
# POR QUÉ HASH Y NO mtime:
#   El vault está bajo sincronización en la nube, cuya sincronización re-toca mtime sin cambiar
#   el contenido. El hash detecta el cambio REAL y es determinista (mismo
#   contenido → mismo hash, independiente de reloj, zona horaria o sync).
#
# QUIÉN LO USA (misma definición a ambos lados → comparación confiable):
#   /ingest          → embebe `(sha256:…)` en la línea `Fuentes:` del log al compilar.
#   stale_sources.sh → recomputa el hash actual y lo compara contra el registrado.
#
# Uso:
#   bash scripts/source_hash.sh raw/ruta/archivo.md           # → sha256:abc…
#   bash scripts/source_hash.sh raw/a.md raw/b.md             # → una línea "path<TAB>sha256:…" por archivo
#   bash scripts/source_hash.sh --line raw/a.md               # → "Fuentes: `raw/a.md` (sha256:…)" lista para pegar
#   bash scripts/source_hash.sh --help
#
# Read-only: nunca modifica ningún archivo. Solo lee y hashea.
#
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -eq 0 ]]; then
  grep '^#' "$0" | sed 's/^# \?//' | head -34
  exit 0
fi

cd "$(dirname "$0")/.." 2>/dev/null || true

line_mode=0
if [[ "${1:-}" == "--line" ]]; then
  line_mode=1
  shift
fi

if [[ $# -eq 0 ]]; then
  echo "source_hash.sh: falta el path de la fuente raw/" >&2
  exit 2
fi

# Hashea con Perl Digest::SHA (módulo core, portable, sin shell-out por archivo).
# Misma rutina exacta que stale_sources.sh para garantizar hashes idénticos.
perl - "$line_mode" "$@" <<'PERL'
use strict; use warnings;
use Digest::SHA ();

my $line_mode = shift @ARGV;
my @files     = @ARGV;
my $multi     = (@files > 1);
my $rc        = 0;

for my $path (@files) {
    $path =~ s{^\./}{};                       # normalizar ./raw/ → raw/

    if ($path !~ m{^raw/}) {
        warn "source_hash.sh: '$path' no está bajo raw/ — se omite\n";
        $rc = 2;
        next;
    }
    unless (-f $path) {
        warn "source_hash.sh: '$path' no existe o no es un archivo — se omite\n";
        $rc = 2;
        next;
    }

    my $d = Digest::SHA->new(256);
    eval { $d->addfile($path); 1 }
        or do { warn "source_hash.sh: no se pudo leer '$path': $@\n"; $rc = 2; next; };

    my $sha = 'sha256:' . $d->hexdigest;      # bytes crudos, hex minúsculas

    if ($line_mode) {
        print "Fuentes: `$path` ($sha)\n";
    } elsif ($multi) {
        print "$path\t$sha\n";
    } else {
        print "$sha\n";
    }
}

exit $rc;
PERL
