fse = require 'fs-extra'

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
    return cb() unless @site.command is 'clean' and @site.opts.clean.gen
    @site.log "Removing tmp dir: '#{@genDir}'."
    fse.remove @genDir, cb

  cleanupTmp: (cb) ->
    return cb() unless @site.command is 'clean' and @site.opts.clean.tmp
    @site.log "Removing gen dir: '#{@tmpDir}'."
    fse.remove @tmpDir, cb

  recreate: (cb) ->
    fse.mkdirp @genDir, 0o755, =>
      fse.mkdirp @tmpDir, 0o755, ->
        cb() # Ignore errors.
