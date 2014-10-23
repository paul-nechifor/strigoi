types =
  'module-not-found': (t, o) ->
    "Module '#{o.module}' not found. Did you run the install step?"

exports.create = (type, opts, err) ->
  errType = types[type]
  switch typeof errType
    when 'string' then errType
    when 'function' then errType type, opts
    else type: type, opts: opts, err: err
