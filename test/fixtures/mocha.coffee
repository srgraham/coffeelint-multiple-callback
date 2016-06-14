expect = require('chai').expect

whatever = require 'thing'

describe 'random test fixture', ->
  it 'func 1', (done) ->
    whatever.test_connection (err) ->
      expect(err).to.be.a('null')
      done()
      return
    return

  it 'func 2', (done) ->
    whatever.getPoolConnection (err, conn) ->
      expect(err).to.be.a('null')
      expect(conn).to.respondTo('query')
      expect(conn).to.respondTo('end')
      conn.release()
      done()
      return
    return

  it 'should error', (done)->
    done()
    done() # HIT
    return