recursive = require 'recursive-readdir'

module.exports = class FilesProcessor extends require './Processor'
  constructor: ->
    super
    @files = null
    @types = {}

  init: (cb) ->
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
