# LPiL helper scripts

This directory contains a number of Bash scripts which help in the *use*
of the LPiL LaTeX style.

The **`updatePackage`** script, ensures that the LPiL LaTeX file is
installed in the correct directory for the user's TeXLive installation of
TeX/LaTeX.

The **`initializePreamble`** script, copies the template LPiL
`preamble.tex`, `postamble.tex` and `latexmkrc` files into the user's
project directory. It is expected that the user will further alter these
template files for the needs of the given project.

The **`createPygmentsStyle`** script, creates a Pygments (LaTeX) style
file suitable for highlighting code using a given Pygments style.
