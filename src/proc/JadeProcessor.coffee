path = require 'path'
async = require 'async'
fse = require 'fs-extra'

module.exports = class JadeProcessor extends require './Processor'
  init: (cb) ->
    proc = (f, cb) =>
      relative = path.relative @site.dir, f
      try fs.mkdirSync path.dirname relative
      fse.copy f, @site.dirJoins(@site.tmpDir, relative), cb
    async.map @site.files.types['.jade'], proc, cb
