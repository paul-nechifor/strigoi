async = require 'async'
errors = require '../errors'
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
    fse.mkdirp @site.path('@modules'), cb

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
    from = @site.path opts.path, '@dir'
    try
      mod =  require from + '/strigoi-module.coffee'
    catch err
      if err.code is 'MODULE_NOT_FOUND'
        return cb errors.create 'module-not-found', module: opts.path
      else
        return cb err
    @site.modules[mod.name] = mod
    @site.log "Init module '#{mod.name}'."
    mod.init @site, opts, (err) =>
      return cb err if err
      fse.symlink from, @site.path("@modules/#{mod.name}"), (err) ->
        # Ignore for now.
        cb()

  installPartialPackages: (cb) ->
    lines = ["cd '#{@site.path '@tmp'}'"]
    if @site.npmPackages.length > 0
      lines.push "npm install --prefix . #{@site.npmPackages.join ' '}"
    if @site.bowerPackages.length > 0
      lines.push "bower install #{@site.bowerPackages.join ' '}"
    @site.npmPackages = []
    @site.bowerPackages = []
    @site.exec lines.join('\n'), cb
