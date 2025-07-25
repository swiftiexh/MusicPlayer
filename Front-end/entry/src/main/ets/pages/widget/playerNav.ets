import { PlayStateModel, PlayStateType } from '../model/PlayStateModel'
import {ConfigUtil as Config} from '../common/ConfigUtil'
import { dayModel,nightModel,ColorModel } from '../model/ColorModel'
import { AvPlayerUtils } from '../common/AvPlayerUtils'


@Component
export default struct PlayerNav {
  @Link playState: PlayStateType
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor:ColorModel = (this.isDark==true?nightModel:dayModel)

  build() {
    Row() {
      Row({space:10}) {
        Image(Config.SERVERURL+this.playState.pic)
          .width(40)
          .aspectRatio(1)
        Column() {
          Text(this.playState.name)
            .fontColor(this.myColor.dark)
        }.alignItems(HorizontalAlign.Start)
      }.height('100%')
      .alignItems(VerticalAlign.Center)
      Row({space:16}) {
        Image($r("app.media.ic_prev"))
          .width(20)
          .aspectRatio(1)
          .fillColor(this.myColor.gray)
          .onClick(() => {
            AvPlayerUtils.prev()  // 上一首
          })
        Image( this.playState.isPlay?$r('app.media.ic_paused'): $r('app.media.ic_play'))
          .fillColor(this.myColor?.gray ?? '#7e7e7e')
          .width(20)
          .onClick(() => {
            // 播放/暂停切换
            if (this.playState.isPlay) {
              AvPlayerUtils.pause()
            } else {
              // 恢复播放
              if (AvPlayerUtils.player && AvPlayerUtils.playList.length > 0) {
                // 如果播放器存在且有播放列表
                if (AvPlayerUtils.player.state === 'paused') {
                  // 如果播放器处于暂停状态，则恢复播放
                  AvPlayerUtils.player.play()
                  AvPlayerUtils.isPlay = true
                  AvPlayerUtils.updateStateAfterChange()
                } else {
                  // 其他情况，重新播放当前歌曲
                  AvPlayerUtils.playSingle(AvPlayerUtils.playList[AvPlayerUtils.playIndex])
                }
              }
            }
          })

        Image($r('app.media.ic_next'))
          .width(20)
          .aspectRatio(1)
          .fillColor(this.myColor.gray)
          .onClick(() => {
            AvPlayerUtils.next()  // 下一首
          })
      }.height('100%')
    }
    .width('100%')
    .height(60)
    .backgroundColor(this.myColor.background)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 20, right: 20 })
  }
}
