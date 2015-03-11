require('chai').should()
s = require '../src'

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
      s.File.createRootDir '/asdf/ff'
      .root is null
