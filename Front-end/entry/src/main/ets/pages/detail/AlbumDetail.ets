import { SongModel, AlbumModel, Consumer, UserInfo } from '../model/AppModel';
import { getAlbumDetail, getSongs, add_click_num, user_addclick, getSingerDetail } from '../common/Api';
import { AvPlayerUtils } from '../common/AvPlayerUtils';
import { dayModel, nightModel, ColorModel } from '../model/ColorModel';
import router from '@ohos.router';
import { ConfigUtil as Config } from '../common/ConfigUtil';
import { ParamModel, CollectionModel } from '../model/paramModel';
import promptAction from '@ohos.promptAction';
import { addCollection, deleteCollection, checkCollection } from '../common/Api';
import preferencesUtil from '../common/PreferencesUtil';
import songHistoriesService from '../services/SongHistoriesService';
import { NavBar } from '../widget/NavBar';

interface TagItem {
  index: number;
  text: string;
  color: string;
}

// 定义歌手信息接口
interface SingerInfo {
  name?: string;
}

@Entry
@Component
struct AlbumDetail {
  @StorageLink("isDark") isDark: boolean = false;
  @StorageLink("myColor") myColor: ColorModel = this.isDark ? nightModel : dayModel;

  @State albumDetail: AlbumModel = {};
  @State songList: SongModel[] = [];
  @State filteredSongList: SongModel[] = [];
  @State singerName: string = "未知歌手";

  // 保留第二段的收藏功能状态
  @State favorites: number[] = [];
  @State isLoading: boolean = true;
  @State currentUser: Consumer | null = null;
  @State isUpdatingFavorite: boolean = false;

  @State isBottomSheetVisible: boolean = false;
  @State selectedSong: SongModel | null = null;
  bottomSheetController: CustomDialogController | null = null;

  // 第一段特有的标签切换状态
  @State currentTab: number = 0; // 0: 歌曲, 1: 简介

  // 底部弹窗控制（保留第二段功能）
  createBottomSheetController() {
    this.bottomSheetController = new CustomDialogController({
      builder: BottomSheetDialog({
        selectedSong: this.selectedSong,
        onCancel: this.hideBottomSheet.bind(this)
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      offset: { dx: 0, dy: 0 },
      autoCancel: true,
      cancel: () => this.hideBottomSheet()
    });
  }

  showBottomSheet(song: SongModel) {
    this.selectedSong = song;
    this.createBottomSheetController();
    if (this.bottomSheetController) {
      this.bottomSheetController.open();
      this.isBottomSheetVisible = true;
    }
  }

  hideBottomSheet() {
    this.isBottomSheetVisible = false;
    if (this.bottomSheetController) {
      this.bottomSheetController.close();
      this.bottomSheetController = null;
    }
    this.selectedSong = null;
  }

  // 用户登录与收藏状态检查（保留第二段功能）
  async checkUserLoginStatus() {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string;
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean;
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string;

      if (isLoggedIn && token && userInfoStr) {
        this.currentUser = JSON.parse(userInfoStr) as Consumer;
      } else {
        this.currentUser = null;
      }
    } catch (error) {
      console.error('检查登录状态失败:', error);
      this.currentUser = null;
    }
  }

  async checkSongCollectionStatus(songId: number) {
    if (!this.currentUser) return false;
    try {
      const params: CollectionModel = { user_id: this.currentUser.id, song_id: songId };
      const res = await checkCollection(params);
      return res.data;
    } catch (error) {
      console.error('检查收藏状态失败:', error);
      return false;
    }
  }

  async checkAllSongsCollectionStatus() {
    if (!this.currentUser || !this.filteredSongList.length) return;
    const newFavorites: number[] = [];
    for (const song of this.filteredSongList) {
      if (await this.checkSongCollectionStatus(song.id)) {
        newFavorites.push(song.id);
      }
    }
    this.favorites = newFavorites;
  }

  // 获取歌手详情信息
  async getSingerInfo() {
    if (!this.albumDetail.singer_id) return;

    try {
      const params: ParamModel = { cid: this.albumDetail.singer_id };
      const res = await getSingerDetail(params);
      if (res.success) {
        const singerData: SingerInfo = JSON.parse(JSON.stringify(res.data));
        this.singerName = singerData.name || "未知歌手";
      }
    } catch (error) {
      console.error('获取歌手信息失败:', error);
      this.singerName = "未知歌手";
    }
  }



  // 专辑数据获取（保留核心逻辑）
  async getAlbumDetailData() {
    const params: ParamModel = router.getParams() as ParamModel;
    const res = await getAlbumDetail(params);
    if (res.success) {
      this.albumDetail = JSON.parse(JSON.stringify(res.data));
      // 获取歌手信息
      await this.getSingerInfo();
    } else {
      promptAction.showToast({ message: res.message, duration: 5000 });
    }
  }


  filterSongListByAlbumId() {
    if (!this.albumDetail.id || !this.songList.length) {
      this.filteredSongList = [];
      return;
    }
    this.filteredSongList = this.songList.filter(song => song.album_id === this.albumDetail.id);
  }

  async getSongList() {
    const res = await getSongs();
    this.songList = JSON.parse(JSON.stringify(res.data));
    this.filterSongListByAlbumId();
    await this.checkAllSongsCollectionStatus();
    this.isLoading = false;
  }

  async aboutToAppear() {
    this.isLoading = true;
    await this.checkUserLoginStatus();
    await this.getAlbumDetailData();
    await this.getSongList();
    await this.getSingerInfo() ;
  }

  // 收藏功能处理（保留第二段逻辑）
  async handleFavorite(song: SongModel) {
    if (!this.currentUser) {
      promptAction.showToast({ message: '请先登录后再收藏', duration: 2000 });
      return;
    }
    if (this.isUpdatingFavorite) return;
    this.isUpdatingFavorite = true;

    const params: CollectionModel = { user_id: this.currentUser.id, song_id: song.id };
    try {
      if (this.favorites.includes(song.id)) {
        const res = await deleteCollection(params);
        if (JSON.parse(JSON.stringify(res))["code"] === 200) {
          promptAction.showToast({ message: '取消收藏成功', duration: 1500 });
          this.favorites = this.favorites.filter(id => id !== song.id);
        } else {
          promptAction.showToast({ message: res.message || '取消收藏失败', duration: 2000 });
        }
      } else {
        const res = await addCollection(params);
        if (JSON.parse(JSON.stringify(res))["code"] === 200) {
          promptAction.showToast({ message: '收藏成功', duration: 1500 });
          this.favorites = [...this.favorites, song.id];
        } else {
          promptAction.showToast({ message: res.message || '收藏失败', duration: 2000 });
        }
      }
    } catch (error) {
      promptAction.showToast({ message: '操作失败，请重试', duration: 2000 });
    } finally {
      this.isUpdatingFavorite = false;
    }
  }

  isSongFavorited(songId: number): boolean {
    return this.favorites.includes(songId);
  }

  // 歌曲列表构建器（采用第一段布局风格）
  @Builder
  showSongList() {
    List() {
      ForEach(this.filteredSongList, (song: SongModel) => {
        ListItem() {
          Row() {
            Image(`${Config.SERVERURL}${song.pic}`)
              .width(50)
              .height(50)
              .borderRadius(40)
              .margin({ left: 20, right: 15 })

            Column({ space: 5 }) {
              Text(song.name)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.myColor.dark)
              Text(`歌手: ${song.singer || "未知歌手"}`)
                .fontSize(14)
                .opacity(0.7)
                .fontColor(this.myColor.gray)
                .onClick((event: ClickEvent) => {
                  if (song.singer_id) {
                    router.pushUrl({
                      url: 'pages/detail/SingerDetail',
                      params: { cid: song.singer_id }
                    });
                  } else {
                    promptAction.showToast({ message: '无法跳转到歌手详情', duration: 2000 });
                  }
                })
                .backgroundColor(Color.Transparent)


            }

            .width('56%')
            .alignItems(HorizontalAlign.Start)

            Row({ space: 8 }) {
              Image($r("app.media.ic_star1"))
                .fillColor(this.isSongFavorited(song.id) ? '#ff6b35' : this.myColor.dark)
                .onClick(() => this.handleFavorite(song))
                .width(20)
                .height(20)
                .enabled(!this.isLoading && !this.isUpdatingFavorite)
                .opacity((!this.isLoading && !this.isUpdatingFavorite) ? 1.0 : 0.5)
                .animation({ duration: 200, curve: Curve.EaseInOut })

              Image($r("app.media.ic_addplay"))
                .width(20)
                .height(20)
                .fillColor(this.myColor.dark)
                .onClick(() => {
                  const isExist = AvPlayerUtils.playList.some(item => item.id === song.id);
                  if (!isExist) {
                    AvPlayerUtils.playList.push(song);
                    AvPlayerUtils.updateStateAfterChange();
                    promptAction.showToast({ message: '已添加到播放列表' });
                  } else {
                    promptAction.showToast({ message: '歌曲已在播放列表中' });
                  }
                })

              Image($r("app.media.ic_detail"))
                .width(20)
                .height(20)
                .fillColor(this.myColor.dark)
                .onClick(() => this.showBottomSheet(song))
            }
            .margin({ left: 15 })
          }
          .width('85%')
          .height(100)
          .alignItems(VerticalAlign.Center)
          .onClick(async () => {
            add_click_num(song.id);
            if (this.currentUser) user_addclick(this.currentUser.id, song.id);

            const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string;
            if (userInfoStr) {
              const userInfo: UserInfo = JSON.parse(userInfoStr);
              await songHistoriesService.addSongHistory(userInfo.id, song);
            }

            const isExist = AvPlayerUtils.playList.some(item => item.id === song.id);
            if (!isExist) {
              AvPlayerUtils.playList.unshift(song);
            } else {
              const index = AvPlayerUtils.playList.findIndex(item => item.id === song.id);
              if (index > 0) {
                AvPlayerUtils.playList.splice(index, 1);
                AvPlayerUtils.playList.unshift(song);
              }
            }
            AvPlayerUtils.playIndex = 0;
            AvPlayerUtils.playSingle(song);
            router.pushUrl({ url: 'pages/Player', params: { song: JSON.stringify(song) } });
          })
        }
      });
    }
    .width('100%');
  }

  // 第一段特有的简介构建器
  @Builder
  showIntroduction() {
    Column() {
      Column() {
        Text(this.albumDetail.introduction || "暂无简介")
          .fontSize(14)
          .opacity(0.8)
          .textAlign(TextAlign.Start)
          .fontColor(this.myColor.dark)
          .padding(20)
      }
      .width('90%')
      .backgroundColor(this.myColor.bright)
      .borderRadius(10)
      .border({ width: 1, color: '#03726c6c', style: BorderStyle.Solid })
      .shadow({ radius: 5, color: '#888888', offsetX: 2, offsetY: 2 })
      .padding({ top: 20, bottom: 20 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }

  // 第一段特有的标签栏构建器
  @Builder
  tabBar() {
    Row() {
      ForEach([
        { index: 0, text: "歌曲", color: "#FF6A6A" },
        { index: 1, text: "简介", color: "#4A90E2" }
      ], (item: TagItem) => {
        Column() {
          Text(item.text)
            .fontSize(16)
            .fontColor(this.currentTab === item.index ? this.myColor.dark : this.myColor.gray)
            .fontWeight(this.currentTab === item.index ? FontWeight.Bold : FontWeight.Normal)

          if (this.currentTab === item.index) {
            Divider()
              .color(this.myColor.dark)
              .strokeWidth(2)
              .margin({ top: 5 })
          }
        }
        .width('50%')
        .height(50)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.currentTab = item.index);
      });
    }
    .width('100%')
    .backgroundColor(this.myColor.background);
  }

  // 采用第一段的布局风格
  build() {
    Column() {
      Scroll() {
        Column() {
          // 第一段特有的Stack背景布局
          Stack() {
            // 背景图带模糊效果
            Image(Config.SERVERURL + this.albumDetail.pic)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .blur(10)

            // 半透明悬浮层
            Column() {
              // 顶部导航栏
              Row() {
                Button({ type: ButtonType.Circle, stateEffect: true }) {
                  Image($r('app.media.ic_back'))
                    .width(25)
                    .height(25)
                    .fillColor('#fff')
                }
                .width(40)
                .height(40)
                .backgroundColor('rgba(0, 0, 0, 0)')
                .margin({ left: 10 })
                .onClick(() => router.back())

                Blank().width(40).height(40)
              }
              .width('100%')
              .height(30)
              .alignItems(VerticalAlign.Center)

              // 专辑信息区域（左右布局）
              Row() {
                Blank()

                // 左侧专辑封面
                Image(Config.SERVERURL + this.albumDetail.pic)
                  .width(120)
                  .height(120)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(10)
                  .margin({ top: 10, right: 15 })

                // 右侧专辑信息
                Column() {
                  Text(this.albumDetail.name || "未知专辑")
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 10 })
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Text(`歌手: ${this.singerName}`)
                    .fontSize(12)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 5 })
                    .width('100%')

                  Text(`发行年份: ${this.albumDetail.year || "未知年份"}`)
                    .fontSize(12)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 5 })
                    .width('100%')

                  Text(this.albumDetail.introduction || "暂无简介")
                    .fontSize(10)
                    .opacity(0.8)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 10 })
                    .width('100%')
                    .textAlign(TextAlign.Start)
                }
                .width('60%')
                .alignItems(HorizontalAlign.Start)

                Blank()
              }
              .layoutWeight(1)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#66000000')
          }
          .width('100%')
          .height('46.15%')
          .clip(true)
          .borderRadius(10)
          .margin({ bottom: 10 })

          // 标签栏（第一段特有）
          this.tabBar()

          // 根据标签切换内容
          if (this.currentTab === 0) {
            this.showSongList();
          } else {
            this.showIntroduction();
          }
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.myColor.background);
  }
}

// 保留第二段的底部弹窗组件
@CustomDialog
struct BottomSheetDialog {
  selectedSong?: SongModel | null;
  onCancel?: () => void;
  controller?: CustomDialogController;

  @StorageLink("isDark") isDark: boolean = false;
  @StorageLink("myColor") myColor: ColorModel = this.isDark ? nightModel : dayModel;

  build() {
    Column() {
      Divider()
        .width(40)
        .height(4)
        .backgroundColor(this.myColor.gray)
        .borderRadius(2)
        .margin({ top: 8, bottom: 16 })

      Column() {
        Row() {
          Image($r("app.media.ic_comment"))
            .width(20)
            .height(20)
            .fillColor(this.myColor.dark)
            .margin({ right: 25 })

          Text('评论')
            .fontSize(16)
            .fontColor(this.myColor.dark)
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onCancel?.();
          setTimeout(() => {
            router.pushUrl({
              url: 'pages/Comment',
              params: { cid: this.selectedSong?.id }
            });
          }, 100);
        })
        .backgroundColor(Color.Transparent)
        .stateStyles({ pressed: { .backgroundColor(this.myColor.gray) } })

        Divider()
          .color(this.myColor.gray)
          .strokeWidth(1)
          .margin({ left: 20, right: 20 })

        Row() {
          Image($r("app.media.ic_video"))
            .width(20)
            .height(20)
            .fillColor(this.myColor.dark)
            .margin({ right: 25 })

          Text('播放视频')
            .fontSize(16)
            .fontColor(this.myColor.dark)
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onCancel?.();
          setTimeout(() => {
            router.pushUrl({
              url: 'pages/MusicVideo',
              params: { cid: this.selectedSong?.id }
            });
          }, 100);
        })
        .backgroundColor(Color.Transparent)
        .stateStyles({ pressed: { .backgroundColor(this.myColor.gray) } })
      }
      .backgroundColor(this.myColor.background)
      .borderRadius({ topLeft: 16, topRight: 16 })

      Row().height(20)
    }
    .width('100%')
    .backgroundColor(this.myColor.background)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ bottom: 20 })
  }
}