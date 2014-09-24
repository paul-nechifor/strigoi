yaml = require 'js-yaml'
Type = require './Type'

module.exports = class Yaml extends Type
  constructor: ->
    super
    @content = null

  process: (cb) ->
    @content = yaml.safeLoad @str
    cb()
