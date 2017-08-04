Utils = require './utils'
request = require 'request-promise'
client = require './redis'

module.exports = (robot) ->

  robot.hear /xxxxx login (.*) (.*)$/i, (res) ->
    name = res.message.user.name
    key = name + "-authtoken"
    username = res.match[1]
    password = res.match[2]
    body = JSON.stringify({username: username, password: password})
    options = Utils.requestData "post", "/token/", {body: body}
    request(options)
      .then (body) ->
        body = JSON.parse(body)
        if body.token?
          client.set(key, body.token)
            .then () ->
              res.send "`OK`"
            .catch (err) ->
              res.send err
        else
          res.send "`Field`"
      .catch (response) ->
        err = response.message
        res.send err

  robot.hear /xxxxx(.*)/i, (res) ->
    username = res.message.user.name
    key = username + "-authtoken"
    argv = res.match[1]
    return if argv.indexOf("login") is 1
    body = JSON.stringify({cmd: argv})
    client.get(key)
      .then (token) ->
        return res.send "Pleases use 'xxxxx login <username> <password>' to login" unless token
        options = Utils.requestData "post", "/api/execute/", {body: body, token: token}
        request(options)
          .then (body) ->
            body = JSON.parse(body)
            rc = body.rc

            stdout = "`#{body.stdout.trim()}`"
            stderr = if body.stderr then "`#{body.stderr}`" else body.stderr

            stdout = stdout.replace(/\n/g, "`\n`")
            stdout = stdout.replace(/\ /g, "  ")
            stdout = stdout.replace(/``/g, "")

#            TextMessage
            if rc is 0
              res.send stdout
            else if rc is 1
              res.send if stderr then stderr else stdout
            else
              res.send body.toString()
          .catch (response) ->
            err = response.message
            res.send err
      .catch (err) ->
        res.send err.toString()
