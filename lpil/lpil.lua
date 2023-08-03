
local lpilMod = {}

local tInsert = table.insert
local tRemove = table.remove
local tConcat = table.concat
local sSub    = string.sub
local sGSub   = string.gsub
local sFormat = string.format

-------------------------------------------------------------------------
-- initialize this module

function lpilMod.initialize()
  local homeDir = os.getenv("HOME")
  lpilMod.config = dofile(homeDir..'/.config/cfdoit/config.lua')

  if (lpilMod.config['build']) then
    if (lpilMod.config['build']['latexDir']) then
      local latexDir = lpilMod.config['build']['latexDir']
      texio.write("\nSetting LaTeXDir = "..latexDir.."\n")
      tex.print("\\def\\latexBuildDir{"..latexDir.."}")
    else 
      tex.print("\\def\\latexBuildDir{.}")
    end
  else
    tex.print("\\def\\latexBuildDir{.}")
  end
end

-------------------------------------------------------------------------
-- Provide a simple stack of "input files"

local function sEndsWith(aStr, aSuffix)
  return sSub(aStr, -#aSuffix) == aSuffix
end

local inputFiles = {}

function lpilMod.topInputFile()
  inputFile = "unknown"
  if 0 < #inputFiles then
    inputFile = inputFiles[#inputFiles]
  end
  --texio.write("\ncurrentInputFile: "..inputFile.."\n")
  return inputFile

end

function lpilMod.currentInputFile()
  tex.print(lpilMod.topInputFile)
end

function lpilMod.pushInputFile(aPath)
  --lpilMod.topInputFile()

  -- ensure we honour the LaTeX \input/\include by silently adding the
  -- .tex if there is no file extension...

  if (sEndsWith(aPath, '.tex') or sEndsWith(aPath, '.sty')) then
    -- do nothing
  else
    aPath = aPath..'.tex'
  end

  --texio.write("\npushInputFile: "..aPath.."\n")
  tInsert(inputFiles, aPath)
end

function lpilMod.popInputFile()
  --texio.write("\npopInputFile\n")
  tRemove(inputFiles, aPath)
  --lpilMod.topInputFile()
end
-------------------------------------------------------------------------

-- Note the ordering of the "extra" \\begingroup / \\endgroup pair...
--
-- This is REQUIRED to ensure we leave the "verbatim" mode induced by the
-- \\comment / \\endcomment "envirnoment"

function lpilMod.newCodeType(codeType, pygmentOpts)
  texio.write("\nnewCodeType("..codeType..","..pygmentOpts..")\n")

  texCmd = {}
  tInsert(texCmd, "\\newenvironment{lpil:")
  tInsert(texCmd, codeType)
  tInsert(texCmd, "}[1]{")
  tInsert(texCmd, "\\directlua{lpil.defineLoadPygmentedCode('")
  tInsert(texCmd, codeType)
  tInsert(texCmd, "','#1')}\\begingroup\\comment}")
  tInsert(texCmd, "{\\endcomment\\endgroup\\loadPygmentedCode}")
  texCmd = tConcat(texCmd, '')

  tex.print(texCmd)
  --return texCmd
end

local fileCounters = {}

function lpilMod.defineLoadPygmentedCode(codeType, baseName)
  texio.write("\ndefineLoadPygmentedCode("..codeType..","..baseName..")")

  curFilePath = lpilMod.topInputFile()
  --texio.write("\ncurFilePath: "..curFilePath.."\n")
  -- need to change directory separators to a simple '.'
  curFilePath = sGSub(curFilePath, '[%\\%/]', '.')
  --texio.write("\ncurFilePath: "..curFilePath.."\n")

  fileCounters[codeType] = fileCounters[codeType] or {}
  codeTypes = fileCounters[codeType]
  codeTypes[curFilePath] = codeTypes[curFilePath] or {}
  curFile = codeTypes[curFilePath]
  if curFile[baseName] == nil then
    curFile[baseName] = 1
  else
    curFile[baseName] = curFile[baseName] + 1
  end

  fileName = {}
  tInsert(fileName, baseName)
  tInsert(fileName, ".")
  tInsert(fileName, curFilePath)
  tInsert(fileName, ".c")
  tInsert(fileName, sFormat("%05d", curFile[baseName]))
  tInsert(fileName, ".pygmented.tex")
  fileName = tConcat(fileName, '')
  texio.write("\n  will load file: "..fileName.."\n")

  texCmd = {}
  tInsert(texCmd, "\\def\\loadPygmentedCode{\\IfFileExists{")
  tInsert(texCmd, fileName)
  tInsert(texCmd, "}{\\input{")
  tInsert(texCmd, fileName)
  tInsert(texCmd, "}}{\\par \\noindent \\fbox{ Pygmented ")
  tInsert(texCmd, codeType)
  tInsert(texCmd, " code for chunk ")
  tInsert(texCmd, sFormat("%d", curFile[baseName]))
  tInsert(texCmd, " of ")
  tInsert(texCmd, baseName)
  tInsert(texCmd, " does not exist} \\par }}")
  texCmd = tConcat(texCmd, '')

  tex.print(texCmd)
  --return texCmd
end

texio.write("\nLoaded lpil Lua module\n")

return lpilMod
