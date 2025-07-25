export interface UserInfo {
  id: number;
  username: string;
  sex : string;
  birth: string;
  location: string;
  avatar: string;
}
export interface Consumer{
  id: number;
  username: string;
  password?: string;
  sex: string;
  phone_num?: string;
  birth?: string;
  location?: string;
  avatar?: string;
}

export interface SongList{
  id: number;
  user_id?: number;
  name?: string;
  pic?: string;
  style?: string;
  introduction?: string;
  username?: string;
}

export interface  SwiperModel{
  id: number,
  title: string,
  pic: string
}

export interface RankModel {
  id: number;
  rank: number;
  name: string;
  singer: string;
}

export interface SearchResultModel {
  // 歌曲、歌手、歌单、专辑
  // 歌曲
  id:number;
  name?:string;
  pic?:string;
  lyric?:string;
  url?:string;
  video_url?:string;
  click_num?:number;
  singer?:string;
  album?:string;
  // 歌手
  sex?:string;
  region?:string;
  introduction?:string;
  // 歌单
  style?: string;
  consumer?: string;
  // 专辑
  year?: string;
}

export interface SingerModel {
  id?: number,
  name?: string,
  sex?: string,
  pic?: string,
  region?: string,
  introduction?: string
}

export interface SongModel {
  id: number,
  singer_id?: number,
  name: string,
  pic: string,
  lyric: string,
  url: string,
  video_url: string,
  album_id?: number,
  click_num: number,
  singer: string,
  album: string
}

export class SongModelClass implements SongModel {
  // 手动声明所有接口属性
  id: number;
  singer_id: number;
  name: string;
  pic: string;
  lyric: string;
  url: string;
  video_url: string;
  album_id: number;
  click_num: number;
  singer: string;  // 新增缺失的属性声明
  album: string;   // 新增缺失的属性声明

  // 构造函数参数不要加 public 修饰符
  constructor(
    id: number,
    singer_id: number,
    name: string,
    pic: string,
    lyric: string,
    url: string,
    video_url: string,
    album_id: number,
    click_num: number,
    singer: string,
    album: string
  ) {
    this.id = id;
    this.singer_id = singer_id;
    this.name = name;
    this.pic = pic;
    this.lyric = lyric;
    this.url = url;
    this.video_url = video_url;
    this.album_id = album_id;
    this.click_num = click_num;
    this.singer = singer;
    this.album = album;
  }
}

export interface SongToListModel
{
  id: number;
  song_id: number;
  list_id: number;
}

export interface AlbumModel {
  id?: number,
  name?: string,
  year?: number,
  singer_id?: number,
  introduction?: string,
  pic?: string,
  singer_name?:  string
}

export interface CollectionModel {
  id: number;
  user_id: number;
  song_id: number;
  song_name: string;
  song_pic: string;
  song_lyric: string;
  song_url: string;
  song_video_url: string;
  song_click_num: number;
  singer: string;
  album: string;
  song_duration: number;
}

// 评论记录模型
export interface CommentModel {
  id: number;
  user_id: number;
  user_name: string;
  avatar?: string;  // 用户头像
  song_id: number;
  pic: string;  // 歌曲封面
  song_name: string;
  singer: string;
  content: string;
  up_content?: string;
  up_user?: number;
  up_user_name?: string;
  create_time: string;
}

export interface CommentReplyModel {
  id?: number;
  username?: string;
  avatar?: string;
  content?: string;
  create_time?: string;
  reply?: CommentReplyModel[];
}

// 排行榜歌曲模型
export interface RankSongModel {
  id: number;
  name: string;
  pic: string;
  lyric: string;
  url: string;
  video_url: string;
  click_num: number;
  singer_id: number;
  album_id: number;
  singer: string;
  album: string;
}

// 用户点击记录模型
export interface UserClickModel {
  id: number;
  user_id: number;
  song_id: number;
  click_num: number;
}

export interface PlayerPageRouteParams {
  song?: string; // JSON 字符串的 SongModel
}

