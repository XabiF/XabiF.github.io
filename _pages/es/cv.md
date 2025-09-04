---
layout: archive
title: "CV"
permalink: /cv/
author_profile: true
lang: es
redirect_from:
  - /resume
---

{% include base_path %}

{% include pre-print.html %}

<div class="print-tip">
  <blockquote>
    <p>Imprime esta página para obtener mi CV en formato PDF!</p>
    <button class="btn btn--inverse" onclick="print()">Imprimir CV</button>
  </blockquote>
  
</div>

## Educación

* Máster en Ciencia y Tecnología Cuábticas, UPV/EHU, 2024-2025
* Grado en Física, UPV/EHU, 2020-2024

## Experiencia laboral

* Mayo-Septiembre 2025: Prácticas en Ayesa, Ibermática (I3B)
  * Investigación de distintos métodos de simulación de fluidos de Navier-Stokes mediante la Computación Cuántica ([TFM](/pubs))
  * Supervisado por Dr. Aitor Moreno Fernández de Leceta

## Conocimientos

* LaTeX
* Control de software: git / GitHub, Visual Studio Code
* Desarrollo de software: C++, Python and more
* Sistemas Operativos: Linux, Windows

## Habilidades

* Creatividad
* Resolución de problemas
* Pensamiento crítico

## Idiomas

* Español: nativo
* Inglés: C1
* Euskera: B2

## Publicaciones

  <ul>{% for post in site.pubs reversed %}
    {% include archive-single-cv.html %}
  {% endfor %}</ul>
  
## Charlas

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
