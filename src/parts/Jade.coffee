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

  load: (cb) ->
    @fn = jade.compile @str, {}
    cb()

  render: (opts, cb) ->
    cb null, @fn @doc.site.merge opts, @locals
