should = require('chai').should()
s = require process.env.SRC_REQ or '../src'

describe 'File', ->

  describe '#createRootDir', ->

    it 'should get rid of path redundancies', ->

      s.File.createRootDir '/highway/./to/the/../heaven'
      .path.should.equal '/highway/to/heaven'

    it 'should get rid of trailing slashes', ->

      s.File.createRootDir '/it/is/'
      .path.should.equal '/it/is'

      s.File.createRootDir '/i/am///'
      .path.should.equal '/i/am'

    it 'should have no parent', ->
      f = s.File.createRootDir '/asdf/ff'
      should.equal f.parent, null

    it 'should have no children', ->
      f = s.File.createRootDir '/asdf/weoifjwe'
      should.equal f.children, null

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

describe 'Strigoi', ->

  describe 'constructor', ->

    it 'should start without a root', ->
      s = new s.Strigoi
      should.equal s.root, null
