async = require 'async'
errors = require './errors'
fs = require 'fs'
fse = require 'fs-extra'
path = require 'path'
{exec, spawn} = require 'child_process'
require 'coffee-script/register'

module.exports = class Site
  constructor: (@opts) ->
    @dir = null
    @id = null
    @skipStrigoifile = false
    @useDocs = null
    @modules = {}
    @findIgnorePatterns = []
    @genDir = 'strigoi-gen'
    @tmpDir = 'strigoi-tmp'
    @modulesDir = 'modules' # Relative to @tmpDir
    @idsDir = 'by-id' # Relative to @tmpDir
    @dirVars =
      bower: => path.resolve @dirVars.tmp(), 'bower_components'
      dir: => @dir
      gen: => path.resolve @dir, @genDir
      ids: => path.resolve @dirVars.tmp(), @idsDir
      modules: => path.resolve @dirVars.tmp(), @modulesDir
      npm: => path.resolve @dirVars.tmp(), 'node_modules'
      tmp: => path.resolve @dir, @tmpDir
    @npmPackages = []
    @bowerPackages = []
    @minifyHtmlOptions =
      removeComments: true
      collapseWhitespace: true
      caseSensitive: true
    @markedOptions =
      smartypants: true
    @stylusOptions =
      compress: true
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
      markedOptions: true
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
    @command = null
    if @opts.file
      full = path.resolve process.cwd(), @opts.file
      @dir = path.dirname full
      @skipStrigoifile = true
      @useDocs = [path.basename full]
    else
      @dir = path.resolve process.cwd(), @opts.dir
    @id = path.basename @dir

  run: (cb) ->
    @log 'Starting.'
    @process (err) =>
      return cb err if err
      @log 'Done.'

  process: (cb) ->
    if @opts.clean.gen or @opts.clean.tmp
      @command = 'clean'
    else if @opts.install
      @command = 'install'
    else
      @command = 'build'
    @log "Executing command #{@command}."
    @successiveCalls @processors, ['init', 'init2', 'run', 'finish'], cb

  successiveCalls: (array, methods, cb) ->
    f = (method, cb) => @callMethods array, method, cb
    async.mapSeries methods, f, cb

  callMethods: (array, method, cb) ->
    f = (x, cb) -> x[method] cb
    async.mapSeries array, f, cb

  writeFile: (file, data, cb) ->
    fse.mkdirp path.dirname(file), (err) ->
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

  path: (file, optionalStart) ->
    ret = file.replace /^@(\w+)/i, (m, name) =>
      return @dirVars[name]() if @dirVars[name]
      throw errors.create 'unknown-dir-shortcut', name: name, full: file
    if optionalStart
      path.resolve @path(optionalStart), ret
    else
      ret

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

  merge: ->
    merged = {}
    for obj in arguments
      for key, value of obj
        merged[key] = value
    merged
