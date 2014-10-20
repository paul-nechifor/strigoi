LatexEnv = require './LatexEnv'
async = require 'async'
fs = require 'fs'
jade = require 'jade'
nib = require 'nib'
path = require 'path'
stylus = require 'stylus'
yaml = require 'js-yaml'

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
    @partsIds = {}
    @async = {}
    @yaml = {}
    @asyncsToLoad = []
    @main = null
    @latexEnv = new LatexEnv @
    @exports = new StrigoiExports @
    @asyncFunctionSet = new AsyncFunctionSet @

  init: (cb) ->
    fs.readFile @src, {encoding: 'utf8'}, (err, data) =>
      return cb err if err
      @data = data
      cb()

  load: (cb) ->
    parts = @data.split '\n---\n'
    for i in [0 .. parts.length - 1] by 2
      @addPart parts[i], parts[i + 1]
    @loadParts (err) =>
      return cb err if err
      @writeIds cb

  addPart: (dataStr, str) ->
    data = yaml.safeLoad dataStr
    Part = partTypes[data.type]
    unless Part?
      return cb 'Unkown part type: ' + data.type
    part = new Part @, data, str
    @parts.push part
    @partsIds[data.id] = part if data.id?
    if data.main
      @main = part
      @info = data.info if data.info
    if data.async
      for key, value of data.async
        a = {id: key}
        if value instanceof Array
          a.name = value[0]
          a.opts = value.slice 1
        else if typeof value is 'string'
          a.name = value
        else
          a.name = value.name
          a.opts = value.opts
        @asyncsToLoad.push a
    @site.configure data.configure if data.configure
    return

  loadParts: (cb) ->
    f = (p, cb) -> p.load cb
    async.mapSeries @parts, f, cb

  writeIds: (cb) ->
    return cb() unless @site.command is 'build'
    root = @site.fromTmpPath @site.idsDir
    writePart = (p, cb) =>
      file = "#{root}/#{@id}/#{p.data.id}#{p.constructor.extension}"
      @site.writeFile file, p.str, cb
    parts = @parts.filter (p) -> p.data.id
    async.map parts, writePart, cb

  loadAsync: (cb) ->
    renderAsync = (a, cb) =>
      @asyncFunctionSet[a.name] a.opts, (err, result) =>
        return cb err if err
        @async[a.id] = result
        cb()
    async.mapSeries @asyncsToLoad, renderAsync, cb

  write: (cb) ->
    @site.log "Building doc '#{@id}'."
    @buildHtml (err, html) =>
      return cb err if err
      @save html, cb

  buildHtml: (cb) ->
    return @main.render {}, cb if @main
    @asyncFunctionSet.innerDoc {}, cb

  save: (html, cb) ->
    file = @site.dirJoins @site.genDir, @id + '.html'
    @site.writeFile file, html, cb

class StrigoiExports
  constructor: (@doc) ->
    @async = @doc.async
    @yaml = @doc.yaml
    @mod = @doc.site.modules

class AsyncFunctionSet
  constructor: (@doc) ->

  innerDoc: (opts, cb) ->
    f = (p, cb) ->
      return cb null, '' if p.data.exclude or p.data.main
      p.render {}, cb

    async.mapSeries @doc.parts, f, (err, results) ->
      return cb err if err
      cb null, results.join ''

  readFile: (opts, cb) ->
    file = @doc.site.fromPath opts[0]
    fs.readFile file, {encoding: 'utf8'}, cb

  joinFiles: (args, cb) ->
    files = args.map (f) => @doc.site.fromPath f
    read = (f, cb) ->
      fs.readFile f, {encoding: 'utf8'}, (err, data) ->
        return cb err if err
        data += '\n' if data[data.length - 1] isnt '\n'
        cb null, data

  renderJadeFile: (opts, cb) ->
    file = @doc.site.fromTmpPath opts[0]
    locals =
      doc: @doc
      strigoi: @doc.exports
      filename: file
    cb null, jade.renderFile file, @doc.site.merge opts[1], locals

  renderStylusFile: (args, cb) ->
    file = @doc.site.fromPath args[0]
    opts = args[1] or {}
    fs.readFile file, {encoding: 'utf8'}, (err, data) =>
      return cb err if err
      s = stylus data
      .include nib.path
      .set 'filename', file
      s.set 'include css', true if opts.includeCss
      s.render (err, css) =>
        return cb err if err
        css = @doc.async[opts.includeBefore] + css if opts.includeBefore
        css += @doc.async[opts.includeAfter] if opts.includeAfter
        cb null, css

  bundleStylus: (args, cb) ->
    [from, to, opts] = args
    to = @doc.site.toPath to
    @renderStylusFile [from, opts], (err, css) =>
      return cb err if err
      @doc.site.writeFile to, css, cb
