#set page(
  paper: "a4",
  margin: (x: 18mm, y: 18mm),
  numbering: "1 / 1",
)
#set text(font: ("Spectral", "Georgia"), size: 9.5pt, fill: rgb("#2A2A2A"))
#set par(justify: false, leading: 0.62em)

#show heading.where(level: 1): it => block(
  above: 0pt, below: 10pt,
  text(font: "Spectral", size: 24pt, weight: 300, fill: rgb("#111111"), it.body),
)
#show heading.where(level: 2): it => block(
  above: 16pt, below: 7pt,
  stack(
    spacing: 5pt,
    text(font: "IBM Plex Sans", size: 7.5pt, weight: 500,
         tracking: 1.6pt, fill: rgb("#8C3B2E"), upper(it.body)),
    line(length: 100%, stroke: 0.5pt + rgb("#E4E4E4")),
  ),
)
#show heading.where(level: 3): it => block(
  above: 10pt, below: 3pt,
  text(font: "Spectral", size: 11.5pt, weight: 400, fill: rgb("#111111"), it.body),
)
#show link: it => text(fill: rgb("#8C3B2E"), it)
