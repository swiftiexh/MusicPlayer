const router = require('koa-router')()
const controller = require('../controller/api.js')
const {verifyToken} = require('../utils/token.js')

// 添加根路径处理
router.get('/', async (ctx) => {
  ctx.body = {
    title: 'Music Player API',
    version: '1.0.0',
    message: '欢迎使用音乐播放器API服务'
  }
})

//不需要使用token的
router.post('/login',controller.login)
router.get('/getSwiper',controller.getSwiper)
router.get('/doSearch',controller.doSearch)
router.get('/getAllSongs',controller.getAllSongs)
router.get('/getSong',controller.getSong)
router.get('/getAllSingers',controller.getAllSingers)
router.get('/getSinger',controller.getSinger)
router.get('/getAllAlbums',controller.getAllAlbums)
router.get('/getAlbum',controller.getAlbum)
router.get('/getAllSongLists',controller.getAllSongLists)
router.get('/getSongList',controller.getSongList)
router.get('/getAllSongToLists',controller.getAllSongToLists)
router.get('/getCommentsByUser',controller.getCommentsByUser)
router.get('/getCommentsBySong',controller.getCommentsBySong)
router.post('/postComment',controller.postComment)
router.post('/addCollect',controller.addCollect)
router.post('/deleteCollect',controller.deleteCollect)
router.get('/checkCollect',controller.checkCollect)
router.get('/user_clicks', controller.getUserClicks)
router.get('/songs_ranking', controller.getSongsRanking)
router.get('/add_click_num', controller.incrementSongClick)
router.get('/user_addclick', controller.recordUserClick)

router.get('/getSongListByListId',controller.getSongListByListId)
router.get('/addSongToList',controller.addSongToList )
router.post('/createSongList', controller.createSongList)


// 需要token的路由 - 使用verifyToken中间件
router.get('/user/getUserInfo', verifyToken(), controller.getUserInfo)
router.get('/user/collections', verifyToken(), controller.getUserCollections)


module.exports = router