GITLAB_URL = process.env.GITLAB_URL or "http://192.168.1.32:808"
GITLAB_TOKEN = process.env.GITLAB_TOKEN or "V32g5nW6jbmKNGWuGx9k"

gitlab = (require 'gitlab')
  url: GITLAB_URL
  token: GITLAB_TOKEN

module.exports = (robot) ->

  robot.hear /create project (.*)$/i, (res) ->
    name = res.match[1].trim()
    projectData = {"name": name}
    gitlab.projects.create projectData, (body) ->
      if body.id?
        fileData = {
          "projectId": body.id,
          "file_path": "README.md",
          "branch_name": "master",
          "content": "# README for #{body.name}\n",
          "encoding": "text",
          "commit_message": "initial commit",
        }
        gitlab.projects.repository.createFile fileData, (r) ->
          if r.file_path == fileData.file_path
            branchData = {
              "projectId": body.id,
              "branch_name": "develop",
              "ref": "master",
            }
            gitlab.projects.repository.createBranch branchData, (re) ->
              if re.name == branchData.branch_name
                gitlab.projects.repository.protectBranch body.id, "develop", (body) ->
                  if body.protected == true
                    return res.reply "成功"
                  return res.reply "分支develop加锁失败"
              return res.reply "创建develop分支失败"
          return res.reply "初始化版本库失败"
      return res.reply "项目创建失败"
    return res.reply "失败"
