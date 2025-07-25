import {ParamModel} from "./model/paramModel"
import router from '@ohos.router';
import {getCommentBySongId,postComment} from "./common/Api"
import {CommentReplyModel, Consumer} from "./model/AppModel"
import promptAction from '@ohos.promptAction'
import {ConfigUtil as Config} from "./common/ConfigUtil"
import preferencesUtil from './common/PreferencesUtil'
import {CommentModel} from "./model/paramModel"
import {dayModel,nightModel,ColorModel} from "./model/ColorModel"


@Entry
@Component
struct Comment
{
  @State commentList: CommentReplyModel[] = []
  @State newComment: string = ''
  @State isReplying: boolean = false
  @State replyToId: number = 0
  @State replyToUsername: string = ''
  @State isLoggedIn: boolean = false
  @State currentUser: Consumer | null = null
  @State song_id:number = 0

  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor:ColorModel = (this.isDark==true?nightModel:dayModel)

  async getCommentDetailData() {
    const params: ParamModel = (router.getParams() as ParamModel)
    this.song_id = params.cid ? params.cid : 0
    const res = await getCommentBySongId(params)
    if (res.success) {
      this.commentList = JSON.parse(JSON.stringify(res.data))
      console.log('getCommentDetail' + JSON.stringify(this.commentList))
    } else {
      promptAction.showToast({
        message: res.message,
        duration: 5000
      })
    }
  }

  aboutToAppear() {
    this.checkLoginStatus()
    this.getCommentDetailData()
  }

  // 检查用户登录状态
  async checkLoginStatus() {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string

      this.isLoggedIn = isLoggedIn && token.length > 0

      // 获取用户信息
      if (userInfoStr && userInfoStr.length > 0) {
        try {
          this.currentUser = JSON.parse(userInfoStr) as Consumer
          console.log('获取到用户信息:', this.currentUser)
        } catch (parseError) {
          console.error('解析用户信息失败:', parseError)
          this.currentUser = null
        }
      }
    } catch (error) {
      console.error('检查登录状态失败:', error)
      this.isLoggedIn = false
    }
  }

  // 检查登录状态并执行评论操作
  checkLoginAndComment() {
    if (!this.isLoggedIn) {
      promptAction.showToast({ 
        message: '请先登录',
        duration: 2000
      })
      return false
    }
    return true
  }

  // 格式化时间显示
  formatTime(timeStr: string): string {
    if (!timeStr) return '刚刚'

    try {
      const commentTime = new Date(timeStr)
      const now = new Date()
      const diffMs = now.getTime() - commentTime.getTime()
      const diffMins = Math.floor(diffMs / (1000 * 60))
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
      const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

      if (diffMins < 1) return '刚刚'
      if (diffMins < 60) return `${diffMins}分钟前`
      if (diffHours < 24) return `${diffHours}小时前`
      if (diffDays < 7) return `${diffDays}天前`

      return commentTime.toLocaleDateString()
    } catch (error) {
      return '刚刚'
    }
  }

  // 构建回复组件
  @Builder
  buildReplyItem(reply: CommentReplyModel, replyToUsername?: string) {
    Column() {
      Row() {
        Image(`${Config.SERVERURL}${reply.avatar}` || $r('app.media.ic_comment'))
          .width(32)
          .height(32)
          .borderRadius(16)
          .margin({ right: 8 })

        Column() {
          Row() {
            Text(reply.username)
              .fontSize(14)
              .fontColor(this.myColor.dark)
              .fontWeight(500)
            
            Blank()
            
            Text(this.formatTime(reply.create_time || ''))
              .fontSize(12)
              .fontColor(this.myColor.gray)
              .margin({right:5})
          }
          .width('100%')
          .margin({ bottom: 4 })

          // 显示回复内容，如果是回复他人则显示被回复的用户名
          Row() {
            if (replyToUsername) {
              Text(`回复 `)
                .fontSize(15)
                .fontColor(this.myColor.dark)
              Text(`@${replyToUsername}`)
                .fontSize(15)
                .fontColor('#007AFF')
              Text(`: ${reply.content}`)
                .fontSize(15)
                .fontColor(this.myColor.dark)
                .lineHeight(20)
            } else {
              Text(reply.content)
                .fontSize(15)
                .fontColor(this.myColor.dark)
                .lineHeight(20)
            }
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Image($r('app.media.ic_comment'))
              .width(16)
              .height(16)
              .margin({ right: 4 })
              .fillColor(this.myColor.gray)
            
            Text('回复')
              .fontSize(12)
              .fontColor(this.myColor.gray)
          }
          .onClick(() => {
            // 检查登录状态
            if (!this.checkLoginAndComment()) {
              return
            }
            
            this.isReplying = true
            this.replyToId = reply.id || 0
            this.replyToUsername = reply.username || ''
          })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')
    }
    .margin({ bottom: 2 })
  }

  // 构建评论项
  @Builder
  buildCommentItem(comment: CommentReplyModel) {
    Column() {
      // 显示根评论
      this.buildReplyItem(comment)
      
      // 显示所有回复，扁平化处理
      if (comment.reply && comment.reply.length > 0) {
        this.buildRepliesList(comment.reply, comment.username || '')
      }
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.myColor.background)
  }

  // 构建回复列表（扁平化显示）
  @Builder
  buildRepliesList(replies: CommentReplyModel[], parentUsername: string) {
    Column() {
      ForEach(replies, (reply: CommentReplyModel) => {
        // 显示当前回复
        Column() {
          this.buildReplyItem(reply, parentUsername)
        }
        .margin({ left: 40 })
        .padding({ left: 12, top: 8, bottom: 8 })
        .backgroundColor(this.myColor.background)
        .borderRadius(8)
        
        // 递归显示子回复
        if (reply.reply && reply.reply.length > 0) {
          this.buildRepliesList(reply.reply, reply.username || '')
        }
      })
    }
    .margin({ top: 12 })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back()
          })
          .fillColor(this.myColor.dark)

        Text('评论')
          .fontSize(18)
          .fontWeight(500)
          .fontColor(this.myColor.dark)
          .margin({ left: 12 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.myColor.background)

      // 评论列表
      List() {
        ForEach(this.commentList, (comment: CommentReplyModel) => {
          ListItem() {
            this.buildCommentItem(comment)
          }
        })
      }
      .layoutWeight(1)
      .backgroundColor(this.myColor.background)
      .divider({
        strokeWidth: 1,
        color: this.myColor.gray
      })

      // 输入框区域
      Row() {
        TextInput({ 
          placeholder: this.isReplying ? `回复 ${this.replyToUsername}:` : '写评论...',
          text: this.newComment 
        })
          .layoutWeight(1)
          .height(40)
          .placeholderColor(this.myColor.gray)
          .fontColor(this.myColor.dark)
          .backgroundColor(this.myColor.bright)
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.newComment = value
          })

        if (this.isReplying) {
          Text('取消')
            .fontSize(14)
            .fontColor(this.myColor.gray)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.isReplying = false
              this.replyToId = 0
              this.replyToUsername = ''
            })
        }

        Text('发送')
          .fontSize(14)
          .fontColor(this.newComment.trim() ? '#007AFF' : this.myColor.gray)
          .padding({ left: 12, right: 12 })
          .onClick(async () => {
            if (this.newComment.trim()) {
              // 检查登录状态
              if (!this.checkLoginAndComment()) {
                return
              }
              
              try {
                // 发送评论的逻辑
                const comment: CommentModel = {
                  user_id: this.currentUser?.id,
                  song_id: this.song_id,
                  content: this.newComment,
                  up: this.replyToId
                }
                
                const result = await postComment(comment)
                
                if (result && result.success) {
                  // 发送成功，显示提示
                  promptAction.showToast({
                    message: '评论发布成功',
                    duration: 2000
                  })
                  
                  // 清空输入框和重置状态
                  this.newComment = ''
                  this.isReplying = false
                  this.replyToId = 0
                  this.replyToUsername = ''
                  
                  // 刷新评论列表
                  await this.getCommentDetailData()
                } else {
                  // 发送失败
                  promptAction.showToast({
                    message: result?.message || '评论发布失败',
                    duration: 2000
                  })
                }
              } catch (error) {
                console.error('发送评论失败:', error)
                promptAction.showToast({
                  message: '评论发布失败，请重试',
                  duration: 2000
                })
              }
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.myColor.background)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.myColor.background)
  }
}