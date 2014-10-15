async = require 'async'
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
LatexEnv = require './LatexEnv'

module.exports = class Document
  partTypes =
    jade: require './parts/Jade'
    latex: require './parts/Latex'
    md: require './parts/Markdown'
    yaml: require './parts/Yaml'

  constructor: (@docs, @site, @id, @src) ->
    @info = null
    @data = null
    @parts = []
    @ids = {}
    @async = {}
    @asyncsToLoad = []
    @main = null
    @latexEnv = new LatexEnv @
    @exports = new StrigoiExports @

  init: (cb) ->
    fs.readFile @src, {encoding: 'utf8'}, (err, data) =>
      return cb err if err
      @data = data
      cb()

  load: (cb) ->
    parts = @data.split '\n---\n'
    for i in [0 .. parts.length - 1] by 2
      @addPart parts[i], parts[i + 1]
    @loadParts cb

  addPart: (dataStr, str) ->
    data = yaml.safeLoad dataStr
    Part = partTypes[data.type]
    unless Part?
      return cb 'Unkown part type: ' + data.type
    part = new Part @, data, str
    @parts.push part
    @ids[data.id] = part if data.id?
    if data.main
      @main = part
      @info = data.info if data.info
    if data.async
      for key, value of data.async
        a = {id: key}
        if typeof value is 'string'
          a.name = value
        else
          a.name = value.name
          a.opts = value.opts
        @asyncsToLoad.push a
    return

  loadParts: (cb) ->
    f = (p, cb) -> p.load cb
    async.mapSeries @parts, f, cb

  loadAsync: (cb) ->
    renderAsync = (a, cb) =>
      @[a.name] a.opts, (err, result) =>
        return cb err if err
        @async[a.id] = result
        cb()
    async.mapSeries @asyncsToLoad, renderAsync, cb

  write: (cb) ->
    @buildHtml (err, html) =>
      return cb err if err
      @save html, cb

  buildHtml: (cb) ->
    return @main.render {}, cb if @main
    @innerDoc {}, cb

  innerDoc: (opts, cb) ->
    f = (p, cb) ->
      return cb null, '' if p.data.exclude or p.data.main
      p.render {}, cb

    async.mapSeries @parts, f, (err, results) ->
      return cb err if err
      cb null, results.join ''

  save: (html, cb) ->
    file = @site.dirJoins @site.genDir, @id + '.html'
    parent = path.dirname file
    fs.mkdir parent, (err) =>
      # Ignore error.
      fs.writeFile file, html, cb

class StrigoiExports
  constructor: (@doc) ->
    @async = @doc.async

  getYaml: (id) -> @doc.ids[id].content
