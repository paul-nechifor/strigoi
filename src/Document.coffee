async = require 'async'
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

module.exports = class Document
  types =
    md: require './types/Markdown'

  constructor: (@srcFile, @data) ->
    @dirName = path.dirname @srcFile
    @id = path.basename @srcFile, '.strig'
    @doc = {}
    @parts = []
    @ids = {}
    @html = ''

  process: (cb) ->
    parts = @data.split '\n---\n'
    @doc = yaml.safeLoad parts[0]
    n = parts.length - 1
    n-- if n % 2 is 1
    for i in [1 .. n] by 2
      @addPart parts[i], parts[i + 1]
    @processParts (err) =>
      return cb err if err
      @buildHtml()
      cb()

  addPart: (dataStr, str) ->
    data = yaml.safeLoad dataStr
    Type = types[data.type]
    unless Type?
      return cb 'Unkown type: ' + data.type
    type = new Type data, str
    @parts.push type
    @ids[data.id] = type if data.id?

  processParts: (cb) ->
    f = (p, cb) -> p.process cb
    async.mapSeries @parts, f, (err, results) ->
      return cb err if err
      cb()

  buildHtml: ->
    @html = @parts.map((p) -> p.html).join ''

  save: (cb) ->
    parent = @dirName + '/strigoi'
    fs.mkdir parent, (err) =>
      # Ignore error.
      path = parent + '/' + @id + '.html'
      fs.writeFile path, @html, cb
