# ebukin.github.io — personal site

Quarto website. Monochrome Bootstrap 5 (cosmo) with a single accent, Spectral + IBM Plex Sans.

## First run after cloning

Fonts are not committed. Fetch them once — the Typst CV builds need them on disk, and
without them the PDFs silently fall back to Typst's defaults:

```bash
bash scripts/fetch-fonts.sh        # macOS / Linux / Git Bash
```

```powershell
.\scripts\fetch-fonts.ps1          # Windows PowerShell
```

Both read `scripts/fonts.txt` and write to `fonts/` (gitignored). Re-running skips files
already present. The HTML pages pull the same families from the Google Fonts CDN, so this
step only affects the PDFs.

## Build

```bash
quarto preview          # local, live reload
quarto render           # -> _site/  (includes the three CV PDFs)
```

Requires Quarto 1.9+. No R or Python — the site has no executable code chunks.

## CV PDFs

The two CVs live in `cv/` and render with Typst (bundled with Quarto — no LaTeX needed):

```bash
quarto render cv/cv-short.qmd
quarto render cv/cv-full.qmd
```

The three files are section headings and shortcode calls: `{{< cv >}}` pulls the entries
out of `_cv.yml` and `{{< pubs >}}` the papers out of `_publications.yml`, each variant
asking for the subset and the depth it wants. Shared styling is in `cv/_typst-style.typ`, and
`cv/_metadata.yml` points Typst at `fonts/`. The PDFs are linked from `index.qmd` and
`cv.qmd` as `cv/cv-*.pdf`, so a full `quarto render` is what publishing needs.

## Adding a publication

Publications are data, not markup. Add one entry to `_publications.yml`:

```yaml
  - type: article          # article | wip | working-paper | report | conference | thesis
    year: 2026
    title: "Full title, with Markdown — subscripts as CO~2~"
    authors: ["Coauthor, A.", "Bukin, E.", "Coauthor, B."]
    journal: "Land Use Policy"
    detail: "165, 107976"
    doi: "10.1016/…"       # or url: for anything without a DOI
    page: notes/my-note.qmd  # a page on this site; takes the row over from the DOI
    selected: true         # also show on the home page and in the short CV
    summary: "One line, on its own line under the authors."
    description: >-
      Optional paragraph. Collapsed behind a + on pages that ask for show=full.
```

A row links to `page`, else `url`, else `doi`. An entry with none of the three is not a
link — it renders as an inert row rather than one that goes nowhere.

It then appears everywhere the `{{< pubs >}}` shortcode already selects it — the publications
page, the home page, and the CV PDFs — with no other file to edit. The shortcode is
`_templates/pubs.lua`; `_quarto.yml` wires both up. Field-by-field documentation is in the
header comment of `_publications.yml`.

Use `url:` instead of `doi:` for anything without one — a reproducibility package, a data
catalogue entry, a conference programme.

## Adding a CV entry

The CV is data too. Add one entry to `_cv.yml`, in the place it should read — nothing is
sorted, `period:` is a display string. A dated entry:

```yaml
  - type: experience     # experience | education | teaching
    period: "Feb 2025 — present"
    title: "Economist, Global Poverty Department"
    title-short: "Economist (ETC2)"        # optional, only the two-page CV uses it
    place: "The World Bank · Washington DC"
    place-short: "The World Bank"          # optional, same rule
    in: [short, full]    # which CVs keep it; omitted means all three
    summary: "One sentence — the whole entry in the short CV, and the collapsed row on the web."
    description: |
      One sentence — the whole entry in the short CV, and the collapsed row on the web.
      Then the long version: paragraphs, links and bullet lists all work.
    references: "Name; Name"   # optional, printed only in the full PDF
```

`description:` must open with the exact text of `summary:`, because opening the entry on the
web replaces the one sentence with the long text — the row should read as the sentence
growing, not repeating itself. `_templates/cv.lua` warns at render time if the two drift.

A flat list — skills, languages, scholarships — has no dates and nothing to disclose:

```yaml
  - type: skills         # skills | languages | scholarships
    in: [short, full]
    items:
      - "R and R Shiny, package development (12+ yrs)"
      - "Stata (10+ yrs)"
```

It then appears wherever the `{{< cv >}}` shortcode already selects it — the timeline on
`cv.qmd` and the sections of the CV PDFs — with no other file to edit:

```
{{< cv type=experience >}}                one type, or "skills,languages" (required)
{{< cv type=education in=short >}}        only entries whose `in:` names this variant
{{< cv type=teaching show=full >}}        none | summary (default) | full
{{< cv type=experience titles=short >}}   prefer the `-short` fields
{{< cv type=experience limit=3 >}}        cap the list
```

The same file provides `{{< cv-pdf variant=short >}}`, which writes one of the two PDF
download links in the page header. It exists as a shortcode so the saved file is named
for the reader — `cv-short.pdf` on the server arrives as `Bukin-2026-09-08-short.pdf` —
and so the link carries `download`, which is what makes the browser save the PDF instead
of opening it in a tab. The surname comes from `author-me:` in `_publications.yml` and
the date is the day the site was built.

`show=` decides how much of an entry's prose is printed: `summary` the one sentence, `full`
the whole `description:` plus the `references:` line. The shortcode is `_templates/cv.lua`,
the sibling of `pubs.lua`; `_quarto.yml` wires both up. Field-by-field documentation is in
the header comment of `_cv.yml`.

## Structure

| File | Page |
| --- | --- |
| `index.qmd` | Home — bio, current focus, selected work, CV downloads |
| `cv.qmd` | Web CV — expandable timeline |
| `publications.qmd` | Everything, grouped by type |
| `projects.qmd` | Research streams + software |
| `teaching.qmd` | JLU courses + ai4coding |
| `notes.qmd` + `notes/` | Research and food notes (Quarto listing, RSS enabled) |
| `_publications.yml` | The publication record — the only place papers are written down |
| `_cv.yml` | The CV record — positions, degrees, courses, skills, languages, scholarships |
| `_templates/` | Reusable rendering machinery — the `{{< pubs >}}` and `{{< cv >}}` Lua shortcodes, plus `cv-views.html`, the switcher script `cv.qmd` includes |
| `styles.scss` | The whole theme — Bootstrap variable overrides + ~200 lines of rules |

## Publishing

`.github/workflows/publish.yml` renders the site and deploys it to GitHub Pages. It is
**manual only** — the workflow has no push trigger, so merging to `main` publishes nothing
until the steps below are taken deliberately.

To go live:

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.** Pages is currently
   disabled on this repo; nothing is served until this is set.
2. Run the workflow once by hand: **Actions → Publish site → Run workflow**. Confirm the
   deployed site looks right.
3. Only then, uncomment the `push:` block in `.github/workflows/publish.yml` to publish on
   every push to `main`.

A custom domain would need a `CNAME` file at the repo root plus the DNS records; the old
Jekyll site's `CNAME` was empty, so there is nothing to carry over.

Manual one-off alternative, no Actions involved:

```bash
quarto publish gh-pages
```

## To do

- Replace the placeholder `summary:` / `description:` example text in `_publications.yml`
  (the entries carrying it are flagged with an `# EXAMPLE TEXT` comment).
- Replace the two placeholder food notes carried over from the template.
- Drop photos into `images/notes/` for the food notes.
- Re-check the `[n p]` page counts on the CV download buttons in `cv.qmd` after any
  substantial edit to `_cv.yml` — they are currently correct at 2 / 4 / 3.
