async = require 'async'
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

module.exports = class Document
  types =
    jade: require './types/Jade'
    md: require './types/Markdown'
    yaml: require './types/Yaml'

  constructor: (@srcFile, @data) ->
    @dirName = path.dirname @srcFile
    @id = path.basename @srcFile, '.strig'
    @exports = new StrigoiExports @
    @doc = {}
    @parts = []
    @ids = {}
    @html = ''
    @nonMainHtml = ''
    @main = null

  process: (cb) ->
    parts = @data.split '\n---\n'
    @doc = yaml.safeLoad parts[0]
    n = parts.length - 1
    n-- if n % 2 is 1
    for i in [1 .. n] by 2
      @addPart parts[i], parts[i + 1]
    @loadParts (err) =>
      return cb err if err
      @buildHtml()
      cb()

  addPart: (dataStr, str) ->
    data = yaml.safeLoad dataStr
    Type = types[data.type]
    unless Type?
      return cb 'Unkown type: ' + data.type
    type = new Type @, data, str
    @parts.push type
    @ids[data.id] = type if data.id?
    @main = type if data.main
    return

  loadParts: (cb) ->
    f = (p, cb) -> p.load cb
    async.mapSeries @parts, f, (err, results) ->
      return cb err if err
      cb()

  buildHtml: ->
    @nonMainHtml = @parts.map((p) -> p.html).join ''
    @html = if @main then @main.render() else @nonMainHtml
    return

  save: (cb) ->
    parent = @dirName + '/strigoi'
    fs.mkdir parent, (err) =>
      # Ignore error.
      path = parent + '/' + @id + '.html'
      fs.writeFile path, @html, cb

class StrigoiExports
  constructor: (@doc) ->

  getYaml: (id) -> @doc.ids[id].content
  getInnerHtml: -> @doc.nonMainHtml
