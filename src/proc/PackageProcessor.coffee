async = require 'async'
fse = require 'fs-extra'

module.exports = class PackageProcessor extends require './Processor'
  init2: (cb) ->
    switch @site.command
      when 'build' then @initModules cb
      when 'install'
        @createModulesDir (err) =>
          #Ignore error.
          @installAndInit cb
      else cb()

  createModulesDir: (cb) ->
    fse.mkdirp @site.dirJoins(@site.tmpDir, @site.modulesDir), cb

  installAndInit: (cb) ->
    moreLeft = => @site.npmPackages.length + @site.bowerPackages.length > 0
    installAndInitPartialPackages = (cb) =>
      @installPartialPackages (err) =>
        return cb err if err
        @initModules cb
    async.whilst moreLeft, installAndInitPartialPackages, cb

  initModules: (cb) ->
    moreLeft = => @site.useModules.length > 0
    initPartialModules = (cb) =>
      modules = @site.useModules
      @site.useModules = []
      async.mapSeries modules, @initModule.bind(@), cb
    async.whilst moreLeft, initPartialModules, cb

  initModule: (opts, cb) ->
    from = @site.fromPath opts.path
    try
      mod =  require from + '/strigoi-module.coffee'
    catch err
      return cb err
    @site.modules[mod.name] = mod
    @site.log "Init module '#{mod.name}'."
    mod.init @site, opts, (err) =>
      return cb err if err
      modLinkDir = @site.dirJoins @site.tmpDir, @site.modulesDir, mod.name
      fse.symlink from, modLinkDir, (err) ->
        # Ignore for now.
        cb()

  installPartialPackages: (cb) ->
    lines = ["cd '#{@site.dirJoin @site.tmpDir}'"]
    if @site.npmPackages.length > 0
      lines.push "npm install --prefix . #{@site.npmPackages.join ' '}"
    if @site.bowerPackages.length > 0
      lines.push "bower install #{@site.bowerPackages.join ' '}"
    @site.npmPackages = []
    @site.bowerPackages = []
    @site.exec lines.join('\n'), cb
