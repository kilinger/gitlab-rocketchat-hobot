Url   = require "url"
Redis = require("promise-redis")()

redisUrl = process.env.REDIS_URL or 'redis://localhost:6379'

info   = Url.parse redisUrl, true

exports.client = () ->
  if info.auth
    client = Redis.createClient(info.port, info.hostname, {no_ready_check: true})
  else
    client = Redis.createClient(info.port, info.hostname)
  return client
