module.exports = ()->

  out =
    files: [
      "*.coffee"
      {
        pattern: "test/fixtures/*.coffee"
        instrument: false
      }
    ]
    tests: [
      "test/test.coffee"
#      "test/fixtures/*.coffee"
    ]
    env: {
      type: "node"
    }
    testFramework: "mocha"
    delays:
      edit: 500
      run: 150
    workers:
      initial: 1
      regular: 1
    recycle: true
    debug: false
#    reportConsoleErrorAsError: true

  return out
