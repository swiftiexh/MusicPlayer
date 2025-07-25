import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {SearchResultModel} from "../model/AppModel"
import {ParamModel} from "../model/paramModel"
import {doSearch} from "../common/Api"
import { ColorModel, dayModel, nightModel } from '../model/ColorModel'
import {SearchTab,SearchTabData} from "../model/TabBar"
import {Album} from "./searchdetail/Album"
import {Singer} from "./searchdetail/Singer"
import {Song} from "./searchdetail/Song"
import {Song_list} from "./searchdetail/Song_list"

@Entry
@Component
struct SearchDetail {
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor:ColorModel = (this.isDark==true?nightModel:dayModel)
  @State keywords: string = ""
  @State resultList: SearchResultModel[] = []
  @State type: number = 1
  @State currentName: string = "Song"


  // 先拿到数据
  async searchedData() {
    const params: ParamModel = {
      keywords: this.keywords,
      type: this.type,
    }
    const res = await doSearch(params)
    if (res.success) {
      this.resultList = JSON.parse(JSON.stringify(res.data)).list
      console.log('searchedData:' + JSON.stringify(this.resultList))
    } else {
      promptAction.showToast({
        message: res.message,
        duration: 5000
      })
    }
  }

  // 切换tab时更新数据
  async onTabChange(tabName: string) {
    this.currentName = tabName
    this.type = (tabName === "Song" ? 1 :
    tabName === "Singer" ? 2 :
    tabName === "Song_list" ? 3 :
    tabName === "Album" ? 4: 0)
    await this.searchedData()
  }

  aboutToAppear() {
    // 页面第一次加载时从路由中获取参数并初始化
    let params: ParamModel = router.getParams() as ParamModel;
    this.keywords = params.keywords ?? ""
    this.searchedData()
  }

  @Builder
  SearchWidget()
  {
    Row(){
      Image($r("app.media.ic_back"))
        .width(25)
        .height(25)
        .borderRadius(3)
        .fillColor(this.myColor.dark)
        .onClick(() => {
          router.back()
        })
        .margin({right:8})
      Search({ value: this.keywords,
        placeholder: '歌手 正在搜索' })
        .height(35)
        .fontColor(this.myColor.dark)
        .searchIcon({color:this.myColor.dark})
        .backgroundColor(this.myColor.bright)
        .placeholderColor(this.myColor.gray)
        .borderColor(this.myColor.dark)
        .borderWidth(2)
        .placeholderFont({ size: 16, weight: 400 })
        .onClick(
          () => {
            router.replaceUrl({
              url: "pages/search/SearchPage",
              params: {
                keywords: this.keywords
              }
            })
          }
        )
        .layoutWeight(1)
    }
    .width("100%")
    .height(50)
    .margin({top:10})
    .backgroundColor(this.myColor.background)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  SearchTabBuilder(item: SearchTab)
  {
    Column(){
      Text(`${item.title}`)
        .fontSize(20)
        .fontColor(item.name==this.currentName?this.myColor.dark:this.myColor.gray)
        .margin({top: 5})
      if(item.name == this.currentName)
      {
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(46)
          .height(3)
      }
    }
    .backgroundColor(this.myColor.background)
    .width("100%")
    .height(50)
    .justifyContent(FlexAlign.Center)
  }
  @Builder
  DetailWidget(){
    Column(){
      Tabs({barPosition: BarPosition.Start}){
        // 歌曲、歌手、歌单、专辑
        ForEach(SearchTabData, (item:SearchTab, index:number) => {
          TabContent(){
            if(item.name == "Song"){
              Song({ resultList: this.resultList })
            }else if(item.name == "Singer"){
              Singer({ resultList: this.resultList })
            }else if(item.name == "Song_list"){
              Song_list({ resultList: this.resultList })
            }else if(item.name == "Album"){
              Album({ resultList: this.resultList })
            }
          }
          .tabBar(this.SearchTabBuilder(item))
        },(item:SearchTab)=>item.name)
      }
      .onChange(index => {
        this.onTabChange(SearchTabData[index].name)
      })
    }
    .width("100%")
    .layoutWeight(1)
  }

  build() {
    Column()
    {
      this.SearchWidget()
      this.DetailWidget()
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.myColor.background)
  }
}