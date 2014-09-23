async = require 'async'
yaml = require 'js-yaml'

module.exports = class Document
  types =
    md: require './types/Markdown'

  constructor: (@src, @data) ->
    @doc = {}
    @parts = []
    @html = ''

  process: (cb) ->
    parts = @data.split '\n---\n'
    @doc = yaml.safeLoad parts[0]
    parts.splice 0, 1
    for i in [0 .. parts.length - 1] by 2
      data = yaml.safeLoad parts[i]
      Type = types[data.type]
      unless Type?
        return cb 'Unkown type: ' + data.type
      @parts.push new Type data, parts[i + 1]

    @processParts (err) =>
      return cb err if err
      @buildHtml cb

  processParts: (cb) ->
    f = (p, cb) -> p.process cb
    async.mapSeries @parts, f, (err, results) ->
      return cb err if err
      cb()

  buildHtml: (cb) ->
    @html = @parts.map((p) -> p.html).join ''
    cb()

  save: (cb) ->
    console.log @html
