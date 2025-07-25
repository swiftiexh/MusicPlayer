import media from '@ohos.multimedia.media'
import emitter from '@ohos.events.emitter'
import { EmitEventType } from '../model/paramModel'
import PreferencesUtils from './PreferencesUtil'
import { SongModel, SongModelClass } from '../model/AppModel'
import { defaultState, PlayStateType, PlayStateModel } from '../model/PlayStateModel'
import { ConfigUtil as Config } from "../common/ConfigUtil"
import router from '@ohos.router'
import { getSongs } from '../common/Api'

/**
 * 播放工具类 - 完整保留原有功能并添加歌词支持
 */
export class AvPlayerUtils {
  static player: media.AVPlayer
  static context: Context
  static duration: number = 0
  static time: number = 0
  static isPlay: boolean = false
  static playMode: 'auto' | 'repeat' | 'random' = 'auto'
  static playList: SongModel[] = []
  static playIndex: number = 0

  // 添加歌曲到播放列表
  public static addSongToPlaylist(song: SongModel) {
    const isExist = AvPlayerUtils.playList.some(item => item.id === song.id);
    if (!isExist) {
      AvPlayerUtils.playList.unshift(song);
      AvPlayerUtils.updateStateAfterChange();
    }
  }

  // 更新状态并通知UI
  public static updateStateAfterChange() {
    const currentSong = AvPlayerUtils.playList[AvPlayerUtils.playIndex] || new SongModelClass(0, 0, '', '', '', '','', 0, 0, '', '');

    const playStateData: PlayStateType = {
      pic: currentSong.pic,
      name: currentSong.name,
      url: currentSong.url,
      playIndex: AvPlayerUtils.playIndex,
      time: AvPlayerUtils.time,
      duration: AvPlayerUtils.duration,
      isPlay: AvPlayerUtils.isPlay,
      playMode: AvPlayerUtils.playMode,
      playlist: AvPlayerUtils.playList,
      lyrics: currentSong.lyric  // 从 currentSong.lyric 获取歌词
    };

    const playState: PlayStateModel = new PlayStateModel(playStateData);

    AvPlayerUtils.updateState(playState);
  }

  // 初始化播放器
  static async init() {
    if (AvPlayerUtils.player) return; // 避免重复初始化

    AvPlayerUtils.player = await media.createAVPlayer()

    AvPlayerUtils.player.on('stateChange', async (state) => {
      switch (state) {
        case 'initialized':
          await AvPlayerUtils.player.prepare()
          break
        case 'prepared':
          await AvPlayerUtils.player.play()
          AvPlayerUtils.isPlay = true
          break
        case 'completed':
          // 处理播放完成逻辑
          if (AvPlayerUtils.playMode === 'random' && AvPlayerUtils.playList.length > 1) {
            let index = 0
            do {
              index = Math.floor(Math.random() * AvPlayerUtils.playList.length)
            } while (index === AvPlayerUtils.playIndex)
            AvPlayerUtils.playIndex = index
          } else if (AvPlayerUtils.playMode === 'auto') {
            AvPlayerUtils.playIndex = (AvPlayerUtils.playIndex + 1) % AvPlayerUtils.playList.length
          }
          // 播放下一首
          if (AvPlayerUtils.playList.length > 0) {
            AvPlayerUtils.playSingle(AvPlayerUtils.playList[AvPlayerUtils.playIndex])
          }
          break
      }
    })

    AvPlayerUtils.player.on('durationUpdate', (duration) => {
      AvPlayerUtils.duration = duration
    })

    AvPlayerUtils.player.on('seekDone', async () => {
      await AvPlayerUtils.player.play()
      AvPlayerUtils.isPlay = true
    })

    // 时间更新
    let lastUpdateTime = 0
    AvPlayerUtils.player.on('timeUpdate', (time) => {
      // 每100ms更新一次，平衡性能和流畅度
      if (time - lastUpdateTime > 100 || time < lastUpdateTime) {
        AvPlayerUtils.time = time
        lastUpdateTime = time

        if (AvPlayerUtils.playList.length > 0) {
          const currentSong = AvPlayerUtils.playList[AvPlayerUtils.playIndex]
          const playStateData: PlayStateType = {
            pic: currentSong.pic,
            name: currentSong.name,
            url: currentSong.url,
            playIndex: AvPlayerUtils.playIndex,
            time: AvPlayerUtils.time,
            duration: AvPlayerUtils.duration,
            isPlay: AvPlayerUtils.isPlay,
            playMode: AvPlayerUtils.playMode,
            playlist: AvPlayerUtils.playList,
            lyrics: currentSong.lyric  // 从 currentSong.lyric 获取歌词
          };
          const playState: PlayStateModel = new PlayStateModel(playStateData);
          AvPlayerUtils.updateState(playState)
        }
      }
    })

    AvPlayerUtils.player.on('error', (error) => {
      console.error('播放器错误:', error)
    })
  }

  // 播放指定歌曲
  static playSingle(song: SongModel) {
    const isList = AvPlayerUtils.playList.some((item) => item.id === song.id)

    if (isList) {
      const index = AvPlayerUtils.playList.findIndex((item) => item.id === song.id)
      if (index !== -1) AvPlayerUtils.playIndex = index
    } else {
      AvPlayerUtils.playList.unshift(song)
      AvPlayerUtils.playIndex = 0
    }

    AvPlayerUtils.changePlay()  // 修改这里，使用类名调用静态方法
  }

  // 切换播放内容
  static async changePlay() {
    if (!AvPlayerUtils.playList.length) return;

    const currentSong = AvPlayerUtils.playList[AvPlayerUtils.playIndex]
    const newUrl = `${Config.SERVERURL}${currentSong.url}`

    if (AvPlayerUtils.player.url !== newUrl) {
      await AvPlayerUtils.player.reset()
      AvPlayerUtils.duration = 0
      AvPlayerUtils.time = 0
      AvPlayerUtils.player.url = newUrl
    }

    await AvPlayerUtils.player.prepare()
    await AvPlayerUtils.player.play()
    AvPlayerUtils.isPlay = true
  }

  // 发布状态更新
  static updateState(playState: PlayStateType) {
    emitter.emit(EmitEventType.UPDATE_STATE, {
      data: {
        playStateStr: JSON.stringify(playState)
      }
    })
    PreferencesUtils.set("play_state", "playState", JSON.stringify(playState))
  }

  // 暂停播放
  static pause() {
    AvPlayerUtils.player.pause()
    AvPlayerUtils.isPlay = false
    AvPlayerUtils.updateStateAfterChange()
  }

  // 下一首
  static next() {
    if (AvPlayerUtils.playList.length === 0) return

    const total = AvPlayerUtils.playList.length
    switch (AvPlayerUtils.playMode) {
      case 'auto':
        AvPlayerUtils.playIndex = (AvPlayerUtils.playIndex + 1) % total
        break
      case 'repeat':
        // 单曲循环 - 保持当前索引
        break
      case 'random':
        let index = AvPlayerUtils.playIndex
        do {
          index = Math.floor(Math.random() * total)
        } while (index === AvPlayerUtils.playIndex && total > 1)
        AvPlayerUtils.playIndex = index
        break
    }

    AvPlayerUtils.playSingle(AvPlayerUtils.playList[AvPlayerUtils.playIndex])
  }

  // 上一首
  static prev() {
    if (AvPlayerUtils.playList.length === 0) return

    if (AvPlayerUtils.playMode === 'random' && AvPlayerUtils.playList.length > 1) {
      let index = 0
      do {
        index = Math.floor(Math.random() * AvPlayerUtils.playList.length)
      } while (index === AvPlayerUtils.playIndex)
      AvPlayerUtils.playIndex = index
    } else {
      AvPlayerUtils.playIndex = (AvPlayerUtils.playIndex - 1 + AvPlayerUtils.playList.length) % AvPlayerUtils.playList.length
    }

    AvPlayerUtils.playSingle(AvPlayerUtils.playList[AvPlayerUtils.playIndex])
  }

  // 切换播放模式
  static changeMode(mode: 'auto' | 'repeat' | 'random') {
    AvPlayerUtils.playMode = mode
    AvPlayerUtils.updateStateAfterChange()
  }

  // 从列表移除歌曲
  static remove(index: number) {
    if (index < 0 || index >= AvPlayerUtils.playList.length) return

    if (AvPlayerUtils.playIndex === index) {
      if (AvPlayerUtils.playList.length > 1) {
        AvPlayerUtils.playList.splice(index, 1)
        AvPlayerUtils.playIndex = Math.min(AvPlayerUtils.playIndex, AvPlayerUtils.playList.length - 1)
        AvPlayerUtils.playSingle(AvPlayerUtils.playList[AvPlayerUtils.playIndex])
      } else {
        AvPlayerUtils.player.reset()
        AvPlayerUtils.playList = []
        AvPlayerUtils.isPlay = false
        AvPlayerUtils.duration = 0
        AvPlayerUtils.time = 0
        AvPlayerUtils.updateState(defaultState)
        router.back()
      }
    } else {
      if (AvPlayerUtils.playIndex > index) {
        AvPlayerUtils.playIndex--
      }
      AvPlayerUtils.playList.splice(index, 1)
      AvPlayerUtils.updateStateAfterChange()
    }
  }
}
