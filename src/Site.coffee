async = require 'async'
path = require 'path'

module.exports = class Site
  constructor: (@clean={}) ->
    @dir = null
    @skipStrigoifile = false
    @useDocs = null
    @findIgnorePatterns = []
    @genDir = 'generated'
    @tmpDir = '.strigoi-tmp'
    @docs = new (require './proc/DocumentsProcessor') @
    @processors = [
      new (require './proc/StrigoifileProcessor') @
      new (require './proc/CleanupProcessor') @
      @docs
    ]

  init: (opts, cb) ->
    if opts.file
      full = path.resolve process.cwd(), opts.file
      @dir = path.dirname full
      @skipStrigoifile = true
      @useDocs = [path.basename full]
    else
      @dir = path.resolve process.cwd(), opts.dir
    @log "Using dir '#{@dir}'."
    @process cb

  process: (cb) ->
    @successiveCalls @processors, ['init', 'run', 'finish'], cb

  successiveCalls: (array, methods, cb) ->
    f = (method, cb) => @callMethods array, method, cb
    async.mapSeries methods, f, cb

  callMethods: (array, method, cb) ->
    f = (x, cb) -> x[method] cb
    async.mapSeries array, f, cb

  dirJoin: (part) ->
    path.join @dir, part

  log: (str) ->
    console.log str
