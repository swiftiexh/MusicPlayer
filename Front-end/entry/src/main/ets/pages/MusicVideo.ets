import router from '@ohos.router';
import {dayModel,nightModel,ColorModel} from "./model/ColorModel"
import {ParamModel} from "./model/paramModel"
import {getSongById} from "./common/Api"
import promptAction from '@ohos.promptAction'
import {ConfigUtil as Config} from "./common/ConfigUtil"

@Entry
@Component
struct MusicVideo
{
  @State song_video_url: string = ''
  @State isPlaying: boolean = false
  @State currentTime: number = 0
  @State totalTime: number = 0
  @State showControls: boolean = true
  @State isLoading: boolean = true
  private videoController: VideoController = new VideoController()
  private hideControlsTimer: number = -1

  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  async getMvUrlData() {
    const params: ParamModel = (router.getParams() as ParamModel)
    const res = await getSongById(params.cid? params.cid : 0)
    if (res.success) {
      this.song_video_url = JSON.parse(JSON.stringify(res.data)).video_url
      console.log('song_video_url:' + this.song_video_url)
      
      // 验证视频URL是否有效
      if (!this.song_video_url || this.song_video_url.trim() === '') {
        console.warn('视频URL为空')
        promptAction.showToast({
          message: '该歌曲暂无视频',
          duration: 2000
        })
        this.isLoading = false
        return
      }
      
      // 检查视频文件扩展名
      const videoUrl = `${Config.SERVERURL}${this.song_video_url}`
      const supportedFormats = ['.mp4', '.avi', '.mov', '.mkv', '.webm']
      const isSupported = supportedFormats.some(format => 
        this.song_video_url.toLowerCase().includes(format)
      )
      
      if (!isSupported) {
        console.warn('可能不支持的视频格式:', this.song_video_url)
      }
      
      console.log('完整视频URL:', videoUrl)
    } else {
      promptAction.showToast({
        message: res.message,
        duration: 5000
      })
      this.isLoading = false
    }
  }

  aboutToAppear()
  {
    this.getMvUrlData()
    this.resetHideControlsTimer()
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.hideControlsTimer !== -1) {
      clearTimeout(this.hideControlsTimer)
    }
  }

  // 重置隐藏控制条的定时器
  resetHideControlsTimer() {
    if (this.hideControlsTimer !== -1) {
      clearTimeout(this.hideControlsTimer)
    }
    this.showControls = true
    this.hideControlsTimer = setTimeout(() => {
      if (this.isPlaying) {
        this.showControls = false
      }
    }, 3000)
  }

  // 播放/暂停切换
  togglePlay() {
    if (this.isPlaying) {
      this.videoController.pause()
      this.isPlaying = false
    } else {
      this.videoController.start()
      this.isPlaying = true
    }
    this.resetHideControlsTimer()
  }

  // 格式化时间显示
  formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = Math.floor(seconds % 60)
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`
  }

  // 拖动进度条
  onSeek(value: number) {
    const seekTime = (value / 100) * this.totalTime
    this.videoController.setCurrentTime(seekTime)
    this.currentTime = seekTime
    this.resetHideControlsTimer()
  }

  build()
  {
    Stack() {
      // 视频播放器
      Video({
        src: `${Config.SERVERURL}${this.song_video_url}`,
        controller: this.videoController
      })
        .width('100%')
        .height('100%')
        .autoPlay(false)
        .controls(false)
        .objectFit(ImageFit.Contain)
        .onStart(() => {
          console.log('视频开始播放')
          this.isPlaying = true
          this.isLoading = false
          this.resetHideControlsTimer()
        })
        .onPause(() => {
          console.log('视频暂停')
          this.isPlaying = false
          this.showControls = true
        })
        .onFinish(() => {
          console.log('视频播放完成')
          this.isPlaying = false
          this.showControls = true
          this.currentTime = 0
        })
        .onError(() => {
          console.error('视频播放错误')
          this.isLoading = false
        })
        .onPrepared((event) => {
          console.log('视频准备完成，时长:', event.duration)
          this.totalTime = event.duration
          this.isLoading = false
        })
        .onUpdate((progress) => {
          this.currentTime = progress.time
        })
        .onClick(() => {
          this.resetHideControlsTimer()
        })

      // 加载指示器
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#ffffff')
          
          Text('视频加载中...')
            .fontSize(16)
            .fontColor('#ffffff')
            .margin({ top: 12 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
      }

      // 视频控制层
      if (this.showControls && !this.isLoading) {
        Column() {
          // 顶部控制栏
          Row() {
            Image($r('app.media.ic_back'))
              .width(24)
              .height(24)
              .fillColor('#ffffff')
              .onClick(() => {
                router.back()
              })

            Blank()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })

          Blank()

          // 中央播放按钮
          Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(60)
            .height(60)
            .fillColor('#ffffff')
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .borderRadius(30)
            .padding(12)
            .onClick(() => {
              this.togglePlay()
            })

          Blank()

          // 底部进度控制栏
          Column() {
            // 进度条
            Row() {
              Text(this.formatTime(this.currentTime))
                .fontSize(12)
                .fontColor('#ffffff')
                .width(50)

              Slider({
                value: this.totalTime > 0 ? (this.currentTime / this.totalTime) * 100 : 0,
                min: 0,
                max: 100,
                step: 0.1
              })
                .layoutWeight(1)
                .trackColor('rgba(255, 255, 255, 0.3)')
                .selectedColor('#ffffff')
                .blockColor('#ffffff')
                .trackThickness(2)
                .onChange((value: number) => {
                  this.onSeek(value)
                })
                .margin({ left: 8, right: 8 })

              Text(this.formatTime(this.totalTime))
                .fontSize(12)
                .fontColor('#ffffff')
                .width(50)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            // 播放控制按钮
            Row() {
              Blank()

              Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                .width(40)
                .height(40)
                .fillColor('#ffffff')
                .onClick(() => {
                  this.togglePlay()
                })

              Blank()
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
          .backgroundColor('rgba(0, 0, 0, 0.5)')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}