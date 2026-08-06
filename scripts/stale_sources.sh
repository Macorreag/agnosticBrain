#!/usr/bin/env bash
#
# stale_sources.sh — Fuentes raw/ que CAMBIARON desde su último ingest compilado.
#
# Una fuente está STALE cuando fue compilada al menos una vez (aparece en el
# ledger wiki/log.md) Y su contenido actual difiere del que se compiló. La forma
# de detectar "difiere" depende de qué registró el log:
#
#   • MODO HASH (preferido) — si la línea `Fuentes:` del último ingest registró el
#     fingerprint `(sha256:…)`: se recomputa el hash actual (misma definición que
#     scripts/source_hash.sh) y se compara. STALE ⇔ el hash cambió. Es preciso e
#     inmune al ruido de mtime que mete la sincronización en la nube.
#
#   • MODO mtime (fallback retrocompatible) — si esa compilación NO registró sha
#     (entradas legacy previas a esta feature, o líneas sin backticks): se vuelve
#     a la heurística histórica: STALE ⇔ mtime > timestamp_compilación + 120 s
#     (margen anti-skew de reloj). Se reemplaza por hash en el próximo /ingest.
#
# La distinción clave con pending_sources.sh:
#   pending_sources.sh  → fuentes que NUNCA se compilaron  (conocimiento nuevo)
#   stale_sources.sh    → fuentes compiladas y LUEGO modificadas  (conocimiento desactualizado)
#
# Uso:
#   bash scripts/stale_sources.sh              # lista de fuentes stale, ordenada por prioridad
#   bash scripts/stale_sources.sh --score      # una línea: STALE=N  (para /status y /compose)
#   bash scripts/stale_sources.sh --full       # añade nota wiki/ afectada + antigüedad + método (hash|mtime)
#   bash scripts/stale_sources.sh --help       # este texto
#
# Priorización de la lista:
#   1. Fuentes que alimentan notas curated/  (⚠️ urgente: cambio → _proposed/, no update silencioso)
#   2. Por días de antigüedad descendente    (más vieja la divergencia → más urgente atenderla)
#
# Integración con operaciones:
#   /status  → bash scripts/stale_sources.sh --score     (Paso 1 del dashboard)
#   /compose → bash scripts/stale_sources.sh             (Paso 1 del loop, junto a pending_sources.sh)
#   /ingest  → escribe `(sha256:…)` en la línea `Fuentes:` del log (habilita MODO HASH a futuro)
#
# Formato de log que habilita el MODO HASH (lo escribe /ingest · ver SKILLS/ingest.md):
#   Fuentes: `raw/ruta/archivo.md` (sha256:<64hex>) — <nota opcional>
#   El paréntesis `(sha256:…)` debe ir inmediatamente después del path entre backticks.
#   Paréntesis descriptivos `(otra cosa)` NO interfieren: solo cuenta el prefijo sha256:.
#
# NO BACKFILL: este script nunca inventa hashes para entradas viejas, y el log es
#   append-only (REGLA 5). Hashear hoy un archivo y declararlo "el de la compilación
#   pasada" sería falso si cambió en el medio → marcaría como fresco algo realmente
#   stale. Los hashes se pueblan solos al recompilar; hasta entonces, MODO mtime.
#
# Auto-mantenido: no requiere cambios cuando el log crece o se agregan fuentes.
#   Todo se deriva del ledger wiki/log.md, del hash de contenido y del mtime real.
#
# Read-only: nunca modifica ningún archivo.
#
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  grep '^#' "$0" | sed 's/^# \?//' | head -52
  exit 0
fi

log_file="wiki/log.md"
skip_file="wiki/.skip-sources.md"
mode="${1:-report}"

cd "$(dirname "$0")/.." 2>/dev/null || true

# Validar que el log existe
if [[ ! -f "$log_file" ]]; then
  [[ "$mode" == "--score" ]] && echo "STALE=0" || echo "# wiki/log.md no encontrado"
  exit 0
fi

# Construir skip set desde .skip-sources.md
tmp_skip="$(mktemp)"
trap 'rm -f "$tmp_skip"' EXIT

if [[ -f "$skip_file" ]]; then
  perl -nE 'say $1 if /^\s*(raw\/.*?\.md)(?:\s+(?:-|—).*)?$/' "$skip_file" \
    | LC_ALL=C sort -u > "$tmp_skip"
fi

perl - "$mode" "$log_file" "$tmp_skip" <<'PERL'
use strict; use warnings;
use POSIX qw(mktime);
use File::stat ();
use Digest::SHA ();

my ($mode, $log_file, $skip_file) = @ARGV;

# Hash canónico — DEBE coincidir byte a byte con scripts/source_hash.sh:
# SHA-256 de los bytes crudos del archivo, prefijado "sha256:".
sub file_sha256 {
    my ($path) = @_;
    my $d = Digest::SHA->new(256);
    eval { $d->addfile($path); 1 } or return undef;
    return 'sha256:' . $d->hexdigest;
}

# ── 1. Cargar skip set ───────────────────────────────────────────────────────
my %skip;
if (open my $sf, '<', $skip_file) {
    while (<$sf>) { chomp; $skip{$_} = 1 if /\S/; }
    close $sf;
}

# ── 2. Parsear el log ────────────────────────────────────────────────────────
#   last_compiled{path} = epoch del ÚLTIMO ingest que compiló la fuente
#   last_hash{path}     = sha registrado en ESA última compilación (undef si no lo tuvo)
#
# Solo captura líneas "Fuentes: …" (ingest/gaps, puede traer `(sha256:…)`) — es el
# único formato de log documentado (SKILLS/ingest.md, SKILLS/gaps.md) que lista paths
# raw/. NO captura "Páginas creadas/actualizadas:" (listan notas wiki/, no paths raw/,
# así que nunca aportan nada acá) ni "Contexto revisado:" (lectura, no compilación).
#
my %last_compiled;
my %last_hash;
my $cur_epoch = 0;

if (open my $fh, '<:encoding(UTF-8)', $log_file) {
    while (my $line = <$fh>) {
        chomp $line;

        # Timestamp de sección: ## [2026-06-11 22:30] …
        if ($line =~ /^##\s+\[(\d{4}-\d{2}-\d{2})(?:\s+(\d{2}):(\d{2}))?\]/) {
            my ($date, $hh, $mm) = ($1, $2 // '23', $3 // '59');
            my ($y, $mo, $d) = split /-/, $date;
            # mktime usa zona local (coherente con el mtime de los archivos)
            $cur_epoch = mktime(0, int($mm), int($hh), int($d), int($mo)-1, int($y)-1900);
            next;
        }

        next unless $line =~ /^Fuentes[:\s]/i;

        # Mapa por-línea: path → sha (sha puede ser undef). Evita que el fallback
        # sin-backticks pise con undef un path que ya trae sha en la misma línea.
        my %lp;

        # (a) Con backticks + sha opcional inmediatamente después:
        #     `raw/x.md` (sha256:<64hex>)
        while ($line =~ /`(raw\/[^`]+?\.md)`(?:\s*\((sha256:[0-9a-fA-F]{64})\))?/g) {
            my ($p, $s) = ($1, $2);
            $p =~ s{^\./}{};
            next unless $p =~ m{^raw/};
            next if $skip{$p};
            $s = lc $s if defined $s;
            # En la misma línea: un sha definido siempre gana sobre undef.
            if (!exists $lp{$p} || (defined $s && !defined $lp{$p})) {
                $lp{$p} = $s;
            }
        }

        # (b) Sin backticks (líneas históricas sueltas) — nunca con sha:
        for my $raw ($line =~ /\b(raw\/\S+?\.md)\b/g) {
            my $p = $raw;
            $p =~ s/[)\].,;:'"]+$//;          # limpiar puntuación trailing
            $p =~ s{^\./}{};
            next unless $p =~ m{^raw/};
            next if $skip{$p};
            $lp{$p} = undef unless exists $lp{$p};   # no pisar un sha ya capturado
        }

        # Aplicar al estado global respetando cronología (last wins por epoch).
        for my $p (keys %lp) {
            my $s = $lp{$p};
            if (!exists $last_compiled{$p} || $cur_epoch > $last_compiled{$p}) {
                $last_compiled{$p} = $cur_epoch;
                $last_hash{$p}     = $s;          # compilación más nueva: su sha (o undef)
            } elsif ($cur_epoch == $last_compiled{$p} && defined $s) {
                $last_hash{$p} = $s;              # mismo epoch: un sha definido gana
            }
        }
    }
    close $fh;
}

# ── 3. Detectar fuentes stale ────────────────────────────────────────────────
my @raw_files;
open my $find, '-|', 'find', 'raw', '-type', 'f', '-name', '*.md'
    or die "Cannot run find: $!";
while (<$find>) { chomp; push @raw_files, $_; }
close $find;

my @stale;

for my $file (sort @raw_files) {
    next unless exists $last_compiled{$file};   # nunca compilada → es pending, no stale
    next if $skip{$file};

    my $st = File::stat::stat($file) or next;
    my $mtime    = $st->mtime;
    my $compiled = $last_compiled{$file};
    my $recorded = $last_hash{$file};

    my ($is_stale, $method);

    if (defined $recorded) {
        # MODO HASH — preciso, inmune al ruido de mtime de sincronización en la nube.
        my $cur = file_sha256($file);
        if (defined $cur) {
            $is_stale = (lc($cur) ne lc($recorded)) ? 1 : 0;
            $method   = 'hash';
        } else {
            # No se pudo hashear (permiso/IO) → fallback defensivo a mtime.
            $is_stale = ($mtime > $compiled + 120) ? 1 : 0;
            $method   = 'mtime';
        }
    } else {
        # MODO mtime — entrada legacy sin sha registrado.
        $is_stale = ($mtime > $compiled + 120) ? 1 : 0;
        $method   = 'mtime';
    }

    next unless $is_stale;

    # Antigüedad: mtime es el mejor proxy de "cuándo cambió". Clamp a >= 0 por si
    # el hash detecta cambio pero el mtime quedó atrás (Drive restaurando mtimes).
    my $delta_s = $mtime - $compiled;
    $delta_s = 0 if $delta_s < 0;

    push @stale, {
        path        => $file,
        mtime       => $mtime,
        compiled    => $compiled,
        days_stale  => int($delta_s / 86400),
        hours_stale => int($delta_s / 3600),
        method      => $method,
    };
}

# ── 4. Detectar si alguna nota curated/ cita estas fuentes ───────────────────
my %curated_cites;   # raw/path → curated/nota.md  (primera coincidencia)

for my $cf (glob('curated/*.md')) {
    open my $fh, '<:encoding(UTF-8)', $cf or next;
    local $/; my $c = <$fh>; close $fh;

    # Citas inline: [[raw/algo]] o [[raw/algo|alias]]
    while ($c =~ /\[\[(raw\/[^\]|]+?)(?:\|[^\]]*)?\]\]/g) {
        my $p = $1;
        $p =~ s/\\//g;                   # desescapar pipes que escapó el formato de tabla
        $curated_cites{$p} //= $cf;
    }
    # Frontmatter sources: (formato YAML lista o string)
    while ($c =~ /^\s+-\s+(raw\/[^\n]+\.md)/mg) {
        $curated_cites{$1} //= $cf;
    }
    while ($c =~ /sources:\s+"?(raw\/[^\n"]+\.md)"?/mg) {
        $curated_cites{$1} //= $cf;
    }
}

# ── 5. Ordenar: ⚠️ curated-afectada primero, luego por antigüedad desc ────────
@stale = sort {
    my $ac = exists $curated_cites{$a->{path}} ? 1 : 0;
    my $bc = exists $curated_cites{$b->{path}} ? 1 : 0;
    return $bc <=> $ac if $ac != $bc;
    return $b->{days_stale} <=> $a->{days_stale};
} @stale;

# ── 6. Output ─────────────────────────────────────────────────────────────────
my $n = scalar @stale;

if ($mode eq '--score') {
    print "STALE=$n\n";
    exit 0;
}

if ($n == 0) {
    print "# No hay fuentes stale — raw/ está sincronizado con wiki/\n";
    exit 0;
}

for my $s (@stale) {
    my $cn = $curated_cites{$s->{path}} // '';
    $cn =~ s{^curated/}{} if $cn;

    if ($mode eq '--full') {
        my $age = $s->{days_stale} > 0
            ? sprintf('%dd', $s->{days_stale})
            : sprintf('%dh', $s->{hours_stale});

        if ($cn) {
            printf "%-72s  [%s, %s]  ← ⚠️  curated: %s\n", $s->{path}, $age, $s->{method}, $cn;
        } else {
            printf "%-72s  [%s, %s]\n", $s->{path}, $age, $s->{method};
        }
    } else {
        # modo report: una línea limpia, lista para pasar a /ingest
        if ($cn) {
            print "$s->{path}  ← ⚠️  curated: $cn\n";
        } else {
            print "$s->{path}\n";
        }
    }
}
PERL
