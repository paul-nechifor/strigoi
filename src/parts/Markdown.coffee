marked = require 'marked'
minifyHtml = require('html-minifier').minify

marked.setOptions
  smartypants: true

module.exports = class Markdown extends require './Part'
  constructor: ->
    super

  render: (opts, cb) ->
    html = marked @str
    html = minifyHtml html, @doc.site.minifyHtmlOptions
    cb null, html
