marked = require 'marked'
minifyHtml = require('html-minifier').minify
Type = require './Type'

marked.setOptions
  smartypants: true

module.exports = class Markdown extends Type
  constructor: ->
    super
    @minifyHtmlOptions =
      removeComments: true
      collapseWhitespace: true
      caseSensitive: true

  load: (cb) ->
    @html = marked @str
    @html = minifyHtml @html, @minifyHtmlOptions
    cb()
