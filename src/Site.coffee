async = require 'async'
fs = require 'fs'
path = require 'path'

module.exports = class Site
  constructor: (@clean={}) ->
    @info =
      dir: null
      files: {}
    @skipStrigoifile = false
    @useFiles = null

  init: (opts, cb) ->
    if opts.file
      full = path.resolve process.cwd(), opts.file
      @info.dir = path.dirname full
      @skipStrigoifile = true
      @useFiles = [path.basename full]
      @log "Processing single file '#{@useFiles[0]}'."
    else
      @info.dir = path.resolve process.cwd(), opts.dir
    @log "Using dir '#{@info.dir}'."
    @process cb

  process: (cb) ->
    list = [
      @processStrigoifile
      @cleanup
      @findFiles
      @loadFiles
      @getFilesInfo
      @processFiles
    ].map (i) => i.bind @
    async.series list, cb

  processStrigoifile: (cb) ->
    if @skipStrigoifile
      return cb()

    file = @info.dir + '/strigoifile.coffee'
    if not fs.existsSync file
      return cb()

    require 'coffee-script/register'
    try
      strigoifile = require file
    catch err
      return cb err

    @log "Using strigoifile '#{file}'."
    strigoifile @, cb

  cleanup: (cb) ->
    cb()

  findFiles: (cb) ->
    if @useFiles
      @info.files[file] = {} for file in @useFiles
      return cb()
    cb()

  loadFiles: (cb) ->
    cb()

  getFilesInfo: (cb) ->
    cb()

  processFiles: (cb) ->
    cb()

  log: (str) ->
    console.log str
