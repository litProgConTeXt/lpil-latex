# LPiL LaTeX templates


## LPiL-preambles

Unfortunately we can not implement LPiL-preambles using an official LaTeX
style file.

The "catch-22" problem, is that *if* the preamble has already been read by
LaTeX, then we can't use `\RequirePackage` to load the preamble style, we
*must* use `\usepackage`. However *if* the preamble has not yet been read
by LaTeX, then we can't use `\usepackage`, we *must* use
`\RequirePackage`.

The solution is to use `\ifdefined\startLpilPreamble`, at which point we
might as well place the "whole" preamble "style" in a template which the
user can then tailor to their needs.

**Our solution** is to:

1. provide the user with template `preamble.tex` and `postamble.tex` files
   which can be altered by the user to provide the packages required for a
   given project

2. alter the latexmk runtime configuration file (`latexmkrc`) so that the
   a `preamble.tex` is `\input` before the "main" document and that the
   `postamble.tex` file is `\input` after the "main" document.

## Pygments style

Using the `lpil-tool`, the LPiL code environments
(`\begin{lpil:<<codeType>>}` / `\end{lpil:<<codeTyle>>}`) make use of the
[Python Pygments](https://pygments.org/) tool to highlight the code
keywords.

The pygments `LaTeXFormater` requires a latex style file to be loaded to
define its FancyVRB Verbatim commands.

The `./scripts/createPygmentsStyle` script helps to automate the creation
of this style file.
