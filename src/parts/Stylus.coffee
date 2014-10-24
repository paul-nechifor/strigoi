module.exports = class Stylus extends require './Part'
  @extension = '.styl'

  render: (opts, cb) ->
    @doc.asyncFunctionSet.renderStylusFile [@filePath()], cb
