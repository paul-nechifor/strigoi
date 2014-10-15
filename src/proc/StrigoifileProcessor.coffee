fs = require 'fs'

module.exports = class DocumentsProcessor extends require './Processor'
  constructor: ->
    super
    @strigoifile = null

  init: (cb) ->
    err = @initFile()
    return cb err if err

    if @site.configureJson
      @site.configure JSON.parse @site.configureJson

    @runFunc 'init', cb

  initFile: ->
    return if @site.skipStrigoifile

    file = @site.dirJoin 'strigoifile.coffee'
    return unless fs.existsSync file

    require 'coffee-script/register'
    try
      @strigoifile = require file
    catch err
      return err
    return

  run: (cb) ->
    @runFunc 'run', cb

  finish: (cb) ->
    @runFunc 'finish', cb

  runFunc: (name, cb) ->
    return cb() unless @strigoifile and @strigoifile[name]
    @strigoifile[name] @site, cb

