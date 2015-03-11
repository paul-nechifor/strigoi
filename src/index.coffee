fs = require 'fs'
path = require 'path'

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

# The main class that does all the processing of the entire file structure.
exports.Strigoi = class Strigoi

  constructor: ->
    @root = null

  run: (cb) ->
