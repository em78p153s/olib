---
layout: post
title: OLIB-Github常用指令
sidebar_link: false
topmost: 2
date: 2022-01-31
category: OLIB-Doc
tags:
- Github 
- ssh
last_modified_at: 2022-01-31T12:57:42-05:00
# excerpt_separator:  <!--more-->
---

#### 一：Github使用前配置
1. 配置Github用户名和邮箱<br>

```cpp
    git config --global user.name "zhang_san"
    git config --global user.email zhang_san@163.com
    git config --global credential.helper store
    git config --list
```

2. 生成并配置连接到Github远程存储库的凭据<br>
```cpp
    ls -al ~/.ssh                                           # 查看所有密钥
    ssh-keygen -t rsa -C zhang_san@163.com -f id_rsa        # 创建密钥（此命令需要敲两次回车键）
```

![生成ssh访问凭据](/assets/images/home/ssh_cfg_init_0.png)<br>
![ssh方式访问凭据配置](/assets/images/home/ssh_cfg.png)<br>
<p>
    id_rsa 是私钥，id_rsa.pub 是公钥<br>
    复制凭据：即复制文件D:\web\id_rsa.pub中字符串<br>
    配置凭据：即打开Github->User->Settings->SSH and GPG keys-New SSH key<br>
    填写Title：即zhang_san<br>
    填写Key：即复制的文件id_rsa.pub中字符串<br>
</p>

#### 二：Github存储库关联配置
1. 已有远程库，克隆Github用户：zhang_san存储库：web到本地<br>

    git clone git@github.com:zhang_san/web.git              # SSH方式克隆远程仓库
    git clone https://github.com/zhang_san/web.git          # https方式克隆远程仓库到本地，需要再次验证用户名与密码。

2. 已有本地库，没有创建远程库，新建本地存储库并与远程存储库同步：假设用户名为：zhang_san 且已有远程存储库：web
```cpp
    d:                                                      # 进入Windows D盘根目录
    mkdir web                                               # 创建web目录
    cd web                                                  # 进入web目录
    git init                                                # 初始化web存储库
    git remote rm origin                                    # 移除原有origin
    git remote add origin git@github.com:zhang_san/web.git  # 关联到远程仓库
    git remote -v                                           # 检查关联仓库是否成功
```
3. 设置本地分支与远程分支对应，变更文件后提交修改部分到Github用户：zhang_san存储库：web
```cpp
    git pull origin main                                    # 更新本地库
    git push --set-upstream origin main                     # 首次推送与远程库关联
    git branch --set-upstream-to=origin/main  main          # 如果后续需要更改，再次设置分支为main分支
    git merge origin/main --allow-unrelated-histories       # 合并远程仓库到本地文件
```
#### 三：Github 分支操作
```cpp
    git branch                                              # 查看当前所在分支
    git branch -a                                           # 查看所有分支
    git remote -v                                           # 查看远程库信息
    git branch "new branch"                                 # 新建分支
    git checkout "target branch"                            # 切换分支
    git checkout -b "new branch"                            # 新建并切换到新分支
    git checkout -b "new branch" origin/"new branch"        # 新建分支并和远程分支进行关联
    git merge "your branch"                                 # 合并分支到当前所处分支上
    git branch -d "your branch"                             # 删除分支
    git branch -D "your branch"                             # 强制删除未 commit 的分支
```
#### 四：Github 正常工作流程
```cpp
    git log                                                 # 查看历史提交记录
    git status                                              # 查看工作区状态

    git add *                                               # 添加文件
    git commit -m "改动的文件"                               # 提交并备注信息
    git push -u origin main                                 # 提交到 Github main分支

    git push --set-upstream origin main                     # 本地库关联远程库
    git checkout -- "xxx.txt"                               # 使用版本库中的文件或者暂存区中的文件替换工作区的文件，让文件回到最近一次 git commit 或 git add 时的状态
    rm "xxx.txt"                                            # 删除工作区中的文件
    git rm "xxx.txt"                                        # 提交删除操作到暂存区
    git commit -m "remove file"                             # 提交删除到版本库，在版本库中彻底删除文件
```
#### 五：对比文件
```cpp
    git diff "xxx.txt"                                      # 工作区和暂存区之间差异对比
    git diff --cached(--staged) "xxx.txt"                   # 暂存区和版本库之间差异对比
    git diff master                                         # 工作区和版本库之间差异对比
```
#### 六：版本回退
```cpp
    git reset --hard HEAD^                                  # HEAD 是最新版本，HEAD^ 是上一个版本
    git reset –hard cb926e7e                                # 回退到指定id，git log 查看版本id，版本id不用全部输入，取头几位就可以
```

#### 七：存储工作现场
<p>
    修复bug时，我们会通过创建新的bug分支进行修复，然后合并，最后删除；<br>
    当手头工作没有完成时，先把工作现场git stash一下，然后去修复bug，修复后，再git stash pop，回到工作现场<br>
</p>
```cpp
    git stash                                               # 储存工作现场
    git stash list                                          # 工作现场列表
    git stash apply                                         # 恢复但不删除储藏栈的工作现场
    git stash pop                                           # 恢复并删除储藏栈中的工作现场
```
#### 八：多人协作工作模式
<p>
    试图用git push origin branch-name推送自己的修改<br>
    如果推送失败，则因为远程分支比你的本地更新，需要先用git pull试图合并<br>
    如果合并有冲突，则解决冲突，并在本地提交<br>
    没有冲突或者解决掉冲突后，再用git push origin branch-name推送就能成功<br>
</p>

#### 九：起其他相关
1. git fetch 和 git pull 区别<br>
<p>
    git pull 相当于 git fetch origin 和 git merge<br>
    git fetch 相当于先将服务器上的 origin 分支更新到本地 remotes/origin 分支上，然后手动去 merge 合并 origin 分支到本地分支上<br>
    2.git clone xxx<br>
    执行完此命令后：<br>
    Git会自动为你将远程仓库命名为origin，并下载其中所有的数据到本地；<br>
    在本地建立所有远程存在的分支，并且命名为origin/xxx，例如远程分支有master、developer，那么本地就会建立origin/master分支、origin/developer分支，并且它们都是处于remotes目录下，是隐藏的。<br>
    使用命令git branch -a就可以看到隐藏目录remotes，结果显示为remotes/origin/master以及remotes/origin/developer。<br>
    接着，Git会继续建立一个属于你的本地master和developer分支，位置和远程origin/master、origin/developer分支处于相同的位置，你就可以开始工作了。<br>
    这样，我们在本地仓库的本地分支和远程分支就都有了，并且始于同一位置。<br>
    如果其他人向github上xxx分支推送了他们的更新，那么服务器上的相应分支就会向前推进。<br>
    如果在本地的相应分支进行了commit提交到本地代码库，那么本地的master或者developer分支也会向前推进，不过只要你不和服务器通信数据，那么本地的remotes/origin/master（developer）指针仍然会在原地不动。<br>
    3.git fetch origin<br>
    运行git fetch origin命令后，会同步远程服务器上的数据到本地；<br>
    该命令首先找到origin是哪个服务器，从上面获取你未曾拥有的数据，更新到你的本地remotes/origin/master（developer），然后把remotes/origin/master(developer)的指针移动到最新的位置上：<br>
</p>

2. 配置文件<br>
<p>
    git 配置文件放在 ~/.gitconfig <br>
    git 忽略文件 在 git 工作区根目录下创建 .gitignore 文件，把要忽略的文件名写进去。<br>
    git config --global alias.st status # 给 status 创建别名 st<br>
</p>

3. 比较分支差异<br>
```cpp
    git log master..origin/master                           # 比较本地 master 分支和 origin/master 分支有什么区别
    git checkout master                                     # 切换到本地 master 分支下
    git merge origin master                                 # 合并 origin/master 分支到本地 master 分支
```
4. 删除未跟踪文件<br>
```cpp
    git clean -f                                            # 删除未跟踪文件
    git clean -fd                                           # 删除未跟踪文件目录
    git clean -nf                                           # 正式删除文件以前先查看哪些会被删除
    git clean -nfd
```
5. 删除分支<br>
```cpp
    git fetch -p origin # 在本地删除远程已经没有的分支
    git branch -m old-local-branch-name new-local-branch-name # 重命名本地分支
    git push origin :old-remote-branch-name # 删除远程分支
```
6. 本地分支与远程分支建立关联（远程分支不存在也可以）<br>
```cpp
    git checkout local-branch                               # 切换到本地分支
    git push -u origin/remote-branch                        # push 到想要建立关联的远程分支
```
7. 重新跟踪远程文件<br>
```cpp
    git remote rm origin                                    # 先删除远程文件
    git remote add origin https://xxx.git                   # 跟踪新远程文件
    git remote origin set-url https://xxx.git               # 或者合并成一条命令
```
8. Github pages 有两种

    Github pages 必须命名为 username.github.io Github pages默认访问地址为：https://username.github.io
    Github 项目nas pages 可以用项目名称明名：pages默认访问地址为：https://username.github.io/nas/

#### 十：参考资料
[Github配置文档](https://git-scm.com/book/en/v2)