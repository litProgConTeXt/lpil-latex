
local lpilMod = {}

local tInsert = table.insert
local tRemove = table.remove
local tConcat = table.concat
local sSub    = string.sub
local sGSub   = string.gsub
local sUpper  = string.upper
local sFormat = string.format

require("lualibs-util-jsn")
local json    = utilities.json

-------------------------------------------------------------------------
-- initialize this module

function lpilMod.initialize()
  local homeDir = os.getenv("HOME")
  lpilMod.config = dofile(homeDir..'/.config/cfdoit/config.lua')

  lpilMod.latexDir = '.'
  if (lpilMod.config['build']) then
    if (lpilMod.config['build']['latexDir']) then
      local latexDir = lpilMod.config['build']['latexDir']
      lpilMod.latexDir = latexDir
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
-- track input/output files

function lpilMod.addDependentFile(aFilePath, codeType)
  codeType = codeType or 'tex'
  texio.write("\nAdding dependent file: ["..aFilePath.."] with codeType: "..codeType.."\n")
  lpilMod.deps = lpilMod.deps or {}
  lpilMod.deps[aFilePath] = codeType
end

function addPygmentsOptions(aCodeType, someCodeOptions)
  lpilMod.pygments = lpilMod.pygments or {}
  lpilMod.pygments[aCodeType] = someCodeOptions
end

function lpilMod.writeDependentFiles()
  local jsonStruct       = { }
  lpilMod.pygments       = lpilMod.pygments or {}
  jsonStruct['pygments'] = lpilMod.pygments
  lpilMod.deps           = lpilMod.deps or {}
  jsonStruct['deps']     = lpilMod.deps
  local jsonStr = json.tostring(jsonStruct)
  local jsonFile = io.open(lpilMod.latexDir..'/'..tex.jobname..'.deps.json', 'w')
  jsonFile:write(jsonStr)
  jsonFile:close()
end
-------------------------------------------------------------------------
-- Provide a simple stack of "input files"

local function sEndsWith(aStr, aSuffix)
  return sSub(aStr, -#aSuffix) == aSuffix
end

local inputFiles = {}

function lpilMod.showInputFiles()
  texio.write("\n-----------------------------\n")
  for _, aFile in ipairs(inputFiles) do
    texio.write("  "..aFile.." "..getParentDir(aFile).."\n")
  end
  texio.write("-----------------------------\n")
end

function getSep()
  return sSub(package.config, 1, 1)
end

function getParentDir(aPath)
  aPath = aPath or ""
  if aPath:sub(#aPath) =="/" then
    aPath = aPath:sub(1,-2)
  end
  sep = getSep()
  parentDir = aPath:match("(.*"..sep..")") or ""
  --texio.write("getParentDir: ["..aPath.."] -> ["..parentDir.."]\n")
  return parentDir
end

function mkdirs(aPath)
  --texio.write("mkdirs ["..aPath.."]\n")
  local parentDir = getParentDir(aPath)
  if parentDir:sub(#parentDir) =="/" then
    parentDir = parentDir:sub(1,-2)
  end
  if parentDir ~= "" then
    mkdirs(parentDir)
    --texio.write("parentDir: ["..parentDir.."] type: "..type(parentDir).."\n")
    --texio.write("lfs.mkdir("..parentDir..") ["..aPath.."]\n")
    local ok, err = lfs.mkdir(parentDir)
    if not ok then
      if err ~= "File exists" then
        texio.write("lfs.mkdir error: ["..err.."]\n")
      end
    end
  end
  --texio.write("mkdirs ["..aPath.."]\n")
end

function lpilMod.topInputFile()
  inputFile = "unknown"
  if 0 < #inputFiles then
    inputFile = inputFiles[#inputFiles]
  end
  --texio.write("\ncurrentInputFile: ["..inputFile.."]\n")
  --lpilMod.showInputFiles()
  return inputFile
end

function lpilMod.currentFile()
  --texio.write("\ncurrentFile")
  --lpilMod.showInputFiles()
  tex.print(lpilMod.topInputFile)
end

function lpilMod.currentDirectory()
  --texio.write("\ncurrentDirectory")
  --lpilMod.showInputFiles()
  tex.print(getParentDir(lpilMod.topInputFile()))
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

  tInsert(inputFiles, aPath)
  --texio.write("pushInputFile: "..aPath.."\n")
  --lpilMod.showInputFiles()
end

function lpilMod.popInputFile()
  tRemove(inputFiles, aPath)
  --texio.write("popInputFile\n")
  --lpilMod.showInputFiles()
end

-------------------------------------------------------------------------

-- Note the ordering of the "extra" \\begingroup / \\endgroup pair...
--
-- This is REQUIRED to ensure we leave the "verbatim" mode induced by the
-- \\comment / \\endcomment "envirnoment"

function lpilMod.newCodeType(codeType, pygmentOpts)
  texio.write("\nnewCodeType("..codeType..","..pygmentOpts..")\n")

  local CodeType = codeType:gsub("^%l", sUpper)

  addPygmentsOptions(codeType, pygmentOpts)

  texCmd = {}
  tInsert(texCmd, "\\newenvironment{lpil:")
  tInsert(texCmd, codeType)
  tInsert(texCmd, "}[1]{")
  tInsert(texCmd, "\\directlua{lpil.defineLoadPygmentedCode('")
  tInsert(texCmd, codeType)
  tInsert(texCmd, "','#1','noCopy')}\\begingroup\\filecontents[noheader,overwrite]\\pygmentedCodeFileName}")
  tInsert(texCmd, "{\\endfilecontents\\endgroup\\loadPygmentedCode}")

	tInsert(texCmd, "\\newcommand{\\loadLpil")
	tInsert(texCmd, CodeType)
	tInsert(texCmd, "Code}[1]{\\directlua{lpil.defineLoadPygmentedCode('")
  tInsert(texCmd, codeType)
  tInsert(texCmd, "', '#1','copy')}\\loadPygmentedCode}")

  texCmd = tConcat(texCmd, '')
  texio.write("\nnewCodeTypeCMD("..texCmd..")")

  tex.print(texCmd)
  --return texCmd
end

local fileCounters = {}

local function computeCodeTypeFileNames(codeType, baseName)
  curFilePath = lpilMod.topInputFile()
  --texio.write("\ncurFilePath: "..curFilePath.."\n")
  -- need to change directory separators to a simple '.'
  curFilePathKey = sGSub(curFilePath, '[%\\%/]', '.')
  --texio.write("\ncurFilePath: "..curFilePath.."\n")

  fileCounters[codeType] = fileCounters[codeType] or {}
  codeTypes = fileCounters[codeType]
  codeTypes[curFilePathKey] = codeTypes[curFilePathKey] or {}
  curFile = codeTypes[curFilePathKey]
  if curFile[baseName] == nil then
    curFile[baseName] = 1
  else
    curFile[baseName] = curFile[baseName] + 1
  end

  writeFileName = {}
  tInsert(writeFileName, getParentDir(lpilMod.topInputFile()))
  --tInsert(fileName, getSep())
  tInsert(writeFileName, baseName)
  tInsert(writeFileName, "-")
  tInsert(writeFileName, curFilePathKey)
  tInsert(writeFileName, "-")
  tInsert(writeFileName, codeType)
  tInsert(writeFileName, "-c")
  tInsert(writeFileName, sFormat("%05d", curFile[baseName]))
  tInsert(writeFileName, ".pygmented.tex")
  writeFileName = tConcat(writeFileName, '')

  readFileName = {}
  tInsert(readFileName, lpilMod.latexDir)
  tInsert(readFileName, getSep())
  tInsert(readFileName, writeFileName)
  readFileName = tConcat(readFileName, '')

  copyFileName = {}
  curDirPath = getParentDir(curFilePath)
  if curDirPath then
		tInsert(copyFileName, curDirPath)
		--tInsert(copyFileName, getSep())
	end
	tInsert(copyFileName, baseName)
	copyFileName = tConcat(copyFileName, '')

  -- make sure all required directories exist
  mkdirs(readFileName)

  return readFileName, writeFileName, copyFileName
end

local function copyPygmentedCode(copyFileName, readFileName)
  texio.write("\ncopyPygmentedCode("..copyFileName..","..readFileName..")")

  texio.write("\nreading from: ["..copyFileName.."]\n")
  local inFile = io.open(copyFileName, "r")
  if inFile then
    local contents = inFile:read("a")
    inFile:close()
    if contents then
      texio.write("\nwriting to: ["..readFileName..".out]\n")
      local outFile = io.open(readFileName..".out", "w")
      if outFile then
        outFile:write(contents)
        outFile:close()
      else
        texio.write("\ncould not write to: ["..readFileName..".out]\n")
      end
    else
      texio.write("\nnothing read from: ["..copyFileName.."]\n")
    end
  else
    texio.write("\ncould not read from: ["..copyFileName.."]\n")
  end
end

function lpilMod.defineLoadPygmentedCode(codeType, baseName, shouldCopy)
  texio.write("\ndefineLoadPygmentedCode("..codeType..","..baseName..","..shouldCopy..")")

  local readFileName, writeFileName, copyFileName =
    computeCodeTypeFileNames(codeType, baseName)

  if shouldCopy == 'copy' then
    copyPygmentedCode(copyFileName, readFileName)
  end

  texio.write("\n  will load file: "..readFileName.."\n")

  safeBaseName = sGSub(baseName, "_", "\\_")
  texio.write("  safe baseName: ["..safeBaseName.."]\n")

  lpilMod.addDependentFile(readFileName, 'pygments-'..codeType)

  texCmd = {}
  tInsert(texCmd, "\\def\\pygmentedCodeFileName{")
  tInsert(texCmd, writeFileName)
  tInsert(texCmd, ".out}")
  tInsert(texCmd, "\\def\\loadPygmentedCode{\\IfFileExists{")
  tInsert(texCmd, readFileName)
  tInsert(texCmd, "}{\\lpilOrigInput{")
  tInsert(texCmd, readFileName)
  tInsert(texCmd, "}}{\\par \\noindent \\fbox{ Pygmented ")
  tInsert(texCmd, codeType)
  tInsert(texCmd, " code for chunk ")
  tInsert(texCmd, sFormat("%d", curFile[baseName]))
  tInsert(texCmd, " of ")
  tInsert(texCmd, safeBaseName)
  tInsert(texCmd, " does not exist} \\par }}")
  texCmd = tConcat(texCmd, '')
  texio.write("\ndefineLoadPygmentedCodeCMD("..texCmd..")")

  tex.print(texCmd)
  --return texCmd
end

texio.write("\nLoaded lpil Lua module\n")

return lpilMod
