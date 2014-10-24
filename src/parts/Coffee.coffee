module.exports = class Coffee extends require './Part'
  @extension = '.coffee'

  load: (cb) ->
    return cb() unless @doc.site.command is 'build'
    return cb() unless @data.id or @data.render
    try
      @required = require @filePath()
    catch err
      return cb err
    @doc.coffee[@data.id] = @required if @data.id
    cb()

  render: (opts, cb) ->
    return cb null, '' unless @required
    @required[@data.render[0]] @data.render[1], cb
