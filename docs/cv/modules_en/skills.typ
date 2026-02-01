// Imports
#import "@preview/brilliant-cv:3.1.2": cv-section, cv-skill, cv-skill-with-level, cv-skill-tag, h-bar

#cv-section("Skills")

#cv-skill-with-level(
  type: [Languages],
  level: 4,
  info: [Spanish (Native) #h-bar() English (C1) #h-bar() Basque (B2)],
)

#cv-skill-with-level(
  type: [Technologies],
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
  type: [Hobbies],
  info: [Reverse-engineering #h-bar() Reading #h-bar() Cooking #h-bar() Nature],
)
