tmp = require 'tmp'
fs = require 'fs'

module.exports = class Latex extends require './Part'
  constructor: ->
    super

  render: (opts, cb) ->
    tmp.dir (err, path) =>
      return cb err if err
      fs.writeFile path + '/a.tex', @str, (err) =>
        return cb err if err
        @compile path, opts, cb

  compile: (path, opts, cb) ->
    ratio = opts.ratio or 1.3
    @doc.site.exec """
      cd '#{path}'
      latex '#{path}/a.tex'
      dvisvgm -c #{ratio} --no-fonts a.dvi
      scour #{@doc.site.scourOptions.join ' '} -i a.svg -o b.svg
    """, (err) =>
      return cb err if err
      fs.readFile path + '/b.svg', {encoding: 'utf8'}, (err, data) =>
        data = data.replace /<!--.*-->/, ''
        data = data.replace /<!DOCTYPE.*>/i, ''
        data = data.replace />\n</g, '><'
        data = data.trim()
        if @data.id
          data = "<div id='#{@data.id}'>#{data}</div>"
        @doc.site.spawn 'rm', ['-fr', path], (err) ->
          return cb err if err
          cb null, data
