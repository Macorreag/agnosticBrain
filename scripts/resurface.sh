#!/usr/bin/env bash
#
# resurface.sh — Resurfacing proactivo de notas wiki/ HACIA EL HUMANO.
#
# graph_health.sh mide la salud del grafo hacia la MÁQUINA (qué debe refactorizar
# el agente). Este script hace lo complementario, que era el hueco: te muestra a
# VOS 1-2 notas viejas que quizás olvidaste, para que las reconectes con algo
# nuevo, las cures (/curate) o las archives (/archive). Es el gap con más
# convergencia de toda la investigación externa — BASB/Readwise ("weekly review"
# + resurfacing aleatorio), herramientas de memoria ("Heads Up"), RemNote/Logseq (repetición
# espaciada) apuntan al mismo lugar.
#
# NO es repetición espaciada real (SM-2/FSRS): es una heurística simple y honesta.
# Una nota es más candidata a resurfacing cuanto más vieja Y más aislada esté:
#
#   score = antiguedad_dias + bonus_aislamiento
#     antiguedad_dias   : hoy - `updated:` del frontmatter
#                         (fallback: `created:`, luego mtime del archivo; se reporta cuál se usó)
#     bonus_aislamiento : +60 si 0 backlinks (huérfana), +20 si 1 backlink, si no +0
#                         (una nota que nadie enlaza "envejece" más rápido a la vista)
#
#   backlink = otra nota wiki/ que la enlaza con [[...]] (se cuentan fuentes
#              distintas; se excluyen index.md/log.md/_gaps.md y las
#              autoreferencias; los MOC sí cuentan). El vault no guarda timestamp
#              de cada enlace, así que "enlaces recientes" se aproxima honestamente
#              por "cantidad de backlinks".
#
# Solo entran notas con antiguedad >= --min-age dias (default 14): lo que tocaste
# esta quincena sigue fresco en tu cabeza y no necesita resurfacing.
#
# Uso:
#   bash scripts/resurface.sh                 # 1-2 notas candidatas, con el porqué
#   bash scripts/resurface.sh --score         # una línea para /status (RESURFACE=…)
#   bash scripts/resurface.sh --num 3         # cuántas notas resurfacing (default 2)
#   bash scripts/resurface.sh --min-age 30    # antiguedad mínima en días (default 14)
#   bash scripts/resurface.sh --random        # serendipia estilo Readwise: elige al azar
#                                             #   entre las más candidatas (no siempre las mismas)
#   bash scripts/resurface.sh --help
#
# Env (opcional): RESURFACE_NUM, RESURFACE_MIN_AGE, RESURFACE_SEED (semilla de --random).
#
# Integración: /status puede correr este script para mostrarte 1-2 notas a
#   reconectar (ver SKILLS/status.md). NO tiene trigger automático: lo corrés vos.
#
# Read-only: nunca modifica ningún archivo del vault.
#
set -euo pipefail

# Ruta absoluta a este script (antes del cd) para poder imprimir la ayuda.
self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

print_help() {
  awk 'NR==1 && /^#!/ {next} /^#/ {sub(/^# ?/,""); print; next} {exit}' "$self"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

mode="report"
want_random=0
num="${RESURFACE_NUM:-2}"
min_age="${RESURFACE_MIN_AGE:-14}"
seed="${RESURFACE_SEED:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --score)     mode="score" ;;
    --random)    want_random=1 ;;
    -n|--num)    shift; num="${1:-}" ;;
    --min-age)   shift; min_age="${1:-}" ;;
    --seed)      shift; seed="${1:-}" ;;
    -h|--help)   print_help; exit 0 ;;
    *)           : ;;   # ignorar desconocidos (compat con la familia de scripts)
  esac
  shift || true
done

cd "$(dirname "$0")/.." 2>/dev/null || true

perl - "$mode" "$want_random" "$num" "$min_age" "$seed" <<'PERL'
use strict;
use warnings;
use utf8;                              # los literales con tildes/emoji del reporte son chars
use POSIX qw(mktime);
use File::stat ();
use List::Util qw(shuffle);
binmode(STDOUT, ':encoding(UTF-8)');   # imprimir tildes/emoji sin warnings

my ($mode, $want_random, $num, $min_age, $seed) = @ARGV;
$mode        //= 'report';
$want_random //= 0;
$num     = (defined $num     && $num     =~ /^\d+$/) ? int($num)     : 2;
$num     = 2 if $num < 1;
$min_age = (defined $min_age && $min_age =~ /^\d+$/) ? int($min_age) : 14;
srand(int($seed)) if defined $seed && $seed =~ /^\d+$/;

my $now = time;

# ── helpers ──────────────────────────────────────────────────────────────────
sub ymd_epoch {
    my ($d) = @_;
    return undef unless defined $d && $d =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    # mediodía local: evita saltos de un día por DST/medianoche al dividir en días
    return mktime(0, 0, 12, int($3), int($2) - 1, int($1) - 1900);
}

sub strip_fences {   # quita bloques ``` para no contar enlaces de ejemplos de código
    my ($c) = @_;
    my ($out, $in) = ('', 0);
    for my $line (split /\n/, $c, -1) {
        if ($line =~ /^```/) { $in = !$in; next; }
        $out .= "$line\n" unless $in;
    }
    return $out;
}

sub fm_field {       # lee un campo escalar del frontmatter YAML
    my ($fm, $key) = @_;
    return undef unless $fm =~ /^\Q$key\E:\s*(.*?)\s*$/m;
    my $v = $1;
    $v =~ s/^["']//; $v =~ s/["']$//;     # quitar comillas envolventes
    $v =~ s/\s+$//;
    return length $v ? $v : undef;
}

# ── 1. Cargar notas wiki/ candidatas ─────────────────────────────────────────
my @files = glob("wiki/*.md");   # glob '*' no matchea dotfiles (.skip-sources.md queda fuera)
my %skip  = map { $_ => 1 } qw(wiki/index.md wiki/log.md wiki/_gaps.md);

my @notes;
for my $f (@files) {
    next if $skip{$f};
    next if $f =~ m{/lint-\d};    # reportes de lint
    next if $f =~ m{/_};          # _gaps, _proposed u otros archivos de sistema

    open my $fh, '<:encoding(UTF-8)', $f or next;
    local $/; my $c = <$fh>; close $fh;

    my $base = $f; $base =~ s{^wiki/}{}; $base =~ s{\.md$}{};

    my $fm    = ($c =~ /\A---\s*\n(.*?)\n---\s*\n/s) ? $1 : $c;
    my $title = fm_field($fm, 'title')       // $base;
    my $type  = fm_field($fm, 'type')        // 'nota';
    my $dom   = fm_field($fm, 'domain')      // '';
    my $desc  = fm_field($fm, 'description') // '';
    my $upd   = fm_field($fm, 'updated');
    my $crt   = fm_field($fm, 'created');

    push @notes, {
        f => $f, base => $base, title => $title, type => $type,
        domain => $dom, desc => $desc, updated => $upd, created => $crt,
        body => strip_fences($c),
    };
}

my $total = scalar @notes;

# ── 2. Contar backlinks (fuentes distintas que enlazan cada nota) ────────────
my %links;   # target_base => { source_base => 1 }
for my $n (@notes) {
    while ($n->{body} =~ /\[\[([^\]\|\#]+)(?:[#\|][^\]]*)?\]\]/g) {
        my $t = $1;
        $t =~ s/\\//g;                # desescapar la pipe de tablas: [[wiki/x\|alias]]
        $t =~ s/^\s+//; $t =~ s/\s+$//;
        next if $t =~ m{^raw/};       # las citas a raw/ no son enlaces del grafo wiki
        $t =~ s{^wiki/}{};
        $t =~ s{\.md$}{};
        next if $t eq $n->{base};     # autoreferencia no cuenta
        $links{$t}{ $n->{base} } = 1;
    }
}

# ── 3. Calcular candidatos con score ─────────────────────────────────────────
my @cand;
for my $n (@notes) {
    my ($epoch, $src);
    if    (defined($epoch = ymd_epoch($n->{updated}))) { $src = 'updated'; }
    elsif (defined($epoch = ymd_epoch($n->{created}))) { $src = 'created'; }
    else {
        my $st = File::stat::stat($n->{f});
        $epoch = $st ? $st->mtime : $now;
        $src   = 'mtime';
    }

    my $age = int(($now - $epoch) / 86400);
    $age = 0 if $age < 0;

    next if $age < $min_age;          # fresco → no es candidato a resurfacing

    my $bl    = $links{ $n->{base} } ? scalar keys %{ $links{ $n->{base} } } : 0;
    my $bonus = $bl == 0 ? 60 : $bl == 1 ? 20 : 0;

    push @cand, {
        base => $n->{base}, type => $n->{type}, domain => $n->{domain},
        desc => $n->{desc},
        age => $age, date_src => $src,
        date_str  => ($src eq 'mtime' ? '' : ($n->{$src} // '')),
        backlinks => $bl,
        score     => $age + $bonus,
    };
}

# orden determinista: score desc, luego antiguedad desc, backlinks asc, nombre asc
@cand = sort {
       $b->{score}     <=> $a->{score}
    || $b->{age}       <=> $a->{age}
    || $a->{backlinks} <=> $b->{backlinks}
    || $a->{base}      cmp $b->{base}
} @cand;

my $eligible = scalar @cand;

# ── 4. Selección ─────────────────────────────────────────────────────────────
my @pick;
if ($want_random && $eligible) {
    # Serendipia acotada (estilo Readwise): baraja el pool de las más candidatas
    # y toma N. Sesgado a viejas/aisladas (el pool ya viene rankeado) pero no
    # siempre las mismas. Reproducible si se pasa RESURFACE_SEED.
    my $pool_n = $num * 3;
    $pool_n = 6        if $pool_n < 6;
    $pool_n = $eligible if $pool_n > $eligible;
    my @pool = @cand[0 .. $pool_n - 1];
    my $take = $num < $pool_n ? $num : $pool_n;
    @pick = (shuffle @pool)[0 .. $take - 1];
    # mostrar en orden de score para legibilidad
    @pick = sort { $b->{score} <=> $a->{score} || $a->{base} cmp $b->{base} } @pick;
} elsif ($eligible) {
    my $take = $num < $eligible ? $num : $eligible;
    @pick = @cand[0 .. $take - 1];
}

# ── 5. Salida ────────────────────────────────────────────────────────────────
if ($mode eq 'score') {
    if (!@pick) {
        print $total == 0
            ? "RESURFACE=none (sin notas wiki/)\n"
            : "RESURFACE=none (todo revisado < ${min_age}d)\n";
        exit 0;
    }
    my $t     = $pick[0];
    my $extra = $eligible - 1;
    my $tail  = $extra > 0 ? " (+$extra candidata" . ($extra == 1 ? '' : 's') . ")" : '';
    printf "RESURFACE=%s — %dd sin revisar, %d backlink%s%s\n",
        $t->{base}, $t->{age}, $t->{backlinks}, ($t->{backlinks} == 1 ? '' : 's'), $tail;
    exit 0;
}

# --- modo report ---
if (!@pick) {
    print $total == 0
        ? "# wiki/ todavía no tiene notas — nada que resurfacing.\n"
        : "# Nada para resurfacing: las $total nota(s) de wiki/ se revisaron hace < ${min_age}d.\n";
    exit 0;
}

my $shown = scalar @pick;
printf "🔁 Resurfacing — %d nota%s que quizás olvidaste (de %d candidata%s · reconectá con lo nuevo)\n\n",
    $shown, ($shown == 1 ? '' : 's'), $eligible, ($eligible == 1 ? '' : 's');

my $i = 0;
for my $n (@pick) {
    $i++;
    my $meta = $n->{type};
    $meta .= " · $n->{domain}" if length $n->{domain};
    printf "  %d. [[wiki/%s]]  ·  %s\n", $i, $n->{base}, $meta;

    print "     ", (length $n->{desc} ? $n->{desc} : '(sin description en frontmatter)'), "\n";

    my $when = $n->{date_src} eq 'updated' ? "$n->{age}d desde updated ($n->{date_str})"
             : $n->{date_src} eq 'created' ? "$n->{age}d desde created ($n->{date_str}) · sin updated"
             :                               "$n->{age}d desde mtime del archivo · sin fechas en frontmatter";

    my $iso = $n->{backlinks} == 0 ? ' — huérfana (nadie la enlaza)'
            : $n->{backlinks} == 1 ? ' — sub-enlazada'
            :                        '';

    printf "     %s · %d backlink%s%s\n",
        $when, $n->{backlinks}, ($n->{backlinks} == 1 ? '' : 's'), $iso;

    print "     → ¿sigue vigente? reconectala con una nota nueva, o /curate, o /archive\n\n";
}

print "Tip: no es repetición espaciada real; es una señal simple (antiguedad + aislamiento). --random para serendipia.\n";
PERL
