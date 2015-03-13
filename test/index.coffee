# # Strigoi tests

# ## Requirements

should = require('chai').should()
mockFs = require 'mock-fs'
s = require process.env.SRC_REQ or '../src'

# ## Helpful utilities

fsys = (opts, cb) ->
  {cwd, chdir} = process
  currentDir = '/'
  process.cwd = -> currentDir
  process.chdir = (dir) -> currentDir = dir

  mockFs opts.mock
  process.chdir opts.cwd

  doneCb = ->
    mockFs.restore()
    process.cwd = cwd
    process.chdir = chdir

  cb doneCb

getFilesAsDict = (root) ->
  ret = {}

  if root.children isnt null
    ret.children = {}
    for k, v of root.children
      ret.children[k] = getFilesAsDict v
  else
    ret.children = null

  ret

assertScan = (mock, cwd, dir, done, equal, expectErr, config) ->
  fsys {mock: mock, cwd: cwd}, (cb) ->
    root = s.File.createRootDir (new s.Strigoi), dir
    root.strigoi.config = config if config
    root.scanAllFiles (err) ->
      cb()
      if expectErr
        err.should.deep.equal expectErr
      else
        should.not.exist err
        getFilesAsDict root
        .should.deep.equal equal
      done()

# ## Tests

# ### File
describe 'File', ->

  describe '#createRootDir', ->
    emptyStrig = new s.Strigoi

    it 'should get rid of path redundancies', ->
      s.File.createRootDir emptyStrig, '/highway/./to/the/../heaven'
      .path.should.equal '/highway/to/heaven'

    it 'should get rid of trailing slashes', ->
      s.File.createRootDir emptyStrig, '/it/is/'
      .path.should.equal '/it/is'

      s.File.createRootDir emptyStrig, '/i/am///'
      .path.should.equal '/i/am'

    it 'should keep the root slash', ->
      s.File.createRootDir emptyStrig, '/'
      .path.should.equal '/'

    it 'should use absolute paths', (done) ->
      fsys
        mock: '/there/once/was': 'a'
        cwd: '/there'
      , (cb) ->
        s.File.createRootDir emptyStrig, 'once/'
        .path.should.equal '/there/once'
        cb()
        done()

    it 'should have no parent', ->
      f = s.File.createRootDir emptyStrig, '/asdf/ff'
      should.equal f.parent, null

    it 'should have no children loaded', ->
      s.File.createRootDir emptyStrig, '/asdf/weoifjwe'
      .children.should.deep.equal {}

  describe '#scanAllFiles', ->

    it 'should read an all .strig directory structure', (done) ->
      mock =
        '/aici':
          'a.strig': 'a'
          'b.strig': 'b'

      assertScan mock, '/', '/', done,
        children:
          'aici':
            children:
              'a.strig':
                children: null
              'b.strig':
                children: null
          'tmp':
            children: {}

    it 'should ignore unrecognized files', (done) ->
      mock =
        '/aici':
          'a.strig': 'a'
          'b.qqqqqqq': 'b'
      assertScan mock, '/.//', '/././/', done,
        children:
          'aici':
            children:
              'a.strig':
                children: null
          'tmp':
            children: {}

    it 'should respect ignore rules', (done) ->
      mock =
        '/aa':
          'bb':
            'b.strig': 'b'
          'cc':
            'c.strig': 'c'
          'dd':
            'd.strig': 'd'
      expect =
        children:
          'bb':
            children:
              'b.strig':
                children: null
          'dd':
            children:
              'd.strig':
                children: null
      config = new s.Config
      config.walkIgnore = /^cc$/

      assertScan mock, '/aa/cc', '/aa', done, expect, null, config

    it 'should fail if no .strig files are found', (done) ->
      mock =
        '/aici2':
          'a.strig': 'a'
        '/not-here':
          'a.qqqqqqq': 'a'
      assertScan mock, '/aici', '/not-here', done, null,
          new s.StrigFsEx 'no-strig-files'

    it 'should fail if a file is given instead of a dir', (done) ->
      mock = '/aaa': 'a.qqqqqqq': 'a'
      assertScan mock, '/aaa', '/aaa/a.qqqqqqq', done, null,
          new s.StrigFsEx 'not-a-dir'

    it 'should fail if the dir does not exist', (done) ->
      mock = '/bbb': 'a.qqqqqqq': 'a'
      assertScan mock, '/bbb', '/ccc', done, null,
          new s.StrigFsEx 'not-a-dir'


# ### parseStrigParts
describe 'parseStrigParts', ->

  it 'should recognize a single multiline header', ->
    s.parseStrigParts """
      ---
      hello: world
      ---
      text here
    """
    .should.deep.equal [
      header: hello: 'world'
      content: 'text here'
    ]

  it 'should recognize two multiline headers', ->
    s.parseStrigParts """
      ---
      hello: world
      ---
      text here
      ---
      bye: non world
      ---
      text not here
    """
    .should.deep.equal [
        header: hello: 'world'
        content: 'text here'
      ,
        header: bye: 'non world'
        content: 'text not here'
    ]

  it 'should recognize a single single-line header', ->
    s.parseStrigParts """
      --- hello2: world2
      text2 here2
    """
    .should.deep.equal [
      header: hello2: 'world2'
      content: 'text2 here2'
    ]

  it 'should recognize two single-line headers', ->
    s.parseStrigParts """
      --- aaa: bbb
      cccc dddd
      --- eee: fff
      gggg hhhh
    """
    .should.deep.equal [
        header: aaa: 'bbb'
        content: 'cccc dddd'
      ,
        header: eee: 'fff'
        content: 'gggg hhhh'
    ]

  it 'should recognize mixed headers', ->
    s.parseStrigParts """
      --- a: a
      AA
      --- b: b
      BB
      ---
      c: c
      d: d
      ---
      CC
      DD
      ---
      e: e
      f: f
      ---
      EE
      FF
      --- {g: g, h: h}
      GG
      HH
      ---
      i: i
      ---
      II
    """
    .should.deep.equal [
        header: a: 'a'
        content: 'AA'
      ,
        header: b: 'b'
        content: 'BB'
      ,
        header: c: 'c', d: 'd'
        content: 'CC\nDD'
      ,
        header: e: 'e', f: 'f'
        content: 'EE\nFF'
      ,
        header: g: 'g', h: 'h'
        content: 'GG\nHH'
      ,
        header: i: 'i'
        content: 'II'
    ]

  it 'should require starting with ---', ->
    fn = ->
      s.parseStrigParts """
        ccc
        ---
        bbb
      """
    fn.should.throw s.StrigParsingEx, 'start-delimiter-missing'

  it 'should not allow a header right after another header', ->
    fn = ->
      s.parseStrigParts """
        ---
        a: a
        --- c: c
        bbb
      """
    fn.should.throw s.StrigParsingEx, 'header-after-header'

# ### Strigoi
describe 'Strigoi', ->

  describe 'constructor', ->

    it 'should start without a root', ->
      s = new s.Strigoi
      should.equal s.root, null
