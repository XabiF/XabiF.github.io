#!/bin/bash

mkdir -p files/cv
cp -r cv/out/* files/cv/

bundle exec jekyll serve
