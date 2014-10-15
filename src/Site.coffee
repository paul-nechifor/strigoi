async = require 'async'
path = require 'path'
{exec, spawn} = require 'child_process'

module.exports = class Site
  constructor: (@clean={}, @configureJson) ->
    @dir = null
    @skipStrigoifile = false
    @useDocs = null
    @findIgnorePatterns = []
    @genDir = 'generated'
    @tmpDir = '.strigoi-tmp'
    @npmPackages = []
    @bowerPackages = []
    @minifyHtmlOptions =
      removeComments: true
      collapseWhitespace: true
      caseSensitive: true
    @rsync = []
    @scourOptions = [
      '--enable-comment-stripping'
      '--enable-id-stripping'
      '--enable-viewboxing'
      '--enable-viewboxing'
      '--indent=none'
      '--remove-metadata'
      '--shorten-ids'
      '--strip-xml-prolog'
    ]
    @arrayOptions =
      findIgnorePatterns: true
      npmPackages: true
      bowerPackages: true
      rsync: true
      scourOptions: true
      processors: true
    @objectOptions =
      minifyHtmlOptions: true
    @docs = new (require './proc/DocumentsProcessor') @
    @processors = [
      new (require './proc/StrigoifileProcessor') @
      new (require './proc/CleanupProcessor') @
      new (require './proc/PackageProcessor') @
      new (require './proc/RsyncProcessor') @
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

  dirJoins: ->
    parts = Array.prototype.slice.call arguments, 0
    parts.splice 0, 0, @dir
    path.join.apply path.join, parts

  log: (str) ->
    console.log str

  configure: (cs) ->
    for key, value of cs
      if @arrayOptions[key]
        @[key].push.apply @[key], value
      else if @objectOptions[key]
        @[key][oKey] = oValue for oKey, oValue of value
      else
        @[key] = value
    return

  spawn: (name, args, cb) ->
    s = spawn name, args
    s.stdout.on 'data', (data) -> process.stdout.write data
    s.stderr.on 'data', (data) -> process.stderr.write data
    s.on 'close', (code) ->
      cb 'err-' + code unless code is 0
      cb()

  exec: (script, cb) ->
    exec script, (err, stdout, stderr) ->
      process.stdout.write stdout
      process.stderr.write stderr
      return cb err if err
      cb()
