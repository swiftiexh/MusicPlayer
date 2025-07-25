// 接口返回值
export class ResponseModel {
  success: boolean;
  message: string;
  data: Array<object>;
  constructor() {
    this.success = false;
    this.message = "";
    this.data = [];
  }
}

// 传值参数
export class ParamModel{
  cid?:number;
  keywords?:string;
  type?:number;
}

//登录
export  interface  LoginModel {
  username:string,
  password:string
}

// 登录响应中的用户信息
export interface LoginUserData {
  id: number;
  username: string;
  sex?: string;
  phone_num?: string;
  birth?: string;
  location?: string;
  avatar?: string;
}

// 登录响应数据类型
export interface LoginResponseData {
  user: LoginUserData;
  token: string;
}

// 提交评论
export interface CommentModel {
  user_id?: number;
  song_id?: number;
  content?: string;
  up?: number;
}

// 增加/删除收藏功能
export interface CollectionModel {
  user_id?: number;
  song_id?: number;
}

export enum EmitEventType {
  UPDATE_STATE = 'update_state',
  PLAY_SONG = 'play_song',
  TOGGLE_PLAY = 'toggle_play'
}

// 新建歌单参数类型
export interface SongListCreateParams {
  name: string;
  user_id: number;
  pic?: string;
  introduction?: string;
  style?: string;
}