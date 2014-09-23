async = require 'async'
fs = require 'fs'
optimist = require 'optimist'
Document = require './Document'

module.exports = main = ->
  argv = optimist
  .usage 'Usage: $0 [<file1> <file2> ...]'

  .alias 'c', 'clean'
  .describe 'clean', 'Clean up generated files.'

  .default 'd', process.cwd()
  .alias 'd', 'doc-dir'
  .describe 'd', 'Documents directory. This is where the files are searched' +
      ' for if no files are given as arguments.'

  .alias 'h', 'help'
  .describe 'h', 'Print this help message.'

  .argv

  if argv.h
    optimist.showHelp()
    process.exit()

  if argv._.length > 0
    processFiles argv._
    return

  findFiles argv['doc-dir'], (err, files) ->
    throw err if err
    if files.length is 0
      console.error 'No files give or found.'
      process.exit()
    processFiles files

processFiles = (files) ->
  async.mapSeries files, processFile, (err, results) ->
    throw err if err

processFile = (file, cb) ->
  fs.readFile file, {encoding: 'utf8'}, (err, data) ->
    d = new Document file, data
    d.process (err) ->
      return cb err if err
      d.save cb

findFiles = (dir, cb) ->
  fs.readdir dir, (err, files) ->
    return cb err if err
    files = files.filter (f) -> f.indexOf('.strig') is f.length - 6
    files = files.map (f) -> dir + '/' + f
    cb null, files
