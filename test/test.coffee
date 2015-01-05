# build time tests for grep plugin
# see http://mochajs.org/

grep = require '../client/grep'
expect = require 'expect.js'

describe 'grep plugin', ->

  describe 'parse', ->
    it 'accepts empty', ->
      [program,listing,errors] = grep.parse ''
      expect(errors).to.eql 0

    it 'accepts whitespace', ->
      [program,listing,errors] = grep.parse '   \n   '
      expect(errors).to.eql 0

    it 'ignores empty lines', ->
      [program,listing,errors] = grep.parse '   \n    \n'
      expect(program).to.eql []

    it 'accepts item types', ->
      [program,listing,errors] = grep.parse 'ITEM paragraph'
      expect(program).to.eql [{'op': 'ITEM', 'type': 'paragraph'}]

    it 'accepts action types', ->
      [program,listing,errors] = grep.parse 'ACTION fork'
      expect(program).to.eql [{'op': 'ACTION', 'type': 'fork'}]

    it 'accepts text patterns', ->
      [program,listing,errors] = grep.parse 'TEXT foo'
      expect(program).to.eql [{'op':'TEXT', 'regex': {}}]

    it 'accepts item with unspecified type', ->
      [program,listing,errors] = grep.parse 'ITEM'
      expect(program).to.eql [{'op': 'ITEM', 'type': ''}]


  describe 'parse fails on', ->
    it 'unknown operation', ->
      [program,listing,errors] = grep.parse 'MUMBLE'
      expect(errors).to.eql 1

    it 'unreasonable type', ->
      [program,listing,errors] = grep.parse 'ITEM void*'
      expect(errors).to.eql 1

    it 'irregular expression', ->
      [program,listing,errors] = grep.parse 'TEXT a)b'
      expect(errors).to.eql 1

  page = {
    'title':'Federated Wiki',
    'story':[
      {'type':'paragraph'; 'text':'It keeps getting better.'},
      {"type":'video'; 'text':'YOUTUBE 2R3LM_A7Cg4\nWard introduces the parts.'}
    ],
    'journal':[
      {'type':'create'},
      {'type':'fork', 'site':'fed.wiki.org'}
    ]
  }

  describe 'sample eval', ->
    it 'should find a video', ->
      expect(grep.evalPage page, [{'op': 'ITEM', 'type':'video'}], 0).to.be true

    it 'should not find a method', ->
      expect(grep.evalPage page, [{'op': 'ITEM', 'type':'method'}], 0).to.be false

    it 'should find a fork', ->
      expect(grep.evalPage page, [{'op': 'ACTION', 'type':'fork'}], 0).to.be true

    it 'should not find a delete', ->
      expect(grep.evalPage page, [{'op': 'ACTION', 'type':'delete'}], 0).to.be false

    it 'should find ward in text', ->
      expect(grep.evalPage page, [{'op': 'ITEM', 'type':''}, {'op':'TEXT', 'regex':/ward/im}], 0).to.be true

    it 'should find federated in title', ->
      expect(grep.evalPage page, [{'op': 'TITLE', 'regex':/federated/im}], 0).to.be true


