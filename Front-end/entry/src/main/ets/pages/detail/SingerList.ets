import { SingerModel } from '../model/AppModel'
import {dayModel,nightModel,ColorModel} from "../model/ColorModel"
import {getSingerList} from "../common/Api"
import router from '@ohos.router';
import {ConfigUtil as Config} from  "../common/ConfigUtil"
import {NavBar} from "../widget/NavBar"


@Entry
@Component
struct SingerList {
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  @State singerList: SingerModel[]=[]
  @State filteredSingerList: SingerModel[] = []

  @State regionFilter: string = '全部';
  @State sexFilter: string = '全部';
  regions: string[] = ['全部', '内地', '港台', '欧美', '日韩'];
  sexes: string[] = ['全部', '男', '女', '组合'];
  @State selectedRegionIndex: number = 0;  // 地区筛选的初始选中索引
  @State selectedSexIndex: number = 0;    // 性别筛选的初始选中索引

  async getSingerList(){
    const res = await getSingerList()
    this.singerList = JSON.parse(JSON.stringify(res.data))
    this.filterSingerList()
  }

  aboutToAppear(): void {
    this.getSingerList()
  }

  filterSingerList() {
    let filtered = this.singerList;

    if (this.regionFilter !== '全部') {
      filtered = filtered.filter(item => item.region === this.regionFilter);
    }

    if (this.sexFilter !== '全部') {
      filtered = filtered.filter(item => item.sex === this.sexFilter);
    }

    this.filteredSingerList = filtered;
  }

  @Builder
  filterSingerListBuilder() {
    Row() {
      // 地区筛选
      Column() {
        Text("地区")
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(45)
          .height(2)
      }
      Select(this.regions.map((region): SelectOption => ({ value: region })))
        .selected(this.selectedRegionIndex)
        .backgroundColor(this.myColor.background)
        .menuBackgroundColor(this.myColor.background)
        .fontColor(this.myColor.dark)
        .optionBgColor(this.myColor.background)
        .optionFontColor(this.myColor.dark)
        .width('30%')
        .font({ size: 20 , weight: FontWeight.Bold})
        .selectedOptionFont({ size: 16, weight: FontWeight.Medium })
        .optionFont({ size: 16 })
        .onSelect((index: number) => {
          this.selectedRegionIndex = index;
          this.regionFilter = this.regions[index];
          this.filterSingerList();
        })

      // 性别筛选
      Column() {
        Text("性别")
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(45)
          .height(2)
      }
      Select(this.sexes.map((sex): SelectOption => ({ value: sex })))
        .selected(this.selectedSexIndex) // 使用专门的索引状态变量
        .backgroundColor(this.myColor.background)
        .menuBackgroundColor(this.myColor.background)
        .fontColor(this.myColor.dark)
        .optionBgColor(this.myColor.background)
        .optionFontColor(this.myColor.dark)
        .width('30%')
        .font({ size: 20 , weight: FontWeight.Medium})
        .selectedOptionFont({ size: 16, weight: FontWeight.Medium })
        .optionFont({ size: 16 })
        .onSelect((index: number) => {
          this.selectedSexIndex = index;
          this.sexFilter = this.sexes[index];
          this.filterSingerList();
        })
    }
    .width('100%')
    .padding({left: 20, right: 20})
    .justifyContent(FlexAlign.SpaceAround)
    .margin({ bottom: 10 })
  }

  @Builder
  showSingerList() {
    // 歌手列表
    List() {
      ForEach(this.filteredSingerList, (singer: SingerModel) => {
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
            router.pushUrl({url:'pages/detail/SingerDetail',params:{cid:singer.id}})
          })
        }
      })
    }
    .width('100%')
  }

  build() {
    Column() {
      NavBar({title: "歌手"})

      Scroll() {
        Column() {
          this.filterSingerListBuilder()
          this.showSingerList()
        }
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.myColor.background)
  }
}