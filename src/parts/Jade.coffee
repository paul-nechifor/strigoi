jade = require 'jade'

module.exports = class Jade extends require './Part'
  constructor: ->
    super
    @fn = null
    @locals =
      part: @
      strigoi: @doc.exports

  load: (cb) ->
    @fn = jade.compile @str, {}
    cb()

  render: (opts, cb) ->
    merged = {}
    merged[key] = value for key, value of opts
    merged[key] = value for key, value of @locals
    cb null, @fn merged
