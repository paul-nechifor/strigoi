yaml = require 'js-yaml'
Type = require './Type'

module.exports = class Yaml extends Type
  constructor: ->
    super
    @content = null

  load: (cb) ->
    @content = yaml.safeLoad @str
    cb()
