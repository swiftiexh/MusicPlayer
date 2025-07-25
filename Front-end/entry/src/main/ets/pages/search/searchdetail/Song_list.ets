import {SearchResultModel} from "../../model/AppModel"
import { dayModel, nightModel, ColorModel } from '../../model/ColorModel'
import router from '@ohos.router';
import {ConfigUtil as Config} from "../../common/ConfigUtil"

@Component
export struct Song_list {
  @Prop resultList: SearchResultModel[] = []
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  build() {
    Column()
    {
      if(this.resultList.length) {
        // 瀑布流容器，可滚动
        Scroll() {
          Column() {
            // Grid 实现瀑布流，2列布局
            Grid() {
              ForEach(this.resultList, (item: SearchResultModel) => {
                GridItem() {
                  Column({ space: 8 }) {
                    // 歌单封面
                    Image(`${Config.SERVERURL}${item.pic}`)
                      .width('100%')
                      .aspectRatio(1) // 保持正方形比例
                      .borderRadius(8);
                    // 歌单名称
                    Text(item.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.myColor.dark)
                      .maxLines(1)
                    // 歌单简介
                    Text(item.introduction)
                      .fontSize(14)
                      .fontColor(this.myColor.gray)
                      .maxLines(2)
                      .textOverflow({
                        overflow: TextOverflow.Ellipsis
                      })
                  }
                  .padding(12)
                  .backgroundColor(this.myColor.bright)
                  .borderRadius(12)
                  .onClick(() => {
                    router.pushUrl({ url: "pages/detail/SongListDetail", params: { cid: item.id } });
                  })
                }
              })
            }
            .columnsTemplate('1fr 1fr') // 2列布局，可调整列数
            .columnsGap(12)
            .rowsGap(12)
            .padding(16)
            .width('100%');
          }
          .width('100%')
          .height("100%")
        }
        .flexGrow(1)
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