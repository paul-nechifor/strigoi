fs = require 'fs'

module.exports = class CleanupProcessor extends require './Processor'
  init: (cb) ->
    @genDir = @site.dirJoin @site.genDir
    @tmpDir = @site.dirJoin @site.tmpDir
    @selfSeries [
      @cleanupGen
      @cleanupTmp
      @recreate
    ], cb

  cleanupGen: (cb) ->
    return cb() unless @site.clean['gen']
    @site.spawn 'rm', ['-fr', @genDir], cb

  cleanupTmp: (cb) ->
    return cb() unless @site.clean['tmp']
    @site.spawn 'rm', ['-fr', @tmpDir], cb

  recreate: (cb) ->
    fs.mkdir @genDir, 0o755, =>
      fs.mkdir @tmpDir, 0o755, ->
        cb() # Ignore errors.
