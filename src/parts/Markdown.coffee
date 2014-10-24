marked = require 'marked'

marked.setOptions
  smartypants: true

module.exports = class Markdown extends require './Part'
  @extension = '.md'

  render: (opts, cb) ->
    cb null, marked @str
