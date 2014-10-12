fs = require 'fs'

module.exports = class DocumentsProcessor extends require './Processor'
  constructor: ->
    super
    @strigoifile = null

  init: (cb) ->
    return cb() if @site.skipStrigoifile

    file = @site.dirJoin 'strigoifile.coffee'
    return cb unless fs.existsSync file

    require 'coffee-script/register'
    try
      @strigoifile = require file
    catch err
      return cb err

    @runFunc 'init', cb

  run: (cb) ->
    @runFunc 'run', cb

  finish: (cb) ->
    @runFunc 'finish', cb

  runFunc: (name, cb) ->
    return cb() unless @strigoifile and @strigoifile[name]
    @strigoifile[name] @site, cb

