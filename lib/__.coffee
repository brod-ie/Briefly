# Helper class
class __

  config: ->
    return process.env if process.env.ENVIRONMENT?
    return require "#{ __dirname }/../../Briefly.json"

module.exports = new __