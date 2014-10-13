async = require 'async'

module.exports = class Processor
  constructor: (@site) ->

  init: (cb) -> cb()

  run: (cb) -> cb()

  finish: (cb) -> cb()

  selfSeries: (list, cb) ->
    list = list.map (i) => i.bind @
    async.series list, cb
