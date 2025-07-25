import { SongModel } from './AppModel';

// 播放器通知页面的数据结构
export interface PlayStateType {
  pic: string
  name: string
  url: string
  playIndex: number
  time: number
  duration: number
  isPlay: boolean
  playMode: 'auto' | 'repeat' | 'random'
  playlist: SongModel[]
  lyrics?: string  // 添加 lyrics 字段，与 SongModel.lyric 对应
}

export class PlayStateModel implements PlayStateType {
  pic: string;
  name: string;
  url: string;
  playIndex: number;
  time: number;
  duration: number;
  isPlay: boolean;
  playMode: 'auto' | 'repeat' | 'random';
  playlist: SongModel[];
  lyrics?: string;  // 添加 lyrics 字段

  constructor(playState: PlayStateType) {
    this.pic = playState.pic;
    this.name = playState.name;
    this.url = playState.url;
    this.playIndex = playState.playIndex;
    this.time = playState.time;
    this.duration = playState.duration;
    this.isPlay = playState.isPlay;
    this.playMode = playState.playMode;
    this.playlist = playState.playlist;
    this.lyrics = playState.lyrics;  // 添加 lyrics 字段赋值
  }
}

export const defaultState: PlayStateType = {
  pic: " ",
  name: "音乐网",
  url: "",
  playIndex: 0,
  time: 0,
  duration: 0,
  isPlay: false,
  playMode: "auto",
  playlist: [],
  lyrics: ""  // 添加默认 lyrics 值
};