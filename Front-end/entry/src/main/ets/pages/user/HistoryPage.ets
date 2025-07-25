import songHistoriesService from '../services/SongHistoriesService'
import { SongModel,Consumer,UserInfo} from '../model/AppModel'
import { dayModel, nightModel, ColorModel } from '../model/ColorModel'
import { ConfigUtil as Config } from '../common/ConfigUtil'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'
import preferencesUtil from '../common/PreferencesUtil'
import {AvPlayerUtils} from '../common/AvPlayerUtils'
import {add_click_num,user_addclick} from '../common/Api'
import {addCollection,deleteCollection,checkCollection} from "../common/Api"
import {CollectionModel} from "../model/paramModel"


@Entry
@Component
struct HistoryPage {
  @State histories: SongModel[] = []
  @State isLoading: boolean = false
  @State isRefreshing: boolean = false
  @State isLoggedIn: boolean = false
  @State currentUserId: number = 1 // 当前用户ID
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  @State favorites: number[] = [] // 改用数组存储收藏的歌曲ID
  @State currentUser: Consumer | null = null
  @State isUpdatingFavorite: boolean = false // 防止重复点击

  @State isBottomSheetVisible: boolean = false
  @State selectedSong: SongModel | null = null

  // 底部弹窗控制器
  bottomSheetController: CustomDialogController | null = null

  // 创建底部弹窗控制器
  createBottomSheetController() {
    this.bottomSheetController = new CustomDialogController({
      builder: BottomSheetDialog({
        selectedSong: this.selectedSong,
        onCancel: this.hideBottomSheet.bind(this)
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      offset: { dx: 0, dy: 0 },
      autoCancel: true,
      cancel: () => {
        this.hideBottomSheet()
      }
    })
  }
  // 显示底部弹窗
  showBottomSheet(song: SongModel) {
    this.selectedSong = song
    this.createBottomSheetController()
    if (this.bottomSheetController) {
      this.bottomSheetController.open()
      this.isBottomSheetVisible = true
    }
  }
  // 隐藏底部弹窗
  hideBottomSheet() {
    this.isBottomSheetVisible = false
    if (this.bottomSheetController) {
      this.bottomSheetController.close()
      this.bottomSheetController = null
    }
    this.selectedSong = null
  }

  async aboutToAppear() {
    await this.checkLoginAndLoad()
  }

  // 检查用户登录状态
  async checkUserLoginStatus() {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string

      // 检查是否真正登录
      if (isLoggedIn && token.length > 0 && userInfoStr && userInfoStr.length > 0) {
        try {
          this.currentUser = JSON.parse(userInfoStr) as Consumer
          console.log('当前用户:', JSON.stringify(this.currentUser))
        } catch (parseError) {
          console.error('解析用户信息失败:', parseError)
          this.currentUser = null
        }
      } else {
        this.currentUser = null
      }
    } catch (error) {
      console.error('检查用户登录状态失败:', error)
      this.currentUser = null
    }
  }

  // 检查歌曲收藏状态
  async checkSongCollectionStatus(songId: number) {
    if (!this.currentUser) return false

    try {
      const params: CollectionModel = {
        user_id: this.currentUser.id,
        song_id: songId
      }
      console.log('检查收藏状态参数:', JSON.stringify(params))
      const res = await checkCollection(params)
      console.log('收藏状态检查完整结果:', JSON.stringify(res))
      return res.data
    } catch (error) {
      console.error('检查收藏状态失败:', error)
      return false
    }
  }

  // 批量检查收藏状态
  async checkAllSongsCollectionStatus() {
    if (!this.currentUser || !this.histories.length) {
      console.log('检查收藏状态跳过: 用户未登录或历史列表为空')
      return
    }

    console.log('开始检查收藏状态，用户ID:', this.currentUser.id, '历史数量:', this.histories.length)
    const newFavorites: number[] = []

    for (const song of this.histories) {
      const isCollected = await this.checkSongCollectionStatus(song.id)
      console.log(`歌曲 ${song.name}(ID: ${song.id}) 收藏状态:`, isCollected)
      if (isCollected) {
        newFavorites.push(song.id)
      }
    }

    this.favorites = newFavorites
    console.log('收藏状态检查完成，收藏的歌曲ID:', this.favorites)
  }

  async handleFavorite(song: SongModel) {
    // 检查用户是否已登录
    if (!this.currentUser) {
      promptAction.showToast({
        message: '请先登录后再收藏歌曲',
        duration: 2000
      })
      return
    }

    // 防止重复点击
    if (this.isUpdatingFavorite) {
      console.log('收藏操作进行中，请稍等...')
      return
    }

    this.isUpdatingFavorite = true

    const params: CollectionModel = {
      user_id: this.currentUser.id,
      song_id: song.id
    }

    try {
      if (this.favorites.includes(song.id)) {
        // 取消收藏
        const res = await deleteCollection(params)
        console.log('取消收藏结果:', JSON.stringify(res))
        if (JSON.parse(JSON.stringify(res))["code"] === 200) {
          promptAction.showToast({
            message: '取消收藏成功',
            duration: 1500
          })
          
          // 立即更新本地状态 - 从收藏列表中移除
          this.favorites = this.favorites.filter(id => id !== song.id)
        } else {
          promptAction.showToast({
            message: res.message || '取消收藏失败',
            duration: 2000
          })
        }
      } else {
        // 添加收藏
        const res = await addCollection(params)
        console.log('添加收藏结果:', JSON.stringify(res))
        if (JSON.parse(JSON.stringify(res))["code"] === 200) {
          promptAction.showToast({
            message: '收藏成功',
            duration: 1500
          })
          
          // 立即更新本地状态 - 添加到收藏列表
          this.favorites = [...this.favorites, song.id]
        } else {
          promptAction.showToast({
            message: res.message || '收藏失败',
            duration: 2000
          })
        }
      }
    } catch (error) {
      console.error('收藏操作失败:', error)
      promptAction.showToast({
        message: '操作失败，请稍后重试',
        duration: 2000
      })
    } finally {
      // 操作完成后重置状态
      this.isUpdatingFavorite = false
    }
  }

  // 检查单个歌曲是否被收藏
  isSongFavorited(songId: number): boolean {
    return this.favorites.includes(songId)
  }

  // 检查登录状态并加载数据
  async checkLoginAndLoad(): Promise<void> {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string

      this.isLoggedIn = isLoggedIn && token.length > 0

      // 获取当前用户ID
      if (userInfoStr && userInfoStr.length > 0) {
        try {
          const userInfo: UserInfo = JSON.parse(userInfoStr)
          this.currentUserId = userInfo.id || 1
        } catch (parseError) {
          console.error('解析用户信息失败:', parseError)
          this.currentUserId = 1
        }
      }

      if (this.isLoggedIn) {
        await this.checkUserLoginStatus()
        await this.initTestData() // 初始化测试数据
        await this.loadHistories()
      }
    } catch (error) {
      console.error('检查登录状态失败:', error)
      this.isLoggedIn = false
    }
  }

  // 初始化测试数据
  async initTestData(): Promise<void> {
    try {
      // 添加测试歌曲：夜曲
      await songHistoriesService.addSongHistoryByName(this.currentUserId, "夜曲")

      // 添加测试歌曲：以父之名
      await songHistoriesService.addSongHistoryByName(this.currentUserId, "以父之名")

      console.log('测试数据初始化完成')
    } catch (error) {
      console.error('初始化测试数据失败:', error)
    }
  }

  // 加载历史记录列表
  async loadHistories(showLoading: boolean = true): Promise<void> {
    if (!this.isLoggedIn) return

    if (showLoading) {
      this.isLoading = true
    } else {
      this.isRefreshing = true
    }

    try {
      // 从本地获取用户历史记录
      this.histories = await songHistoriesService.getUserSongHistory(this.currentUserId)
      console.log('历史记录加载成功，数量:', this.histories.length)
      // 加载历史后检查收藏状态
      await this.checkAllSongsCollectionStatus()

      if (!showLoading) {
        promptAction.showToast({ message: '刷新成功', duration: 2000 })
      }
    } catch (error) {
      console.error('加载历史记录错误:', error)
      this.histories = []
      if (!showLoading) {
        promptAction.showToast({ message: '刷新失败', duration: 2000 })
      }
    } finally {
      this.isLoading = false
      this.isRefreshing = false
    }
  }

  // 删除历史记录
  async removeHistory(songId: number): Promise<void> {
    try {
      const success = await songHistoriesService.removeSongFromHistory(this.currentUserId, songId)
      if (success) {
        await this.loadHistories(false)
        promptAction.showToast({ message: '删除成功', duration: 2000 })
      } else {
        promptAction.showToast({ message: '删除失败', duration: 2000 })
      }
    } catch (error) {
      console.error('删除历史记录失败:', error)
      promptAction.showToast({ message: '删除失败', duration: 2000 })
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
        Text("播放历史")
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
          .onClick(() => this.loadHistories(false))
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .margin({ bottom: -10 })
    .backgroundColor(this.myColor.background)
  }

  // 历史记录项
  @Builder
  HistoryItem(song: SongModel ) {
    Row() {
      Image(`${Config.SERVERURL}${song.pic}`)
        .width(50)
        .height(50)
        .objectFit(ImageFit.Contain)
        .borderRadius(40)
        .margin({right: 15 })

      Column({ space: 5 }) {
        Text(song.name)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.myColor.dark)
        Text(`${song.singer}`)
          .fontSize(14)
          .opacity(0.7)
          .fontColor(this.myColor.gray)
      }
      .width('56%')
      .alignItems(HorizontalAlign.Start)

      Row({space:8}) {
        // 添加收藏按钮 - 使用方法调用确保重新计算
        Image($r("app.media.ic_star1"))
          .fillColor(this.isSongFavorited(song.id) ? '#ff6b35' : this.myColor.dark)
          .onClick(async () => {
            // 处理收藏逻辑
            await this.handleFavorite(song);
          })
          .width(20)
          .height(20)
          .enabled(!this.isLoading && !this.isUpdatingFavorite) // 加载或更新时禁用按钮
          .opacity((!this.isLoading && !this.isUpdatingFavorite) ? 1.0 : 0.5) // 禁用时显示半透明
          .animation({
            duration: 200,
            curve: Curve.EaseInOut
          }) // 添加动画效果
         Image($r("app.media.ic_addplay"))
          .width(20)
          .height(20)
          .fillColor(this.myColor.dark)
          .onClick((event: ClickEvent) => {
            // 阻止事件冒泡，避免触发歌曲项的点击事件

            // 插入到播放列表最后一个位置
            const isExist = AvPlayerUtils.playList.some((item: SongModel) => item.id === song.id);
            if (!isExist) {
              AvPlayerUtils.playList.push(song); // 插入到末尾
              AvPlayerUtils.updateStateAfterChange(); // 更新状态
              promptAction.showToast({ message: '已添加到播放列表' });
            } else {
              promptAction.showToast({ message: '歌曲已在播放列表中' });
            }
          })
        Image($r("app.media.ic_detail"))
          .width(20)
          .height(20)
          .fillColor(this.myColor.dark)
          .onClick(() => {
            this.showBottomSheet(song)
          })
      }
      .margin({left:15})
    }
    .width('100%')
    .padding({left:20 , right: 40})
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.myColor.background)
    .borderRadius(12)
    .onClick(async()=>{
      // 1.
      add_click_num(song.id)
      if(this.currentUser)
      {
        user_addclick(this.currentUser.id,song.id)
      }
      // 2.
      // 获取当前用户id
      const userInfoRaw: string = await preferencesUtil.get("userinfoStore", "userInfo", "") as string;
      const userInfoStr: string = typeof userInfoRaw === "string" ? userInfoRaw : String(userInfoRaw);
      if (userInfoStr && userInfoStr.length > 0) {
        const userInfo: UserInfo = JSON.parse(userInfoStr) as UserInfo;
        await songHistoriesService.addSongHistory(userInfo.id, song);
      }
      // 3.点击歌曲项：插入到播放列表第一个位置并播放
      const isExist = AvPlayerUtils.playList.some(item => item.id === song.id);
      if (!isExist) {
        AvPlayerUtils.playList.unshift(song); // 插入到首位
      } else {
        // 如果已存在，移动到首位
        const index = AvPlayerUtils.playList.findIndex(item => item.id === song.id);
        if (index > 0) {
          AvPlayerUtils.playList.splice(index, 1);
          AvPlayerUtils.playList.unshift(song);
        }
      }
      AvPlayerUtils.playIndex = 0; // 设置当前播放索引为首位
      AvPlayerUtils.playSingle(song); // 播放当前歌曲
      // 跳转到播放器页面
      router.pushUrl({
        url: 'pages/Player',
        params: { song: JSON.stringify(song) }
      });
    })
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
      } else if (this.histories.length === 0) {
        Column() {
          Text('暂无播放历史')
            .fontSize(18)
            .fontColor(this.myColor.dark)
            .margin({ bottom: 16 })

          Button('去首页听歌')
            .onClick(() => router.back())
            .backgroundColor(this.myColor.gray)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: this.isRefreshing }) {
          List({space:15}) {
            ForEach(this.histories, (song: SongModel) => {
              ListItem() {
                this.HistoryItem(song)
              }
            }, (item: SongModel) => item.id.toString())
          }
          .padding(16)
        }
        .onRefreshing(() => this.loadHistories(false))
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.myColor.background)
  }
}

// 底部弹窗对话框组件
@CustomDialog
struct BottomSheetDialog {
  selectedSong?: SongModel | null;
  onCancel?: () => void;
  controller?: CustomDialogController;

  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  build() {
    Column() {
      // 拖拽指示器
      Divider()
        .width(40)
        .height(4)
        .backgroundColor(this.myColor.gray)
        .borderRadius(2)
        .margin({ top: 8, bottom: 16 })

      // 菜单项列表
      Column() {
        // 评论选项
        Row() {
          Image($r("app.media.ic_comment"))
            .width(20)
            .height(20)
            .fillColor(this.myColor.dark)
            .margin({ right: 25 })

          Text('评论')
            .fontSize(16)
            .fontColor(this.myColor.dark)
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onCancel?.();
          // 延迟跳转，确保弹窗先关闭
          setTimeout(() => {
            router.pushUrl({
              url: 'pages/Comment',
              params: {
                cid: this.selectedSong?.id
              }
            });
          }, 100);
        })
        .backgroundColor(Color.Transparent)
        .stateStyles({
          pressed: {
            .backgroundColor(this.myColor.gray)
          }
        })

        // 分割线
        Divider()
          .color(this.myColor.gray)
          .strokeWidth(1)
          .margin({ left: 20, right: 20 })

        // 播放视频选项
        Row() {
          Image($r("app.media.ic_video"))
            .width(20)
            .height(20)
            .fillColor(this.myColor.dark)
            .margin({ right: 25 })

          Text('播放视频')
            .fontSize(16)
            .fontColor(this.myColor.dark)
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onCancel?.();
          // 延迟跳转，确保弹窗先关闭
          setTimeout(() => {
            router.pushUrl({
              url: 'pages/MusicVideo',
              params: {
                cid : this.selectedSong?.id
              }
            });
          }, 100);
        })
        .backgroundColor(Color.Transparent)
        .stateStyles({
          pressed: {
            .backgroundColor(this.myColor.gray)
          }
        })
      }
      .backgroundColor(this.myColor.background)
      .borderRadius({ topLeft: 16, topRight: 16 })

      // 底部安全区域
      Row()
        .height(20)
    }
    .width('100%')
    .backgroundColor(this.myColor.background)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ bottom: 20 })
  }
}
