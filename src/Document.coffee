LatexEnv = require './LatexEnv'
async = require 'async'
errors = require './errors'
fs = require 'fs'
jade = require 'jade'
minifyHtml = require('html-minifier').minify
nib = require 'nib'
path = require 'path'
stylus = require 'stylus'
yaml = require 'js-yaml'

module.exports = class Document
  partTypes =
    coffee: require './parts/Coffee'
    jade: require './parts/Jade'
    latex: require './parts/Latex'
    md: require './parts/Markdown'
    stylus: require './parts/Stylus'
    yaml: require './parts/Yaml'

  constructor: (@docs, @site, @id, @src) ->
    @info = null
    @data = null
    @partList = []
    @part = {}
    @coffee = {}
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
    @loadParts cb

  addPart: (dataStr, str) ->
    data = yaml.safeLoad dataStr
    Part = partTypes[data.type]
    unless Part?
      return cb errors.create 'unknown-part', type: data.type
    part = new Part @, data, str, @partList.length
    @partList.push part
    @part[data.id] = part if data.id?
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
    writePart = (p, cb) -> p.writePart cb
    load = (p, cb) -> p.load cb
    async.mapSeries @partList, writePart, (err) =>
      return cb err if err
      async.mapSeries @partList, load, cb

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
      html = minifyHtml html, @site.minifyHtmlOptions
      @save html, cb

  buildHtml: (cb) ->
    return @main.render {}, cb if @main
    @asyncFunctionSet.innerDoc {}, cb

  save: (html, cb) ->
    file = @site.path "@gen/#{@id}.html"
    @site.writeFile file, html, cb

class StrigoiExports
  constructor: (@doc) ->
    @async = @doc.async
    @coffee = @doc.coffee
    @docs = @doc.docs.docs
    @mod = @doc.site.modules
    @part = @doc.part
    @site = @doc.site
    @yaml = @doc.yaml

class AsyncFunctionSet
  constructor: (@doc) ->

  innerDoc: (args, cb) ->
    f = (p, cb) ->
      return cb null, '' if p.data.exclude or p.data.main
      p.render {}, cb

    async.mapSeries @doc.partList, f, (err, results) ->
      return cb err if err
      cb null, results.join ''

  readFile: (args, cb) ->
    file = @doc.site.path args[0], '@dir'
    fs.readFile file, {encoding: 'utf8'}, cb

  joinFiles: (args, cb) ->
    files = args.map (f) => @doc.site.path f, '@dir'
    read = (f, cb) ->
      fs.readFile f, {encoding: 'utf8'}, (err, data) ->
        return cb err if err
        data += '\n' if data[data.length - 1] isnt '\n'
        cb null, data

  renderPart: (args, cb) ->
    @doc.part[args[0]].render args[1] or {}, cb

  renderJadeFile: (args, cb) ->
    file = @doc.site.path args[0], '@tmp'
    locals =
      doc: @doc
      strigoi: @doc.exports
      filename: file
    cb null, jade.renderFile file, @doc.site.merge args[1], locals

  renderStylusFile: (args, cb) ->
    file = @doc.site.path args[0], '@dir'
    opts = @doc.site.stylusOptions
    opts = @doc.site.merge opts, args[1] if args[1]
    fs.readFile file, {encoding: 'utf8'}, (err, data) =>
      return cb err if err
      stylus data
      .include nib.path
      .set 'filename', file
      .set 'compress', !!opts.compress
      .set 'include css', !!opts.includeCss
      .render (err, css) =>
        return cb err if err
        css = @doc.async[opts.includeBefore] + css if opts.includeBefore
        css += @doc.async[opts.includeAfter] if opts.includeAfter
        cb null, css

  bundleStylus: (args, cb) ->
    [from, to, opts] = args
    to = @doc.site.path to, '@gen'
    @renderStylusFile [from, opts], (err, css) =>
      return cb err if err
      @doc.site.writeFile to, css, cb
