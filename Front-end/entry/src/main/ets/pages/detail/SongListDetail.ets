import { SongModel, SongList, SongToListModel, Consumer, UserInfo } from '../model/AppModel';
import { getSongs, getSongListDetail, getSongToLists, add_click_num, user_addclick } from '../common/Api';
import { AvPlayerUtils } from '../common/AvPlayerUtils';
import { dayModel, nightModel, ColorModel } from '../model/ColorModel';
import router from '@ohos.router';
import { ConfigUtil as Config } from '../common/ConfigUtil';
import { ParamModel, CollectionModel } from '../model/paramModel';
import promptAction from '@ohos.promptAction';
import { addCollection, deleteCollection, checkCollection } from '../common/Api';
import preferencesUtil from '../common/PreferencesUtil';
import songHistoriesService from '../services/SongHistoriesService';

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
        .margin({ top: 8, bottom: 16 });

      Column() {
        // 评论选项
        Row() {
          Image($r("app.media.ic_comment"))
            .width(20)
            .height(20)
            .fillColor(this.myColor.dark)
            .margin({ right: 25 });

          Text('评论')
            .fontSize(16)
            .fontColor(this.myColor.dark)
            .layoutWeight(1);
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
        .stateStyles({
          pressed: { .backgroundColor(this.myColor.gray) }
        });

        Divider()
          .color(this.myColor.gray)
          .strokeWidth(1)
          .margin({ left: 20, right: 20 });

        // 播放视频选项
        Row() {
          Image($r("app.media.ic_video"))
            .width(20)
            .height(20)
            .fillColor(this.myColor.dark)
            .margin({ right: 25 });

          Text('播放视频')
            .fontSize(16)
            .fontColor(this.myColor.dark)
            .layoutWeight(1);
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
        .stateStyles({
          pressed: { .backgroundColor(this.myColor.gray) }
        });
      }
      .backgroundColor(this.myColor.background)
      .borderRadius({ topLeft: 16, topRight: 16 });

      Row().height(20);
    }
    .width('100%')
    .backgroundColor(this.myColor.background)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ bottom: 20 });
  }
}

@Entry
@Component
struct SongListDetail {
  @StorageLink("isDark") isDark: boolean = false;
  @StorageLink("myColor") myColor: ColorModel = this.isDark ? nightModel : dayModel;

  @State songListDetail: SongList = { id: 0 };
  @State songs: SongModel[] = [];
  @State songtolist: SongToListModel[] = [];
  @State filteredSongList: SongModel[] = [];

  // 保留第二段的收藏相关状态
  @State favorites: number[] = [];
  @State isLoading: boolean = true;
  @State currentUser: Consumer | null = null;
  @State isUpdatingFavorite: boolean = false;

  // 底部弹窗相关状态（保留第二段功能）
  @State isBottomSheetVisible: boolean = false;
  @State selectedSong: SongModel | null = null;
  bottomSheetController: CustomDialogController | null = null;

  // 底部弹窗控制方法（保留第二段实现）
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

  // 用户登录检查（保留第二段实现）
  async checkUserLoginStatus() {
    try {
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string;
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean;
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string;

      if (isLoggedIn && token.length > 0 && userInfoStr) {
        this.currentUser = JSON.parse(userInfoStr) as Consumer;
      } else {
        this.currentUser = null;
      }
    } catch (error) {
      console.error('检查用户登录状态失败:', error);
      this.currentUser = null;
    }
  }

  // 收藏状态检查（保留第二段实现）
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

  // 数据获取方法（保留第二段核心逻辑）
  async getSongListDetailData() {
    try {
      const params: ParamModel = router.getParams() as ParamModel;
      const res = await getSongListDetail(params);
      if (res.success) {
        this.songListDetail = JSON.parse(JSON.stringify(res.data));
      } else {
        promptAction.showToast({ message: res.message, duration: 5000 });
      }
    } catch (error) {
      console.error('获取歌单详情失败:', error);
      promptAction.showToast({ message: '获取歌单详情失败', duration: 3000 });
    }
  }

  async getSongList() {
    try {
      const res = await getSongs();
      if (res.success) {
        this.songs = JSON.parse(JSON.stringify(res.data));
        this.filterSongListBySongListId();
      }
    } catch (error) {
      console.error('获取歌曲列表失败:', error);
    }
  }

  filterSongListBySongListId() {
    if (!this.songListDetail.id || !this.songs.length || !this.songtolist.length) {
      this.filteredSongList = [];
      return;
    }
    const currentSongIds = this.songtolist
      .filter(item => item.list_id === this.songListDetail.id)
      .map(item => item.song_id);
    this.filteredSongList = this.songs.filter(song => currentSongIds.includes(song.id));
  }

  async getSongToList() {
    try {
      const res = await getSongToLists();
      if (res.success) {
        this.songtolist = JSON.parse(JSON.stringify(res.data));
        this.filterSongListBySongListId();
        await this.checkAllSongsCollectionStatus();
      }
    } catch (error) {
      console.error('获取歌曲关联失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async aboutToAppear() {
    this.isLoading = true;
    await this.checkUserLoginStatus();
    await Promise.all([
      this.getSongListDetailData(),
      this.getSongList()
    ]);
    await this.getSongToList();
  }

  // 收藏处理方法（保留第二段实现）
  async handleFavorite(song: SongModel) {
    if (!this.currentUser) {
      promptAction.showToast({ message: '请先登录后再收藏歌曲', duration: 2000 });
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

  // 歌曲列表构建器（保留第二段功能，适配第一段布局）
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
              .margin({ left: 20, right: 15 });

            Column({ space: 5 }) {
              Text(song.name)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.myColor.dark);
              Text(`歌手: ${song.singer}`)
                .fontSize(14)
                .opacity(0.7)
                .fontColor(this.myColor.gray);
            }
            .width('56%')
            .alignItems(HorizontalAlign.Start);

            Row({ space: 8 }) {
              Image($r("app.media.ic_star1"))
                .fillColor(this.isSongFavorited(song.id) ? '#ff6b35' : this.myColor.dark)
                .onClick(() => this.handleFavorite(song))
                .width(20)
                .height(20)
                .enabled(!this.isLoading && !this.isUpdatingFavorite)
                .opacity((!this.isLoading && !this.isUpdatingFavorite) ? 1.0 : 0.5)
                .animation({ duration: 200, curve: Curve.EaseInOut });

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
                });

              Image($r("app.media.ic_detail"))
                .width(20)
                .height(20)
                .fillColor(this.myColor.dark)
                .onClick(() => this.showBottomSheet(song));
            }
            .margin({ left: 15 });
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
          });
        };
      });
    }
    .width('100%');
  }

  // 采用第一段的布局风格
  build() {
    Column() {
      Scroll() {
        Column() {
          // 第一段特有的Stack背景布局
          Stack() {
            // 背景图带模糊效果
            Image(Config.SERVERURL + this.songListDetail.pic)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .blur(10);

            // 半透明悬浮层
            Column() {
              // 顶部导航栏（第一段风格）
              Row() {
                Button({ type: ButtonType.Circle, stateEffect: true }) {
                  Image($r('app.media.ic_back'))
                    .width(25)
                    .height(25)
                    .fillColor('#fff');
                }
                .width(40)
                .height(40)
                .backgroundColor('rgba(0, 0, 0, 0)')
                .margin({ left: 10 })
                .onClick(() => router.back());

                Blank().width(40).height(40);
              }
              .width('100%')
              .height(30)
              .alignItems(VerticalAlign.Center);

              // 歌单信息区域（左侧封面+右侧详情）
              Row() {
                Blank();

                // 左侧封面
                Image(Config.SERVERURL + this.songListDetail.pic)
                  .width(120)
                  .height(120)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(10)
                  .margin({ top: 10, right: 15 });

                // 右侧信息（整合第二段的创建者和风格信息）
                Column() {
                  Text(`歌单：${this.songListDetail.name}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 10 })
                    .textAlign(TextAlign.Start)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%');

                  Text(`创建者：${this.songListDetail.username || '未知'}`)
                    .fontSize(12)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 5 })
                    .textAlign(TextAlign.Start)
                    .width('100%');

                  Text(`风格：${this.songListDetail.style || '未知'}`)
                    .fontSize(12)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 5 })
                    .textAlign(TextAlign.Start)
                    .width('100%');

                  Text(`歌曲数量: ${this.filteredSongList.length} 首`)
                    .fontSize(12)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 5 })
                    .textAlign(TextAlign.Start)
                    .width('100%');

                  Blank().height(10);

                  Text(`${this.songListDetail.introduction || '暂无简介'}`)
                    .fontSize(10)
                    .opacity(0.8)
                    .textAlign(TextAlign.Start)
                    .fontColor(this.myColor.bright)
                    .width('100%');
                }
                .width('60%')
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center);

                Blank();
              }
              .layoutWeight(1)
              .width('100%');
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#66000000');
          }
          .width('100%')
          .height('46.15%')
          .clip(true)
          .borderRadius(10)
          .margin({ bottom: 10 });

          // 歌曲列表（使用第二段的实现）
          this.showSongList();
        }
        .width('100%');
      }
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.myColor.background);
  }
}