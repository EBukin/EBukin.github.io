---
title:  "Writing documents and thesis in markdown"
layout: post
tags:
  - PhD
  - markdowd
categories:
  - blog
---

When I started my PhD in October 2017 (it was only 2 month ago) I was certain about one thing: I need to stop using Microsoft Word and Excel for my private needs and everyday work that do not include collaboration with and dependency on others. I also wanted to use git in order to track versions of my work. Therefore, I found a solution in developing my work in **Markdown**. Below, I document my journey through Markdown, R Markdown and LaTeX, what and how I use it.

# Getting started

I stated working with `.md` because of `R`. Once I had to document some results of my statistical analysis and I used R markdown for that. Ever since then, I was infected by the simplicity and (quasi-) robustness of markdown and wanted to use it for everyday work.

* [Slow introduction to R Markdown](http://rmarkdown.rstudio.com/lesson-1.html)
* [R for data science - R Markdown](http://r4ds.had.co.nz/r-markdown.html)
* [On of the markdown cheat-sheets](https://guides.github.com/features/mastering-markdown/);

Then, I slowly realized that using R Studio for writing and documenting work all the time is not the best thing to do because it destructs allot. Therefore, I decided to to find a way of using pure markdown with more control over layout and direct usage of pandoc.

* [Markdown template for the PhD thesis](https://github.com/tompollard/phd_thesis_markdown);
* [Personal experience of a dude about using Markdown for writing thesis](https://bartschat.github.io/post/thesis_workflow/);
* [Pandoc users guide](http://pandoc.org/MANUAL.html);

# Actual work or how have I managed to do this

1. Prepare bibliography file in one folder - exporting relevant data to one .bibtex file.

1. Download the templates and explore all possible and nicely prepared templates on the pandoc github [pandoc Wiki](https://github.com/jgm/pandoc/wiki).

  - [Various pandoc examples and templates](https://github.com/Wandmalfarbe/pandoc-latex-template/tree/master/examples)
  - [thesis in markdown](https://github.com/chiakaivalya/thesis-markdown-pandoc) - and a corresponding [blog post](https://chiakaivalya.wordpress.com/2014/04/23/using-markdown-pandoc-to-write-my-biology-phd-thesis/)
  - [another thesis in markdown](https://github.com/tompollard/phd_thesis_markdown)
  - Tufte styled handouts [tamplate](https://github.com/wcaleb/pandoc-templates/blob/master/handout.tex)

  There were several problems with dependencies and additional packages. In particular, I had to install pandoc-citeproc with `sudo apt-get install pandoc-citeproc` and texlive-latex-extra with some important libraries `sudo apt-get -y install texlive-latex-extra`.

1. To convert markdown document into a `pdf` I use [Tufte styled handouts template](https://github.com/wcaleb/pandoc-templates/blob/master/handout.tex). In the markdown document, in the YAML header I specify `links-as-notes: true` and `linenos: true`.

1. to run the code, I use two commands:
  - windows `pandoc 2018-proposal.md -s -o output/2018-proposal.pdf --template ~/.pandoc/templates/handout.tex --bibliography /c/Users/bukin/Documents/projects/PhD-library.bib`
  - Ubuntu `pandoc 2017-proposal/2018-proposal.md -s -o 2017-proposal/output/2018-proposal.pdf --template ~/projects/phd-notebook/pandoc/templates/handout.tex --bibliography ~/projects/phd-notebook/library.bib`
