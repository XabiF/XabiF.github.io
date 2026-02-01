// Imports
#import "@preview/brilliant-cv:3.1.2": cv-section, cv-publication

#cv-section("Publicaciones")

#cv-publication(
  bib: bibliography("../assets/publications.bib"),
  key-list: (
    "tfg",
    "tfm",
  ),
  ref-style: "ieee",
  ref-full: false,
)

// Example 2: All publications with APA style (commented out to avoid duplication)
// #cv-publication(
//   bib: bibliography("../assets/publications.bib"),
//   ref-style: "apa",
//   ref-full: true,
// )
