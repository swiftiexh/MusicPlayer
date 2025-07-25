import { AlbumModel } from '../model/AppModel'
import {getAlbums} from "../common/Api"
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

  // 专辑数据
  @State albumList: AlbumModel[]=[]
  async getAlbumList(){
    const res = await getAlbums()
    this.albumList = JSON.parse(JSON.stringify(res.data))
  }
  aboutToAppear(): void {
    this.getAlbumList()
  }

  build() {
    Column() {
      // 导航栏
      NavBar({title:"专辑"}).margin({bottom:-25})

      // 瀑布流容器，可滚动
      Scroll() {
        Column() {
          // Grid 实现瀑布流，2列布局
          Grid() {
            ForEach(this.albumList, (item: AlbumModel) => {
              GridItem() {
                Column({ space: 8 }) {
                  // 专辑封面
                  Image(`${Config.SERVERURL}${item.pic}`)
                    .width('100%')
                    .aspectRatio(1) // 保持正方形比例
                    .borderRadius(8);
                  // 专辑名称
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.myColor.dark)
                    .maxLines(1)
                  // 专辑歌手
                  Text(item.singer_name)
                    .fontSize(14)
                    .fontColor(this.myColor.gray)
                    .maxLines(2)
                }
                .padding(12)
                .backgroundColor(this.myColor.bright)
                .borderRadius(12)
                .onClick(() => {
                  router.pushUrl({ url: "pages/detail/AlbumDetail", params: { cid: item.id } });
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