types =
  'module-not-found': (t, o) ->
    "Module '#{o.module}' not found. Did you run the install step?"
  'unknown-dir-shortcut': (t, o) ->
    "Unknown dir shortcut: '#{o.name}' in '#{o.full}'."
  'unknown-part': (t, o) ->
    "Unknown document type: '#{o.type}'."

exports.create = (type, opts, err) ->
  errType = types[type]
  switch typeof errType
    when 'string' then errType
    when 'function' then errType type, opts
    else type: type, opts: opts, err: err
