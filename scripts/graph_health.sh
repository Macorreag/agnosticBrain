#!/usr/bin/env bash
#
# graph_health.sh — Termómetro del grafo de conocimiento BrainAI (REGLA 8).
#
# Mide la DEUDA del grafo de forma numérica y repetible, para que /compose y /lint
# puedan PROBAR (no suponer) que cada ciclo de auto-compilación mejoró la red.
#
# Read-only: nunca modifica nada. Idempotente: misma entrada → misma salida.
#
# Uso:
#   bash scripts/graph_health.sh            # reporte legible + DEUDA total
#   bash scripts/graph_health.sh --score    # una línea, para comparar entre ciclos de /compose
#
# Umbrales (kernel v2.3):
#   fan-in excesivo  : >12 fuentes raw distintas  O  >150 líneas
#   huérfana salida  : 0 enlaces [[wiki/...]] salientes
#   sub-enlazada     : exactamente 1 enlace saliente (densidad mínima = 2; exento: moc)
#   dominio sin MOC  : dominio con ≥3 notas y sin nota type:moc
#   monocultivo      : un type > 70% de las notas
#
set -euo pipefail

mode="report"
if [[ "${1:-}" == "--score" ]]; then mode="score"; fi

cd "$(dirname "$0")/.." 2>/dev/null || true

perl - "$mode" <<'PERL'
use strict; use warnings;

my $mode = shift // 'report';

my @files = glob("wiki/*.md");          # glob '*' no matchea dotfiles (.skip-sources.md queda fuera)
my %skip  = map { $_ => 1 } qw(wiki/index.md wiki/log.md wiki/_gaps.md);

my (@info, %type_count, %domain_notes, %moc_domains);
my $total = 0;

for my $f (@files) {
    next if $skip{$f};
    next if $f =~ m{/lint-\d};   # reportes lint
    next if $f =~ m{/_};         # _gaps, _proposed, etc.

    open my $fh, '<', $f or next;
    local $/; my $c = <$fh>; close $fh;

    my $base = $f; $base =~ s{^wiki/}{}; $base =~ s{\.md$}{};
    my ($type)   = $c =~ /^type:\s*"?([A-Za-z0-9_-]+)"?/m;
    my ($domain) = $c =~ /^domain:\s*"?([^"\n]+?)"?\s*$/m;
    $type   //= 'unknown';
    $domain //= 'sin-dominio';

    my $lines = ($c =~ tr/\n//) + 1;

    # quitar fences de código antes de contar links/citas
    my ($body, $infence) = ('', 0);
    for my $line (split /\n/, $c) {
        if ($line =~ /^```/) { $infence = !$infence; next; }
        $body .= "$line\n" unless $infence;
    }

    my %raws;
    while ($body =~ /\[\[(raw\/[^\]\#\|]+)/g) { $raws{$1} = 1; }
    my $nraw = scalar keys %raws;

    my %out;
    while ($body =~ /\[\[([^\]\#\|]+)/g) {
        my $t = $1;
        next if $t =~ m{^raw/};
        $t =~ s{^wiki/}{}; $t =~ s{\s+$}{};
        next if $t eq $base;      # auto-referencia
        next if $t =~ /^_/;       # _gaps no es nodo del grafo
        $out{$t} = 1;
    }
    my $nout = scalar keys %out;

    push @info, { f => $f, type => $type, domain => $domain,
                  nraw => $nraw, lines => $lines, nout => $nout };
    $total++;
    $type_count{$type}++;
    push @{ $domain_notes{$domain} }, $base;
    $moc_domains{$domain} = 1 if $type eq 'moc';
}

# clasificación
my (@cubes, @orphans, @under, @dom_no_moc);
for my $n (@info) {
    push @cubes, $n if (($n->{nraw} > 12 || $n->{lines} > 150) && $n->{type} ne 'moc');
    push @orphans, $n if ($n->{nout} == 0 && $n->{type} ne 'moc');
    push @under, $n if ($n->{nout} == 1 && $n->{type} ne 'moc');
}
for my $d (sort keys %domain_notes) {
    next if $d eq 'sin-dominio';
    my $k = scalar @{ $domain_notes{$d} };
    push @dom_no_moc, "$d ($k notas)" if ($k >= 3 && !$moc_domains{$d});
}

# monocultivo
my ($dom_type, $dom_n) = ('-', 0);
for (sort keys %type_count) { if ($type_count{$_} > $dom_n) { $dom_n = $type_count{$_}; $dom_type = $_; } }
my $mono_pct = $total ? int(100 * $dom_n / $total + 0.5) : 0;
my $mono = ($mono_pct > 70) ? 1 : 0;

my $debt = 5 * @cubes + 3 * @orphans + 1 * @under + 4 * @dom_no_moc + ($mono ? 10 : 0);

if ($mode eq 'score') {
    printf "DEUDA=%d | cubos=%d huerfanas=%d subenlazadas=%d dom_sin_moc=%d monocultivo=%d%% (%s) notas=%d\n",
        $debt, scalar @cubes, scalar @orphans, scalar @under, scalar @dom_no_moc, $mono_pct, $dom_type, $total;
    exit 0;
}

# ---- reporte legible ----
print "==================================================\n";
print " BrainAI · Salud del grafo (REGLA 8)\n";
print "==================================================\n";
printf " Notas analizadas        : %d\n", $total;
printf " DEUDA total del grafo   : %d   (menor = mejor; 0 = punto fijo)\n", $debt;
print  "--------------------------------------------------\n";

printf " Notas-cubo (fan-in)     : %d   [>12 fuentes raw o >150 líneas → split + MOC]\n", scalar @cubes;
for my $n (sort { $b->{nraw} <=> $a->{nraw} || $b->{lines} <=> $a->{lines} } @cubes) {
    printf "    - %-52s %2d fuentes | %3d líneas\n", $n->{f}, $n->{nraw}, $n->{lines};
}
printf " Huérfanas de salida     : %d   [0 enlaces salientes → enlazar/extraer nodo]\n", scalar @orphans;
printf "    - %s\n", $_->{f} for @orphans;
printf " Sub-enlazadas (1 link)  : %d   [densidad mínima = 2]\n", scalar @under;
printf " Dominios sin MOC        : %d   [≥3 átomos sin moc-<dominio>]\n", scalar @dom_no_moc;
printf "    - %s\n", $_ for @dom_no_moc;
print  "--------------------------------------------------\n";
print  " Histograma de type (extracción de nodos):\n";
for my $t (sort { $type_count{$b} <=> $type_count{$a} } keys %type_count) {
    my $pct = $total ? int(100 * $type_count{$t} / $total + 0.5) : 0;
    printf "    %-12s %3d  (%2d%%)\n", $t, $type_count{$t}, $pct;
}
printf " Monocultivo de tipo     : %s  (%s = %d%%, umbral 70%%)\n",
    ($mono ? "SÍ ⚠" : "no"), $dom_type, $mono_pct;
print  "==================================================\n";
if ($debt == 0) {
    print " ✓ Grafo en punto fijo: no hay deuda medible que /compose pueda bajar.\n";
} else {
    print " → /compose puede bajar esta deuda. Re-correr este script tras cada ciclo y comparar DEUDA.\n";
}
print  "==================================================\n";
PERL
