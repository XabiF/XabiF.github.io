#!/bin/bash

# Avoid recursive adding of docs inside docs etc, ensure we regenerate everything
rm -rf docs

bundle exec jekyll build --incremental

# Copy _site/ to docs/ for GitHub Pages
mkdir -p docs
cp -r _site/* docs/
git add docs
