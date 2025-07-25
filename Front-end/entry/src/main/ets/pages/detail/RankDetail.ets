import { RankSongModel, UserClickModel, Consumer, SongModel } from '../model/AppModel'
import { getSongsRanking, getUserClicks, getSongs } from '../common/Api'
import { dayModel, nightModel, ColorModel } from "../model/ColorModel"
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import preferencesUtil from '../common/PreferencesUtil'
import { ConfigUtil } from '../common/ConfigUtil'

@Entry
@Component
export struct Rank {
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)
  @StorageLink("isLoggedIn") isLoggedIn: boolean = false
  @StorageLink("currentUser") currentUser: Consumer | null = null

  @State currentTab: number = 0 // 0: 热度榜单, 1: 我的榜单
  @State songsRanking: RankSongModel[] = []
  @State userClicks: UserClickModel[] = []
  @State allSongs: SongModel[] = []
  @State isLoading: boolean = false

  async aboutToAppear() {
    await this.initializeUserState()
    await this.getAllSongs()
    await this.getSongsRankingData()
    if (this.isLoggedIn && this.currentUser) {
      await this.getUserClicksData()
    }
  }

  // 初始化用户状态
  async initializeUserState() {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean

      if (token && userInfoStr && isLoggedIn) {
        // 用户已登录，恢复登录状态
        const userInfo = JSON.parse(userInfoStr) as Consumer
        this.restoreLoggedInState(userInfo, token)
      } else {
        // 确保未登录状态
        this.resetToLoggedOutState()
      }
    } catch (error) {
      console.error('初始化用户状态失败:', error)
    }
  }

  // 恢复登录状态
  private restoreLoggedInState(userInfo: Consumer, token: string) {
    this.isLoggedIn = true
    this.currentUser = userInfo

    // 同步持久化存储
    PersistentStorage.PersistProp('isLoggedIn', true)
    PersistentStorage.PersistProp('userToken', token)
    PersistentStorage.PersistProp('currentUser', userInfo)
  }

  // 重置为未登录状态
  private resetToLoggedOutState() {
    this.isLoggedIn = false
    this.currentUser = null

    // 清除持久化存储
    PersistentStorage.PersistProp('isLoggedIn', false)
    PersistentStorage.PersistProp('userToken', '')
    PersistentStorage.PersistProp('currentUser', null)
  }

  // 获取所有歌曲信息
  async getAllSongs() {
    try {
      const res = await getSongs()
      if (res.success) {
        this.allSongs = res.data as SongModel[]
      }
    } catch (error) {
      console.error('获取歌曲信息失败:', error)
    }
  }

  // 获取歌曲热度排行榜
  async getSongsRankingData() {
    try {
      this.isLoading = true
      const res = await getSongsRanking()
      if (res.success) {
        this.songsRanking = res.data as RankSongModel[]
      } else {
        promptAction.showToast({ message: res.message || '获取热度榜单失败' })
      }
    } catch (error) {
      console.error('获取热度榜单失败:', error)
      promptAction.showToast({ message: '获取热度榜单失败' })
    } finally {
      this.isLoading = false
    }
  }

  // 获取用户点击排行榜
  async getUserClicksData() {
    try {
      if (!this.currentUser?.id) return

      this.isLoading = true
      const res = await getUserClicks(this.currentUser.id)
      if (res.success) {
        this.userClicks = res.data as UserClickModel[]
      } else {
        promptAction.showToast({ message: res.message || '获取我的榜单失败' })
      }
    } catch (error) {
      console.error('获取我的榜单失败:', error)
      promptAction.showToast({ message: '获取我的榜单失败' })
    } finally {
      this.isLoading = false
    }
  }

  // 获取用户头像URL
  getUserAvatarUrl(avatar?: string): string {
    if (!avatar) return ''
    return `${ConfigUtil.SERVERURL}consumer/${avatar}`
  }

  // 获取歌曲图片URL
  getSongImageUrl(songName: string): string {
    if (!songName) return ''
    return `${ConfigUtil.SERVERURL}song/${songName}.jpg`
  }

  // 根据歌曲ID获取歌曲信息
  getSongById(songId: number): SongModel | null {
    return this.allSongs.find(song => song.id === songId) || null
  }

  // 播放歌曲
  playSong(songId: number) {
    router.pushUrl({
      url: 'pages/Player',
      params: { songId: songId }
    })
  }

  // 标签页切换组件
  @Builder
  TabBar() {
    Row() {
      // 热度榜单
      Column({space:5}) {
        Text('热度榜单')
          .fontSize(16)
          .fontColor(this.currentTab === 0 ? this.myColor.dark : this.myColor.gray)
          .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)

        if (this.currentTab === 0) {
          Image($r('app.media.line'))
            .fillColor("#03e884")
            .width(70)
            .height(3)
        }
      }
      .width('50%')
      .padding({ top: 15, bottom: 15 })
      .onClick(() => {
        this.currentTab = 0
      })

      // 我的榜单
      Column() {
        Text('我的榜单')
          .fontSize(16)
          .fontColor(this.currentTab === 1 ? this.myColor.dark : this.myColor.gray)
          .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)

        if (this.currentTab === 1) {
          Image($r('app.media.line'))
            .fillColor("#03e884")
            .width(70)
            .height(3)
        }
      }
      .width('50%')
      .padding({ top: 15, bottom: 15 })
      .onClick(() => {
        if (!this.isLoggedIn) {
          promptAction.showToast({ message: '请先登录' })
          return
        }
        this.currentTab = 1
        if (this.userClicks.length === 0) {
          this.getUserClicksData()
        }
      })
    }
    .height(50)
    .width('100%')
    .backgroundColor(this.myColor.bright)
    .justifyContent(FlexAlign.SpaceAround)
  }

  // 排名图标组件
  @Builder
  RankIcon(rank: number) {
    if (rank < 3) {
      Stack() {
        Circle()
          .width(36)
          .height(36)
          .fill(rank === 0 ? '#FFD700' : rank === 1 ? '#C0C0C0' : '#CD7F32')

        Text((rank + 1).toString())
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
    } else {
      Stack() {
        Circle()
          .width(36)
          .height(36)
          .fill(this.myColor.bright)
          .border({
            width: 2,
            color: this.myColor.gray,
            radius: 18
          })

        Text((rank + 1).toString())
          .fontSize(16)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Bold)
      }
    }
  }

  // 排行榜项目组件
  @Builder
  RankItem(rank: number, song: RankSongModel, clickNum: number) {
    Row() {
      // 排名
      this.RankIcon(rank)

      // 歌曲封面
      Image(this.getSongImageUrl(song.name) || $r('app.media.img'))
        .width(60)
        .height(60)
        .borderRadius(12)
        .margin({ left: 20, right: 16 })
        .alt($r('app.media.img'))
        .shadow({
          radius: 8,
          color: '#00000015',
          offsetX: 0,
          offsetY: 2
        })

      // 歌曲信息
      Column() {
        Text(song.name)
          .fontSize(17)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(song.singer || '未知歌手')
          .fontSize(14)
          .fontColor(this.myColor.gray)
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (song.album) {
          Text(song.album)
            .fontSize(12)
            .fontColor(this.myColor.gray)
            .opacity(0.7)
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 播放次数
      Column() {
        Text(clickNum.toString())
          .fontSize(18)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Bold)

        Text('播放')
          .fontSize(12)
          .fontColor(this.myColor.gray)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 16 })

      // 播放按钮
      Stack() {
        Circle()
          .width(36)
          .height(36)
          .fill(this.myColor.bright)
          .border({
            width: 2,
            color: this.myColor.dark,
            radius: 18
          })

        Image($r('app.media.play_icon'))
          .width(20)
          .height(20)
          .fillColor(this.myColor.dark)
          .margin({left:4})
      }
      .margin({ right: 15 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.myColor.bright)
    .borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 12 })
    .shadow({
      radius: 8,
      color: '#00000008',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.playSong(song.id)
    })
  }

  // 用户点击排行榜项目组件
  @Builder
  UserClickItem(rank: number, userClick: UserClickModel) {
    Row() {
      // 排名
      this.RankIcon(rank)

      // 歌曲封面
      Image(this.getSongById(userClick.song_id)?.name ?
      this.getSongImageUrl(this.getSongById(userClick.song_id)!.name) :
      $r('app.media.img'))
        .width(60)
        .height(60)
        .borderRadius(12)
        .margin({ left: 20, right: 16 })
        .alt($r('app.media.img'))
        .shadow({
          radius: 8,
          color: '#00000015',
          offsetX: 0,
          offsetY: 2
        })

      // 歌曲信息
      Column() {
        Text(this.getSongById(userClick.song_id)?.name || '未知歌曲')
          .fontSize(17)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.getSongById(userClick.song_id)?.singer || '未知歌手')
          .fontSize(14)
          .fontColor(this.myColor.gray)
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.getSongById(userClick.song_id)?.album) {
          Text(this.getSongById(userClick.song_id)!.album!)
            .fontSize(12)
            .fontColor(this.myColor.gray)
            .opacity(0.7)
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 点击次数
      Column() {
        Text(userClick.click_num.toString())
          .fontSize(18)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Bold)

        Text('点击')
          .fontSize(12)
          .fontColor(this.myColor.gray)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 16 })

      // 播放按钮
      Stack() {
        Circle()
          .width(36)
          .height(36)
          .fill(this.myColor.bright)
          .border({
            width: 2,
            color: this.myColor.dark,
            radius: 18
          })

        Image($r('app.media.play_icon'))
          .width(20)
          .height(20)
          .fillColor(this.myColor.dark)
          .margin({left:4})
      }
      .margin({ right: 15 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.myColor.bright)
    .borderRadius(16)
    .margin({ left: 16, right: 16, bottom: 12 })
    .shadow({
      radius: 8,
      color: '#00000008',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.playSong(userClick.song_id)
    })
  }

  build() {
    Column() {
      // 页面标题
      Row() {
        Column({space:5}) {
          Text('排行榜')
            .fontSize(24)
            .fontColor(this.myColor.dark)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 })
            .width(90)
          Image($r('app.media.line'))
            .fillColor("#03e884")
            .width(70)
            .height(3)
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .padding({ top: 20 , bottom: 10})
      .backgroundColor(this.myColor.background)
      .justifyContent(FlexAlign.Start)

      // 标签页
      this.TabBar()

      Divider()
        .color(this.myColor.gray)
        .opacity(0.2)

      // 内容区域
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#4CAF50')

          Text('加载中...')
            .fontSize(16)
            .fontColor(this.myColor.gray)
            .margin({ top: 15 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.myColor.background)
      } else {
        if (this.currentTab === 0) {
          // 热度榜单
          if (this.songsRanking.length > 0) {
            Column() {
              // 榜单头部信息
              Row() {
                Column() {
                  Text(`热度榜单`)
                    .fontSize(20)
                    .fontColor(this.myColor.dark)
                    .fontWeight(FontWeight.Bold)

                  Text(`共 ${this.songsRanking.length} 首歌曲`)
                    .fontSize(14)
                    .fontColor(this.myColor.gray)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 热度图标
                Stack() {
                  Circle()
                    .width(44)
                    .height(44)
                    .fill('#ffe2decf')

                  Text('🔥')
                    .fontSize(24)
                }
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 16, bottom: 16 })
              .backgroundColor(this.myColor.bright)
              .borderRadius(16)
              .margin({top:8, left: 16, right: 16, bottom: 8 })

              List({ space: 0 }) {
                ForEach(this.songsRanking, (rankSong: RankSongModel, index: number) => {
                  ListItem() {
                    this.RankItem(index, rankSong, rankSong.click_num)
                  }
                })
              }
              .width('100%')
              .layoutWeight(1)
              .scrollBar(BarState.Auto)
              .backgroundColor(this.myColor.background)
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor(this.myColor.background)
          } else {
            Column() {
              Stack() {
                Circle()
                  .width(120)
                  .height(120)
                  .fill(this.myColor.bright)
                  .border({
                    width: 2,
                    color: this.myColor.gray,
                    style: BorderStyle.Dashed
                  })

                Text('📊')
                  .fontSize(48)
              }

              Text('暂无热度榜单')
                .fontSize(18)
                .fontColor(this.myColor.dark)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 24 })

              Text('稍后再来看看吧')
                .fontSize(14)
                .fontColor(this.myColor.gray)
                .opacity(0.8)
                .margin({ top: 8 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.myColor.background)
          }
        } else {
          // 我的榜单
          if (!this.isLoggedIn) {
            Column() {
              Stack() {
                Circle()
                  .width(120)
                  .height(120)
                  .fill(this.myColor.bright)
                  .border({
                    width: 2,
                    color: '#4CAF50',
                    style: BorderStyle.Dashed
                  })

                Text('🔐')
                  .fontSize(48)
              }

              Text('请先登录')
                .fontSize(20)
                .fontColor(this.myColor.dark)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 24 })

              Text('登录后查看您的个人点击榜单')
                .fontSize(14)
                .fontColor(this.myColor.gray)
                .opacity(0.8)
                .margin({ top: 8 })
                .textAlign(TextAlign.Center)

              Button('去登录')
                .backgroundColor('#4CAF50')
                .fontColor(Color.White)
                .borderRadius(25)
                .margin({ top: 32 })
                .padding({ left: 32, right: 32, top: 12, bottom: 12 })
                .shadow({
                  radius: 8,
                  color: '#4CAF5030',
                  offsetX: 0,
                  offsetY: 4
                })
                .onClick(() => {
                  // 提示用户到"我的"页面登录
                  promptAction.showToast({ message: '请到"我的"页面进行登录' })
                })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.myColor.background)
            .padding({ left: 40, right: 40 })
          } else if (this.userClicks.length > 0) {
            Column() {
              // 榜单头部信息
              Row() {
                // 用户头像
                Image(this.currentUser?.avatar ?
                this.getUserAvatarUrl(this.currentUser.avatar) :
                $r('app.media.profile'))
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .alt($r('app.media.profile'))
                  .margin({ right: 12 })

                Column() {
                  Row() {
                    Text(`${this.currentUser?.username || '用户'} 的榜单`)
                      .fontSize(20)
                      .fontColor(this.myColor.dark)
                      .fontWeight(FontWeight.Bold)

                    Text('🎖️')
                      .fontSize(16)
                      .margin({ left: 8 })
                  }

                  Text(`共 ${this.userClicks.length} 首歌曲`)
                    .fontSize(14)
                    .fontColor(this.myColor.gray)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // VIP标识
                Stack() {
                  Circle()
                    .width(44)
                    .height(44)
                    .fill('#ffe2decf')

                  Text('🎧')
                    .fontSize(20)
                }
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 16, bottom: 16 })
              .backgroundColor(this.myColor.bright)
              .borderRadius(16)
              .margin({ left: 16, right: 16, bottom: 8 ,top:8 })

              List({ space: 0 }) {
                ForEach(this.userClicks, (userClick: UserClickModel, index: number) => {
                  ListItem() {
                    this.UserClickItem(index, userClick)
                  }
                })
              }
              .width('100%')
              .layoutWeight(1)
              .scrollBar(BarState.Auto)
              .backgroundColor(this.myColor.background)
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor(this.myColor.background)
          } else {
            Column() {
              Stack() {
                Circle()
                  .width(120)
                  .height(120)
                  .fill(this.myColor.bright)
                  .border({
                    width: 2,
                    color: this.myColor.gray,
                    style: BorderStyle.Dashed
                  })

                Text('🎵')
                  .fontSize(48)
              }

              Text('暂无个人点击记录')
                .fontSize(18)
                .fontColor(this.myColor.dark)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 24 })

              Text('快去听歌，建立属于你的音乐榜单吧')
                .fontSize(14)
                .fontColor(this.myColor.gray)
                .opacity(0.8)
                .margin({ top: 8 })
                .textAlign(TextAlign.Center)
                .maxLines(2)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.myColor.background)
            .padding({ left: 40, right: 40 })
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.myColor.background)
  }
}