# coffeelint-multiple-callback
CoffeeLint rule that finds instances where callbacks might be called more than once or not at all.

This code is in the very early stages of development. If you find cases where it's broken, please add example test fixtures. For lines in tests that should trigger an error, add the comment ``# HIT`` to the end of the line. The tests go through line by line and verify that lines with that comment trigger a linting error and all other lines do not.
## Examples
These functions have the potential of calling cb() multiple times or zero times, and is likely an error:
```coffee
# cb() is called twice

badFunc = (err, cb)->
  cb err
  cb err # BAD
  return
```

```coffee
# cb() could be called multiple times

badIf = (err, cb)->
  if err
    cb err

  cb null # BAD
  return
```

```coffee
# cb() might never be called

badIf = (err, cb)-> # BAD
  if err
    cb err
  return
```

These functions are okay, since they only call the callback once no matter how the logic runs:
```coffee
goodIf = (err, cb)->
  if err
    cb err
  else
    cb null
  return
```
```coffee
goodIf2 = (err, cb)->
  if err
    cb err
    return

  cb null
  return
```
```coffee
goodIf3 = (err, cb)->
  if cb
    cb()
  return
```

## Installation
```sh
npm install coffeelint-multiple-callback
```
## Usage

Add the following configuration to coffeelint.json:

```json
"multiple_callback": {
  "module": "coffeelint-multiple-callback"
}
```
## Configuration

There are currently no configuration options.

## Contributing
I don't know what I'm doing. I just jumped in with an idea and tried to get it to work. Please assist if this is something you understand or have ideas on how to handle this better.