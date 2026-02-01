#!/bin/bash

mkdir -p files/cv
cp -r cv/out/* files/cv/

bundle exec jekyll build

# Copy _site/ to docs/ for GitHub Pages
mkdir -p docs
cp -r _site/* docs/
git add docs
