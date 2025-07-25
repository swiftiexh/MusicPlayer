import { SongModel, SingerModel, Consumer, UserInfo,AlbumModel } from '../model/AppModel';
import { getSingerDetail, getSongs, getAlbums, add_click_num, user_addclick } from '../common/Api';
import { AvPlayerUtils } from '../common/AvPlayerUtils';
import { dayModel, nightModel, ColorModel } from '../model/ColorModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConfigUtil as Config } from '../common/ConfigUtil';
import { ParamModel, CollectionModel } from '../model/paramModel';
import { addCollection, deleteCollection, checkCollection } from '../common/Api';
import preferencesUtil from '../common/PreferencesUtil';
import songHistoriesService from '../services/SongHistoriesService';
import { NavBar } from '../widget/NavBar';

// 定义标签项的接口
interface TabItem {
  index: number;
  title: string;
}

// 定义标签项的接口
interface LabelItem {
  text: string;
  color: string;
}


@Entry
@Component
struct SingerDetail {
  @StorageLink('isDark') isDark: boolean = false;
  @StorageLink('myColor') myColor: ColorModel = this.isDark ? nightModel : dayModel;

  @State singerDetail: SingerModel = {};
  @State songList: SongModel[] = [];
  @State filteredSongList: SongModel[] = [];

  @State favorites: number[] = []; // 改用数组存储收藏的歌曲ID
  @State isLoading: boolean = true;
  @State currentUser: Consumer | null = null;
  @State isUpdatingFavorite: boolean = false; // 防止重复点击

  @State isBottomSheetVisible: boolean = false;
  @State selectedSong: SongModel | null = null;

  // 底部弹窗控制器
  bottomSheetController: CustomDialogController | null = null;

  // 专辑列表状态
  @State albumList: AlbumModel[] = [];
  @State currentTab: number = 0; // 0: 歌曲, 1: 专辑, 2: 简介

  // 栏目切换标签构建器
  @Builder
  tabBar() {
    Row() {
      ForEach(
        [
          { index: 0, title: '歌曲' },
          { index: 1, title: '专辑' },
          { index: 2, title: '简介' },
        ],
        (item: TabItem) => {
          Column() {
            Text(item.title)
              .fontSize(16)
              .fontColor(
                this.currentTab === item.index ? this.myColor.dark : this.myColor.gray
              )
              .fontWeight(
                this.currentTab === item.index ? FontWeight.Bold : FontWeight.Normal
              );

            // 选中状态下的下划线指示器
            if (this.currentTab === item.index) {
              Divider()
                .color(this.myColor.dark)
                .strokeWidth(2)
                .margin({ top: 5 });
            }
          }
          .width('33.3%')
          .height(50)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.currentTab = item.index;
          });
        }
      );
    }
    .width('100%')
    .backgroundColor(this.myColor.background);
  }

  // 创建底部弹窗控制器
  createBottomSheetController() {
    this.bottomSheetController = new CustomDialogController({
      builder: BottomSheetDialog({
        selectedSong: this.selectedSong,
        onCancel: this.hideBottomSheet.bind(this),
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      offset: { dx: 0, dy: 0 },
      autoCancel: true,
      cancel: () => {
        this.hideBottomSheet();
      },
    });
  }

  // 显示底部弹窗
  showBottomSheet(song: SongModel) {
    this.selectedSong = song;
    this.createBottomSheetController();
    if (this.bottomSheetController) {
      this.bottomSheetController.open();
      this.isBottomSheetVisible = true;
    }
  }

  // 隐藏底部弹窗
  hideBottomSheet() {
    this.isBottomSheetVisible = false;
    if (this.bottomSheetController) {
      this.bottomSheetController.close();
      this.bottomSheetController = null;
    }
    this.selectedSong = null;
  }

  // 检查用户登录状态
  async checkUserLoginStatus() {
    try {
      const token = await preferencesUtil.get('userinfoStore', 'token', '') as string;
      const isLoggedIn = await preferencesUtil.get('userinfoStore', 'isLoggedIn', false) as boolean;
      const userInfoStr = await preferencesUtil.get('userinfoStore', 'userInfo', '') as string;

      // 检查是否真正登录
      if (isLoggedIn && token.length > 0 && userInfoStr && userInfoStr.length > 0) {
        try {
          this.currentUser = JSON.parse(userInfoStr) as Consumer;
          console.log('当前用户:', JSON.stringify(this.currentUser));
        } catch (parseError) {
          console.error('解析用户信息失败:', parseError);
          this.currentUser = null;
        }
      } else {
        this.currentUser = null;
      }
    } catch (error) {
      console.error('检查用户登录状态失败:', error);
      this.currentUser = null;
    }
  }

  // 检查歌曲收藏状态
  async checkSongCollectionStatus(songId: number) {
    if (!this.currentUser) return false;

    try {
      const params: CollectionModel = {
        user_id: this.currentUser.id,
        song_id: songId,
      };
      console.log('检查收藏状态参数:', JSON.stringify(params));
      const res = await checkCollection(params);
      console.log('收藏状态检查完整结果:', JSON.stringify(res));
      return res.data;
    } catch (error) {
      console.error('检查收藏状态失败:', error);
      return false;
    }
  }

  // 批量检查收藏状态
  async checkAllSongsCollectionStatus() {
    if (!this.currentUser || !this.filteredSongList.length) {
      console.log('检查收藏状态跳过: 用户未登录或歌曲列表为空');
      return;
    }

    console.log('开始检查收藏状态，用户ID:', this.currentUser.id, '歌曲数量:', this.filteredSongList.length);
    const newFavorites: number[] = [];

    for (const song of this.filteredSongList) {
      const isCollected = await this.checkSongCollectionStatus(song.id);
      console.log(`歌曲 ${song.name}(ID: ${song.id}) 收藏状态:`, isCollected);
      if (isCollected) {
        newFavorites.push(song.id);
      }
    }

    this.favorites = newFavorites;
    console.log('收藏状态检查完成，收藏的歌曲ID:', this.favorites);
  }

  async getSingerDetailData() {
    const params: ParamModel = router.getParams() as ParamModel;
    const res = await getSingerDetail(params);
    if (res.success) {
      this.singerDetail = JSON.parse(JSON.stringify(res.data));
      console.log('getSingerDetail' + JSON.stringify(this.singerDetail));
    } else {
      promptAction.showToast({
        message: res.message,
        duration: 5000,
      });
    }
  }

  filterSongListBySingerId() {
    if (!this.singerDetail.id || !this.songList.length) {
      this.filteredSongList = [];
      return;
    }
    this.filteredSongList = this.songList.filter((song) => song.singer_id === this.singerDetail.id);
  }

  async getSongList() {
    const res = await getSongs();
    this.songList = JSON.parse(JSON.stringify(res.data));
    this.filterSongListBySingerId(); // 筛选歌曲
    console.log('歌手歌曲过滤后数量:' + this.filteredSongList.length.toString());
    console.log('当前用户信息:' + JSON.stringify(this.currentUser));
    // 过滤歌曲后检查收藏状态
    await this.checkAllSongsCollectionStatus();
    // 收藏状态检查完成后，取消加载状态
    this.isLoading = false;
  }

  // 获取专辑数据
  async getAlbumList() {
    try {
      // 从后端获取专辑数据
      const res = await getAlbums();
      if (res.success) {
        // 过滤出当前歌手的专辑
        const allAlbums = JSON.parse(JSON.stringify(res.data)) as AlbumModel[];
        this.albumList = allAlbums.filter(album => album.singer_id === this.singerDetail.id);
      }
    } catch (error) {
      console.error('获取专辑数据失败:', error);
      // 出错时使用空数组
      this.albumList = [];
    }
  }


  async aboutToAppear() {
    this.isLoading = true;
    await this.checkUserLoginStatus();
    await this.getSingerDetailData();
    await this.getSongList();
    this.getAlbumList();
  }

  async handleFavorite(song: SongModel) {
    // 检查用户是否已登录
    if (!this.currentUser) {
      promptAction.showToast({
        message: '请先登录后再收藏歌曲',
        duration: 2000,
      });
      return;
    }

    // 防止重复点击
    if (this.isUpdatingFavorite) {
      console.log('收藏操作进行中，请稍等...');
      return;
    }

    this.isUpdatingFavorite = true;

    const params: CollectionModel = {
      user_id: this.currentUser.id,
      song_id: song.id,
    };

    try {
      if (this.favorites.includes(song.id)) {
        // 取消收藏
        const res = await deleteCollection(params);
        console.log('取消收藏结果:', JSON.stringify(res));
        if (JSON.parse(JSON.stringify(res))['code'] === 200) {
          promptAction.showToast({
            message: '取消收藏成功',
            duration: 1500,
          });

          // 立即更新本地状态 - 从收藏列表中移除
          this.favorites = this.favorites.filter((id) => id !== song.id);
        } else {
          promptAction.showToast({
            message: res.message || '取消收藏失败',
            duration: 2000,
          });
        }
      } else {
        // 添加收藏
        const res = await addCollection(params);
        console.log('添加收藏结果:', JSON.stringify(res));
        if (JSON.parse(JSON.stringify(res))['code'] === 200) {
          promptAction.showToast({
            message: '收藏成功',
            duration: 1500,
          });

          // 立即更新本地状态 - 添加到收藏列表
          this.favorites = [...this.favorites, song.id];
        } else {
          promptAction.showToast({
            message: res.message || '收藏失败',
            duration: 2000,
          });
        }
      }
    } catch (error) {
      console.error('收藏操作失败:', error);
      promptAction.showToast({
        message: '操作失败，请稍后重试',
        duration: 2000,
      });
    } finally {
      // 操作完成后重置状态
      this.isUpdatingFavorite = false;
    }
  }

  // 检查单个歌曲是否被收藏
  isSongFavorited(songId: number): boolean {
    return this.favorites.includes(songId);
  }

  @State isFollowing: boolean = false;

  @Builder
  showIntroduction() {
    Column() {
      // 简介容器
      Column() {
        Text(`${this.singerDetail.introduction || "暂无简介"}`)
          .fontSize(14)
          .opacity(0.8)
          .textAlign(TextAlign.Start)
          .fontColor(this.myColor.dark)
          .padding(20)
      }
      .width('90%')
      .backgroundColor(this.myColor.bright)
      .borderRadius(10)
      .border({
        width: 1,
        color: '#03726c6c',
        style: BorderStyle.Solid
      })
      .shadow({
        radius: 5,
        color: '#888888',
        offsetX: 2,
        offsetY: 2
      })
      .padding({
        top: 20,
        bottom: 20
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  showSongList() {
    List() {
      ForEach(this.filteredSongList, (song: SongModel) => {
        ListItem() {
          Row() {
            Image(`${Config.SERVERURL}${song.pic}`)
              .width(50)
              .height(50)
              .objectFit(ImageFit.Contain)
              .borderRadius(40)
              .margin({ left: 20, right: 15 });

            Column({ space: 5 }) {
              Text(song.name)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.myColor.dark);
              Text(`${this.singerDetail.name}`)
                .fontSize(14)
                .opacity(0.7)
                .fontColor(this.myColor.gray);
            }
            .width('56%')
            .alignItems(HorizontalAlign.Start);

            Row({ space: 8 }) {
              // 收藏按钮
              Image($r('app.media.ic_star1'))
                .fillColor(
                  this.isSongFavorited(song.id) ? '#ff6b35' : this.myColor.dark
                )
                .onClick(async () => {
                  await this.handleFavorite(song);
                })
                .width(20)
                .height(20)
                .enabled(!this.isLoading && !this.isUpdatingFavorite)
                .opacity(
                  (!this.isLoading && !this.isUpdatingFavorite) ? 1.0 : 0.5
                )
                .animation({
                  duration: 200,
                  curve: Curve.EaseInOut,
                });

              // 添加到播放列表按钮
              Image($r('app.media.ic_addplay'))
                .width(20)
                .height(20)
                .fillColor(this.myColor.dark)
                .onClick((event: ClickEvent) => {
                  // 阻止事件冒泡
                  const isExist = AvPlayerUtils.playList.some(
                    (item: SongModel) => item.id === song.id
                  );
                  if (!isExist) {
                    AvPlayerUtils.playList.push(song);
                    AvPlayerUtils.updateStateAfterChange();
                    promptAction.showToast({ message: '已添加到播放列表' });
                  } else {
                    promptAction.showToast({ message: '歌曲已在播放列表中' });
                  }
                });

              // 详情按钮
              Image($r('app.media.ic_detail'))
                .width(20)
                .height(20)
                .fillColor(this.myColor.dark)
                .onClick(() => {
                  this.showBottomSheet(song);
                });
            }
            .margin({ left: 15 });
          }
          .width('85%')
          .height(100)
          .alignItems(VerticalAlign.Center)
          .onClick(async () => {
            // 更新点击量
            add_click_num(song.id);
            if (this.currentUser) {
              user_addclick(this.currentUser.id, song.id);
            }

            // 添加到播放历史
            const userInfoRaw: string = await preferencesUtil.get(
              'userinfoStore',
              'userInfo',
              ''
            ) as string;
            const userInfoStr: string =
              typeof userInfoRaw === 'string' ? userInfoRaw : String(userInfoRaw);
            if (userInfoStr && userInfoStr.length > 0) {
              const userInfo: UserInfo = JSON.parse(userInfoStr) as UserInfo;
              await songHistoriesService.addSongHistory(userInfo.id, song);
            }

            // 处理播放逻辑
            const isExist = AvPlayerUtils.playList.some(
              (item) => item.id === song.id
            );
            if (!isExist) {
              AvPlayerUtils.playList.unshift(song);
            } else {
              const index = AvPlayerUtils.playList.findIndex(
                (item) => item.id === song.id
              );
              if (index > 0) {
                AvPlayerUtils.playList.splice(index, 1);
                AvPlayerUtils.playList.unshift(song);
              }
            }
            AvPlayerUtils.playIndex = 0;
            AvPlayerUtils.playSingle(song);
            // 跳转到播放器页面
            router.pushUrl({
              url: 'pages/Player',
              params: { song: JSON.stringify(song) },
            });
          });
        }
      });
    }
    .width('100%');
  }

  // 专辑列表构建器
  @Builder
  showAlbumList() {
    List() {
      ForEach(this.albumList, (album: AlbumModel) => {
        ListItem() {
          Row() {
            Image(`${Config.SERVERURL}${album.pic}`)
              .width(60)
              .height(60)
              .objectFit(ImageFit.Contain)
              .borderRadius(10)
              .margin({ left: 20, right: 15 })

            Column({ space: 5 }) {
              Text(album.name)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.myColor.dark)
                .textAlign(TextAlign.Start)
              Text(`发行时间: ${album.year}`)
                .fontSize(14)
                .opacity(0.7)
                .fontColor(this.myColor.gray)
                .textAlign(TextAlign.Start)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .height(80)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // 点击专辑项跳转到专辑详情页
            router.pushUrl({
              url: 'pages/detail/AlbumDetail',
              params: { cid: album.id }
            });
          })
        }
      })
    }
    .width('100%')
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 使用 Stack 实现背景图和悬浮框的层叠效果
          Stack() {
            // 背景图片作为底层
            Image(Config.SERVERURL + this.singerDetail.pic)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .blur(10) // 添加模糊效果增强悬浮感

            // 半透明悬浮框作为上层
            Column() {
              // 顶部导航栏区域
              Row() {
                // 返回按钮
                Button({ type: ButtonType.Circle, stateEffect: true }) {
                  Image($r('app.media.ic_back'))
                    .width(15)
                    .height(15)
                    .fillColor('#fff') // 白色图标以便在深色背景上可见
                }
                .width(40)
                .height(40)
                .backgroundColor('rgba(0, 0, 0, 0)')
                .margin({ left: 10 })
                .onClick(() => {
                  router.back();
                })
              }
              .width('100%')
              .height(56)
              .alignItems(VerticalAlign.Center)

              // 歌手信息区域
              Row() {
                Blank()
                Column() {
                  // 歌手头像
                  Image(Config.SERVERURL + this.singerDetail.pic)
                    .width(80)
                    .height(80)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(40)
                    .margin({ top: 10 })

                  // 歌手姓名
                  Text(`${this.singerDetail.name}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.myColor.bright)
                    .margin({ top: 10 })
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // 关注按钮
                  Button(this.isFollowing ? '已关注' : '关注')
                    .onClick(() => {
                      this.isFollowing = !this.isFollowing;
                    })
                    .margin({ top: 10, bottom: 10 })
                    .width(100)
                    .height(36)
                    .backgroundColor(this.isFollowing ? this.myColor.gray : this.myColor.bright)
                    .fontColor(this.isFollowing ? this.myColor.bright : this.myColor.dark)
                    .fontSize(14)
                    .borderRadius(18)


                  // 标签区域
                  Row({ space: 15 }) {
                    ForEach([
                      { text: "TA的乐谜团", color: "#FF6A6A" },
                      { text: "VR专辑", color: "#4A90E2" },
                      { text: "周边商品", color: "#50C878" }
                    ], (item: LabelItem) => {
                      Row() {
                        Text(item.text)
                          .fontSize(12)
                          .fontColor(this.myColor.bright)
                          .padding({ left: 8, right: 8 })
                      }
                      .height(24)
                      .borderRadius(12)
                      .backgroundColor('#00ffff33') // 20% 透明度的背景
                      .onClick(() => {
                        console.log(`点击了标签: ${item.text}`);
                      })
                    })
                  }
                  .margin({ top: 5 })
                }
                .width('80%')
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Center)

                Blank()
              }
              .layoutWeight(1)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#66000000') // 40% 透明度的黑色
          }
          .width('100%')
          .height('46.15%')
          .clip(true)
          .borderRadius(10)
          .margin({ bottom: 10 })

          // 栏目切换标签
          this.tabBar()

          // 根据当前选中标签显示对应内容
          if (this.currentTab === 0) {
            // 显示歌曲列表
            this.showSongList()
          } else if (this.currentTab === 1) {
            // 显示专辑列表
            this.showAlbumList()
          } else if (this.currentTab === 2) {
            // 显示简介
            this.showIntroduction()
          }
        }
        .width('100%')
      }
      .width("100%")
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.myColor.background)
  }
}

// 底部弹窗对话框组件
@CustomDialog
struct BottomSheetDialog {
  selectedSong?: SongModel | null;
  onCancel?: () => void;
  controller?: CustomDialogController;

  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor: ColorModel = (this.isDark == true ? nightModel : dayModel)

  build() {
    Column() {
      // 拖拽指示器
      Divider()
        .width(40)
        .height(4)
        .backgroundColor(this.myColor.gray)
        .borderRadius(2)
        .margin({ top: 8, bottom: 16 })

      // 菜单项列表
      Column() {
        // 评论选项
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
          // 延迟跳转，确保弹窗先关闭
          setTimeout(() => {
            router.pushUrl({
              url: 'pages/Comment',
              params: {
                cid: this.selectedSong?.id
              }
            });
          }, 100);
        })
        .backgroundColor(Color.Transparent)
        .stateStyles({
          pressed: {
            .backgroundColor(this.myColor.gray)
          }
        })

        // 分割线
        Divider()
          .color(this.myColor.gray)
          .strokeWidth(1)
          .margin({ left: 20, right: 20 })

        // 播放视频选项
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
          // 延迟跳转，确保弹窗先关闭
          setTimeout(() => {
            router.pushUrl({
              url: 'pages/MusicVideo',
              params: {
                cid : this.selectedSong?.id
              }
            });
          }, 100);
        })
        .backgroundColor(Color.Transparent)
        .stateStyles({
          pressed: {
            .backgroundColor(this.myColor.gray)
          }
        })
      }
      .backgroundColor(this.myColor.background)
      .borderRadius({ topLeft: 16, topRight: 16 })

      // 底部安全区域
      Row()
        .height(20)
    }
    .width('100%')
    .backgroundColor(this.myColor.background)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ bottom: 20 })
  }
}
