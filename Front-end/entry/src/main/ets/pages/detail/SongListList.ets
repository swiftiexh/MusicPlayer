import { SongList } from '../model/AppModel';
import {getSongLists} from "../common/Api"
import {NavBar} from "../widget/NavBar"

import { dayModel, nightModel, ColorModel } from '../model/ColorModel';
import router from '@ohos.router';
import {ConfigUtil as Config} from  "../common/ConfigUtil"


@Entry
@Component
struct SongListList {
  // 主题相关状态
  @StorageLink("isDark") isDark: boolean = false;
  @StorageLink("myColor") myColor: ColorModel = this.isDark ? nightModel : dayModel;

  // 歌单数据
  @State songList: SongList[]=[]
  async getSongList(){
     const res = await getSongLists()
     this.songList = JSON.parse(JSON.stringify(res.data))
  }
  aboutToAppear(): void {
   this.getSongList()
  }


  build() {
    Column() {
      // 导航栏
      NavBar({title:"歌单"}).margin({bottom:-25})

      // 瀑布流容器，可滚动
      Scroll() {
        Column() {
          // Grid 实现瀑布流，2列布局
          Grid() {
            ForEach(this.songList, (item: SongList) => {
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
    .width('100%')
    .height('100%')
    .backgroundColor(this.myColor.background);
  }
}