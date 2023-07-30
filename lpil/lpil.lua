
local lpilMod = {}

local tInsert = table.insert
local tConcat = table.concat
local sFormat = string.format

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
  texio.write("\ndefineLoadPygmentedCode("..codeType..","..baseName..")\n")

  fileCounters[codeType] = fileCounters[codeType] or {}
  if fileCounters[codeType][baseName] == nil then
    fileCounters[codeType][baseName] = 1
  else
    fileCounters[codeType][baseName] = fileCounters[codeType][baseName] + 1
  end

  fileName = {}
  tInsert(fileName, "c")
  tInsert(fileName, sFormat("%05d", fileCounters[codeType][baseName]))
  tInsert(fileName, baseName)
  tInsert(fileName, ".pygmented.tex")
  fileName = tConcat(fileName, '')

  texCmd = {}
  tInsert(texCmd, "\\def\\loadPygmentedCode{\\IfFileExists{")
  tInsert(texCmd, fileName)
  tInsert(texCmd, "}{\\input{")
  tInsert(texCmd, fileName)
  tInsert(texCmd, "}}{\\par \\noindent \\fbox{ Pygmented ")
  tInsert(texCmd, codeType)
  tInsert(texCmd, " code for chunk ")
  tInsert(texCmd, sFormat("%d", fileCounters[codeType][baseName]))
  tInsert(texCmd, " of ")
  tInsert(texCmd, baseName)
  tInsert(texCmd, " does not exist} \\par }}")
  texCmd = tConcat(texCmd, '')

  tex.print(texCmd)
  --return texCmd
end

texio.write("\nLoaded lpil Lua module\n")

return lpilMod
