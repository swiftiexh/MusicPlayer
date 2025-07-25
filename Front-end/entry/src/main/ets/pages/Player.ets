import emitter from '@ohos.events.emitter'
import { EmitEventType, CollectionModel, ParamModel } from './model/paramModel'
import { SongModel, PlayerPageRouteParams, Consumer } from './model/AppModel'
import { defaultState, PlayStateModel, PlayStateType } from './model/PlayStateModel'
import { AvPlayerUtils } from './common/AvPlayerUtils'
import PreferencesUtil from './common/PreferencesUtil'
import { ConfigUtil as Config } from './common/ConfigUtil'
import { dayModel, nightModel, ColorModel } from "./model/ColorModel"
import router from '@ohos.router';
import { PlaylistPanel } from './widget/PlayListPanel'
import { addCollection, deleteCollection, checkCollection } from './common/Api'
import promptAction from '@ohos.promptAction'


// 歌词数据结构
interface LyricItem {
  time: number; // 毫秒
  text: string;
}

interface PlayStateEventData {
  playStateStr?: string
}

@Entry
@Component
struct Play {
  @State opacityNum: number = 1
  @State bgOpacity: number = 0.6
  @State isPlaylistVisible: boolean = false  // 布尔值控制显示/隐藏
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  // 视频背景资源列表（存放多个视频路径）
  @State videoSources: string[] = [
    '000.mp4',
    '111.mp4',
    '222.mp4',
    '333.mp4',
    '444.mp4',
    '555.mp4',
    '666.mp4',
    '777.mp4',
    '888.mp4',
    '999.mp4'
  ]
  // 当前播放的视频索引（默认播放第一个）
  @State currentVideoIndex: number = 0

  private switchVideoBackground() {
    this.currentVideoIndex = (this.currentVideoIndex + 1) % this.videoSources.length;
  }

  // 歌词相关状态
  @State lyrics: LyricItem[] = []
  @State currentLyricIndex: number = -1
  private scroller: Scroller = new Scroller()

  // 收藏相关状态
  @State isCollected: boolean = false
  @State currentUser: Consumer | null = null
  @State isUpdatingFavorite: boolean = false

  // 将十六进制颜色转换为带透明度的RGBA
  hexToRgba(hex: string, opacity: number): string {
    // 处理简写格式（如#fff -> #ffffff）
    if (hex.length === 4) {
      hex = `#${hex[1]}${hex[1]}${hex[2]}${hex[2]}${hex[3]}${hex[3]}`
    }

    // 提取RGB值
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)

    // 返回RGBA格式
    return `rgba(${r}, ${g}, ${b}, ${opacity})`
  }

  // 时长数字(ms)转字符串
  number2time(number: number) {
    const ms: number = number % 1000
    const second = (number - ms) / 1000
    const s: number = second % 60
    if (second > 60) {
      const m: number = (second - s) / 60 % 60
      return m.toString()
        .padStart(2, '0') + ':' + s.toString()
        .padStart(2, '0')
    }
    return '00:' + s.toString()
      .padStart(2, '0')
  }

  // 解析LRC格式歌词
  parseLyrics(lrcText: string): LyricItem[] {
    const lyricItems: LyricItem[] = []
    if (!lrcText) return lyricItems;

    const lines = lrcText.split('\n')
    const timeRegex = /\[(\d{2}):(\d{2})\.(\d{2,3})\]/

    lines.forEach(line => {
      const match = line.match(timeRegex)
      if (match) {
        const minutes = parseInt(match[1])
        const seconds = parseInt(match[2])
        const ms = parseInt(match[3].length === 2 ? match[3] + '0' : match[3])
        const totalMs = minutes * 60 * 1000 + seconds * 1000 + ms

        const text = line.replace(timeRegex, '').trim()
        if (text) {
          lyricItems.push({ time: totalMs, text })
        }
      }
    })

    return lyricItems.sort((a, b) => a.time - b.time)
  }

  // 更新当前歌词索引
  updateCurrentLyric(currentTime: number) {
    if (this.lyrics.length === 0) return;

    const currentMs = Math.floor(currentTime);
    let newIndex = -1;

    for (let i = 0; i < this.lyrics.length; i++) {
      if (currentMs < this.lyrics[i].time) {
        newIndex = i > 0 ? i - 1 : 0;
        break;
      }
      if (i === this.lyrics.length - 1) {
        newIndex = i;
      }
    }

    if (newIndex !== -1 && newIndex !== this.currentLyricIndex) {
      this.currentLyricIndex = newIndex;
      this.scrollToCurrentLyric();
    }
  }

  // 滚动到当前歌词
  scrollToCurrentLyric() {
    if (this.currentLyricIndex === -1 || !this.lyrics.length) return;

    const itemHeight = 40;
    const containerHeight = 80;
    const targetLineIndex = 0;

    const scrollOffset = (this.currentLyricIndex * itemHeight) - (targetLineIndex * itemHeight);

    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: scrollOffset,
      animation: {
        duration: 200,
        curve: Curve.EaseOut
      }
    });
  }

  // 原始删除按钮（使用ic_delete图标）
  @Builder
  deleteButton(index: number) {
    Button() {
      Image($r('app.media.ic_remove'))  // 使用ic_delete图标
        .width(20)
        .height(20)
        .fillColor('#fff')
    }
    .backgroundColor('#ec5c87')
    .width(80)
    .height('100%')
    .type(ButtonType.Normal)
    .onClick(() => {
      AvPlayerUtils.remove(index)
    })
  }

  // 动画效果状态
  @State randomShakenX: number = 0
  @State randomShakenY: number = 0
  @State randomNum: number = 0
  @State randomColor: string = 'rgb(0,0,0)'

  // 播放状态
  @State
  @Watch("onPlayStateChange") playState: PlayStateType = defaultState

  // 状态变化监听
  onPlayStateChange() {
    if (this.playState.isPlay) {
      this.randomNum = Math.random() * 50
      this.randomShakenX = 2 - Math.random() * 4
      this.randomShakenY = 2 - Math.random() * 4
      this.randomColor = `rgb(${Math.floor(Math.random() * 255)},${Math.floor(Math.random() * 255)},${Math.floor(Math.random() * 255)})`
    }

    this.updateCurrentLyric(this.playState.time)

    if (this.playState.lyrics &&
      (!this.lyrics.length || this.playState.lyrics !== this.lyrics[0].text)) {
      this.lyrics = this.parseLyrics(this.playState.lyrics)
      this.currentLyricIndex = -1
    }

    // 检查收藏状态（当歌曲发生变化时）
    this.checkCurrentSongCollectionStatus()
  }

  // 页面初始化
  async aboutToAppear() {
    emitter.on(EmitEventType.UPDATE_STATE, (data: emitter.EventData) => {
      const eventData = data.data as PlayStateEventData | undefined

      if (eventData?.playStateStr !== undefined) {
        this.playState = new PlayStateModel(JSON.parse(eventData.playStateStr))
        // 当播放状态更新时，检查收藏状态
        this.checkCurrentSongCollectionStatus()
      }
    })

    const params = router.getParams() as PlayerPageRouteParams;
    const songJson = params?.song as string;

    if (songJson) {
      const song = JSON.parse(songJson) as SongModel;
      AvPlayerUtils.addSongToPlaylist(song);
      AvPlayerUtils.playSingle(song);

      if (song.lyric) {
        this.lyrics = this.parseLyrics(song.lyric)
      }
    }

    AvPlayerUtils.changeMode('random');
    PreferencesUtil.set("play_state", "playState", JSON.stringify(this.playState))
    
    // 检查用户登录状态和收藏状态
    await this.checkUserLoginStatus()
    await this.checkCurrentSongCollectionStatus()
  }

  // 打开播放列表
  private openPlaylist() {
    this.isPlaylistVisible = true;
  }

  // 关闭播放列表
  private closePlaylist() {
    this.isPlaylistVisible = false;
  }

  // 播放指定歌曲
  private handlePlaySong(song: SongModel) {
    AvPlayerUtils.playSingle(song)
    if (song.lyric) {
      this.lyrics = this.parseLyrics(song.lyric)
      this.currentLyricIndex = -1
    }
    this.isPlaylistVisible = false; // 播放后关闭列表
  }

  // 检查用户登录状态
  async checkUserLoginStatus() {
    try {
      const token = await PreferencesUtil.get("userinfoStore", "token", "") as string
      const isLoggedIn = await PreferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean
      const userInfoStr = await PreferencesUtil.get("userinfoStore", "userInfo", "") as string

      if (isLoggedIn && token.length > 0 && userInfoStr && userInfoStr.length > 0) {
        try {
          this.currentUser = JSON.parse(userInfoStr) as Consumer
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

  // 检查当前歌曲收藏状态
  async checkCurrentSongCollectionStatus() {
    if (!this.currentUser || !this.playState.playlist.length || this.playState.playIndex < 0) return

    const currentSong = this.playState.playlist[this.playState.playIndex]
    if (!currentSong || !currentSong.id) return

    try {
      const params: CollectionModel = {
        user_id: this.currentUser.id,
        song_id: currentSong.id
      }
      const res = await checkCollection(params)
      this.isCollected = JSON.parse(JSON.stringify(res))["data"]
    } catch (error) {
      console.error('检查收藏状态失败:', error)
    }
  }

  // 处理收藏功能
  async handleFavorite() {
    if (!this.currentUser) {
      promptAction.showToast({
        message: '请先登录后再收藏歌曲',
        duration: 2000
      })
      return
    }

    if (!this.playState.playlist.length || this.playState.playIndex < 0) {
      promptAction.showToast({
        message: '当前没有播放歌曲',
        duration: 2000
      })
      return
    }

    const currentSong = this.playState.playlist[this.playState.playIndex]
    if (!currentSong || !currentSong.id) {
      promptAction.showToast({
        message: '获取当前歌曲信息失败',
        duration: 2000
      })
      return
    }

    if (this.isUpdatingFavorite) {
      return
    }

    this.isUpdatingFavorite = true

    const params: CollectionModel = {
      user_id: this.currentUser.id,
      song_id: currentSong.id
    }

    try {
      if (this.isCollected) {
        // 取消收藏
        const res = await deleteCollection(params)
        if (JSON.parse(JSON.stringify(res))["code"] === 200) {
          promptAction.showToast({
            message: '取消收藏成功',
            duration: 1500
          })
          this.isCollected = false
        } else {
          promptAction.showToast({
            message: res.message || '取消收藏失败',
            duration: 2000
          })
        }
      } else {
        // 添加收藏
        const res = await addCollection(params)
        if (JSON.parse(JSON.stringify(res))["code"] === 200) {
          promptAction.showToast({
            message: '收藏成功',
            duration: 1500
          })
          this.isCollected = true
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
      this.isUpdatingFavorite = false
    }
  }

  // 跳转到视频播放页面
  private navigateToMusicVideo() {
    if (!this.playState.playlist.length || this.playState.playIndex < 0) {
      promptAction.showToast({
        message: '当前没有播放歌曲',
        duration: 2000
      })
      return
    }

    const currentSong = this.playState.playlist[this.playState.playIndex]
    if (!currentSong || !currentSong.id) {
      promptAction.showToast({
        message: '获取当前歌曲信息失败',
        duration: 2000
      })
      return
    }

    const params: ParamModel = {
      cid: currentSong.id
    }

    router.pushUrl({
      url: 'pages/MusicVideo',
      params: params
    }).catch((error: Error) => {
      console.error('跳转到视频页面失败:', error)
      promptAction.showToast({
        message: '跳转失败，请稍后重试',
        duration: 2000
      })
    })
  }

  // 跳转到评论页面
  private navigateToComment() {
    if (!this.playState.playlist.length || this.playState.playIndex < 0) {
      promptAction.showToast({
        message: '当前没有播放歌曲',
        duration: 2000
      })
      return
    }

    const currentSong = this.playState.playlist[this.playState.playIndex]
    if (!currentSong || !currentSong.id) {
      promptAction.showToast({
        message: '获取当前歌曲信息失败',
        duration: 2000
      })
      return
    }

    const params: ParamModel = {
      cid: currentSong.id
    }

    router.pushUrl({
      url: 'pages/Comment',
      params: params
    }).catch((error: Error) => {
      console.error('跳转到评论页面失败:', error)
      promptAction.showToast({
        message: '跳转失败，请稍后重试',
        duration: 2000
      })
    })
  }

  build() {
    Stack() {
      Video({
        src: $rawfile(this.videoSources[this.currentVideoIndex])  // 绑定当前索引对应的视频
      })
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('100%')
        .zIndex(0)
        .autoPlay(true)
        .loop(true)
        .muted(true)
        .controls(false)
      // 播放界面
      Stack() {
        Column() {
          Column() {
            // 顶部导航栏区域
            Row() {
              // 返回按钮
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Image($r('app.media.ic_back'))
                  .width(25)
                  .height(25)
                  .fillColor(this.myColor.dark)
              }
              .width(40)
              .height(40)
              .backgroundColor('rgba(0, 0, 0, 0)')
              .margin({ left: 10 })
              .onClick(() => {
                router.back();
              })
              Blank()
            }
            .width('100%')
            .height(56)
            .alignItems(VerticalAlign.Center)

            // 唱片和封面
            Stack({ alignContent: Alignment.Top }) {
              Row() {
                Row() {
                  Image(Config.SERVERURL + this.playState.pic)
                    .width('70%')
                    .borderRadius(400)
                }
                .backgroundImage($r('app.media.ic_cd'))
                .backgroundImageSize(ImageSize.Cover)
                .justifyContent(FlexAlign.Center)
                .width('100%')
                .borderRadius(400)
                .clip(true)
                .aspectRatio(1)
                .shadow({
                  radius: this.randomNum,
                  color: this.randomColor
                })
                .animation({ duration: 1000 })
              }
              .margin({ top: 25 })
              .width('90%')
              .aspectRatio(1)
              .justifyContent(FlexAlign.Center)
              .padding(24)
            }

            // 歌曲名称动画
            Stack() {
              Column({ space: 8 }) {
                Text(this.playState.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor("#ff4d6746")
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .zIndex(1)
              .translate({ x: this.randomShakenX, y: this.randomShakenY })

              Column({ space: 8 }) {
                Text(this.playState.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#ff27431c')
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .zIndex(2)
              .translate({ x: this.randomShakenX, y: this.randomShakenY })

              Column({ space: 8 }) {
                Text(this.playState.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.myColor.dark)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .zIndex(3)
            }
            .layoutWeight(1)

            // 歌词显示区域
            Column() {
              if (this.lyrics.length > 0) {
                List({ scroller: this.scroller }) {
                  ListItem() {}

                  ForEach(this.lyrics, (item: LyricItem, index: number) => {
                    ListItem() {
                      Text(item.text)
                        .fontSize(18)
                        .fontColor(this.myColor.dark)
                        .fontWeight(FontWeight.Bold)
                        .height(40)
                        .width('100%')
                        .textAlign(TextAlign.Center)
                        .padding({ top: 0, bottom: 0 })
                    }
                  })

                }
                .width('100%')
                .height(80)
                .scrollBar(BarState.Off)
              } else {
                Text('暂无歌词')
                  .fontSize(18)
                  .fontColor(this.myColor.dark)
                  .height(80)
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20 })
            .justifyContent(FlexAlign.Center)

            // 操作按钮组
            Row() {
              Image($r("app.media.ic_star1"))
                .width(25)
                .height(25)
                .fillColor(this.isCollected ? '#ff6b35' : this.myColor.dark)
                .onClick(() => {
                  this.handleFavorite()
                })
                .enabled(!this.isUpdatingFavorite)
                .opacity(this.isUpdatingFavorite ? 0.5 : 1.0)
                .animation({
                  duration: 200,
                  curve: Curve.EaseInOut
                })

              Image($r("app.media.ic_video"))
                .width(30)
                .height(30)
                .fillColor(this.myColor.dark)
                .onClick(() => {
                  this.navigateToMusicVideo()
                })

              Image($r("app.media.ic_comment"))
                .width(30)
                .height(30)
                .fillColor(this.myColor.dark)
                .onClick(() => {
                  this.navigateToComment()
                })

              Image($r("app.media.ic_bashift"))
                .width(27)
                .height(27)
                .fillColor(this.myColor.dark)
                .onClick(() => this.switchVideoBackground())
            }
            .width('100%')
            .height(30)
            .justifyContent(FlexAlign.SpaceAround)
            .alignItems(VerticalAlign.Center)
            .padding({ left: 16, right: 16 })
            .margin({top: 15})

            // 播放控制区域
            Column() {
              // 进度条
              Row({ space: 4 }) {
                Text(this.number2time(this.playState.time))
                  .fontSize(12)
                  .fontColor(this.myColor.dark)
                Slider({
                  value: this.playState.time,
                  min: 0,
                  max: this.playState.duration
                })
                  .layoutWeight(1)
                  .blockColor(this.myColor.dark)
                  .selectedColor(this.myColor.dark)
                  .trackColor('#ccc5c5c5')
                  .trackThickness(2)
                  .onChange((time) => {
                    AvPlayerUtils.player.seek(time)
                  })

                Text(this.number2time(this.playState.duration))
                  .fontSize(12)
                  .fontColor(this.myColor.dark)
              }
              .width('100%')
              .padding(24)

              // 控制按钮
              Row() {
                if (this.playState.playMode === 'auto') {
                  Image($r("app.media.ic_auto"))
                    .fillColor(this.myColor.dark)
                    .width(30)
                    .onClick(() => {
                      AvPlayerUtils.changeMode('repeat')
                    })
                } else if (this.playState.playMode === 'repeat') {
                  Image($r("app.media.ic_repeat"))
                    .fillColor(this.myColor.dark)
                    .width(30)
                    .onClick(() => {
                      AvPlayerUtils.changeMode('random')
                    })
                } else if (this.playState.playMode === 'random') {
                  Image($r("app.media.ic_random"))
                    .fillColor(this.myColor.dark)
                    .width(30)
                    .onClick(() => {
                      AvPlayerUtils.changeMode('auto')
                    })
                }

                Image($r('app.media.ic_prev'))
                  .fillColor(this.myColor.dark)
                  .width(30)
                  .onClick(() => {
                    AvPlayerUtils.prev()
                  })

                Image(this.playState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
                  .fillColor(this.myColor.dark)
                  .width(50)
                  .onClick(() => {
                    this.playState.isPlay ? AvPlayerUtils.pause() : AvPlayerUtils.player.seek(this.playState.time)
                  })

                Image($r('app.media.ic_next'))
                  .fillColor(this.myColor.dark)
                  .width(30)
                  .onClick(() => {
                    AvPlayerUtils.next()
                  })

                // 播放列表按钮
                Image($r('app.media.ic_song_list'))
                  .fillColor(this.myColor.dark)
                  .width(30)
                  .onClick(() => {
                    this.openPlaylist()  // 点击打开播放列表
                  })
              }
              .width('100%')
              .padding({ bottom: 24 })
              .justifyContent(FlexAlign.SpaceAround)
            }
            .width('100%')
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor(this.hexToRgba(this.myColor.bright, this.bgOpacity))
        }
      }
      .backgroundColor(Color.Transparent)
      .zIndex(1) // 让播放界面内容在视频背景之上

      // 播放列表面板组件 - 条件渲染，默认不显示
      if (this.isPlaylistVisible) {
        PlaylistPanel({
          panelHeight: '100%',
          playlist: this.playState.playlist,
          currentIndex: this.playState.playIndex,
          myColor: this.myColor,
          onClose: this.closePlaylist.bind(this),
          onPlaySong: this.handlePlaySong.bind(this),
          onRemoveSong: (index: number) => {
            AvPlayerUtils.remove(index);
          },

        })
          .zIndex(100)  // 确保在最上层显示
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .opacity(this.opacityNum)
  }

  // 页面过渡效果
  pageTransition() {
    PageTransitionEnter({ duration: 200 })
      .onEnter(() => {
        this.opacityNum = 1
      })
    PageTransitionExit({ duration: 200 })
      .onExit(() => {
        this.opacityNum = 0
      })
  }
}