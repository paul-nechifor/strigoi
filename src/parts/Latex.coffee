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
    """, (err) =>
      return cb err if err
      fs.readFile path + '/a.svg', {encoding: 'utf8'}, (err, data) =>
        @doc.site.spawn 'rm', ['-fr', path], (err) ->
          return cb err if err
          console.log data
          cb null, data
