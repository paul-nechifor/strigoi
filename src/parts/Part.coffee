module.exports = class Part
  constructor: (@doc, @data, @str) ->

  @extension = ''

  filePath: ->
    @doc.site.path "@ids/#{@doc.id}/#{@data.id}#{@constructor.extension}"

  load: (cb) -> cb()

  render: (opts, cb) -> cb null, ''
