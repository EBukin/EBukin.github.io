# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Quarto website (personal academic site for Eddie Bukin) that also typesets three CV PDFs
with Typst. There is no R, Python, or executable code in any chunk — rendering is pure
Quarto/Pandoc/Typst, and there is no test suite or linter.

## Commands

Fonts are not committed and must be fetched once after cloning; without `fonts/` the Typst
builds silently fall back to Typst's defaults and the PDFs stop matching the web design:

```powershell
.\scripts\fetch-fonts.ps1     # Windows
```
```bash
bash scripts/fetch-fonts.sh   # macOS / Linux / Git Bash
```

Both read `scripts/fonts.txt`, write to `fonts/` (gitignored), and skip files already present.

```bash
quarto preview                # local server, live reload
quarto render                 # full site -> _site/, including the three CV PDFs
quarto render cv/cv-full.qmd  # one CV only
quarto render index.qmd       # one page only
```

Local Quarto is 1.10.x; CI pins 1.9.37 (`.github/workflows/publish.yml`).

## Architecture

**Pages.** Each `.qmd` at the root is one navbar page (`index`, `cv`, `publications`,
`projects`, `teaching`, `notes`), wired up in `_quarto.yml`. `notes.qmd` is a Quarto listing
over `notes/`, with RSS (`feed: true`) emitted as `_site/notes.xml`.

**CV PDFs.** `cv/` holds three Typst-only documents that render to `_site/cv/cv-*.pdf`.
`cv/_metadata.yml` applies `font-paths: ../fonts` to every file in the directory;
`cv/_typst-style.typ` is included in each CV's header and carries the entire PDF design.
`index.qmd` and `cv.qmd` link to `cv/cv-*.pdf`, so anything short of a full `quarto render`
leaves those links dead in `_site/`.

**`_templates/`** holds the reusable rendering machinery — Lua shortcodes and filters, and any
Pandoc or Typst templates added later. Nothing in it is a page; Quarto ignores `_`-prefixed
directories when building `_site/`. Register anything added here in `_quarto.yml` (`shortcodes:`
or `filters:`), with paths relative to the project root.

**Publications are data.** `_publications.yml` is the single source for every publication on
the site and in the PDFs. `_quarto.yml` merges it into all page metadata (`metadata-files:`)
and registers `_templates/pubs.lua`, which implements the `{{< pubs >}}` shortcode. The
shortcode picks entries and typesets them per format — `.pub` rows for HTML, reference-list
bullets for Typst:

```
{{< pubs type=article >}}                one type, or "working-paper,report"
{{< pubs selected=true >}}               entries flagged `selected: true`
{{< pubs selected=true titles=short >}}  prefer `title-short:` where defined
{{< pubs type=article limit=5 >}}        cap the list
{{< pubs type=thesis show=full >}}       none | summary (default) | full
```

`show=` controls how much of an entry's prose is printed: `summary` adds the one-line
`summary:` to the citation, `full` also prints the `description:` paragraph. On the web a
`description:` forces the row into a `.pub-entry` wrapper (block content cannot nest inside
the `.pub` anchor), so `styles.scss` carries `.pub-entry` / `.pub-more` alongside `.pub`.

Never hand-write a publication row. Add the entry to `_publications.yml` and it appears
wherever the matching shortcode already runs (`publications.qmd`, `index.qmd`,
`cv/cv-academic.qmd`, `cv/cv-short.qmd`). Field documentation is in the file's header comment.
Because Pandoc parses YAML scalars as Markdown, a title is written `CO~2~` once and comes out
as `<sub>2</sub>` in HTML and `CO#sub[2]` in Typst — do not write format-specific syntax there.

**Duplicated facts, by design.** Everything *except* publications still exists twice: as HTML
(`index.qmd`, `cv.qmd`) and as Typst (`cv/cv-*.qmd`). `cv-full.qmd` is the source of record;
`cv-short.qmd` and `cv-academic.qmd` are edited-down selections of it. A change to a position
or degree generally has to land in several files — check all of them rather than assuming one
place. When the CV sources change, bump the `cv-updated:` metadata field in `cv.qmd`
(surfaced on the page via `{{< meta cv-updated >}}`).

Prose that crosses the two worlds still needs different syntax: subscripts are `CO~2~` in the
HTML `.qmd` files and `CO#sub[2]` in the Typst ones.

**Design system.** `styles.scss` is the whole theme — Bootstrap 5 variable overrides in the
`scss:defaults` block, then ~190 lines of rules. There are no per-page stylesheets. Pages are
built by composing the semantic classes it defines, so a new section should reuse them rather
than introduce CSS:

- Layout: `.hero`, `.section-split` (sticky label left / content right), `.card-grid`
- Type: `.eyebrow`, `.display-name`, `.lede`, `.meta`, `.rule-short`
- Components: `.flat-card` (+ `.featured`), `.chips` with `.chip` / `.chip-out`,
  `.btn-flat` / `.btn-outline-flat` / `.btn-quiet` (+ `.qty` for the trailing count),
  `.timeline` (CV entries are raw `<details>`/`<summary>` HTML), `.pub`

A publication row is a single Markdown link wrapping nested spans, ending in `{.pub}`:

```
[[2025]{.yr}[[Title]{.ttl}[Author, A., [Bukin, E.]{.me} · *Journal* 158, 107741]{.aut}]{}](https://doi.org/…){.pub}
```

Colors and fonts are defined once in `styles.scss` (accent `#8C3B2E`, ink `#111111`) and
mirrored as literals in `cv/_typst-style.typ` — change both together. HTML pulls Spectral and
IBM Plex Sans from the Google Fonts CDN; the PDFs use the local `fonts/` copies. IBM Plex is
pinned to v6.4.0 in `fonts.txt` because google/fonts ships only a variable build, which Typst
renders at a single weight.

## Publishing

`.github/workflows/publish.yml` is **manual only** — `workflow_dispatch`, with the `push:`
trigger commented out. Merging to `main` publishes nothing. README.md documents the three
steps to go live (enable Pages with source "GitHub Actions", run the workflow by hand, then
uncomment `push:`).

## Known placeholders

`href="#"` appears deliberately in several places pending real values: the Scholar / ORCID /
LinkedIn links in `_quarto.yml`, the 2021 IFAMAR DOI in `publications.qmd`, and entries with
no public URL. The two food notes in `notes/` are template carry-overs, and
`images/notes/` does not exist yet, so their `image:` paths resolve to nothing.
