import {dayModel,nightModel,ColorModel} from "../model/ColorModel"
import {getSwiperList,getSongs,getSongLists} from "../common/Api"
import {ConfigUtil as Config} from  "../common/ConfigUtil"
import { Consumer,UserInfo,SwiperModel,SongList,SongModel } from '../model/AppModel'

import router from '@ohos.router';
import preferencesUtil from '../common/PreferencesUtil'


@Component
export struct Home{
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor:ColorModel = (this.isDark==true?nightModel:dayModel)
  @State swiperList: SwiperModel[]=[]

  @StorageLink("isLoggedIn") isLoggedIn: boolean = false
  @StorageLink("userToken") userToken: string = ''
  @StorageLink("currentUser") currentUser: Consumer | null = null

  @State dailySongs: SongModel[] = [] // 每日推荐歌曲
  @State vipSongLists: SongList[] = [] // 会员歌单

  @State userInfo: UserInfo = {
    id: 1,
    username: 'epiphany',
    sex: '男',
    birth: '2005-9-28',
    location: '天津',
    avatar: 'app.media.profile',
  }


  async initializeUserState() {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string
      const userInfo = await preferencesUtil.get("userinfoStore", "userInfo", "") as string
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean

    } catch (error) {
      console.error('初始化用户状态失败:', error)
    }
  }

  // 获得轮播图接口
  async getSwiper(){ // async异步转同步  await后跟的是promise对象，接收的的promise返回的结果
    const res = await getSwiperList()
    this.swiperList = JSON.parse(JSON.stringify(res.data))
    console.log("--------------------"+JSON.stringify(this.swiperList))
  }

  // 获取每日推荐歌曲（随机4首）
  async getDailySongs() {
    try {
      const res = await getSongs()
      if (res.success) {
        // 将获取到的所有歌曲转换为SongModel数组
        const allSongs: SongModel[] = res.data as SongModel[]
        // 随机选择4首歌曲
        const randomSongs: SongModel[] = []
        const songCount = Math.min(4, allSongs.length)
        const selectedIndices: number[] = []

        while (randomSongs.length < songCount) {
          const randomIndex = Math.floor(Math.random() * allSongs.length)
          if (!selectedIndices.includes(randomIndex)) {
            selectedIndices.push(randomIndex)
            randomSongs.push(allSongs[randomIndex])
          }
        }
        this.dailySongs = randomSongs
      }
    } catch (error) {
      console.error("获取每日推荐歌曲失败:", error)
    }
  }

  // 获取会员歌单（静态展示4个）
  async getVipSongLists() {
    try {
      const res = await getSongLists()
      if (res.success) {
        // 获取所有歌单
        const allSongLists: SongList[] = res.data as SongList[]
        // 选择前4个歌单
        this.vipSongLists = allSongLists.slice(0, 4)
      }
    } catch (error) {
      console.error("获取会员歌单失败:", error)
    }
  }

  aboutToAppear(): void {
    this.getSwiper()
    this.getDailySongs()
    this.getVipSongLists()
    this.initializeUserState()
  }


  // 统计卡片组件
  @Builder
  ListCard(title: string) {
    Row() {
      // 图标和小图片
      if(title=="收藏") {
        Image($r('app.media.ic_heart'))
          .width(30)
          .height(30)
          .fillColor(this.myColor.dark)
      }
      if(title=="历史") {
        Image($r('app.media.ic_history'))
          .width(30)
          .height(30)
          .fillColor(this.myColor.dark)
      }
      if(title=="评论") {
        Image($r('app.media.ic_comment'))
          .width(30)
          .height(30)
          .fillColor(this.myColor.dark)
      }
      if(title=="关注") {
        Image($r('app.media.ic_star'))
          .width(30)
          .height(30)
          .fillColor(this.myColor.dark)
      }
      Text(`${title}`)
        .fontSize(21)
        .fontColor(this.myColor.dark)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
      Image($r("app.media.right_icon"))
        .width(15)
        .height(15)
        .fillColor(this.myColor.gray)
    }
    .width("100%")
    .height(20)
    .backgroundColor(this.myColor.background)
    .justifyContent(FlexAlign.SpaceEvenly)
    .onClick(() => {
      console.log(`点击了${title}`)
    })
  }
  // 添加侧边栏状态控制
  @State showSidebar: boolean = false
  @State sidebarTranslateX: number = -300 // 初始位置在左侧屏幕外
  @Builder
  UserSidebar(){
    Column() {
      // 判断登录状态
      if (this.isLoggedIn) {
        // 信息展示区域
        Column() {
          Image($r(this.userInfo.avatar))
            .width(140)
            .height(140)
            .borderRadius(75)
            .margin({bottom:10})
          Column({ space: 8 }) {
            Text(this.userInfo.username)
              .fontSize(35)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.myColor.dark)
            Row({ space: 8 }) {
              Text(this.userInfo.sex)
                .fontSize(20)
                .fontColor(this.myColor.dark)
                .opacity(0.8)
                .padding({
                  left: 8,
                  right: 8,
                  top: 2,
                  bottom: 2
                })
                .borderRadius(10)
              Text(this.userInfo.location)
                .fontSize(20)
                .fontColor(this.myColor.dark)
                .opacity(0.8)
                .padding({
                  left: 8,
                  right: 8,
                  top: 2,
                  bottom: 2
                })
                .borderRadius(10)
            }
            Text(`${this.userInfo.birth}`)
              .fontSize(17)
              .fontColor(this.myColor.dark)
              .opacity(0.7)
          }
          .width("100%")
          .alignItems(HorizontalAlign.Center)
          .margin({bottom:20})
        }
        .margin({top:60,bottom:30})
        .border({
          width: { top: 0, right: 0, bottom: 2, left: 0 },
          color: { top: Color.Transparent, right: Color.Transparent, bottom: this.myColor.dark, left: Color.Transparent }
        })

        // 选项区域
        Column({space:30}){
          this.ListCard('收藏')
          this.ListCard('历史')
          this.ListCard('评论')
          this.ListCard('关注')
        }
        .width("100%")
      } else {
        // 未登录时显示
        Column()
        {
          Text('请登录')
            .fontSize(28)
            .fontColor(this.myColor.dark)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('70%')
    .height('100%')
    .backgroundColor(this.myColor.background)
    .borderWidth({ right: 2 })
    .borderColor(this.myColor.dark)
    .translate({ x: this.sidebarTranslateX })
  }

  // 固定顶部导航栏
  @Builder
  TopNavigationBar() {
    Row() {
      Image($r("app.media.ic_detail"))
        .width(25)
        .height(25)
        .borderRadius(3)
        .fillColor(this.myColor.dark)
        .onClick(() => {
          // 点击显示侧边栏
          this.showSidebar = true
          // 动画弹出效果
          animateTo({
            duration: 300,
            curve: Curve.EaseOut
          }, () => {
            this.sidebarTranslateX = 0
          })
        })

      Column() {
        Text('首页')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(65)
          .height(3)
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.myColor.background)
    .padding({ left: 20, right: 20 })
  }

  // 搜索框
  @Builder
  SearchInput() {
    Row() {
      Row({ space: 4 }) {
        Image($r('app.media.ic_search'))
          .width(20)
          .aspectRatio(1)
          .fillColor(this.myColor.gray)
          .margin({ left: 5 })
        Text('徐佳莹 大象的葬礼')
          .fontSize(17)
          .fontColor(this.myColor.gray)
          .layoutWeight(1)
          .margin({ left: 5 })
      }
      .backgroundColor(this.myColor.bright)
      .borderColor(this.myColor.dark)
      .borderWidth(1)
      .borderRadius(8)
      .width('90%')
      .height(40)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(50)
    .margin({bottom:8})
    .backgroundColor(this.myColor.background)
    .onClick(()=> {
      router.pushUrl({
        url: "pages/search/SearchPage"
      })
    })
  }

  // 轮播图
  @Builder
  Swiper() {
    Swiper() {
      ForEach(this.swiperList, (item: SwiperModel) => {
        Image(`${Config.SERVERURL}${item.pic}`)
          .width("90%")
          .height(200)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      }, (item: SwiperModel) => item.id.toString())
    }
    .loop(true)
    .autoPlay(true)
    .interval(2000)
    .displayArrow(true)
    .indicator(
      Indicator.dot()
        .color("#f2f1ef")
        .selectedColor("#d7d7d7")
    )
  }

  // 歌手/歌单/专辑
  @Builder
  StatCard(title: string, icon: string) {
    Column({ space: 8 }) {
      // 图标和小图片
      Image($r(icon))
        .width(35)
        .height(35)
        .fillColor(this.myColor.dark)
      Text(`${title}`)
        .fontSize(15)
        .fontColor(this.myColor.dark)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
    }
    .width(80)
    .height(80)
    .backgroundColor(this.myColor.background)
    .borderRadius(16)
    .borderWidth(2)
    .borderColor(this.myColor.dark)
    .margin({top:10,bottom:10})
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if(title == "歌手")
      {
        router.pushUrl({
          url: "pages/detail/SingerList"
        })
      }
      else if(title == "歌单")
      {
        router.pushUrl({
          url: "pages/detail/SongListList"
        })
      }
      else if (title == "专辑")
      {
        router.pushUrl({
          url: "pages/detail/AlbumList"
        })
      }
    })
  }
  @Builder
  StatsSection() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        this.StatCard('歌手', 'app.media.ic_singer')
        this.StatCard('歌单', 'app.media.ic_list')
        this.StatCard('专辑', 'app.media.ic_album')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
  }

  // 每日推荐
  @Builder
  DailyRecommend() {
    Column() {
      Column() {
        Text('每日推荐')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(80)
          .height(2.5)
      }
      .margin({bottom:-10})
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.dailySongs, (item: SongList) => {
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(`${Config.SERVERURL}${item.pic}`)
                .width(90)
                .height(90)
                .borderRadius(8)
              Image($r("app.media.play_icon"))
                .width(30)
                .height(30)
                .fillColor(Color.Gray)
                .margin({ left: 5, bottom: 5 })
            }
            .onClick(() => {
              // 点击跳转到播放页面并播放当前歌曲
              router.pushUrl({
                url: "pages/Player",
                params: {
                  song: JSON.stringify(item)
                }
              })
            })
          }, (item: SongList) => item.id.toString())
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(140)
    }
    .padding({left: 20, right: 20})
    .margin({bottom:-5})
    .width("100%")
    .layoutWeight(1)
  }

  // 每日推荐
  @Builder
  VIPRecommend() {
    Column() {
      Column() {
        Text('甄选歌单')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.myColor.dark)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(80)
          .height(2.5)
      }
      .margin({bottom:-10})
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.vipSongLists, (item: SongList) => {
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(`${Config.SERVERURL}${item.pic}`)
                .width(90)
                .height(90)
                .borderRadius(8)
              Image($r("app.media.play_icon"))
                .width(30)
                .height(30)
                .fillColor(Color.Gray)
                .margin({ left: 5, bottom: 5 })
            }
            .onClick(() => {
              // 点击跳转到歌单详情页面
              router.pushUrl({
                url: "pages/detail/SongListDetail",
                params: {
                  cid: item.id  // 改为cid以匹配API要求
                }
              })
            })
          }, (item: SongList) => item.id.toString())
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(140)
    }
    .padding({left: 20, right: 20})
    .width("100%")
    .layoutWeight(1)
  }


  // 关闭侧边栏方法
  closeSidebar() {
    animateTo({
      duration: 300,
      curve: Curve.EaseIn
    }, () => {
      this.sidebarTranslateX = -300
    })
    // 延迟隐藏遮罩
    setTimeout(() => {
      this.showSidebar = false
    }, 300)
  }
  build() {
    Stack() {
      Column() {
        this.TopNavigationBar()
        this.SearchInput()
        this.Swiper()
        this.StatsSection()
        this.DailyRecommend()
        this.VIPRecommend()
      }
      .height("100%")
      .width("100%")
      .backgroundColor(this.myColor.background)
      // 侧边栏遮罩和内容
      if (this.showSidebar) {
        Row() {
          // 侧边栏内容
          this.UserSidebar()
          // 半透明遮罩
          Column()
            .width('30%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.3)')
            .onClick(() => {
              this.closeSidebar()
            })
            .opacity(this.sidebarTranslateX === 0 ? 1 : 0)
            .animation({
              duration: 300,
              curve: Curve.EaseOut
            })
        }
        .width('100%')
        .height('100%')
      }
    }
    .height("100%")
    .width("100%")
  }
}