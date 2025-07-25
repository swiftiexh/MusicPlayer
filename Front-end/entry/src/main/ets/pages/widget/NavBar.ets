import router from '@ohos.router'
import {dayModel,nightModel,ColorModel} from "../model/ColorModel"

@Component
export struct NavBar
{
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  @Prop title:string = ""
  build(){
    // 顶部导航栏区域
    Stack({alignContent: Alignment.Start}) {
      Column() {
        Text(this.title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(60)
          .height(2.5)
      }
      .width("100%")
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      // 返回按钮
      Image($r("app.media.ic_back"))
        .width(25)
        .height(25)
        .borderRadius(3)
        .fillColor(this.myColor.dark)
        .onClick(() => {
          router.back()
        })
    }
    .width('100%')
    .height(55)
    .margin({bottom:10})
    .padding({left:20,right:20})
  }
}