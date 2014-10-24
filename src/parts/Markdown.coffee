marked = require 'marked'

module.exports = class Markdown extends require './Part'
  constructor: ->
    super
    @opts = @doc.site.markedOptions
    if @data.markedOpts
      @opts = @doc.site.merge @opts, @data.markedOpts

  @extension = '.md'

  render: (opts, cb) ->
    cb null, marked @str, @doc.site.merge @opts, opts
