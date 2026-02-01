// Imports
#import "@preview/brilliant-cv:3.1.2": cv-section, cv-skill, cv-skill-with-level, cv-skill-tag, h-bar

#cv-section("Aptitudes")

#cv-skill-with-level(
  type: [Idiomas],
  level: 4,
  info: [Español (Nativo) #h-bar() Inglés (C1) #h-bar() Euskera (B2)],
)

#cv-skill-with-level(
  type: [Tecnologías],
  level: 5,
  info: [Python #h-bar() NumPy #h-bar() C/C++ #h-bar() Qiskit #h-bar() Git #h-bar() Linux],
)

// #cv-skill(
//   type: [Certifications],
//   info: [
//     #cv-skill-tag([AWS Certified])
//     #cv-skill-tag([Google Analytics])
//     #cv-skill-tag([Tableau Desktop])
//     #cv-skill-tag([Scrum Master])
//   ],
// )

#cv-skill(
  type: [Pasatiempos],
  info: [Ingeniería inversa #h-bar() Lectura #h-bar() Cocina #h-bar() Naturaleza],
)
