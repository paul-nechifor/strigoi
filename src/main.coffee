fs = require 'fs'
optimist = require 'optimist'
Site = require './Site'

module.exports = main = ->
  argv = optimist
  .usage 'Usage: $0 [file]'

  .alias 'clean', 'c'
  .describe 'clean', 'Clean both generated and temporary files and exit.'

  .describe 'clean-gen', 'Clean generated files and exit.'

  .describe 'clean-tmp', 'Clean temporary files and exit.'

  .alias 'site-dir', 'd'
  .describe 'site-dir', 'Where "strigoifile.coffee" would be.'

  .alias 'configure', 's'
  .describe 'configure', 'The JSON to pass to Site.configure.'

  .alias 'help', 'h'
  .describe 'help', 'Print this help message.'

  .argv

  return optimist.showHelp() if argv.h

  if argv._.length > 1
    console.error 'Only one file can be processed as an argument.'
    process.exit 1

  opts =
    clean:
      gen: argv['clean-gen'] or argv.clean
      tmp: argv['clean-tmp'] or argv.clean
    configure: argv.configure

  if argv._.length is 1
    opts.file = argv._[0]
  else if argv['site-dir']
    opts.dir = argv['site-dir']
  else
    opts.dir = process.cwd()

  site = new Site opts
  site.run (err) ->
    throw err if err
