# Helper class
class __

  config: ->
    if process.env.ENVIRONMENT?
      return process.env
    else
      return require "#{ __dirname }/../../Briefly.json"

module.exports = new __