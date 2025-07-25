import {SearchResultModel,Consumer,UserInfo,SongModel} from "../../model/AppModel"
import {ColorModel,dayModel,nightModel} from "../../model/ColorModel"
import {ConfigUtil as Config} from "../../common/ConfigUtil"
import {AvPlayerUtils} from "../../common/AvPlayerUtils"
import {add_click_num,user_addclick} from "../../common/Api"
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import {CollectionModel} from "../../model/paramModel"
import {addCollection,deleteCollection,checkCollection} from "../../common/Api"
import preferencesUtil from '../../common/PreferencesUtil'
import songHistoriesService from "../../services/SongHistoriesService"

@Component
export struct Song {
  @Prop resultList: SearchResultModel[] = []
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  @State favorites: number[] = [] // 改用数组存储收藏的歌曲ID
  @State isLoading: boolean = true
  @State currentUser: Consumer | null = null
  @State isUpdatingFavorite: boolean = false // 防止重复点击

  @State isBottomSheetVisible: boolean = false
  @State selectedSong: SearchResultModel | null = null

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
  showBottomSheet(song: SearchResultModel) {
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
    if (!this.currentUser || !this.resultList.length) {
      console.log('检查收藏状态跳过: 用户未登录或歌曲列表为空')
      return
    }

    console.log('开始检查收藏状态，用户ID:', this.currentUser.id, '歌曲数量:', this.resultList.length)
    const newFavorites: number[] = []

    for (const song of this.resultList) {
      const isCollected = await this.checkSongCollectionStatus(song.id)
      console.log(`歌曲 ${song.name}(ID: ${song.id}) 收藏状态:`, isCollected)
      if (isCollected) {
        newFavorites.push(song.id)
      }
    }

    this.favorites = newFavorites
    console.log('收藏状态检查完成，收藏的歌曲ID:', this.favorites)
  }

  async aboutToAppear() {
    this.isLoading = true
    await this.checkUserLoginStatus()
    await this.checkAllSongsCollectionStatus()
    this.isLoading = false
  }

  async handleFavorite(song: SearchResultModel) {
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

  build() {
    Column()
    {
      if(this.resultList.length) {
        List() {
          ForEach(this.resultList, (song: SearchResultModel) => {
            ListItem() {
              Row() {
                Image(`${Config.SERVERURL}${song.pic}`)
                  .width(50)
                  .height(50)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(40)
                  .margin({ left: 20, right: 15 })

                Column({ space: 5 }) {
                  Text(song.name)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.myColor.dark)
                  Text(`歌手: ${song.singer}`)
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
                        const song1: SongModel = {
                          id: song.id,
                          name: song.name ? song.name : '',
                          pic: song.pic ? song.pic : '',
                          lyric: song.lyric ? song.lyric : '',
                          url: song.url ? song.url : '',
                          video_url: song.video_url ? song.video_url : '',
                          click_num: song.click_num ? song.click_num : 0,
                          singer: song.singer ? song.singer : '',
                          album: song.album? song.album : '',
                        }
                        AvPlayerUtils.playList.push(song1); // 插入到末尾
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
              .width('85%')
              .height(100)
              .alignItems(VerticalAlign.Center)
              .onClick(async()=>{
                const song1: SongModel = {
                  id: song.id,
                  name: song.name ? song.name : '',
                  pic: song.pic ? song.pic : '',
                  lyric: song.lyric ? song.lyric : '',
                  url: song.url ? song.url : '',
                  video_url: song.video_url ? song.video_url : '',
                  click_num: song.click_num ? song.click_num : 0,
                  singer: song.singer ? song.singer : '',
                  album: song.album? song.album : '',
                }
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
                  await songHistoriesService.addSongHistory(userInfo.id, song1);
                }
                // 3.点击歌曲项：插入到播放列表第一个位置并播放
                const isExist = AvPlayerUtils.playList.some(item => item.id === song1.id);
                if (!isExist) {
                  AvPlayerUtils.playList.unshift(song1); // 插入到首位
                } else {
                  // 如果已存在，移动到首位
                  const index = AvPlayerUtils.playList.findIndex(item => item.id === song1.id);
                  if (index > 0) {
                    AvPlayerUtils.playList.splice(index, 1);
                    AvPlayerUtils.playList.unshift(song1);
                  }
                }
                AvPlayerUtils.playIndex = 0; // 设置当前播放索引为首位
                AvPlayerUtils.playSingle(song1); // 播放当前歌曲
                // 跳转到播放器页面
                router.pushUrl({
                  url: 'pages/Player',
                  params: { song: JSON.stringify(song1) }
                });
              })
            }
          })
        }
        .width('100%')
      }
      else{
        Column(){
        Image($r("app.media.ic_wrong"))
          .width(100)
          .height(100)
          .fillColor("#03e884")

          Text("没有搜索结果")
            .fontSize(18)
            .fontColor(this.myColor.gray)
            .margin({top:10})
        }
        .width("100%")
        .height("100%")
        .margin({top:-40})
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        }
    }
    .margin({top:-40})
    .width("100%")
    .height("100%")
    .onAppear(() => {
      this.aboutToAppear()
    })
  }
}

// 底部弹窗对话框组件
@CustomDialog
struct BottomSheetDialog {
  selectedSong?: SearchResultModel | null;
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