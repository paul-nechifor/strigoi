jade = require 'jade'

module.exports = class Jade extends require './Part'
  constructor: ->
    super
    @fn = null
    @locals =
      part: @
      doc: @doc
      strigoi: @doc.exports

  @extension = '.jade'

  render: (opts, cb) ->
    return @renderId opts, cb if @data.id
    @fn = jade.compile @str, {} unless @fn
    cb null, @fn @doc.site.merge opts, @locals

  renderId: (opts, cb) ->
    @doc.asyncFunctionSet.renderJadeFile [@filePath(), opts], cb
