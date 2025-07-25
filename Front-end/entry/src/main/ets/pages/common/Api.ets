import {HttpGet,HttpPost} from "./HttpUtil"
import {ParamModel,LoginModel,CommentModel,CollectionModel,SongListCreateParams} from "../model/paramModel"

export function getSwiperList(){
  return HttpGet("/getSwiper")
}

export function doSearch(params: ParamModel){
  return HttpGet(encodeURI(`/doSearch?keywords=${params.keywords}&type=${params.type}`))
}

export function getSingerList(){
  return HttpGet("/getAllSingers")
}

export function getSingerDetail(params: ParamModel){
  return HttpGet(`/getSinger?id=${params.cid}`)
}

export function getSongs(){
  return HttpGet("/getAllSongs")
}

export function getSongByName(songName: string){
  return HttpGet(`/getSong?name=${encodeURIComponent(songName)}`)
}

export function getSongById(songID: number)
{
  return HttpGet(`/getSong?id=${songID}`)
}

export function getSongLists(){
  return HttpGet("/getAllSongLists")
}

export function getSongListDetail(params: ParamModel){
  return HttpGet(`/getSongList?id=${params.cid}`)
}

export function getSongToLists(){
  return HttpGet("/getAllSongToLists")
}

export function getAlbums(){
  return HttpGet("/getAllAlbums")
}

export function getAlbumDetail(params: ParamModel){
  return HttpGet(`/getAlbum?id=${params.cid}`)
}

export function getCommentById(id:number) {
  return HttpGet(`/getCommentsByUser?id=${id}`)
}

export function getCommentBySongId(params: ParamModel) {
  return HttpGet(`/getCommentsBySong?song_id=${params.cid}`)
}

export function addCollection(params: CollectionModel)
{
  return HttpPost(`/addCollect`,params)
}

export function deleteCollection(params: CollectionModel)
{
  return HttpPost(`/deleteCollect`,params)
}

export function checkCollection(params: CollectionModel)
{
  return HttpGet(`/checkCollect?user_id=${params.user_id}&song_id=${params.song_id}`)
}

export const login = (params:LoginModel) => HttpPost(`/login`,params);

export const getMySongList = () => HttpGet('/user/collections');

export function postComment(params: CommentModel){
  return HttpPost(`/postComment`,params)
}

export function getSongsRanking(){
  return HttpGet("/songs_ranking")
}

export function getUserClicks(userId: number){
  return HttpGet(`/user_clicks?user_id=${userId}`)
}

export function add_click_num(id: number){
  return HttpGet(`/add_click_num?id=${id}`)
}

export function user_addclick(user_id: number,song_id: number){
  return HttpGet(`/user_addclick?user_id=${user_id}&song_id=${song_id}`)
}

// 创建新歌单
export function createSongList(params: SongListCreateParams){
  return HttpPost("/createSongList", params)
}

// 添加歌曲到歌单
export function addSongToList(songId: number, listId: number){
  return HttpGet(`/addSongToList?song_id=${songId}&list_id=${listId}`)
}

// 根据歌单ID获取歌曲列表
export function getSongsByListId(listId: number){
  return HttpGet(`/getSongListByListId?list_id=${listId}`)
}
