Document = require '../Document'
fs = require 'fs'
path = require 'path'
recursive = require 'recursive-readdir'

module.exports = class DocumentsProcessor extends require './Processor'
  constructor: ->
    super
    @docs = {}
    @docsList = []

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
      place = relative.substring 0, relative.length - 6
      @docsList.push @docs[place] = new Document @, place, full
    return

  loadDocs: (cb) ->
    @site.successiveCalls @docs, ['init', 'load', 'write'], cb

  processDocs: (cb) ->
    cb()
