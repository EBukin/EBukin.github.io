# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Quarto website (personal academic site for Eddie Bukin) that also typesets two CV PDFs
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
quarto render                 # full site -> _site/, including both CV PDFs
quarto render cv/cv-full.qmd  # one CV only
quarto render index.qmd       # one page only
```

Local Quarto is 1.10.x; CI pins 1.9.37 (`.github/workflows/publish.yml`).

## Architecture

**Pages.** Each `.qmd` at the root is one navbar page (`index`, `cv`, `publications`,
`projects`, `teaching`, `notes`), wired up in `_quarto.yml`. `notes.qmd` is a Quarto listing
over `notes/`, with RSS (`feed: true`) emitted as `_site/notes.xml`.

**CV PDFs.** `cv/` holds two Typst-only documents that render to `_site/cv/cv-*.pdf`.
Neither has any YAML frontmatter: `cv/_metadata.yml` carries the whole format block for
the directory — `format: typst:` (which is also what overrides the project's
`format: html:` here), `include-in-header: _typst-style.typ`, `font-paths: ../fonts`, and
`shift-heading-level-by: 0`. That last one is pinned rather than defaulted because Quarto
shifts headings down a level when a document has a `title:` and leaves them alone when it
has not; fixing it at zero means `##` in the source is level 2 in the show rules whatever
Quarto would otherwise decide. `index.qmd` and `cv.qmd` link to `cv/cv-*.pdf`, so anything
short of a full `quarto render` leaves those links dead in `_site/`.

**The PDF design** is `cv/_typst-style.typ`, and it is a plain-Typst adaptation of
[modern-cv](https://typst.app/universe/package/modern-cv/) — itself a port of Awesome-CV:
centred name over one contact line, accent-coloured section headings each ruled off, every
entry a two-column grid with the role left and the dates hard right. It is an adaptation
rather than the package because modern-cv expects to own the document (`resume()` takes the
whole CV as structured arguments) whereas here Pandoc has already turned `_cv.yml` into
Typst markup, and because an `@preview` import would put a package download — and, for its
FontAwesome icons, a second font family — into every render including CI. IBM Plex Sans is
named without a fallback list on purpose: Typst has no generic `sans-serif`, so any
fallback would have to name a system font and would then warn on whichever platform has not
got it.

**The hierarchy is two things: a size ladder and a left-indent ladder.** Both are declared
as named constants at the top of `cv/_typst-style.typ` rather than as literals scattered
through the show rules, so the design can be read off the file. Two rules govern them:

- Nothing below an entry heading is ever as large as that heading. The entry title is the
  biggest thing inside a section, the employer line is smaller, and the prose smaller
  again — `size-title` > `size-place` > `size-body`. If body text ever reads as large as a
  role heading, that ordering has been broken.
- The left edge carries as much of the structure as the sizes do. Section headings (`##`)
  and entry titles sit at the margin, under the full-width rule; every piece of prose is
  indented by `indent-detail` inside `#cv-detail[…]`; bullet lists step in once more by
  `indent-list`. The right edge is justified against the section rules.

The file defines five functions that `_templates/cv.lua` calls — `cv-body`, `cv-header`,
`cv-entry`, `cv-detail`, `cv-note` — and three things about it are load-bearing and easy to
break:

- **`cv-body` is applied from the body, not set in the preamble.** Quarto's own Typst
  template runs *after* the header include and does `set par(justify: …, leading:
  linestretch * 0.65em)`, so anything set above it loses. `{{< cv-header >}}` emits
  `#show: cv-body` as its first block to have the last word on size, leading and
  justification. Setting those in the preamble instead silently gets you Quarto's.
- **`cv-detail` is emitted as a pair of raw blocks around real Pandoc blocks**, not as one
  string, because an entry's body may be paragraphs and bullet lists and writing those is
  still Pandoc's job. `cv.lua`'s `cv_detail()` wraps every entry body, every flat list and
  every profile paragraph; anything that stops going through it will silently fall back out
  to the left margin.
- **`cv-entry`'s `above:` / `below:` are the only spacing around an entry.** Pandoc writes
  the `#cv-entry(…)` call and what follows it into a single Typst paragraph, so no
  paragraph spacing is added between them.

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
`summary:` (its own `.sum` line on the web, run into the citation in the CVs), `full` also
prints the `description:` paragraph.

A web row takes one of three shapes, all handled in `web_row`:

- **inert** — no `page:`, `url:` or `doi:`. A `<div class="pub">`, deliberately not a link;
  a placeholder `href="#"` would only bounce the reader to the top of the page.
- **link** — `<a class="pub">` over the whole row. It points at `page:` if set, else `url:`,
  else `doi:` — most specific first, so adding a `page:` takes the row over from the DOI.
  `page:` is a site-root-relative source path (`notes/foo.qmd`); the shortcode rewrites the
  extension to `.html`.
- **disclosure** — an entry with a `description:` under `show=full`. Raw
  `<details class="pub-entry">` / `<summary class="pub">` with a `.plus`, the same pattern
  `cv.qmd` uses for its timeline. Clicking expands rather than navigates, so the outbound
  link moves onto the title. Block content cannot nest inside an `<a>` anyway.

`styles.scss` carries `.sum`, `.plus`, `.pub-entry` and `.pub-more` alongside `.pub`, and
scopes the hover tint to `a.pub` / `summary.pub` so inert rows stay inert.

Never hand-write a publication row. Add the entry to `_publications.yml` and it appears
wherever the matching shortcode already runs (`publications.qmd`, `index.qmd`, and both
CVs). Field documentation is in the file's header comment. Two things about which CV prints
what: `selected: true` now reaches only `index.qmd` — both CVs select by `type:` instead —
and **neither CV prints `type: conference`**, deliberately; those entries live on
`publications.qmd` alone. The full CV groups articles, working papers and work in progress,
reports, and theses under `###` subheadings; the short CV prints the same groups minus
theses, with trimmed titles.
Because Pandoc parses YAML scalars as Markdown, a title is written `CO~2~` once and comes out
as `<sub>2</sub>` in HTML and `CO#sub[2]` in Typst — do not write format-specific syntax there.

**The CV is data.** `_cv.yml` is the sibling of `_publications.yml` and the single source for
every position, degree, course, skill, language, scholarship, contact link and paragraph of
CV prose — on `cv.qmd` and in both PDFs alike. Neither `cv/cv-full.qmd` nor `cv/cv-short.qmd`
states a single fact about the person: what is left in them is section headings and shortcode
calls, which is to say the choice of sections and how deep to print each. `_quarto.yml` merges
the file into all page metadata and registers `_templates/cv.lua`, which implements the
`{{< cv >}}` shortcode:

```
{{< cv type=experience >}}          one type, or "skills,languages" (required)
{{< cv type=education in=short >}}  keep only entries whose `in:` names this variant
{{< cv type=teaching show=full >}}  none | summary (default) | full
{{< cv type=experience titles=short >}}  prefer `title-short:` / `place-short:`
{{< cv type=experience limit=3 >}}  cap the list
```

Three shapes of entry, told apart by `type:`:

- **dated** — `experience`, `education`, `teaching`. `period:` / `title:` / `place:` (each
  of the latter two with an optional `-short` twin, used only at `titles=short` so the
  two-page CV keeps its headings to one line), a
  one-sentence `summary:`, a Markdown `description:` that may carry paragraphs and bullet
  lists, and an optional `references:` line printed only in the PDFs and only at `show=full`.
  HTML gets a `<details class="cv-entry">` timeline row; Typst gets a `#cv-entry()` call with
  the three fields passed separately, followed by the prose.
- **flat** — `skills`, `languages`, `scholarships`. Only `items:`, a list of strings. Rendered
  as `.chip-out` chips on the web and as one ` · `-joined paragraph in the PDFs; `show=` does
  not apply to them.
- **prose** — `profile`. Only `text:`, the `## About` / `## Profile` paragraph at the top of a
  CV, one entry per variant chosen with `in:`. The one shape that comes out identically in
  both formats, and `show=` does not apply to it either.

`_templates/cv.lua` also provides two shortcodes that take no entries at all:

- `{{< cv-header >}}` — the identity block at the top of each PDF: name, headline, current
  appointments, contact line, all of it read from `cv-me:` in `_cv.yml`, plus the
  `#show: cv-body` rule and the `#set document(title:)` line that gives the PDF its own
  metadata title (injected with `quarto.doc.include_text`, guarded by a module-level flag
  because Quarto runs the shortcode filter over a document more than once). It renders
  nothing on the web — `cv.qmd` sits under the site navbar and its own hero already. Note
  what is deliberately *not* in `cv-me.links`: no postal address, no phone, no date of birth
  and no email, only what the website already publishes. Adding any of them is one entry
  there. `_quarto.yml` keeps its own copy of those URLs for the navbar and footer and cannot
  read `_cv.yml`, so those two lists are kept in step by hand.
- `{{< cv-pdf variant=short|full >}}` — the two download links in the CV page header. It
  emits an `<a download="…">` so the browser saves the file rather than opening it, named
  `<surname>-<build date>-<variant>.pdf` — the surname read from `author-me:` in
  `_publications.yml`, so there is no second place to keep it in step.

`in:` is the analogue of `selected:` in `_publications.yml`: it names the variants an entry
belongs to (`short` and `full`; omitted means both). The PDFs filter on it with
`in=`, so a CV variant is a selection, not a separate copy. Nothing is sorted — `period:` is a
display string, not a date — so entries come out in file order and reordering the CV means
moving lines in `_cv.yml`.

**A `description:` must open with the exact text of its `summary:`.** Opening an entry on the
web replaces the one sentence with the long text, so the row has to read as that sentence
growing rather than repeating itself. Nothing can enforce it, so `cv.lua` compares the two on
collapsed whitespace and logs `(W) cv: ...` at render time when they drift apart. A clean
render of the two CVs prints no such line; treat one as a defect.

`cv.qmd` is now section headings and `{{< cv >}}` calls — none of the raw `<details>` markup it
used to carry is left in the file. The Short / Full / Academic buttons are the only JavaScript
on the site: `_templates/cv-views.html`, pulled in by that page's `include-after-body:`. It
renders nothing. `{{< cv >}}` prints every entry at full depth tagged with `data-in`, and the
script hides the ones the chosen view excludes, opens the rest, and hides a `.section-split`
whose entries have all gone. Without JavaScript the buttons stay `hidden` and the page is
simply the complete CV.

**What is still written twice.** One thing: the `.lede` bio on `index.qmd`, which says the same
as the `type: profile` entries in `_cv.yml` at a third length and in the first person. It is
not generated, so a change of framing has to land there as well as in the record — check both
rather than assuming one place. Everything else about the person — positions, degrees, courses,
skills, languages, scholarships, papers, contact links, the two CV profile paragraphs — is
written down once, in `_cv.yml` or `_publications.yml`. When the CV record changes, bump
`cv-me.updated:` in `_cv.yml`; it is printed in both PDF footers and, via
`{{< meta cv-me.updated >}}`, next to the download buttons on `cv.qmd`.

Prose that crosses the two worlds still needs different syntax: subscripts are `CO~2~` in the
HTML `.qmd` files and `CO#sub[2]` in the Typst ones — but never in `_cv.yml` or
`_publications.yml`, where Markdown is parsed once and written out per format. `cv.lua`
passes those fields into its `#cv-entry(…)` / `#cv-header(…)` calls as Pandoc inlines
interleaved with raw Typst fragments (`typst_call`), precisely so that Pandoc's writer still
gets to write them and a `CO~2~` in the record comes out as Typst markup rather than as
literal text inside the call.

**Design system.** `styles.scss` is the whole theme — Bootstrap 5 variable overrides in the
`scss:defaults` block, then ~190 lines of rules. There are no per-page stylesheets. Pages are
built by composing the semantic classes it defines, so a new section should reuse them rather
than introduce CSS:

- Rhythm: `$row-pad` is the padding above and below every list row — publications, CV
  entries, the notes listing. One variable, so the three cannot drift apart; change it there
  rather than per-list. Note that Quarto's own stylesheet sets `details { margin-bottom: 1em }`,
  which silently loosens anything built on `<details>`; `details.cv-entry, details.pub-entry`
  give it back so `$row-pad` is the only thing setting the gap.
- Layout: `.hero`, `.section-split` (sticky label left / content right), `.card-grid`
- Type: `.eyebrow`, `.display-name`, `.lede`, `.meta`, `.rule-short`
- Components: `.flat-card` (+ `.featured`), `.chips` with `.chip` / `.chip-out`,
  `.btn-flat` / `.btn-outline-flat` / `.btn-quiet` (+ `.qty` for the trailing count),
  `.timeline` (CV entries are `<details>`/`<summary>`, emitted by `{{< cv >}}`), `.pub`

A publication row is a single Markdown link wrapping nested spans, ending in `{.pub}`:

```
[[2025]{.yr}[[Title]{.ttl}[Author, A., [Bukin, E.]{.me} · *Journal* 158, 107741]{.aut}]{}](https://doi.org/…){.pub}
```

Colors are defined once in `styles.scss` (accent `#8C3B2E`, ink `#111111`) and the accent is
mirrored as a literal in `cv/_typst-style.typ` — change both together. The greys there are
not the site's: they are modern-cv's own `color-darknight` and `color-gray`. Fonts diverge on
purpose. The web sets Spectral for display over IBM Plex Sans for body; the PDFs are IBM Plex
Sans throughout, because modern-cv is a sans-serif design and the CV wants the density that
gives it. HTML pulls both faces from the Google Fonts CDN; the PDFs use the local `fonts/`
copies. IBM Plex is pinned to v6.4.0 in `fonts.txt` because google/fonts ships only a variable
build, which Typst renders at a single weight — and the PDF design leans on Plex's Regular /
Medium / SemiBold separately.

## Publishing

`.github/workflows/publish.yml` is **manual only** — `workflow_dispatch`, with the `push:`
trigger commented out. Merging to `main` publishes nothing. README.md documents the three
steps to go live (enable Pages with source "GitHub Actions", run the workflow by hand, then
uncomment `push:`).

**Navbar and footer links.** Profile links live in two places in `_quarto.yml`, written two
different ways, and the difference is not cosmetic:

- `navbar: tools:` — the four icons at the top right. This is the list to extend when another
  platform is worth linking. `icon:` is a [Bootstrap Icons](https://icons.getbootstrap.com/)
  name and `text:` becomes the tooltip and the accessible label. `styles.scss` gives
  `.quarto-navbar-tools` `order: 1000` against Quarto's own `999` on `#quarto-search`, which
  is what puts the icons to the right of the search field rather than left of it — one number
  to flip if they should lead instead.

  **Icons Bootstrap Icons does not have** — Scholar and ORCID, and Hugging Face whenever it
  arrives — are drawn by `styles.scss`, not by the icon font. Naming a nonexistent icon is
  the trick: Quarto emits `<i class="bi bi-orcid">` for `icon: orcid` regardless, no
  `::before` rule matches it, so nothing is drawn and what is left is a correctly-named empty
  box. `styles.scss` then paints the real mark into it with `mask-image` and a data URI — a
  mask rather than an `<img>` so the logo takes `currentColor` and follows the same
  muted-to-accent hover as the genuine glyphs beside it. To add one: pick a name in
  `_quarto.yml`, then add a `mask-image` rule for it next to the other two.
- `page-footer: right:` — **raw HTML, deliberately.** Quarto 1.10.18 renders a footer written
  as `- icon: / text: / href:` items wrong: every item after the first comes out carrying the
  *last* item's text (four links all reading "ORCID"), and an item given both `icon:` and
  `text:` loses its icon. The navbar's `tools:` is a separate code path and handles both
  correctly. Do not "tidy" the footer back into a list without re-testing that on the Quarto
  in use. Raw HTML also bypasses `link-external-newwindow`, so each off-site footer link
  carries its own `target="_blank" rel="noopener"`, and `&` in a URL is written `&amp;`.

Navbar and footer carry the same four destinations — GitHub, LinkedIn, Scholar, ORCID — so
every one of those URLs is written twice. Keep the pairs in step. The footer shows each mark
*and* its name; the navbar is icons alone, with the name as the tooltip. The two masked
logos work in both because the `mask-image` rules are keyed on `.bi-orcid` /
`.bi-google-scholar` alone rather than being scoped to the navbar.

## Known placeholders

No `href="#"` is left anywhere in the sources — every profile link now points somewhere real.
What remains unfinished is content, not markup: eleven entries in `_publications.yml` carry no
`doi:`, `url:` or `page:` and so render as deliberately inert rows; some `description:` text is
still flagged `# EXAMPLE TEXT`; and the two food notes in `notes/` are template carry-overs
whose `image:` paths resolve to nothing, `images/notes/` not existing yet.
