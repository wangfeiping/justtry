### git 基本操作备忘

切换或创建分支
$ git checkout -b dev

查看
$ git status

添加文件
$ git add <file>...

添加更新日志
$ git commit -a -m '更新文档'

提交并签入dev 分支
$ git push --set-upstream origin dev
