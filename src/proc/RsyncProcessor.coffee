async = require 'async'
fs = require 'fs'
path = require 'path'

module.exports = class RsyncProcessor extends require './Processor'
  run: (cb) ->
    return cb() unless @site.command is 'build'
    rsync = (r, cb) =>
      opts = ['-a']
      froms = null
      to = null

      if r instanceof Array
        froms = r.slice 0, r.length - 1
        to = r[r.length - 1]
      else
        if r.from instanceof Array
          froms = r.from
        else
          froms = [r.from]
        to = r.to

      froms = froms.map (f) => @site.path f, '@dir'
      to = @site.path '@gen/' + to

      fs.mkdir path.dirname(to), (err) =>
        # Ignore error.
        opts.push.apply opts, froms
        opts.push to
        @site.spawn 'rsync', opts, cb

    async.mapSeries @site.rsync, rsync, cb
