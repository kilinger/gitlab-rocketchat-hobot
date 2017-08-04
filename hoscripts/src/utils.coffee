DEPLOY_API_URL = process.env.DEPLOY_API_URL or "http://192.168.1.32:8000"

class Utils

  @requestData: (method, url, kwargs) ->
    options = {
      "uri": DEPLOY_API_URL + url
      "method" : method
      "headers": {
        "Content-Type": "application/json"
      }
    }
    options.body = kwargs.body if kwargs?.body?
    options.headers.Authorization = "Token " + kwargs.token if kwargs?.token?
    return options

module.exports = Utils

