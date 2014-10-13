Document = require '../Document'
fs = require 'fs'
path = require 'path'
recursive = require 'recursive-readdir'

module.exports = class DocumentsProcessor extends require './Processor'
  constructor: ->
    super
    @docs = {}
    @docList = []

  init: (cb) ->
    @selfSeries [
      @findDocs
      @loadDocs
    ], cb

  run: (cb) ->
    @processDocs cb

  findDocs: (cb) ->
    if @site.useDocs
      @addDocs @site.useDocs
      return cb()
    recursive @site.dir, @site.findIgnorePatterns, (err, files) =>
      return cb err if err
      @addDocs files
      cb()

  addDocs: (files) ->
    for file in files
      continue unless file.lastIndexOf('.strig') is file.length - 6
      relative = path.relative @site.dir, file
      full = path.resolve @site.dir, file
      id = relative.substring 0, relative.length - 6
      @docList.push @docs[id] = new Document @, @site, id, full
    return

  loadDocs: (cb) ->
    @site.successiveCalls @docList, ['init', 'load', 'loadAsync', 'write'], cb

  processDocs: (cb) ->
    cb()
