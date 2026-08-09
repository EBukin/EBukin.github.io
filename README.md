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

The three CVs live in `cv/` and render with Typst (bundled with Quarto — no LaTeX needed):

```bash
quarto render cv/cv-short.qmd
quarto render cv/cv-full.qmd
quarto render cv/cv-academic.qmd
```

`cv-full.qmd` is the source of record; the short and academic versions are edited-down
selections of the same material. Shared styling is in `cv/_typst-style.typ`, and
`cv/_metadata.yml` points Typst at `fonts/`. The PDFs are linked from `index.qmd` and
`cv.qmd` as `cv/cv-*.pdf`, so a full `quarto render` is what publishing needs.

## Structure

| File | Page |
| --- | --- |
| `index.qmd` | Home — bio, current focus, selected work, CV downloads |
| `cv.qmd` | Web CV — expandable timeline |
| `publications.qmd` | Everything, grouped by type |
| `projects.qmd` | Research streams + software |
| `teaching.qmd` | JLU courses + ai4coding |
| `notes.qmd` + `notes/` | Food notes (Quarto listing, RSS enabled) |
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

- Add real Scholar / ORCID / LinkedIn URLs in `_quarto.yml` (currently `#`).
- Fill in the DOI for the 2021 IFAMAR paper in `publications.qmd` (currently `#`).
- Replace the two placeholder food notes carried over from the template.
- Drop photos into `images/notes/` for the food notes.
