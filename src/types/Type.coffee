module.exports = class Type
  constructor: (@data, @str) ->
    @html = ''

  process: (cb) ->
