# build time tests for grep plugin
# see http://mochajs.org/

grep = require '../client/grep'
expect = require 'expect.js'

describe 'grep plugin', ->

  describe 'parse', ->

    # it 'can make itallic', ->
    #   result = grep.expand 'hello *world*'
    #   expect(result).to.be 'hello <i>world</i>'
