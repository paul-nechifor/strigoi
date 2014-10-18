async = require 'async'
fse = require 'fs-extra'
path = require 'path'
recursive = require 'recursive-readdir'

module.exports = class FilesProcessor extends require './Processor'
  constructor: ->
    super
    @files = null
    @types = {}

  init: (cb) ->
    @selfSeries [@findFiles, @tmpSyncFiles], cb

  findFiles: (cb) ->
    ignore = @site.findIgnorePatterns.concat @site.genDir, @site.tmpDir
    recursive @site.dir, ignore, (err, files) =>
      return cb err if err
      @files = files
      for e in @site.indexFileTypes
        @types[e] = []
      for f in files
        for e in @site.indexFileTypes
          if f.lastIndexOf(e) is f.length - e.length
            @types[e].push f
            break
      cb()

  tmpSyncFiles: (cb) ->
    proc = (f, cb) =>
      relative = path.relative @site.dir, f
      try fs.mkdirSync path.dirname relative
      fse.copy f, @site.dirJoins(@site.tmpDir, relative), cb
    files = []
    for type in @site.tmpSyncFileTypes
      files.push.apply files, @types[type]
    async.map files, proc, cb
