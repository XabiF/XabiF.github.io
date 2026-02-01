#!/bin/bash

bundle exec jekyll build

# Copy _site/ to docs/ for GitHub Pages
mkdir -p docs
cp -r _site/* docs/
