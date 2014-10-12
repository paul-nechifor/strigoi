async = require 'async'
{exec, spawn} = require 'child_process'

module.exports = class Processor
  constructor: (@site) ->

  init: (cb) -> cb()

  run: (cb) -> cb()

  finish: (cb) -> cb()

  selfSeries: (list, cb) ->
    list = list.map (i) => i.bind @
    async.series list, cb

  spawn: (name, args, cb) ->
    s = spawn name, args
    s.stdout.on 'data', (data) -> process.stdout.write data
    s.stderr.on 'data', (data) -> process.stderr.write data
    s.on 'close', (code) ->
      cb 'err-' + code unless code is 0
      cb()
