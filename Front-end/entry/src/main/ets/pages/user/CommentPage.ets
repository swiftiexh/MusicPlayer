import { getCommentById } from '../common/Api'
import { CommentModel } from '../model/AppModel'
import { Consumer } from '../model/AppModel'

import { dayModel, nightModel, ColorModel } from '../model/ColorModel'
import { ConfigUtil as Config } from '../common/ConfigUtil'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'
import preferencesUtil from '../common/PreferencesUtil'



@Entry
@Component
struct CommentPage {
  @State comments: CommentModel[] = []
  @State isLoading: boolean = false
  @State isRefreshing: boolean = false
  @State isLoggedIn: boolean = false
  @State currentUser: Consumer | null = null
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  async aboutToAppear() {
    await this.checkLoginAndLoad()
  }

  // 检查登录状态并加载数据
  async checkLoginAndLoad(): Promise<void> {
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

      if (this.isLoggedIn && this.currentUser) {
        await this.loadComments()
      }
    } catch (error) {
      console.error('检查登录状态失败:', error)
      this.isLoggedIn = false
    }
  }
  // 加载评论列表
  async loadComments(showLoading: boolean = true): Promise<void> {
    if (!this.isLoggedIn || !this.currentUser) return

    if (showLoading) {
      this.isLoading = true
    } else {
      this.isRefreshing = true
    }

    try {
      const result = await getCommentById(this.currentUser.id)

      if (result && result.success && result.data) {
        this.comments = result.data as CommentModel[]
        console.log('评论列表加载成功，数量:', this.comments.length)

        if (!showLoading) {
          promptAction.showToast({ message: '刷新成功', duration: 2000 })
        }
      } else {
        this.comments = []
        if (!showLoading) {
          promptAction.showToast({ message: '刷新失败', duration: 2000 })
        }
      }
    } catch (error) {
      console.error('加载评论列表错误:', error)
      this.comments = []
      if (!showLoading) {
        promptAction.showToast({ message: '刷新失败', duration: 2000 })
      }
    } finally {
      this.isLoading = false
      this.isRefreshing = false
    }
  }

  // 顶部导航栏
  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Image($r("app.media.ic_back"))
        .width(20)
        .height(20)
        .borderRadius(3)
        .fillColor(this.myColor.dark)
        .onClick(() => {
          router.back()
        })

      Column() {
        Text("我的评论")
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(85)
          .height(2.5)
      }
      .width("40%")
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({left:-10})

      Blank()

      if (this.isLoggedIn && !this.isRefreshing) {
        Text('刷新')
          .fontSize(16)
          .fontColor(this.myColor.dark)
          .onClick(() => this.loadComments(false))
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .margin({bottom: -15})
    .backgroundColor(this.myColor.background)
  }

  // 评论项
  @Builder
  CommentItem(comment: CommentModel) {
    Column({ space: 12 }) {
      // 第一、二行
      Stack({ alignContent: Alignment.TopStart } )
      {
        Column() {
          Text(comment.user_name || '未知用户')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.myColor.dark)
            .margin({top:9,bottom:15})
          Text(comment.content || '无评论内容')
            .fontSize(14)
            .fontColor(this.myColor.dark)
        }
        .width('100%')
        .margin({ left: 52 })
        .alignItems(HorizontalAlign.Start)

        Image(this.currentUser?.avatar ? Config.SERVERURL + this.currentUser.avatar : '')
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(this.myColor.gray)
      }

      // 第三行：回复内容（如果存在）
      if (comment.up_content && comment.up_user_name) {
        Text(`@${comment.up_user_name}: ${comment.up_content}`)
          .fontSize(13)
          .fontColor(this.myColor.gray)
          .width('100%')
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor(this.isDark ? '#2A2A2A' : '#F0F0F0')
          .borderRadius(8)
          .margin({ left: 52 })
          .padding(5)
      }

      // 第四行：歌曲信息
      Row() {
        // 歌曲封面
        Image(comment.pic ? Config.SERVERURL + comment.pic : '')
          .width(50)
          .height(50)
          .borderRadius(8)
          .backgroundColor(this.myColor.gray)
          .margin({ right: 12 })

        // 歌曲信息
        Column({ space: 4 }) {
          Text(comment.song_name || '未知歌曲')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.myColor.dark)
            .alignSelf(ItemAlign.Start)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(comment.singer || '未知歌手')
            .fontSize(12)
            .fontColor(this.myColor.gray)
            .alignSelf(ItemAlign.Start)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ left: 52 })

      // 第五行：时间
      Text(this.formatTime(comment.create_time))
        .fontSize(12)
        .fontColor(this.myColor.gray)
        .margin({ left: 52 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.myColor.bright)
    .borderRadius(12)
    .margin({ bottom: 8 })
    .alignItems(HorizontalAlign.Start)
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

  build() {
    Column() {
      this.TopBar()

      if (!this.isLoggedIn) {
        Column() {
          Text('请登录')
            .fontSize(24)
            .fontColor(this.myColor.dark)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor(this.myColor.gray)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.comments.length === 0) {
        Column() {
          Text('暂无评论')
            .fontSize(18)
            .fontColor(this.myColor.dark)
            .margin({ bottom: 16 })

          Button('去首页看看')
            .backgroundColor(this.myColor.gray)
            .onClick(() => router.back())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: this.isRefreshing }) {
          List() {
            ForEach(this.comments, (comment: CommentModel) => {
              ListItem() {
                this.CommentItem(comment)
              }
            }, (item: CommentModel) => item.id.toString())
          }
          .padding(16)
        }
        .onRefreshing(() => this.loadComments(false))
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.myColor.background)
  }
}
