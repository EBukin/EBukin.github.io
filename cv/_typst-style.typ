// The PDF design for both CV variants, plus the three functions the {{< cv-header >}}
// and {{< cv >}} shortcodes call. cv/_metadata.yml includes this file in the header of
// every document in this directory, so neither .qmd names it.
//
// A plain-Typst adaptation of modern-cv (typst.app/universe/package/modern-cv), itself
// a port of the Awesome-CV LaTeX template: a centred name over one contact line,
// accent-coloured section headings each ruled off, and every entry a two-column grid —
// role and employer on the left, dates hard right.
//
// An adaptation rather than the package itself, for two reasons. modern-cv expects to
// own the document: its `resume()` takes the whole CV as structured arguments, whereas
// here Pandoc has already turned _cv.yml into Typst markup, so what is wanted is show
// rules over that markup plus the functions the shortcodes call. And `#import "@preview/
// modern-cv"` would put a package download — and, for its FontAwesome icons, a second
// font family — into every render including CI, where fonts/ is built by
// scripts/fetch-fonts.sh and nothing else is fetched.
//
// Colours are mirrored as literals from styles.scss; change both together. The greys
// are modern-cv's own (color-darknight, color-gray).

#let accent = rgb("#8C3B2E")  // $accent in styles.scss
#let ink    = rgb("#131A28")  // modern-cv color-darknight
#let muted  = rgb("#5D5D5D")  // modern-cv color-gray
#let soft   = rgb("#B3B3B3")  // the · between contact links
#let hair   = rgb("#DADADA")  // the rule under a section heading

// The size ladder, written down in one place so the hierarchy can be read off it
// rather than reconstructed from a dozen scattered literals. Every step down is a real
// step, and nothing below an entry heading is ever as large as that heading: the entry
// title is the largest thing in a section, and its prose is smaller than it.
//
//   16.0  name
//   10.5  headline · section heading (`##`)
//    9.6  entry title
//    9.0  entry employer/place
//    8.5  body, bullets, publication citations, flat lists
//    8.2  period · subsection heading (`###`) · positions line
//    7.8  contact links · references note · page footer
#let size-name     = 16pt
#let size-headline = 10.5pt
#let size-section  = 10.5pt
#let size-title    = 9.6pt
#let size-place    = 9pt
#let size-body     = 8.5pt
#let size-small    = 8.2pt
#let size-tiny     = 7.8pt

// Detail prose sits indented from the left margin, which the section headings and entry
// titles hold; bullet lists step in once more from there. Left alignment is the spine of
// the hierarchy, in other words, and not only size.
#let indent-detail = 11pt
#let indent-list   = 9pt

#let body-leading = 0.62em
#let list-leading = 0.56em

// modern-cv sets Source Sans 3 over Roboto. IBM Plex Sans is the site's own body face
// and the closest thing in fonts/, so it does the work of both. Spectral is
// deliberately unused here: modern-cv is a sans-serif design throughout, and the CV
// wants the density that gives it.
//
// One family and no fallback list on purpose. Typst has no generic `sans-serif`, so
// any fallback would have to name a system font — and it would then warn "unknown
// font family" on every platform that has not got it, which is Windows or CI in turn.
// fonts/ is a build prerequisite here (scripts/fetch-fonts.*), not a nicety.
#let sans = "IBM Plex Sans"

// Written once by #cv-header and read back by the page footer, which is laid out
// before the body reaches it — hence `.final()` rather than `.get()`.
#let cv-meta = state("cv-meta", (:))

#set page(
  paper: "a4",
  margin: (left: 15mm, right: 15mm, top: 13mm, bottom: 13mm),
  footer: context {
    let m = cv-meta.final()
    set text(font: sans, size: size-tiny, fill: muted)
    grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      m.at("footline", default: []),
      counter(page).display("1 / 1", both: true),
    )
  },
)

#set text(font: sans, fill: ink, lang: "en")

// modern-cv's bullet: small, accent, tight against its text. `indent` is what steps a
// list in from whatever holds it — the left margin for the publication lists, the
// already-indented detail column inside #cv-detail — and the tight `spacing` is what
// makes a run of bullets read as one condensed block rather than as separate paragraphs.
#set list(indent: indent-list, body-indent: 5pt, spacing: 0.38em,
          marker: text(fill: accent, size: 7.5pt)[•])

#show link: it => text(fill: accent, it)

// The size, leading and justification of the running text — applied from the body by
// {{< cv-header >}} as `#show: cv-body`, not set here, because Quarto's own Typst
// template runs after this header include and sets `par(justify:, leading:)` itself.
// Anything set above it loses; these are the rules that have to be the last word.
//
// Justified, so the block of prose squares off against the right margin the way the
// section rules do. Hyphenation comes with that and is wanted: at this measure,
// justifying without it opens rivers between the words instead.
#let cv-body(doc) = {
  set text(size: size-body)
  set par(justify: true, leading: body-leading, spacing: body-leading)
  set list(spacing: 0.38em)
  show list: it => { set par(leading: list-leading); it }
  doc
}

// The prose belonging to one entry — a summary sentence, a description with its bullet
// lists, a references note — indented as a column of its own so that the left margin is
// carrying the hierarchy and not just the type sizes. {{< cv >}} wraps every entry's
// body, every flat list and every profile paragraph in one of these.
//
// A list inside it steps in again by `indent-list`, so bullets sit right of the detail
// text, which sits right of the entry title, which sits at the margin under the rule.
#let cv-detail(body) = block(
  above: 3.5pt, below: 0pt, width: 100%,
  pad(left: indent-detail, body),
)

// `##` in the .qmd. cv/_metadata.yml pins shift-heading-level-by: 0, so the levels
// here are the ones written in the source rather than whatever Quarto would shift
// them to when a document has or has not got a `title:`.
#show heading.where(level: 2): it => block(
  above: 14pt, below: 6pt, width: 100%, breakable: false, sticky: true,
  {
    text(font: sans, size: size-section, weight: 600, fill: accent, tracking: 1pt,
         upper(it.body))
    v(2.5pt, weak: true)
    line(length: 100%, stroke: 0.7pt + hair)
  },
)

// `###` — a group inside a section, which the publication lists use in both variants.
// Smaller than an entry title on purpose: it labels a group, it does not head an item.
#show heading.where(level: 3): it => block(
  above: 10pt, below: 4.5pt, breakable: false, sticky: true,
  text(font: sans, size: size-small, weight: 600, fill: muted, tracking: 0.9pt,
       upper(it.body)),
)

// The identity block, called once per document by {{< cv-header >}} with every
// argument filled from `cv-me:` in _cv.yml. `first` / `last` are split from `name:`
// so the surname can carry the weight, as it does in Awesome-CV.
// Laid out as an explicit stack rather than as four paragraphs: the gaps between
// these lines are a fixed part of the design, and paragraph spacing is not — Quarto's
// template has an opinion about that one.
#let cv-header(
  first: none,
  last: none,
  headline: none,
  positions: (),
  links: (),
  footline: none,
) = {
  cv-meta.update(m => (footline: footline))

  let lines = (
    text(font: sans, size: size-name, fill: ink, tracking: 0.2pt, {
      if first != none { text(weight: 400, first) + h(0.28em) }
      text(weight: 600, last)
    }),
  )
  if headline != none {
    lines.push(text(size: size-headline, weight: 500, fill: accent, headline))
  }
  if positions.len() > 0 {
    lines.push(text(size: size-small, fill: muted, positions.join([ · ])))
  }
  if links.len() > 0 {
    lines.push(text(size: size-tiny, fill: muted, links.join(text(fill: soft)[ · ])))
  }

  block(above: 0pt, below: 13pt, width: 100%, {
    set align(center)
    set par(leading: 0.55em, spacing: 0pt)
    stack(spacing: 4.5pt, ..lines)
  })
}

// One dated entry: role over employer at the left margin, period right-aligned against
// the section rule. The period gets its own column rather than trailing the title, so a
// long role wraps inside the left column instead of dragging the dates with it.
//
// Role and employer are both semibold — the pair is the heading of the entry, and the
// prose under it is smaller than either. They are told apart by size and colour, not by
// weight, and neither is italic: italics at this size read as emphasis inside the
// running text rather than as a second heading line.
#let cv-entry(title: none, place: none, period: none) = {
  let cells = (
    text(size: size-title, weight: 600, fill: ink,
         if title == none { [] } else { title }),
    text(size: size-small, fill: muted, if period == none { [] } else { period }),
  )
  if place != none {
    cells.push(text(size: size-place, weight: 600, fill: accent, place))
    cells.push([])
  }
  block(
    above: 9pt, below: 0pt, width: 100%, breakable: false, sticky: true,
    grid(
      columns: (1fr, auto),
      column-gutter: 10pt,
      row-gutter: 2.5pt,
      align: (left + top, right + top),
      ..cells,
    ),
  )
}

// The `references:` line an entry can carry: an aside about the entry above it, not
// part of its prose, so it is set smaller and greyer.
#let cv-note(body) = block(above: 4pt, below: 0pt,
                           text(size: size-tiny, fill: muted, body))
