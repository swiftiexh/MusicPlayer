// PlaylistPanel.ets
import { SongModel } from '../model/AppModel'
import { dayModel,nightModel,ColorModel } from '../model/ColorModel'

@Component
export struct PlaylistPanel {
  // 控制面板显示的高度
  @Prop panelHeight: string
  // 播放列表数据
  @Prop playlist: SongModel[]
  // 当前播放索引
  @Prop currentIndex: number
  // 颜色模型
  @Prop myColor: ColorModel
  // 关闭面板的回调
  private onClose!: () => void
  // 播放指定歌曲的回调
  private onPlaySong!: (song: SongModel) => void
  // 删除歌曲的回调
  private onRemoveSong!: (index: number) => void

  // 构造函数接收参数
  constructor(params: {
    panelHeight: string,
    playlist: SongModel[],
    currentIndex: number,
    myColor: ColorModel,
    onClose: () => void,
    onPlaySong: (song: SongModel) => void,
    onRemoveSong: (index: number) => void
  }) {
    super()
    this.panelHeight = params.panelHeight
    this.playlist = params.playlist
    this.currentIndex = params.currentIndex
    this.myColor = params.myColor
    this.onClose = params.onClose
    this.onPlaySong = params.onPlaySong
    this.onRemoveSong = params.onRemoveSong
  }

  // 删除按钮构建器
  @Builder
  deleteButton(index: number) {
    Button() {
      Image($r('app.media.ic_remove'))  // 使用原始删除图标
        .width(20)
        .height(20)
        .fillColor(this.myColor.dark)
    }
    .backgroundColor("#03e884")
    .width(60)
    .height('100%')
    .type(ButtonType.Normal)
    .onClick(() => {
      this.onRemoveSong(index)
    })
  }

  build() {
    Column() {
      // 遮罩层 - 点击关闭面板
      Column()
        .width('100%')
        .layoutWeight(1)
        .onClick(() => {
          this.onClose()
        })

      // 播放列表内容区域
      Column() {
        // 标题栏
        Row() {
          Row() {
            Image($r("app.media.ic_play"))
              .width(25)
              .height(25)
              .fillColor("#03e884")
          }
          .width(50)
          .aspectRatio(1)
          .justifyContent(FlexAlign.Center)

          Row({ space: 8 }) {
            Text(`播放列表 (${this.playlist.length})`)
              .fontColor(this.myColor.dark)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
          }
          .layoutWeight(1)

          Image($r('app.media.ic_close'))
            .fillColor('#ffa49a9a')
            .width(24)
            .height(24)
            .margin({ right: 16 })
            .onClick(() => {
              this.onClose()
            })
        }
        .width('100%')
        .backgroundColor(this.myColor.gray)
        .padding(8)
        .border({
          width: { bottom: 1 },
          color: this.myColor.bright
        })
        .borderRadius({ topLeft: 4, topRight: 4 })

        // 播放列表
        List() {
          ForEach(this.playlist, (item: SongModel, index: number) => {
            ListItem() {
              Row() {
                Row() {
                  Text((index + 1).toString())
                    .fontColor(this.myColor.gray)
                    .fontSize(20)
                }
                .width(50)
                .aspectRatio(1)
                .justifyContent(FlexAlign.Center)

                Row({ space: 15 }) {
                  Column() {
                    Text(item.name)
                      .fontSize(20)
                      .fontColor(this.currentIndex === index ? "#03e884" : this.myColor.dark)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    this.onPlaySong(item)
                  })
                }
                .layoutWeight(1)

                Image($r('app.media.ic_remove'))
                  .width(24)
                  .height(24)
                  .margin({ right: 16 })
                  .fillColor(Color.Gray)
                  .onClick(() => {
                    this.onRemoveSong(index);
                  })
              }
              .alignItems(VerticalAlign.Center)
              .height(60)
            }
            .swipeAction({ end: this.deleteButton(index) })
          })
        }
        .layoutWeight(1)
        .backgroundColor(this.myColor.bright)
      }
      .height(400)
    }
    .height(this.panelHeight)
    .animation({ duration: 300 })
  }
}