async = require 'async'
fs = require 'fs'

module.exports = class PackageProcessor extends require './Processor'
  init2: (cb) ->
    repeat = =>
      @installPackages (err) =>
        return cb err if err
        @initModules (err) =>
          return cb err if err
          return cb null if @noMorePackages()
          setTimeout repeat, 0
    fs.mkdir @site.dirJoins(@site.tmpDir, @site.modulesDir), (err) ->
      #Ignore error.
      repeat()

  noMorePackages: -> @site.npmPackages.length + @site.bowerPackages.length is 0

  initModules: (cb) ->
    modules = @site.useModules
    return cb() if modules.length is 0
    @site.useModules = []
    async.mapSeries modules, @initModule.bind(@), cb

  initModule: (opts, cb) ->
    from = @site.fromPath opts.path
    try
      mod =  require from + '/strigoi-module.coffee'
    catch err
      return cb err
    @site.modules[mod.name] = mod
    mod.init @site, opts, (err) =>
      return cb err if err
      modLinkDir = @site.dirJoins @site.tmpDir, @site.modulesDir, mod.name
      fs.symlink from, modLinkDir, (err) ->
        # Ignore for now.
        cb()

  installPackages: (cb) ->
    return cb() if @noMorePackages()
    lines = ["cd '#{@site.dirJoin @site.tmpDir}'"]
    if @site.npmPackages.length > 0
      lines.push "npm install --prefix . #{@site.npmPackages.join ' '}"
    if @site.bowerPackages.length > 0
      lines.push "bower install #{@site.bowerPackages.join ' '}"
    @site.npmPackages = []
    @site.bowerPackages = []
    @site.exec lines.join('\n'), cb
