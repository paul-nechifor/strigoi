# # Strigoi

# ## Requirements
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

# ## Exceptions
exports.StrigParsingEx = class StrigParsingEx
  constructor: (@message, @line, @name = 'ParsingException') ->

# ## Filesystem

# A `File` is a generic container that represents a directory, a regular file,
# or part of a regular file.
exports.File = class File

  constructor: (@parent, @name) ->

    # The full path of this file's location.
    @path = null

    # A hash of all the child `File`s.
    @children = null

    # The string content of this file (or `null` for directories).
    @content = null

    # Whether this is an actual regular file or the part of another.
    @pseudo = false

  # This is a builder method for creating the root (a file that has no parent).
  @createRootDir = (dir) ->
    dir = path.normalize dir
    dir = dir.substring 0, dir.length - 1 if dir[dir.length - 1] is '/'
    ret = new File null, path.basename dir
    ret.path = dir
    ret

# ## Parsing

# This splits a text file into its bare parts and returns an array of objects
# having `header` (a parsed YAML object) and `content` (a string).
exports.parseStrigParts = (text) ->
  parts = []
  readingHeader = false
  header = null
  lines = null

  delimRegex = /^---\w*(.*)\w*$/
  textLines = text.split '\n'

  unless textLines[0].match delimRegex
    throw new StrigParsingEx 'start-delimiter-missing', 1

  for line, i in textLines

    match = line.match delimRegex
    if not match
      lines.push line
      continue

    singleLineHeader = match[1]

    if readingHeader
      if singleLineHeader
        throw new StrigParsingEx 'header-after-header', i
      header = lines.join '\n'
    else
      if lines isnt null
        parts.push header: header, content: lines
      header = singleLineHeader if singleLineHeader

    readingHeader = not (readingHeader or singleLineHeader)
    lines = []

  parts.push header: header, content: lines

  parts.map (x) -> header: yaml.safeLoad(x.header), content: x.content.join '\n'


# ## Strigoi

# The main class that does all the processing of the entire file structure.
exports.Strigoi = class Strigoi

  constructor: ->
    @root = null

  run: (cb) ->
