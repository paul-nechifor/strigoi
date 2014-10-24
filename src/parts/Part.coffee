module.exports = class Part
  constructor: (@doc, @data, @str, @index) ->

  @extension = ''

  filePath: ->
    name = @data.id or @index
    @doc.site.path "@ids/#{@doc.id}/#{name}#{@constructor.extension}"

  writePart: (cb) ->
    return cb() unless @doc.site.command is 'build'
    @doc.site.writeFile @filePath(), @str, cb

  load: (cb) -> cb()

  render: (opts, cb) -> cb null, ''
