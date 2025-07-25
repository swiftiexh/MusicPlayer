import { UserInfo, SongList, Consumer, SongModel } from "../model/AppModel"
import { login, createSongList as apiCreateSongList, getSongs, addSongToList } from "../common/Api"
import { LoginModel, LoginResponseData, LoginUserData, ResponseModel, SongListCreateParams } from "../model/paramModel"
import { GlobalStateManager } from "../common/GlobalStateManager"
import promptAction from '@ohos.promptAction'
import { ConfigUtil as Config } from "../common/ConfigUtil"
import preferencesUtil from '../common/PreferencesUtil'
import { dayModel, nightModel, ColorModel } from "../model/ColorModel"
import router from '@ohos.router';
import http from '@ohos.net.http'
import { getSongLists } from "../common/Api"
import { HttpPost } from "../common/HttpUtil"
import songHistoriesService from "../services/SongHistoriesService"


@Component
export struct Mine {
  @StorageLink("isLoggedIn") isLoggedIn: boolean = false
  @StorageLink("userToken") userToken: string = ''
  @StorageLink("currentUser") currentUser: Consumer | null = null
  @State showLoginDialog: boolean = false
  @State username: string = ''
  @State password: string = ''
  @State isLoading: boolean = false

  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  @State showCreatePlaylistDialog: boolean = false
  @State newPlaylistName: string = ''
  @State selectedImagePath: string = 'song_list/example1.jpg'
  @State newPlaylistIntroduction: string = ''
  @State newPlaylistStyle: string = ''

  @State userInfo: UserInfo = {
    id: 0,
    username: '未登录',
    sex: '未设置',
    birth: '未设置',
    location: '未设置',
    avatar: '',
  }

  @State songList: SongList[] = []

  // 歌单加歌功能相关状态
  @State showSongSelector: boolean = false
  @State allSongs: SongModel[] = []
  @State selectedListId: number = 0

  async aboutToAppear() {
    await GlobalStateManager.initializeGlobalState()
    await this.initializeUserState()
    if (this.isLoggedIn) {
      this.fetchSongLists()
    }
  }

  async initializeUserState() {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean
      if (token && userInfoStr && isLoggedIn) {
        const userInfo = JSON.parse(userInfoStr) as Consumer
        this.restoreLoggedInState(userInfo, token)
      } else {
        this.resetToLoggedOutState()
      }
    } catch (error) {
      console.error('初始化用户状态失败:', error)
    }
  }

  private restoreLoggedInState(userInfo: Consumer, token: string) {
    this.isLoggedIn = true
    this.userToken = token
    this.currentUser = userInfo
    PersistentStorage.PersistProp('isLoggedIn', true)
    PersistentStorage.PersistProp('userToken', token)
    PersistentStorage.PersistProp('currentUser', userInfo)
    this.updateUIAfterLogin(userInfo)
  }

  async login() {
    if (!this.username.trim() || !this.password.trim()) {
      promptAction.showToast({ message: '请输入用户名和密码' })
      return
    }
    this.isLoading = true
    try {
      const loginData: LoginModel = {
        username: this.username.trim(),
        password: this.password.trim()
      }
      const response = await login(loginData)
      if (response.success && response.data) {
        const loginResponseData = Array.isArray(response.data) ? response.data[0] : response.data
        const loginData = loginResponseData as LoginResponseData
        if (loginData.user && loginData.token) {
          const consumer: Consumer = {
            id: loginData.user.id,
            username: loginData.user.username,
            sex: loginData.user.sex || '',
            phone_num: loginData.user.phone_num,
            birth: loginData.user.birth,
            location: loginData.user.location,
            avatar: loginData.user.avatar
          }
          await this.saveUserData(consumer, loginData.token)
          // 初始化测试数据
          await songHistoriesService.addSongHistoryByName(consumer.id, "舞娘")
          await songHistoriesService.addSongHistoryByName(consumer.id, "夜曲")
          this.updateUIAfterLogin(consumer)
          this.resetLoginForm()
          promptAction.showToast({ message: '登录成功' })
          this.fetchSongLists()
        } else {
          promptAction.showToast({ message: '登录响应数据格式错误' })
        }
      } else {
        promptAction.showToast({ message: response.message || '登录失败' })
      }
    } catch (error) {
      console.error('登录错误:', error)
      promptAction.showToast({ message: '网络错误，请稍后重试' })
    } finally {
      this.isLoading = false
    }
  }

  private async saveUserData(user: Consumer, token: string) {
    await preferencesUtil.set("userinfoStore", "token", token)
    await preferencesUtil.set("userinfoStore", "userInfo", JSON.stringify(user))
    await preferencesUtil.set("userinfoStore", "isLoggedIn", true)
    this.isLoggedIn = true
    this.userToken = token
    this.currentUser = user
    PersistentStorage.PersistProp('isLoggedIn', true)
    PersistentStorage.PersistProp('userToken', token)
    PersistentStorage.PersistProp('currentUser', user)
  }

  private updateUIAfterLogin(user: Consumer) {
    this.userInfo = {
      id: user.id,
      username: user.username,
      sex: user.sex || '未设置',
      birth: user.birth || '未设置',
      location: user.location || '未设置',
      avatar: user.avatar || 'app.media.profile'
    }
  }

  private resetLoginForm() {
    this.username = ''
    this.password = ''
    this.showLoginDialog = false
  }

  async logout() {
    try {
      await preferencesUtil.delete("userinfoStore", "token")
      await preferencesUtil.delete("userinfoStore", "userInfo")
      await preferencesUtil.delete("userinfoStore", "isLoggedIn")
      this.resetToLoggedOutState()
      promptAction.showToast({ message: '已退出登录' })
      this.songList = []
    } catch (error) {
      console.error('退出登录失败:', error)
      promptAction.showToast({ message: '退出登录失败' })
    }
  }

  private resetToLoggedOutState() {
    this.isLoggedIn = false
    this.userToken = ''
    this.currentUser = null
    this.userInfo = {
      id: 0,
      username: '未登录',
      sex: '未设置',
      birth: '未设置',
      location: '未设置',
      avatar: '',
    }
    PersistentStorage.PersistProp('isLoggedIn', false)
    PersistentStorage.PersistProp('userToken', '')
    PersistentStorage.PersistProp('currentUser', null)
  }

  openCollectionPage() {
    if (!this.isLoggedIn) {
      promptAction.showToast({ message: '请先登录' })
      this.showLoginDialog = true
      return
    }
    router.pushUrl({ url: 'pages/user/CollectionPage' })
      .catch((error: Error) => {
        console.error('跳转收藏页面失败:', error)
        promptAction.showToast({ message: '跳转失败' })
      })
  }

  openHistoryPage() {
    if (!this.isLoggedIn) {
      promptAction.showToast({ message: '请先登录' })
      this.showLoginDialog = true
      return
    }
    router.pushUrl({ url: 'pages/user/HistoryPage' })
      .catch((error: Error) => {
        console.error('跳转历史页面失败:', error)
        promptAction.showToast({ message: '跳转失败' })
      })
  }

  openCommentPage() {
    if (!this.isLoggedIn) {
      promptAction.showToast({ message: '请先登录' })
      this.showLoginDialog = true
      return
    }
    router.pushUrl({ url: 'pages/user/CommentPage' })
      .catch((error: Error) => {
        console.error('跳转评论页面失败:', error)
        promptAction.showToast({ message: '跳转失败' })
      })
  }

  openFollowPage() {
    if (!this.isLoggedIn) {
      promptAction.showToast({ message: '请先登录' })
      this.showLoginDialog = true
      return
    }
    router.pushUrl({ url: 'pages/user/FollowPage' })
      .catch((error: Error) => {
        console.error('跳转评论页面失败:', error)
        promptAction.showToast({ message: '跳转失败' })
      })
  }

  async fetchSongLists() {
    if (!this.currentUser) return
    try {
      const res: ResponseModel = await getSongLists()
      if (res.success) {
        this.songList = res.data as SongList[]
      } else {
        promptAction.showToast({ message: res.message || '获取歌单失败' })
      }
    } catch (e) {
      promptAction.showToast({ message: '网络错误，获取歌单失败' })
    }
  }

  // 显示歌曲选择弹窗
  async showSongListAddDialog(listId: number) {
    this.selectedListId = listId
    try {
      const res = await getSongs()
      if (res && res.data) {
        this.allSongs = res.data as SongModel[]
        this.showSongSelector = true
      } else {
        promptAction.showToast({ message: '获取歌曲失败' })
      }
    } catch (e) {
      promptAction.showToast({ message: '网络错误，获取歌曲失败' })
    }
  }

  // 添加歌曲到歌单
  async handleAddSongToList(songId: number) {
    try {
      const res = await addSongToList(songId, this.selectedListId)
      if (res && res.success) {
        promptAction.showToast({ message: '添加成功' })
        this.showSongSelector = false
      } else {
        promptAction.showToast({ message: res.message || '添加失败' })
      }
    } catch (e) {
      promptAction.showToast({ message: '网络错误，添加失败' })
    }
  }

  async createSongList() {
    if (!this.newPlaylistName.trim()) {
      promptAction.showToast({ message: '请输入歌单名称' })
      return
    }
    if (!this.currentUser) {
      promptAction.showToast({ message: '请先登录' })
      return
    }
    try {
      const params: SongListCreateParams = {
        name: this.newPlaylistName.trim(),
        user_id: this.currentUser.id,
        introduction: this.newPlaylistIntroduction.trim(),
        style: this.newPlaylistStyle.trim(),
        pic: this.selectedImagePath ? this.selectedImagePath : ''
      }
      const res: ResponseModel = await apiCreateSongList(params)
      if (res.success) {
        promptAction.showToast({ message: '歌单创建成功' })
        this.showCreatePlaylistDialog = false
        this.newPlaylistName = ''
        this.newPlaylistIntroduction = ''

        this.newPlaylistStyle = ''
        this.selectedImagePath = ''
        this.fetchSongLists()
      } else {
        promptAction.showToast({ message: res.message || '创建失败' })
      }
    } catch (e) {
      promptAction.showToast({ message: '网络错误，创建失败' })
    }
  }

  @Builder
  TopNavigationBar() {
    Row() {
      Column() {
        Text('我的')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
          .letterSpacing(1)
          .id('myText')
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(46)
          .height(3)
      }
      .justifyContent(FlexAlign.Center)
      Column() {
        Row() {
          Image($r("app.media.moon_icon")).width(23).aspectRatio(1).fillColor(this.myColor.gray).margin({ right: 4 })
          Toggle({
            type: ToggleType.Switch,
            isOn: this.isDark
          })
            .selectedColor("#03e884")
            .onChange((v => {
              this.isDark = v
              PersistentStorage.PersistProp('isDark', v)
              this.myColor = (this.isDark == true ? nightModel : dayModel)
            }))
            .height(22)
            .width(35)
        }
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(65)
          .height(3)
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.myColor.background)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  SearchInput() {
    Row() {
      Row({ space: 4 }) {
        Image($r('app.media.ic_search'))
          .width(20)
          .aspectRatio(1)
          .fillColor(this.myColor.gray)
          .margin({ left: 5 })
        Text('徐佳莹 大象的葬礼')
          .fontSize(17)
          .fontColor(this.myColor.gray)
          .layoutWeight(1)
          .margin({ left: 5 })
      }
      .backgroundColor(this.myColor.bright)
      .borderColor(this.myColor.dark)
      .borderWidth(1)
      .borderRadius(8)
      .width('90%')
      .height(40)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(50)
    .backgroundColor(this.myColor.background)
    .onClick(() => {
      router.pushUrl({
        url: "pages/search/SearchPage"
      })
    })
  }

  @Builder
  UserInfoCard() {
    Column({ space: 20 }) {
      Row() {
        Image(`${Config.SERVERURL}${this.userInfo.avatar}`)
          .width(95)
          .height(95)
          .borderRadius(47.5)
          .margin({ left: 25 })
        Column({ space: 6 }) {
          Text(this.userInfo.username)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.myColor.dark)
          Row({ space: 8 }) {
            Text(this.userInfo.sex)
              .fontSize(18)
              .fontColor(this.myColor.dark)
              .opacity(0.8)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(10)
            Text(this.userInfo.location)
              .fontSize(18)
              .fontColor(this.myColor.dark)
              .opacity(0.8)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(10)
          }
          Text(`${this.userInfo.birth}`)
            .fontSize(15)
            .fontColor(this.myColor.dark)
            .opacity(0.7)
        }
        .width(90)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 20 })
        .layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      Button({ type: ButtonType.Normal }) {
        Text('退出登录')
          .fontSize(14)
          .fontColor(this.myColor.bright)
      }
      .backgroundColor(this.myColor.dark)
      .borderRadius(20)
      .width(90)
      .height(36)
      .onClick(() => {
        this.logout()
      })
    }
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height(170)
    .backgroundColor(this.myColor.bright)
    .margin({ top: 15 })
    .borderRadius(6)
  }

  @Builder
  LoginPromptCard() {
    Column({ space: 25 }) {
      Text('登录音乐世界')
        .fontSize(35)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.myColor.dark)
        .letterSpacing(1)
        .margin({ top: 15 })
      Button({ type: ButtonType.Capsule }) {
        Text('立即登录')
          .fontSize(18)
          .fontColor(this.myColor.bright)
          .fontWeight(FontWeight.Bold)
      }
      .backgroundColor(this.myColor.dark)
      .width(140)
      .height(44)
      .shadow({
        radius: 8,
        color: 'rgba(143, 153, 178, 0.4)',
        offsetX: 0,
        offsetY: 4
      })
      .onClick(() => {
        this.showLoginDialog = true
      })
      Text('登录后可享受个性化推荐')
        .fontSize(13)
        .fontColor(this.myColor.gray)
        .opacity(0.7)
    }
    .width('100%')
    .height(170)
    .backgroundColor(this.myColor.bright)
    .margin({ top: 15 })
    .justifyContent(FlexAlign.SpaceEvenly)
    .borderRadius(6)
  }

  @Builder
  UserSection() {
    Column() {
      if (this.isLoggedIn) {
        this.UserInfoCard()
      } else {
        this.LoginPromptCard()
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 5 })
  }

  @Builder
  StatCard(title: string) {
    Column({ space: 8 }) {
      this.getIconByTitle(title)
      Text(title)
        .fontSize(15)
        .fontColor(this.myColor.dark)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
    }
    .width(80)
    .height(90)
    .backgroundColor(this.myColor.background)
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (title === '收藏') {
        this.openCollectionPage()
      } else if (title === '历史') {
        this.openHistoryPage()
      } else if (title === '评论') {
        this.openCommentPage()
      } else if (title === '关注') {
        this.openFollowPage()
      }
    })
  }

  @Builder
  getIconByTitle(title: string) {
    if (title === '收藏') {
      Image($r('app.media.ic_heart'))
        .width(40)
        .height(40)
        .fillColor(this.myColor.dark)
    } else if (title === '历史') {
      Image($r('app.media.ic_history'))
        .width(35)
        .height(35)
        .fillColor(this.myColor.dark)
    } else if (title === '评论') {
      Image($r('app.media.ic_comment'))
        .width(30)
        .height(30)
        .fillColor(this.myColor.dark)
    } else if (title === '关注') {
      Image($r('app.media.ic_star'))
        .width(35)
        .height(35)
        .fillColor(this.myColor.dark)
    }
  }

  @Builder
  StatsSection() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        this.StatCard('收藏')
        this.StatCard('历史')
        this.StatCard('评论')
        this.StatCard('关注')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .margin({ top: 10, bottom: 10 })
  }

  @Builder
  PlaylistSection() {
    Column() {
      this.PlaylistHeader()
      List() {
        if (this.isLoggedIn) {
          ForEach(this.songList, (item: SongList) => {
            if(item.user_id == this.userInfo.id) {
              ListItem() {
                this.PlaylistItem(item)
              }
            }
          }, (item: SongList) => item.id.toString())
        }
        ListItem() {
          this.CreatePlaylistItem()
        }
      }
      .width("100%")
      .layoutWeight(1)
    }
    .width("100%")
    .layoutWeight(1)
  }

  @Builder
  PlaylistHeader() {
    Column() {
      Text('我的歌单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.myColor.dark)
        .margin({ left: 4 })
      Image($r('app.media.line'))
        .fillColor("#03e884")
        .width(80)
        .height(2.5)
    }
    .margin({ bottom: 10 })
  }

  @Builder
  PlaylistItem(item: SongList) {
    Row() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(item.pic ? (item.pic.startsWith('http') ? item.pic : Config.SERVERURL + item.pic) : $r("app.media.example1"))
          .width(70)
          .height(70)
          .borderRadius(4)
        Image($r("app.media.play_icon"))
          .width(30)
          .height(30)
          .fillColor(Color.Gray)
      }
      .margin({ left:10,right: 18 })
      Column({ space: 5 }) {
        Text(item.name)
          .fontSize(25)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
        Text(item.introduction || "")
          .fontSize(15)
          .fontColor(this.myColor.gray)
          .opacity(0.7)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(160)
      }
      .margin({left:10})
      .alignItems(HorizontalAlign.Start)
      // 右侧加号和箭头横向排布
      Column() {
        Image($r("app.media.ic_add"))
          .width(40)
          .height(40)
          .fillColor(this.myColor.dark)
          .onClick(() => {
            this.showSongListAddDialog(item.id)
          })
        Image($r("app.media.right_icon"))
          .width(20)
          .height(20)
          .fillColor(this.myColor.dark)
      }
      .margin({left:40})
    }
    .margin({ left: 12, right: 12, top: 10, bottom: 10 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/detail/SongListDetail',
        params: { cid: item.id }
      })
    })
  }

  @Builder
  CreatePlaylistItem() {
    Row() {
      Image($r(this.isDark ? "app.media.create_list2" : "app.media.create_list"))
        .width(70)
        .height(70)
        .borderRadius(4)
        .margin({ right: 30 })
      Column({ space: 5 }) {
        Text("新建歌单")
          .fontSize(25)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
        Text("把喜欢的声音装进口袋")
          .fontSize(15)
          .fontColor(this.myColor.gray)
          .opacity(0.7)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(180)
      }
      .alignItems(HorizontalAlign.Start)
      Image($r("app.media.right_icon"))
        .width(25)
        .height(25)
        .fillColor(this.myColor.dark)
        .margin({left:25})
    }
    .margin({ left: 20, right: 20, top: 10, bottom: 10 })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      if (!this.isLoggedIn) {
        promptAction.showToast({ message: '请先登录' })
        this.showLoginDialog = true
        return
      }
      this.showCreatePlaylistDialog = true
    })
  }

  @Builder
  CreatePlaylistDialog() {
    Column() {
      Column() {
        Text('创建歌单')
          .fontSize(35)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
          .letterSpacing(1)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(150)
          .height(3)
      }
      .justifyContent(FlexAlign.Center)
      // 选择图片区域
      Column({ space: 10 }) {
        Text('歌单封面')
          .fontSize(23)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
        Row() {
          Image((this.selectedImagePath == "song_list/example1.jpg") ? $r('app.media.example1') : $r("app.media.example2"))
            .width(100)
            .height(100)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .border({
              width: 1,
              color: this.myColor.dark,
              radius: 8
            })
          Button('更改图片')
            .fontSize(18)
            .fontColor(this.myColor.bright)
            .backgroundColor(this.myColor.dark)
            .borderRadius(12)
            .margin({ left: 20 })
            .onClick(() => {
              this.selectedImagePath = "song_list/example2.png"
              promptAction.showToast({ message: '更改图片成功' })
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .margin({ top: 20 })
      // 歌单名称
      Column({ space: 10 }) {
        Text('歌单名称')
          .fontSize(23)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入歌单名称' })
          .backgroundColor(this.myColor.bright)
          .borderRadius(12)
          .height(40)
          .width('100%')
          .placeholderFont({ size: 18 })
          .fontColor(this.myColor.gray)
          .border({
            width: 1,
            color: this.myColor.dark,
            radius: 12
          })
          .onChange((value: string) => {
            this.newPlaylistName = value
          })
      }
      .margin({ top: 20 })
      // 歌单简介
      Column({ space: 10 }) {
        Text('歌单简介')
          .fontSize(23)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入歌单简介' })
          .backgroundColor(this.myColor.bright)
          .borderRadius(12)
          .height(40)
          .width('100%')
          .placeholderFont({ size: 18 })
          .fontColor(this.myColor.gray)
          .border({
            width: 1,
            color: this.myColor.dark,
            radius: 12
          })
          .onChange((value: string) => {
            this.newPlaylistIntroduction = value
          })
      }
      .margin({ top: 20 })
      // 歌单风格
      Column({ space: 10 }) {
        Text('歌单风格')
          .fontSize(23)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入歌单风格' })
          .backgroundColor(this.myColor.bright)
          .borderRadius(12)
          .height(40)
          .width('100%')
          .placeholderFont({ size: 18 })
          .fontColor(this.myColor.gray)
          .border({
            width: 1,
            color: this.myColor.dark,
            radius: 12
          })
          .onChange((value: string) => {
            this.newPlaylistStyle = value
          })
      }
      .margin({ top: 20, bottom: 20 })
      // 按钮区域
      Row({ space: 16 }) {
        Button({ type: ButtonType.Normal }) {
          Text('取消')
            .fontSize(20)
            .fontColor(this.myColor.bright)
            .fontWeight(FontWeight.Medium)
        }
        .backgroundColor(this.myColor.gray)
        .borderRadius(24)
        .layoutWeight(1)
        .height(40)
        .onClick(() => {
          this.showCreatePlaylistDialog = false
          this.newPlaylistName = ''
          this.newPlaylistIntroduction = ''
          this.newPlaylistStyle = ''
          this.selectedImagePath = ''
        })
        Button({ type: ButtonType.Normal }) {
          Text('创建')
            .fontSize(20)
            .fontColor(this.myColor.bright)
            .fontWeight(FontWeight.Medium)
        }
        .backgroundColor(this.myColor.dark)
        .borderRadius(24)
        .layoutWeight(1)
        .height(40)
        .shadow({
          radius: 8,
          color: 'rgba(143, 153, 178, 0.4)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.createSongList()
        })
      }
      .width('100%')
    }
    .width(320)
    .padding(32)
    .backgroundColor(this.myColor.bright)
    .borderRadius(24)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  LoginDialog() {
    Column() {
      Column() {
        Text('用户登录')
          .fontSize(35)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
          .letterSpacing(1)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(150)
          .height(3)
      }
      .justifyContent(FlexAlign.Center)
      Column({ space: 15 }) {
        this.LoginInputField('账号', '请输入您的账号', false, (value: string) => {
          this.username = value
        })
        this.LoginInputField('密码', '请输入您的密码', true, (value: string) => {
          this.password = value
        })
      }
      .margin({ top: 20, bottom: 20 })
      Row({ space: 16 }) {
        Button({ type: ButtonType.Normal }) {
          Text('取消')
            .fontSize(20)
            .fontColor(this.myColor.bright)
            .fontWeight(FontWeight.Medium)
        }
        .backgroundColor(this.myColor.gray)
        .borderRadius(24)
        .layoutWeight(1)
        .height(40)
        .width(30)
        .onClick(() => {
          this.showLoginDialog = false
          this.username = ''
          this.password = ''
        })
        Button({ type: ButtonType.Normal }) {
          Row() {
            if (this.isLoading) {
              LoadingProgress()
                .width(16)
                .height(16)
                .color(this.myColor.bright)
                .margin({ right: 4 })
            }
            Text(this.isLoading ? '登录中...' : '登录')
              .fontSize(20)
              .fontColor(this.myColor.bright)
              .fontWeight(FontWeight.Medium)
          }
        }
        .backgroundColor(this.myColor.dark)
        .borderRadius(24)
        .layoutWeight(1)
        .height(40)
        .width(30)
        .enabled(!this.isLoading)
        .shadow({
          radius: 8,
          color: 'rgba(143, 153, 178, 0.4)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.login()
        })
      }
      .width('100%')
    }
    .width(320)
    .height(280)
    .padding(32)
    .backgroundColor(this.myColor.bright)
    .borderRadius(24)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  LoginInputField(label: string, placeholder: string, isPassword: boolean, onChange: (value: string) => void) {
    Row() {
      Text(label)
        .fontSize(23)
        .fontColor(this.myColor.dark)
        .fontWeight(FontWeight.Medium)
        .margin({ right: 15 })
      TextInput({ placeholder: placeholder })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .backgroundColor(this.myColor.bright)
        .borderRadius(12)
        .height(40)
        .layoutWeight(1)
        .placeholderFont({ size: 18 })
        .fontColor(this.myColor.gray)
        .border({
          width: 1,
          color: this.myColor.dark,
          radius: 12
        })
        .onChange(onChange)
    }
    .width("100%")
    .margin({ left: 10, right: 10 })
  }

  build() {
    Column() {
      this.TopNavigationBar()
      Scroll() {
        Column() {
          this.SearchInput()
          this.UserSection()
          this.StatsSection()
          this.PlaylistSection()
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.myColor.background)
      // 歌单加歌弹窗
      if (this.showSongSelector) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0,0,0,0.3)')
            .onClick(() => {
              this.showSongSelector = false
            })
          Column() {
            Text('选择要添加的歌曲')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.myColor.dark)
              .margin({ bottom: 10 })
            Scroll() {
              List() {
                ForEach(this.allSongs, (song: SongModel) => {
                  ListItem() {
                    Row() {
                      Image(song.pic ? (song.pic.startsWith('http') ? song.pic : Config.SERVERURL + song.pic) :
                      $r("app.media.example1"))
                        .width(40)
                        .height(40)
                        .borderRadius(4)
                        .margin({ right: 10 })
                      Text(song.name)
                        .fontSize(18)
                        .fontColor(this.myColor.dark)
                    }
                    .onClick(() => {
                      this.handleAddSongToList(song.id)
                    })
                    .margin({ bottom: 8 })
                  }
                }, (song: SongModel) => song.id.toString())
              }
              .width('100%')
            }
            .width('100%')
            .height(320)
            .margin({bottom:8})
            Button('关闭')
              .width('100%')
              .height(40)
              .backgroundColor(this.myColor.gray)
              .fontColor(this.myColor.bright)
              .onClick(() => {
                this.showSongSelector = false
              })
          }
          .width(340)
          .padding(20)
          .backgroundColor(this.myColor.bright)
          .borderRadius(18)
          .alignSelf(ItemAlign.Center)
        }
        .width('100%')
        .height('100%')
      }
      if (this.showLoginDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.myColor.background)
            .onClick(() => {
              this.showLoginDialog = false
            })
          this.LoginDialog()
        }
        .width('100%')
        .height('94%')
      }
      if (this.showCreatePlaylistDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.myColor.background)
            .onClick(() => {
              this.showCreatePlaylistDialog = false
              this.newPlaylistName = ''
              this.newPlaylistIntroduction = ''
              this.newPlaylistStyle = ''
              this.selectedImagePath = ''
            })
          this.CreatePlaylistDialog()
        }
        .width('100%')
        .height('94%')
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(this.myColor.background)
  }
}
