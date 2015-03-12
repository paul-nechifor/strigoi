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
