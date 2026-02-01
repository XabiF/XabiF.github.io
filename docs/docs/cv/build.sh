#!/bin/bash

OUTDIR=out

mkdir -p "$OUTDIR"

typst compile cv.typ --input language=en "$OUTDIR/cv-en.pdf"
typst compile cv.typ --input language=es "$OUTDIR/cv-es.pdf"
