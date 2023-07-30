# Literate Programming in LaTeX Styles

This project collects together all of the styles required for the Literate
Programming in LaTeX (LPiL) projects.

One of our objectives is to be able to split up a large document in to many
small parts which can subsequently be built (typeset and compiled) separately.
To do this we provide the **`lpilPreamble`** style which can be placed at the
begining of any LaTeX file to enable it to be typeset separately from the "root"
document.

The second of our objectives is to enable code of various different types to be
embedded in a document in such a way that the associated `lpil-tool` can extract
it, and write out a build description sufficent to allow the whole project to be
compiled. To do this we provide the **`lpil`** style.

## lpilPreamble

The `lpilPreamble` style provides the `lpilPreamble` environment. If a previous
`lpilPreamble` environment has already been typeset, the the current version of
the enviornment will be ignored. This allows each LaTeX file to contain its own
`lpilPreamble` which details how to typeset just that file, but when the file is
`\include`/`\input` into a larger document, these local `lpilPreamble` details
will be ignored.

In particular the "first" `lpilPreamble` typeset, behaves as the standard LaTeX
`\documentclass`. This means that the `\begin{lpilPreamble}` takes optional
arguments as well as the name of a document class (as a required argument).

## lpil

The `lpil` style provides the `lpilCode` and `lpilBuild` environments.

The `lpilCode` environment is used to typeset a "chunk" of code in one language.
Each such "chunk" must specify both the type of code as well as the file the
code is ultimately part of. The associated `lpil-tool` will then extract all of
the code chunks for a given type of code and a given file into one file.

The `lpilBuild` environment should contain a number of `\requires` and
`\creates` macros which together describe how to build a given computational
artefact.

