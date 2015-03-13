# # Strigoi

# ## Requirements

async = require 'async'
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

# ## Exceptions

exports.StrigParsingEx = class StrigParsingEx
  constructor: (@message, @line, @name = 'StrigParsingEx') ->

exports.StrigFsEx = class StrigFsEx
  constructor: (@message, @name = 'StrigFsEx') ->

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

    # The processor that should handle this file.
    @processor = null

  # This is a builder method for creating the root (a file that has no parent).
  @createRootDir = (dir) ->
    dir = path.resolve process.cwd(), dir
    ret = new File null, path.basename dir
    ret.path = dir
    ret.children = {}
    ret

  addChild: (name, isDir) ->
    f = new File @, name
    f.path = path.join @path, name
    f.children = {} if isDir
    @children[name] = f

  # Recursivelly scan all the files/directories in this directory and construct
  # their `File` representation.
  scanAllFiles: (config, cb) ->
    strigFileFound = false

    # Check if this file type has a processor using the extension.
    getProcessorFor = (fileName) ->
      for p in config.processors
        return p if fileName.match p.extRegex
      null

    # Try to add a specific file to its parent directory if it has a processor.
    tryToAdd = (dir) ->
      (name, cb) ->
        filePath = path.join dir.path, name
        fs.stat filePath, (err, stat) ->
          return cb err if err
          if stat and stat.isDirectory()
            child = dir.addChild name, true
            scan child, cb
          else if processor = getProcessorFor filePath
            child = dir.addChild name, false
            child.processor = processor
            strigFileFound or= processor is StrigProcessor
            cb()
          else cb()

    scan = (dir, cb) ->
      fs.readdir dir.path, (err, list) ->
        return cb err if err
        # Filter out ignored files.
        list = list.filter (x) -> not x.match config.walkIgnore
        async.map list, tryToAdd(dir), cb

    fs.stat @path, (err, stat) =>
      # Check that the root is a directory.
      unless not err and stat and stat.isDirectory()
        return cb new StrigFsEx 'not-a-dir'

      scan @, (err) ->
        return cb err if err
        return cb new StrigFsEx 'no-strig-files' unless strigFileFound
        cb()

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

  # Check that the first line starts with a header delimiter.
  unless textLines[0].match delimRegex
    throw new StrigParsingEx 'start-delimiter-missing', 1

  for line, i in textLines

    # Keep pushing lines until a delimiter is found.
    match = line.match delimRegex
    if not match
      lines.push line
      continue

    singleLineHeader = match[1]

    if readingHeader
      # Check that we aren't reading two successive headers.
      if singleLineHeader
        throw new StrigParsingEx 'header-after-header', i

      header = lines.join '\n'

    else
      # Push the previous part unless this is the first part.
      parts.push header: header, content: lines unless lines is null

      header = singleLineHeader if singleLineHeader

    # Check which part should be expected next and reset the lines.
    readingHeader = not (readingHeader or singleLineHeader)
    lines = []

  # Always push the last part since the previous are pushed when a successor is
  # found.
  parts.push header: header, content: lines

  # Return the parsed YAML headers and the joined content lines.
  parts.map (x) -> header: yaml.safeLoad(x.header), content: x.content.join '\n'


# ## Processors

# A `FileProcessor` subclass handles transforming plaintext into its recognized
# format.
exports.FileProcessor = class FileProcessor

  # The regex for extensions this processor handles.
  @extRegex = null

exports.StrigProcessor = class StrigProcessor

  @extRegex = /.*\.strig$/

# ## Strigoi

# This class stores all the mutable configurations.
exports.Config = class Config

  constructor: ->
    @processors = [
      StrigProcessor
    ]
    @walkIgnore = /^(node_modules|bower_components)$/

# The main class that does all the processing of the entire file structure.
exports.Strigoi = class Strigoi

  constructor: ->
    @root = null
    @config = new Config

  @create = (dir) ->
    s = new Strigoi
    s.root = File.createRootDir dir
    return s

  run: (cb) ->
    @root.scanAllFiles @config, cb
