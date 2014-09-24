jade = require 'jade'
Type = require './Type'

module.exports = class Jade extends Type
  constructor: ->
    super
    @fn = null
    @locals =
      part: @
      strigoi: @doc.exports

  load: (cb) ->
    @fn = jade.compile @str, {}
    @html = @fn @locals unless @data.exclude or @data.main
    cb()

  render: -> @fn @locals
