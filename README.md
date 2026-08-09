# ebukin.github.io — personal site

Quarto website. Monochrome Bootstrap 5 (cosmo) with a single accent, Spectral + IBM Plex Sans.

## Build

```bash
quarto preview          # local, live reload
quarto render           # -> _site/
```

## CV PDFs

The three CVs live in `cv/` and render with Typst (bundled with Quarto — no LaTeX needed):

```bash
quarto render cv/cv-short.qmd
quarto render cv/cv-full.qmd
quarto render cv/cv-academic.qmd
```

`cv-full.qmd` is the source of record; the short and academic versions are edited-down
selections of the same material. Shared styling is in `cv/_typst-style.typ`.

Note: `cv/` is listed under `project.render` exclusions in spirit — the PDFs are linked from
`index.qmd` and `cv.qmd` as `cv/cv-*.pdf`, so render them before publishing.

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

```bash
quarto publish gh-pages
```

## To do

- Add real Scholar / ORCID / LinkedIn URLs in `_quarto.yml`.
- Drop photos into `images/notes/` for the food notes.
