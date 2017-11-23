---
title: Developing a Scripts in Google Apps
layout: post
tags:
  - Google Apps
  - Programming
  - phd
categories:
  - blog
---

# Brief introduction to the problem

While doing a literature review for my PhD, I have slowly become disappointed in the literature management/citations tools. In particular, such things like Mendeley were not meeting my needs to classify and structure description of research methods, questions, data and results. I wanted to tag every of these elements, but the citation tools I have tried did not allow me to do this. Therefore, I built a google form for recoding all this relevant information in a structured way.

However, having it literature information in a spreadsheet was not an option for me and I needed to combine all entered literature reviews in one document: Google doc or PDF did not make any difference for me. Therefore, I came across with the JavaScript development in the Google scripts UI.

Below, you will find some useful links and sources that helped me develop the script for generating PDFs and google docs out of the google form driven spreadsheets.

# Useful references

- Introduction on Google scripts form [Google](https://developers.google.com/apps-script/articles/);
- [Google API reference](https://developers.google.com/apps-script/reference/document/document-app);
- Main source of inspiration of scripts for a document prefilling [Open source hacker](https://opensourcehacker.com/2013/01/21/script-for-generating-google-documents-from-google-spreadsheet-data-source/);
- Some useful [scripts for google apps](https://www.labnol.org/internet/google-scripts/28281/);
- [Another google apps-script library-compilation](https://github.com/oshliaer/google-apps-script-awesome-list);
- [Moving file to a different folder script](https://ctrlq.org/code/20201-move-file-to-another-folder);
- [Merge multiple documents script](https://ctrlq.org/code/19892-merge-multiple-google-documents);
- [Huge collection of google scripts](https://ctrlq.org/code/);
- [Create PDF script](http://www.andrewroberts.net/2014/10/google-apps-script-create-pdf/);

Not useful thins I tried and did not work for me

- [autoCrat](http://cloudlab.newvisions.org/add-ons/autocrat) - is a free Google spreadsheets add-on that should help in document generation. Was not helping me though.

# Developed scripts
