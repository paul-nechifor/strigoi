Document = require '../Document'
fs = require 'fs'
path = require 'path'

module.exports = class DocumentsProcessor extends require './Processor'
  constructor: ->
    super
    @docs = {}
    @docList = []

  init: (cb) ->
    for file in @site.files.types['.strig']
      relative = path.relative @site.dir, file
      full = path.resolve @site.dir, file
      id = relative.substring 0, relative.length - 6
      @docList.push @docs[id] = new Document @, @site, id, full
    cb()

  run: (cb) ->
    @site.successiveCalls @docList, ['init', 'load', 'loadAsync', 'write'], cb
