module.exports = class Part
  constructor: (@doc, @data, @str) ->

  load: (cb) -> cb()

  render: (opts, cb) -> cb null, ''
