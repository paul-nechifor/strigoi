yaml = require 'js-yaml'

module.exports = class Yaml extends require './Part'
  constructor: ->
    super
    @content = null

  load: (cb) ->
    @content = yaml.safeLoad @str
    @doc.yaml[@data.id] = @content if @data.id
    cb()
