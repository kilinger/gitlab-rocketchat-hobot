GITLAB_URL = process.env.GITLAB_URL or "http://192.168.1.32:808"
GITLAB_TOKEN = process.env.GITLAB_TOKEN or "V32g5nW6jbmKNGWuGx9k"
ROCKETCHAT_URL = process.env.ROCKETCHAT_URL or "192.168.1.32:13000"

module.exports = (robot) ->

  gitlab = (require 'gitlab')
    url: GITLAB_URL
    token: GITLAB_TOKEN

  get_merge_comment = (data, room) ->
    path = "/projects/#{data.project_id}/merge_request/#{data.merge_request.id}/comments"
    gitlab.get path, (comments) ->
      uid = []
      for comment in comments
        if comment.note.indexOf("LGFM") >= 0 and (comment.author.id not in uid) and
          (comment.author.id != data.merge_request.author_id)
            uid.push(comment.author.id)
      name = if data.user.name.length > data.user.username.length then data.user.name else data.user.username
      msg = "@all: #{name} 已评论 #{data.object_attributes.url}, 状态为: #{data.merge_request.merge_status},
      已有 #{uid.length} 人同意合并\n"
      if uid.length >= 2 and data.merge_request.merge_status == "can_be_merged"
        robot.messageRoom room, msg + "已满足合并条件!"
      else
        robot.messageRoom room, msg

  robot.router.post '/incident/:room', (req, res) ->
    room = req.params.room
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    if data.object_kind is 'merge_request' and data.object_attributes.state is 'opened'
      robot.messageRoom room, "@all: #{data.user.name} 已提交Merge Request, 快来审代码吧 #{data.object_attributes.url}"
    else if data.object_kind is 'note'
      get_merge_comment data, room

    res.send 'OK'

  robot.hear /sub (.*)$/i, (res) ->
    key = res.message.room
    project = res.match[1]
    data = {
      "url": "http://" + ROCKETCHAT_URL + "/incident/" + key,
      "push_events": "true",
      "merge_requests_events": "true",
      "note_events": "true",
      "enable_ssl_verification": "false",
    }
    gitlab.projects.hooks.add project, data, (body) ->
      res.reply if body.url is data.url then "成功" else "失败"
