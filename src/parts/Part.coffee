module.exports = class Part
  constructor: (@doc, @data, @str) ->

  @extension = ''

  filePath: ->
    root = @doc.site.fromTmpPath @doc.site.idsDir
    "#{root}/#{@doc.id}/#{@data.id}#{@constructor.extension}"

  load: (cb) -> cb()

  render: (opts, cb) -> cb null, ''
