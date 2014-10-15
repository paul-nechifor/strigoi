module.exports = class PackageProcessor extends require './Processor'
  init: (cb) ->
    lines = ["cd '#{@site.dirJoin @site.tmpDir}'"]
    if @site.npmPackages.length > 0
      lines.push "npm install --prefix . #{@site.npmPackages.join ' '}"
    if @site.bowerPackages.length > 0
      lines.push "bower install #{@site.bowerPackages.join ' '}"
    @site.exec lines.join('\n'), cb
