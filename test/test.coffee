fs = require 'fs'
expect = require('chai').expect
CoffeeScript = require 'coffee-script'
Rule = require '../index'
_ = require 'lodash'

getFixtureAST = (fixture)->
  source = fs.readFileSync("#{__dirname}/fixtures/#{fixture}.coffee").toString()
  return CoffeeScript.nodes source

describe 'lint the things', ->

  getErrors = (fixture)=>
    @rule = new Rule()
    @rule.errors = []

    astApi =
      config: use_strict: {}
      createError: (e) -> e

    @rule.lintAST getFixtureAST(fixture), astApi
    @rule.errors.sort (a, b)->
      return a.lineNumber > b.lineNumber
    return

  hasErrorAtLine = (line_number)=>
    error_at_line = _.find @rule.errors, (obj)->
      obj.lineNumber is line_number

    if error_at_line
      return true

    return false

  checkFixtureForHits = (fixture)=>
    fixture_source = fs.readFileSync("#{__dirname}/fixtures/#{fixture}.coffee").toString()
    fixture_nodes = CoffeeScript.nodes fixture_source

    @rule = new Rule()
    @rule.errors = []

    astApi =
      config: use_strict: {}
      createError: (e) -> e

    @rule.lintAST fixture_nodes, astApi
    @rule.errors.sort (a, b)->
      return a.lineNumber > b.lineNumber

    regex_is_hit = /#\s*HIT\s*$/i
    _.each fixture_source.split('\n'), (line_content, key)=>
      line_number = key + 1
      if regex_is_hit.test line_content
        expectHasErrorAtLine line_number
      else
        expectHasNoErrorAtLine line_number
      return

    return

  expectHasErrorAtLine = (line_number)=>
    has_err = hasErrorAtLine line_number
    expect(has_err, "Could not find HIT at line #{line_number}").to.be.true
    return

  expectHasNoErrorAtLine = (line_number)=>
    has_err = hasErrorAtLine line_number
    expect(has_err, "Found unexpected HIT at line #{line_number}").to.be.false
    return


  it 'basic', =>
    getErrors('basic')
    console.log @rule.errors
    checkFixtureForHits('basic')
    return

  it 'mocha', =>
    getErrors('mocha')
    console.log @rule.errors
    checkFixtureForHits('mocha')
    return

  it 'express', =>
    getErrors('express')
    console.log @rule.errors
    checkFixtureForHits('express')
    return

  it 'async', =>
    getErrors('async')
    console.log @rule.errors
    checkFixtureForHits('async')
    return

  it 'lodash', =>
    getErrors('lodash')
    console.log @rule.errors
    checkFixtureForHits('lodash')
    return

  return
