#!/usr/bin/env bash
#
# export_okf.sh — Exporta wiki/ como un bundle conformante a Open Knowledge
# Format v0.1 (Google Cloud, jun-2026): https://cloud.google.com/blog/products/
# data-analytics/how-the-open-knowledge-format-can-improve-data-sharing
#
# Por qué existe: AGENTS.md ya toma prestado el vocabulario de frontmatter de
# OKF (description/resource/tags), pero wiki/ NO es un bundle OKF conformante
# tal como está: OKF exige cross-links en markdown estándar `[texto](/ruta.md)`,
# mientras que wiki/ usa wikilinks de Obsidian `[[nota]]` a propósito (para que
# Graph View y backlinks nativos de Obsidian funcionen en el uso diario). Este
# script resuelve la tensión sin tocar el original: traduce SOLO en la copia
# exportada, dejando wiki/ intacto para seguir editando en Obsidian como siempre.
#
# Qué hace exactamente:
#   1. Copia cada nota de wiki/*.md (excluye index.md, log.md, _gaps.md, _*, lint-*.md)
#      a <outdir>/<nota>.md, preservando el frontmatter YAML tal cual — OKF exige
#      que los consumidores toleren/preserven claves desconocidas, así que los
#      campos propios de BrainAI (domain, status, sources, related, created,
#      last_agent, confidence) NO se eliminan, solo viajan como "extra".
#   2. Agrega `timestamp:` (ISO 8601) derivado de `updated` (o `created` si falta)
#      — es el único campo recomendado de OKF que BrainAI no tenía ya.
#   3. Traduce wikilinks internos [[wiki/nota]] / [[nota#sección|alias]] a
#      markdown estándar `[alias](nota.md#sección)`, porque el bundle exportado
#      ya no vive en Obsidian y OKF no entiende `[[...]]`.
#   4. Deja intactas las citas [[raw/...]] (no son parte del bundle exportado;
#      no hay archivo destino dentro del bundle al que enlazar).
#   5. Genera <outdir>/index.md — listado plano `- [title](nota.md) — description`,
#      el "directory listing para progressive disclosure" que pide el reserved
#      filename de OKF.
#
# Alcance deliberado (v1): solo wiki/, no curated/. Es de solo lectura sobre el
# vault real — nunca escribe dentro de wiki/, raw/, curated/ ni archivo/.
#
# Uso:
#   bash scripts/export_okf.sh [outdir]     # default: okf-export/ (gitignored)
#
# Para qué sirve tener esto: poder probar el bundle contra cualquier herramienta
# que hable OKF (p.ej. el visualizador HTML de referencia del estándar, o un
# agente de un tercero) sin migrar el vault ni renunciar a Obsidian en el uso diario.
#
set -euo pipefail

cd "$(dirname "$0")/.." 2>/dev/null || true

OUTDIR="${1:-okf-export}"
mkdir -p "$OUTDIR"

perl - "$OUTDIR" <<'PERL'
use strict; use warnings;
use utf8;                              # el literal '—'/'→' de este script es char, no bytes
use POSIX qw(strftime);
binmode(STDOUT, ':encoding(UTF-8)');

my ($outdir) = @ARGV;

my @files = glob("wiki/*.md");
my %skip  = map { $_ => 1 } qw(wiki/index.md wiki/log.md wiki/_gaps.md);

my @index_lines;
my $n = 0;

for my $f (@files) {
    next if $skip{$f};
    next if $f =~ m{/lint-\d};
    next if $f =~ m{/_};

    open my $fh, '<:encoding(UTF-8)', $f or next;
    local $/; my $c = <$fh>; close $fh;

    my $base = $f; $base =~ s{^wiki/}{}; $base =~ s{\.md$}{};

    my ($fm, $body) = ($c =~ /\A---\s*\n(.*?)\n---\s*\n(.*)\z/s) ? ($1, $2) : ('', $c);

    my ($title)       = $fm =~ /^title:\s*"?(.*?)"?\s*$/m;
    my ($description) = $fm =~ /^description:\s*"?(.*?)"?\s*$/m;
    my ($updated)      = $fm =~ /^updated:\s*"?(\d{4}-\d{2}-\d{2})"?/m;
    my ($created)      = $fm =~ /^created:\s*"?(\d{4}-\d{2}-\d{2})"?/m;
    $title //= $base;

    my $date = $updated // $created;
    my $timestamp = $date ? "${date}T00:00:00Z" : strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);

    # Traducir wikilinks internos [[wiki/nota#sección|alias]] / [[nota]] a markdown
    # estándar. Deja [[raw/...]] intactas (no forman parte del bundle exportado).
    $body =~ s{
        \[\[
          (?:wiki/)?([^\]\#\|]+?)     # 1: nombre de nota (sin prefijo wiki/, sin # ni |)
          (?:\#([^\]\|]+))?           # 2: sección opcional
          (?:\|([^\]]+))?             # 3: alias opcional
        \]\]
    }{
        my ($note, $section, $alias) = ($1, $2, $3);
        if ($note =~ m{^raw/}) {
            "[[$note" . (defined $section ? "#$section" : '') . (defined $alias ? "|$alias" : '') . "]]";
        } else {
            $note =~ s{\s+$}{};
            my $text = defined $alias ? $alias : $note;
            my $frag = defined $section ? "#$section" : '';
            "[$text]($note.md$frag)";
        }
    }gex;

    # Frontmatter: preservar tal cual + agregar timestamp OKF si no existía.
    my $fm_out = $fm;
    $fm_out .= "\ntimestamp: \"$timestamp\"" unless $fm =~ /^timestamp:/m;

    open my $out, '>:encoding(UTF-8)', "$outdir/$base.md" or die "No se pudo escribir $outdir/$base.md: $!";
    print $out "---\n$fm_out\n---\n$body";
    close $out;

    push @index_lines, "- [$title]($base.md)" . (defined $description ? " — $description" : '');
    $n++;
}

open my $idx, '>:encoding(UTF-8)', "$outdir/index.md" or die $!;
print $idx "# OKF bundle — exportado de agnosticBrain/wiki/\n\n";
print $idx "> Generado por scripts/export_okf.sh. wiki/ sigue siendo la fuente de verdad;\n";
print $idx "> esta carpeta es una traducción de solo lectura, no se edita a mano.\n\n";
print $idx "$_\n" for sort @index_lines;
close $idx;

print "OKF bundle exportado: $n concepto(s) → $outdir/\n";
PERL
