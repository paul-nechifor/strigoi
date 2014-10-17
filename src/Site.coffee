async = require 'async'
fs = require 'fs'
path = require 'path'
{exec, spawn} = require 'child_process'
require 'coffee-script/register'

module.exports = class Site
  constructor: (@clean={}, @configureJson) ->
    @dir = null
    @id = null
    @skipStrigoifile = false
    @useDocs = null
    @modules = {}
    @findIgnorePatterns = []
    @genDir = 'generated'
    @tmpDir = '.strigoi-tmp'
    @modulesDir = 'modules' # Relative to @tmpDir
    @npmPackages = []
    @bowerPackages = []
    @minifyHtmlOptions =
      removeComments: true
      collapseWhitespace: true
      caseSensitive: true
    @rsync = []
    @useModules = []
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
    @indexFileTypes = [
      '.strig'
      '.jade'
    ]
    @tmpSyncFileTypes = [
      '.jade'
    ]
    @arrayOptions =
      findIgnorePatterns: true
      npmPackages: true
      bowerPackages: true
      rsync: true
      scourOptions: true
      processors: true
      indexFileTypes: true
      tmpSyncFileTypes: true
      useModules: true
    @objectOptions =
      minifyHtmlOptions: true
    @docs = new (require './proc/DocumentsProcessor') @
    @files = new (require './proc/FilesProcessor') @
    @processors = [
      new (require './proc/StrigoifileProcessor') @
      new (require './proc/CleanupProcessor') @
      @files
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
    @id = path.basename @dir
    @log 'Starting.'
    @process cb

  process: (cb) ->
    @successiveCalls @processors, ['init', 'init2', 'run', 'finish'], cb

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

  fromPath: (name) ->
    name = name.replace /^@bower/, @tmpDir + '/bower_components'
    name = name.replace /^@npm/, @tmpDir + '/node_modules'
    @dir + '/' + name

  fromTmpPath: (name) ->
    @dirJoin(@tmpDir) + '/' + name

  toPath: (name) ->
    @dirJoin(@genDir) + '/' + name

  writeFile: (file, data, cb) ->
    fs.mkdir path.dirname(file), (err) ->
      # Ignore error.
      fs.writeFile file, data, cb

  log: (str) ->
    console.log @id + ': ' + str.split('\n').join "\n#{@id}: "

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
    s.stdout.on 'data', (data) => @log data
    s.stderr.on 'data', (data) => @log data
    s.on 'close', (code) ->
      cb 'err-' + code unless code is 0
      cb()

  exec: (script, cb) ->
    exec script, (err, stdout, stderr) =>
      @log stdout
      @log stderr
      return cb err if err
      cb()

  merge: (a, b) ->
    merged = {}
    merged[key] = value for key, value of a
    merged[key] = value for key, value of b
    merged
