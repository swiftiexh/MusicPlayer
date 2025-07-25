import { ColorModel, dayModel, nightModel } from '../model/ColorModel'
import { SongModel } from "../model/AppModel"
import router from '@ohos.router'
import SearchService from  '../services/SearchService'
import { getSongsRanking } from '../common/Api'
import promptAction from '@ohos.promptAction'
import {AvPlayerUtils} from '../common/AvPlayerUtils'

import { speechRecognizer } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ICapturerInterface } from '../recognition/ICapturerInterface';
import FileCapturer from '../recognition/FileCapturer';
import AudioCapturer from '../recognition/AudioCapturer'
let asrEngine: speechRecognizer.SpeechRecognitionEngine;


@Entry
@Component
struct SearchPage {
  @State hotRankings: SongModel[] = []

  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("myColor") myColor:ColorModel = (this.isDark==true?nightModel:dayModel)

  @State historySearch: string[] = []
  @State keywords: string = ""

  // 与语音识别相关
  @State sessionId: string = "123456";
  @State isFlag: boolean = false
  private mFileCapturer: ICapturerInterface = new FileCapturer();
  private mAudioCapturer: ICapturerInterface = new AudioCapturer();
  // Setting callbacks
  setListener() {
    // Creating a Callback Object
    let setListener: speechRecognizer.RecognitionListener = {
      // Callback for successful recognition start
      onStart: (sessionId: string, eventMessage: string) => {
        this.keywords = '';
        console.info("setListener onStart sessionId: " + sessionId + "eventMessage: " + eventMessage);
      },
      // Event callback
      onEvent(sessionId: string, eventCode: number, eventMessage: string) {
        console.info("setListener onEvent sessionId: " + sessionId + "eventMessage: " + eventCode + "eventMessage: " +
          eventMessage);
      },
      // Identification result callback, including intermediate results and final results.
      onResult: (sessionId: string, res: speechRecognizer.SpeechRecognitionResult) => {
        let isFinal: boolean = res.isFinal;
        let isLast: boolean = res.isLast;
        let result: string = res.result;
        let regexp: RegExp = new RegExp(/\。$/, "g");
        result = result.replaceAll(regexp, "");
        this.keywords = result;
        console.info('setListener onResult: ' + 'sessionId: ' + sessionId + ' isFinal: ' + isFinal + ' isLast: ' +
          isLast + ' result: ' + result);
      },
      // Recognition completion callback
      onComplete(sessionId: string, eventMessage: string) {
        console.info("setListener onComplete sessionId: " + sessionId + "eventMessage: " + eventMessage);
      },
      // Error callback. The error code is returned by this method.
      onError(sessionId: string, errorCode: number, errorMessage: string) {
        console.error("setListener onError sessionId: " + sessionId + "errorCode: " + errorCode + "errorMessage: " +
          errorMessage);
      }
    }
    // Invoke the callback method.
    asrEngine.setListener(setListener);
  };
  // Recording to text
  async startRecording() {
    // MLRemoteAftSetting setting = new MLRemoteAftSetting.Factory()
    //   .enablePunctuation(false)
    //   .create();
    let extraParam: Record<string, Object> = {
      "locate": "CN",
      "recognizerMode": "short",
    };
    //speechRecognizer.CreateEngineParams
    let initParamsInfo: speechRecognizer.CreateEngineParams = {
      language: 'zh-CN',
      online: 1,
      extraParams: extraParam
    };

    // Invoke the createEngine method.
    speechRecognizer.createEngine(initParamsInfo)
      .then((speechRecognitionEngine: speechRecognizer.SpeechRecognitionEngine) => {
        asrEngine = speechRecognitionEngine;
        this.setListener();
        // Set the parameters related to the start of identification.
        let audioParam: speechRecognizer.AudioInfo = {
          audioType: 'pcm',
          sampleRate: 16000,
          soundChannel: 1,
          sampleBit: 16
        }
        let extraParam: Record<string, Object> = {
          "recognitionMode": 0,
          "vadBegin": 2000,
          "vadEnd": 3000,
          "maxAudioDuration": 20000
        }
        let recognizerParams: speechRecognizer.StartParams = {
          sessionId: this.sessionId,
          audioInfo: audioParam,
          extraParams: extraParam
        }
        // Invoke the start recognition method.
        console.info('startListening start');
        asrEngine.startListening(recognizerParams);

        // Recording Obtaining Audio
        let data: ArrayBuffer;
        this.mFileCapturer = this.mAudioCapturer;
        console.info('create capture success');
        this.mFileCapturer.init((dataBuffer: ArrayBuffer) => {
          console.info('start write');
          console.info('ArrayBuffer ' + JSON.stringify(dataBuffer));
          data = dataBuffer
          let uint8Array: Uint8Array = new Uint8Array(data);
          console.info('ArrayBuffer uint8Array ' + JSON.stringify(uint8Array));
          // Writing Audio Streams
          asrEngine.writeAudio(this.sessionId, uint8Array);
        });
      })
      .catch((err: BusinessError) => {
        console.error('result' + JSON.stringify(err));
      });

  };


  // 进入页面时先获取历史记录
  async getHistoryData(){
    this.historySearch=await SearchService.getHistoryData()
  }
  aboutToAppear() {
    this.getHistoryData()
    this.getHotRankings()
  }

  async getHotRankings() {
    try {
      const res = await getSongsRanking()
      if (Array.isArray(res)) {
        this.hotRankings = res as SongModel[]
      } else if (res && res.data && Array.isArray(res.data)) {
        this.hotRankings = res.data as SongModel[]
      }
    } catch (e) {
      // 可选：错误处理
    }
  }

  // doSearch:保存历史记录执行跳转
  async doSearch(){
    await SearchService.setHistoryData(this.keywords)
    //替换路由
    router.replaceUrl({
      url: 'pages/search/SearchDetail',
      params: {
        "keywords": this.keywords,
      }
    })
  }

  @Builder
  SearchWidget() {
    Column() {
      Row() {
        Image($r("app.media.ic_back"))
          .width(25)
          .height(25)
          .borderRadius(3)
          .fillColor(this.myColor.dark)
          .onClick(() => {
            router.back()
          })
          .margin({ right: 8 })
        Search({
          value: this.keywords,
          placeholder: '歌手 正在搜索'
        })
          .height(35)
          .backgroundColor(this.myColor.bright)
          .fontColor(this.myColor.dark)
          .placeholderColor(this.myColor.gray)
          .searchIcon({ color: this.myColor.dark })
          .borderColor(this.myColor.dark)
          .borderWidth(2)
          .placeholderFont({ size: 16, weight: 400 })
          .onChange((value: string) => {
            this.keywords = value
          })
          .onSubmit(() => {
            this.doSearch()
          })
          .layoutWeight(1)

        Image($r('app.media.ic_huatong'))
          .fillColor(this.isFlag ? Color.Orange : Color.Gray)
          .width(25)
          .height(25)
          .margin({left: 10})
          .onTouch(async (event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.isFlag = true;
              await this.startRecording();
            }
            if (event.type === TouchType.Up) {
              setTimeout(() => {
                this.isFlag = false;
                asrEngine.finish(this.sessionId);
              }, 1000);
            }
          })
      }
      .width("100%")
      .height(50)
      .margin({ top: 10 })
      .backgroundColor(this.myColor.background)
      .padding({ left: 20, right: 20 })
    }
  }

  @Builder
  OptionItem(title:string){
    Column() {
      if(title == '歌手') {
        Image($r('app.media.ic_singer'))
          .width(45)
          .height(45)
          .fillColor(this.myColor.dark)
          .margin({ bottom: 4 })
        Text('歌手')
          .fontSize(15)
          .fontColor(this.myColor.dark)
      }
      else if(title == '专辑') {
        Image($r('app.media.ic_album'))
          .width(45)
          .height(45)
          .fillColor(this.myColor.dark)
          .margin({ bottom: 4 })
        Text('专辑')
          .fontSize(15)
          .fontColor(this.myColor.dark)
      }
      else if(title == '歌单') {
        Image($r('app.media.ic_list'))
          .width(45)
          .height(45)
          .fillColor(this.myColor.dark)
          .margin({ bottom: 4 })
        Text('歌单')
          .fontSize(15)
          .fontColor(this.myColor.dark)
      }
      else if(title == '排行') {
        Image($r('app.media.ic_rank'))
          .width(45)
          .height(45)
          .fillColor(this.myColor.dark)
          .margin({ bottom: 4 })
        Text('排行')
          .fontSize(15)
          .fontColor(this.myColor.dark)
      }
    }
    .backgroundColor(this.myColor.background)
    .width(70)
    .height(30)
    .borderRadius(8)
    .onClick(() => {
      if (title == '歌手') {
        router.pushUrl({
          url: 'pages/detail/SingerList'
        })
      } else if (title == '专辑') {
        router.pushUrl({
          url: 'pages/detail/AlbumList'
        })
      } else if (title == '歌单') {
        router.pushUrl({
          url: 'pages/detail/SongListList'
        })
      } else if (title == '排行') {
        router.pushUrl({
          url: 'pages/detail/RankDetail'
        })
      }
    })
  }
  @Builder
  OptionWidget(){
    Row(){
      this.OptionItem('歌手')
      this.OptionItem('专辑')
      this.OptionItem('歌单')
      this.OptionItem('排行')
    }
    .width("100%")
    .padding({left:25,right:25})
    .margin({bottom: 40})
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  HistoryWidget(){
    Column(){
      Row() {
        Column() {
          Text('搜索历史')
            .fontSize(23)
            .fontColor(this.myColor.dark)
            .fontWeight(FontWeight.Bold)
          Image($r('app.media.line'))
            .fillColor("#03e884")
            .width(90)
            .height(2.5)
        }
        .alignItems(HorizontalAlign.Start)
        Image($r("app.media.delete")).width(20).height(20).fillColor(this.myColor.dark).onClick(async ()=>{
          promptAction.showDialog({
            title:"提示信息!",
            message: '您确定要清空历史记录吗？',
            buttons: [
              {
                text: '取消',
                color: '#ff8d8b8b'
              },
              {
                text: '确认',
                color: '#000000'
              }
            ]
          }).then(async (result) =>  {
            if (result.index === 1) {
              await SearchService.cleanHistoryData()
              this.getHistoryData()  // 再次获取历史记录
            }
          })
        })
      }
      .margin({bottom:5})
      .justifyContent(FlexAlign.SpaceBetween)
      .width("100%")
      if (this.historySearch.length > 0){
        Flex({
          wrap: FlexWrap.Wrap
        }) {
          ForEach(this.historySearch, (item:string) => {
            Button({type: ButtonType.Normal })
            {
              Text(item).fontSize(16).fontColor(this.myColor.dark)
            }
            .padding({left: 10, right: 10,top: 5,bottom: 5})
            .margin(5)
            .backgroundColor(this.myColor.bright)
            .borderRadius(5)
            .onClick(()=>{
              this.keywords = item
              this.doSearch()
            })
            .gesture(
              LongPressGesture(
                {duration:1000}
              ).onAction(()=>{
                promptAction.showDialog({
                  title:"提示信息!",
                  message: '您确定要删除吗？',
                  buttons: [
                    {
                      text: '取消',
                      color:'#ff8d8b8b'
                    },
                    {
                      text: '确认',
                      color: '#000000'
                    }
                  ]
                }).then(async (result) =>  {
                  if (result.index === 1) {
                    await SearchService.deleteHistoryData(item)
                    this.getHistoryData()
                  }
                })
              })
            )
          })
        }
      }
    }
    .width("100%")
    .padding({ left: 20, right: 20 })
    .margin({bottom:10})
  }

  @Builder
  RankWidget(){
    Column() {
      Column() {
        Text('热度榜单')
          .fontSize(23)
          .fontColor(this.myColor.dark)
          .fontWeight(FontWeight.Bold)
        Image($r('app.media.line'))
          .fillColor("#03e884")
          .width(90)
          .height(2.5)
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .width("100%")
      .margin({bottom:10})
      .backgroundColor(this.myColor.background)

      List(){
        ForEach(this.hotRankings, (song: SongModel, index: number)=>{
          ListItem() {
            Row() {
              // 排名
              Text((index + 1).toString())
                .fontSize(16)
                .fontColor(index < 3 ? '#ff6b35' : this.myColor.gray)
                .fontWeight(index < 3 ? FontWeight.Bold : FontWeight.Normal)
                .width(30)
                .textAlign(TextAlign.Center)
                .margin({left:15})

              // 歌曲信息
              Column({ space: 4 }) {
                Text(song.name)
                  .fontSize(15)
                  .fontColor(this.myColor.dark)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(song.singer ?? "")
                  .fontSize(13)
                  .fontColor(this.myColor.gray)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 15 })

              // 播放按钮
              Image($r('app.media.play_icon'))
                .width(20)
                .height(20)
                .fillColor(this.myColor.gray)
                .margin({right:20})
            }
            .borderRadius(3)
            .width('100%')
            .padding({top:8,bottom:8})
            .backgroundColor(this.myColor.bright)
            .onClick(() => {
              // 3.点击歌曲项：插入到播放列表第一个位置并播放
              const isExist = AvPlayerUtils.playList.some(item => item.id === song.id);
              if (!isExist) {
                AvPlayerUtils.playList.unshift(song); // 插入到首位
              } else {
                // 如果已存在，移动到首位
                const index = AvPlayerUtils.playList.findIndex(item => item.id === song.id);
                if (index > 0) {
                  AvPlayerUtils.playList.splice(index, 1);
                  AvPlayerUtils.playList.unshift(song);
                }
              }
              AvPlayerUtils.playIndex = 0; // 设置当前播放索引为首位
              AvPlayerUtils.playSingle(song); // 播放当前歌曲
              // 跳转到播放器页面
              router.pushUrl({
                url: 'pages/Player',
                params: { song: JSON.stringify(song) }
              });
            })
          }
        }, (item: SongModel)=>item.id.toString())
      }
      .width('100%')
      .padding({left:10,right:10})
      .backgroundColor(this.myColor.background)
    }
    .width('100%')
    .backgroundColor(this.myColor.background)
    .padding({left: 20, right: 20})
    .margin({bottom:35})
  }

  build() {
    Column({space: 10})
    {
      this.SearchWidget()
      Scroll() {
        Column() {
          this.OptionWidget()
          this.HistoryWidget()
          this.RankWidget()
        }
      }
      .width("100%")
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .width("100%")
    .height("100%")
    .backgroundColor(this.myColor.background)
  }
}