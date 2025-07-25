import {SearchResultModel,} from "../../model/AppModel"
import {ColorModel,dayModel,nightModel} from "../../model/ColorModel"
import {ConfigUtil as Config} from "../../common/ConfigUtil"
import router from '@ohos.router';

@Component
export struct Singer {
  @Prop resultList: SearchResultModel[] = []
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  build() {
    Column() {
      if(this.resultList.length) {
        // 歌手列表
        List() {
          ForEach(this.resultList, (singer: SearchResultModel) => {
            ListItem() {
              Row() {
                Image(`${Config.SERVERURL}${singer.pic}`)
                  .width(70)
                  .height(70)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(35)
                  .margin({ left: 15, right: 15 })

                Column({ space: 5 }) {
                  Text(`${singer.name}`)
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.myColor.dark)
                  Text(`地区: ${singer.region}`)
                    .fontSize(14)
                    .opacity(0.7)
                    .fontColor(this.myColor.gray)
                }
                .width('70%')
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .height(100)
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                router.pushUrl({ url: 'pages/detail/SingerDetail', params: { cid: singer.id } })
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
    .margin({top:-30})
    .width("100%")
    .height("100%")
  }
}