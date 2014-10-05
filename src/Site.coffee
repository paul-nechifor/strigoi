async = require 'async'
fs = require 'fs'
path = require 'path'
recursive = require 'recursive-readdir'
Document = require './Document'

module.exports = class Site
  constructor: (@clean={}) ->
    @dir = null
    @docs = {}
    @skipStrigoifile = false
    @useDocs = null
    @findIgnorePatterns = []

  init: (opts, cb) ->
    if opts.file
      full = path.resolve process.cwd(), opts.file
      @dir = path.dirname full
      @skipStrigoifile = true
      @useDocs = [path.basename full]
      @log "Processing single file '#{@useDocs[0]}'."
    else
      @dir = path.resolve process.cwd(), opts.dir
    @log "Using dir '#{@dir}'."
    @process cb

  process: (cb) ->
    list = [
      @processStrigoifile
      @cleanup
      @findDocs
      @loadDocs
      @getDocsInfo
      @processDocs
    ].map (i) => i.bind @
    async.series list, cb

  processStrigoifile: (cb) ->
    if @skipStrigoifile
      return cb()

    file = @dir + '/strigoifile.coffee'
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

  findDocs: (cb) ->
    if @useDocs
      @addDocs @useDocs
      return cb()
    recursive @dir, @findIgnorePatterns, (err, files) =>
      return cb err if err
      @addDocs files
    cb()

  addDocs: (files) ->
    for file in files
      continue unless file.lastIndexOf('.strig') is file.length - 6
      relative = path.relative @dir, file
      full = path.resolve @dir, file
      place = relative.substring 0, relative.length - 6
      @docs[place] = new Document @, place, full
    return

  loadDocs: (cb) ->
    cb()

  getDocsInfo: (cb) ->
    cb()

  processDocs: (cb) ->
    cb()

  log: (str) ->
    console.log str
