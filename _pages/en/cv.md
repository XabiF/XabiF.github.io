---
layout: archive
title: "CV"
permalink: /cv/
author_profile: true
lang: en
redirect_from:
  - /resume
---

{% include base_path %}

{% include pre-print.html %}

<div class="print-tip">
  <blockquote>
    <p>Print this page to get my CV in PDF format!</p>
    <button class="btn btn--inverse" onclick="print()">Print CV</button>
  </blockquote>
  
</div>

## Education

* MSc in Quantum Science and Technology, UPV/EHU, 2024-2025
* Degree in Physics, UPV/EHU, 2020-2024

## Work experience

* May-September 2025: Internship at Ayesa, Ibermática (I3B)
  * Research on different approaches to simulate Navier-Stokes fluids through Quantum Computing ([MSc's thesis](/pubs))
  * Supervised by Dr. Aitor Moreno Fernández de Leceta

## Expertise

* LaTeX
* Software control: git / GitHub, Visual Studio Code
* Software development: C++, Python and more
* Operating Systems: Linux, Windows

## Skills

* Creativity
* Problem resolution
* Critical thinking

## Languages

* Spanish: native
* English: C1
* Basque: B2

## Publications

  <ul>{% for post in site.pubs reversed %}
    {% include archive-single-cv.html %}
  {% endfor %}</ul>
  
## Talks

  <ul>{% for post in site.talks reversed %}
    {% include archive-single-talk-cv.html  %}
  {% endfor %}</ul>

<!--
Teaching
======
  <ul>{% for post in site.teaching reversed %}
    {% include archive-single-cv.html %}
  {% endfor %}</ul>
-->  
