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
    @fn = jade.compile @str, {} unless @fn
    cb null, @fn @doc.site.merge opts, @locals
