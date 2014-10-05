fs = require 'fs'
optimist = require 'optimist'
Site = require './Site'

module.exports = main = ->
  argv = optimist
  .usage 'Usage: $0 [<file1> <file2> ...]'

  .alias 'c', 'clean'
  .describe 'clean', 'Clean both generated and temporary files.'

  .describe 'clean-gen', 'Clean generated files.'

  .describe 'clean-tmp', 'Clean temporary files.'

  .alias 'd', 'site-dir'
  .describe 'site-dir', 'Where "strigoifile.coffee" would be.'

  .alias 'h', 'help'
  .describe 'help', 'Print this help message.'

  .argv

  if argv.h
    optimist.showHelp()
    process.exit()

  if argv._.length > 1
    console.error 'Only one file can be processed as an argument.'
    process.exit 1

  clean = {}
  clean['gen'] = true if argv['clean-gen'] or argv['clean']
  clean['tmp'] = true if argv['clean-tmp'] or argv['clean']

  site = new Site clean

  cb = (err) ->
    throw err if err
    site.log 'Done.'

  if argv._.length is 1
    site.init {file: argv._[0]}, cb
    return

  if argv['site-dir']
    site.init {dir: argv['site-dir']}, cb
    return

  site.init {dir: process.cwd()}, cb
