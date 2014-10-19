module.exports = class Part
  constructor: (@doc, @data, @str) ->

  @extension = ''

  load: (cb) -> cb()

  render: (opts, cb) -> cb null, ''
