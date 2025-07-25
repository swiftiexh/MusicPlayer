import { TabBarModel, tabsData } from "./model/TabBar"
import {dayModel,nightModel,ColorModel} from "./model/ColorModel"
import {PlayStateType,PlayStateModel, defaultState} from "./model/PlayStateModel"
import {AvPlayerUtils} from "../pages/common/AvPlayerUtils"
import emitter from '@ohos.events.emitter'
import router from '@ohos.router'
import { EmitEventType } from './model/paramModel'
import PlayerNav from './widget/playerNav'
import { getSongs } from './common/Api'  // 引入getSongs API
import { SongModelClass } from './model/AppModel'  // 引入SongModelClass

import { Home } from "./tabs/Home"
import { Rank } from "./tabs/Rank"
import { Mine } from "./tabs/Mine"

// 文件顶部定义接口
interface PlayStateEventData {
  playStateStr?: string
}

@Entry
@Component
struct Index {
  @State currentName: string = "Home"
  @State opacityNum: number = 0
  @StorageLink("isDark") isDark: boolean =  false
  @StorageLink("myColor") myColor:ColorModel = (this.isDark==true?nightModel:dayModel)

  @State
  playState: PlayStateType = new PlayStateModel(defaultState) as PlayStateType;

  // 重新获取全部歌曲并重置播放列表
  private async resetToAllSongs() {
    try {
      // 从后端获取全部歌曲
      const res = await getSongs()

      // 显式声明 allSongs 类型
      const allSongs: SongModelClass[] = JSON.parse(JSON.stringify(res.data)) as SongModelClass[]

      // 重置播放列表为全部歌曲
      AvPlayerUtils.playList = allSongs.length > 0 ? allSongs : [
        new SongModelClass(1, 1, '刘德华', " ", '', "/song/bingyu.mp3", '',1, 0,"",'')
      ]

      // 重置播放索引为第一首
      AvPlayerUtils.playIndex = 0

      // 如果列表不为空，更新播放状态
      if (AvPlayerUtils.playList.length > 0) {
        const firstSong = AvPlayerUtils.playList[0]
        AvPlayerUtils.playSingle(firstSong) // 自动播放第一首（可选）
      }

      // 通知UI更新
      AvPlayerUtils.updateStateAfterChange()
      console.log('播放列表已重置为全部歌曲')
    } catch (error) {
      console.error('获取全部歌曲失败:', error)
      // 失败时使用默认歌曲
      AvPlayerUtils.playList = [
        new SongModelClass(1, 1, '刘德华', " ", '', "/song/bingyu.mp3",'', 1, 0,'','')
      ]
      AvPlayerUtils.playIndex = 0
      AvPlayerUtils.updateStateAfterChange()
    }
  }

  // 订阅事件
  async aboutToAppear(){
    // 1. 先初始化播放器
    await AvPlayerUtils.init()

    // 2. 先订阅事件，确保不会错过初始化后的状态更新
    emitter.on(EmitEventType.UPDATE_STATE, (data: emitter.EventData) => {
      const eventData = data.data as PlayStateEventData | undefined

      if (eventData?.playStateStr !== undefined) {
        console.log('666', eventData.playStateStr)
        this.playState = new PlayStateModel(JSON.parse(eventData.playStateStr))
        console.log('logData999', '得到通知::', this.playState)
      } else {
        console.warn('事件数据中没有 playStateStr')
      }
    })

    // 3. 最后初始化状态（确保在订阅之后）
    if (AvPlayerUtils.playList.length > 0) {
      const currentSong = AvPlayerUtils.playList[AvPlayerUtils.playIndex];
      this.playState = {
        pic: currentSong.pic,
        name: currentSong.name,
        url: currentSong.url,
        playIndex: AvPlayerUtils.playIndex,
        time: AvPlayerUtils.time,
        duration: AvPlayerUtils.duration,
        isPlay: AvPlayerUtils.isPlay,
        playMode: AvPlayerUtils.playMode,
        playlist: AvPlayerUtils.playList
      };
      // 手动触发一次UI更新
      this.updatePlayStateUI();
    }
  }

  // 手动更新播放状态UI的方法
  private updatePlayStateUI() {
    // 直接创建符合PlayStateType接口的新对象
    const newState: PlayStateType = {
      pic: this.playState.pic,
      name: this.playState.name,
      url: this.playState.url,
      playIndex: this.playState.playIndex,
      time: this.playState.time,
      duration: this.playState.duration,
      isPlay: this.playState.isPlay,
      playMode: this.playState.playMode,
      playlist: this.playState.playlist
    };
    this.playState = newState;
  }

  @Builder
  TabBarBuilder(item: TabBarModel) {
    Column() {
      Image(item.icon)
        .fillColor(item.name === this.currentName ? this.myColor.dark : this.myColor.gray)
        .width(30)
        .height(30)
      Text(`${item.title}`)
        .fontSize(16)
        .fontColor(item.name === this.currentName ? this.myColor.dark : this.myColor.gray)
        .margin({ top: 5 })
    }
    .justifyContent(FlexAlign.Center)
    .width("25%")
    .height(60)
    .onClick(async () => {  // 注意添加async关键字
      if (item.name === "Player") {
        // 点击Player时先重置播放列表为全部歌曲
        await this.resetToAllSongs()
        // 再跳转到播放器页面
        router.pushUrl({ url: "pages/Player" })
        return
      }
      this.currentName = item.name
    })
  }

  @Builder
  PageContent() {
    if (this.currentName === "Home") {
      Home()
    } else if (this.currentName === "Rank") {
      Rank()
    } else if (this.currentName === "Mine") {
      Mine()
    } else {
      // 用空Column替代Blank，避免不支持的问题
      Column()
        .width('100%')
        .height('100%')
    }
  }

  build() {
    Column() {
      // 主内容
      Stack() {
        this.PageContent()
      }.layoutWeight(1)

      // 底部导航栏
      Stack({alignContent: Alignment.Bottom}) {
        Row() {
          ForEach(tabsData, (item: TabBarModel) => {
            this.TabBarBuilder(item)
          }, (item: TabBarModel) => item.name)
        }
        .height(70)
        .backgroundColor(this.myColor.bright)

        // 调整显示条件，只要播放列表有内容就显示
        if (this.currentName !== "Mine" && this.playState.playlist.length > 0) {
          PlayerNav({playState: $playState})
            .translate({y: -60})
            .onClick(() => {
              router.pushUrl({ url: "pages/Player" })
            })
        }
      }
    }
    .width("100%")
    .height("100%")
  }
}
