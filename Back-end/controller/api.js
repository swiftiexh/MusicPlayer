const model = require('../model/index')
const Swiper = model.swiper
const Singer = model.singer
const Album = model.album
const Song = model.song
const SongList = model.song_list
const SongToList = model.song_to_list
const Collect = model.collect
const Comment = model.comment
const UserClick = model.user_click
const Consumer = model.consumer
const Sequelize = require('sequelize')
const Op = Sequelize.Op
const md5 = require('md5')
const {generateToken,verifyToken} = require( '../utils/token')
const song = require('../model/song')
const consumer = require('../model/consumer')
const album = require('../model/album')


// 轮播图
exports.getSwiper = async (ctx,next) => {
    try {
        const swiper = await Swiper.findAll()
        ctx.body = {
            code: 200,
            data: swiper,
            message: '获取轮播图成功'
        }
    }
    catch (err) {
        ctx.body = {
            code: 100,
            data: err,
            message: '获取轮播图失败'
        }
    }
}


// 实现分类查询
exports.doSearch = async (ctx) => {
    const {keywords, type=1} = ctx.query
    let list = null
    if(type == 1){  // 搜索歌曲
        list = await Song.findAll({
            where: {
                name: {
                    [Op.like]: `%${keywords}%`
                }
            },
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                },
                {
                    model: Album,
                    attributes: ['name']
                }
            ],
            order : [['id', 'asc']]  // 升序
        })
        // 把singer和album的name转换为与歌曲同级
        list = list.map(song => {   
            return {
                id: song.id,
                name: song.name,
                pic: song.pic,
                lyric: song.lyric,
                url: song.url,
                video_url: song.video_url,
                click_num: song.click_num,
                singer: song.singer.name,
                album: song.album.name,
            }
        })
    } else if(type == 2){  // 搜索歌手
        list = await Singer.findAll({
            where: {
                name: {
                    [Op.like]: `%${keywords}%`
                }
            },
            order : [['id', 'asc']]  // 升序
        })
    }else if(type == 3){  // 搜索歌单
        list = await SongList.findAll({
            where: {
                name: {
                    [Op.like]: `%${keywords}%`
                }
            },
            include: [
                {
                    model: Consumer,
                    attributes: ['username']
                }
            ],
            order : [['id', 'asc']]  // 升序
        })
        list = list.map(songList => {   
            return {
                id: songList.id,
                name: songList.name,
                pic: songList.pic,
                introduction: songList.introduction,
                style: songList.style,
                consumer: songList.consumer.username
            }
        })
    }else if(type == 4){  // 搜索专辑
        list = await Album.findAll({
            where: {
                name: {
                    [Op.like]: `%${keywords}%`
                }
            },
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                }
            ],
            order : [['id', 'asc']]  // 升序
        })
        list = list.map(album => {   
            return {
                id: album.id,
                name: album.name,
                year: album.year,
                pic: album.pic,
                introduction: album.introduction,
                singer: album.singer.name
            }
        })
    }
    datas = {
        list,
        type
    }
    ctx.body = {code: 200, message:'获取成功',data: datas}
}

// 获取所有歌曲
exports.getAllSongs = async (ctx, next) => {
    try {
        const songs = await Song.findAll({
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                },
                {
                    model: Album,
                    attributes: ['name']
                }
            ]
        })
        ctx.body = {
            code: 200,
            data: songs,
            message: '获取歌曲列表成功'
        }
    } catch (err) {
        ctx.body = {
            code: 104,
            data: err,
            message: '获取歌曲列表失败'
        }
    }
}

// 获取歌曲 - 支持通过id或name查询参数
exports.getSong = async (ctx, next) => {
    try {
        const { id, name } = ctx.query
        let whereCondition = {}
        
        if (id) {
            whereCondition.id = id
        } else if (name) {
            whereCondition.name = decodeURIComponent(name)
        } else {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供id或name参数'
            }
            return
        }
        
        const song = await Song.findOne({
            where: whereCondition,
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                },
                {
                    model: Album,
                    attributes: ['name']
                }
            ]
        })
        
        if (song) {
            ctx.body = {
                code: 200,
                data: song,
                message: '获取歌曲详情成功'
            }
        } else {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌曲不存在'
            }
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            data: err,
            message: '获取歌曲详情失败'
        }
    }
}


// 获取所有歌曲
exports.getAllSongs = async (ctx, next) => {
    try {
        let songs = await Song.findAll({
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                },
                {
                    model: Album,
                    attributes: ['name']
                }
            ]
        })
        songs = songs.map(song => {
            return {
                id: song.id,
                name: song.name,
                pic: song.pic,
                lyric: song.lyric,
                url: song.url,
                video_url: song.video_url,
                click_num: song.click_num,
                singer: song.singer.name,
                album: song.album.name,
                singer_id: song.singer_id,
                album_id: song.album_id
            }
        })
        ctx.body = {
            code: 200,
            data: songs,
            message: '获取歌曲列表成功'
        }
    } catch (err) {
        ctx.body = {
            code: 104,
            data: err,
            message: '获取歌曲列表失败'
        }
    }
}

// 获取歌曲 - 支持通过id或name查询参数
exports.getSong = async (ctx, next) => {
    try {
        const { id, name } = ctx.query
        let whereCondition = {}
        
        if (id) {
            whereCondition.id = id
        } else if (name) {
            whereCondition.name = decodeURIComponent(name)
        } else {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供id或name参数'
            }
            return
        }
        
        let song = await Song.findOne({
            where: whereCondition,
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                },
                {
                    model: Album,
                    attributes: ['name']
                }
            ]
        })
        
        song = {
            id: song.id,
            name: song.name,
            pic: song.pic,
            lyric: song.lyric,
            url: song.url,
            video_url: song.video_url,
            click_num: song.click_num,
            singer: song.singer ? song.singer.name : null,
            album: song.album ? song.album.name : null,
            singer_id: song.singer_id,
            album_id: song.album_id
        }

        if (song) {
            ctx.body = {
                code: 200,
                data: song,
                message: '获取歌曲详情成功'
            }
        } else {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌曲不存在'
            }
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            data: err,
            message: '获取歌曲详情失败'
        }
    }
}

// 获取所有歌手
exports.getAllSingers = async (ctx,next) => {
    try {
        const singers = await Singer.findAll()
        ctx.body = {
            code: 200,
            data: singers,
            message: '获取歌手列表成功'
        }
    }
    catch (err) {
        ctx.body = {
            code: 100,
            data: err,
            message: '获取歌手列表失败'
        }
    }
}

// 获取歌手 - 支持通过id或name查询参数
exports.getSinger = async (ctx, next) => {
    try {
        const { id, name } = ctx.query
        let whereCondition = {}
        
        if (id) {
            whereCondition.id = id
        } else if (name) {
            whereCondition.name = decodeURIComponent(name)
        } else {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供id或name参数'
            }
            return
        }

        const singer = await Singer.findOne({
            where: whereCondition
        })

        if (singer) {
            ctx.body = {
                code: 200,
                data: singer,
                message: '获取歌手成功'
            }
        } else {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌手不存在'
            }
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            data: err,
            message: '获取歌手失败'
        }
    }
}

// 获取所有专辑
exports.getAllAlbums = async (ctx, next) => {
    try {
        let albums = await Album.findAll({
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                }
            ]
        })
        albums = albums.map(album => ({
            id: album.id,
            name: album.name,
            year: album.year,
            pic: album.pic,
            introduction: album.introduction,
            singer_id: album.singer_id,
            singer_name: album.singer ? album.singer.name : null
        }))
        ctx.body = {
            code: 200,
            data: albums,
            message: '获取专辑列表成功'
        }
    } catch (err) {
        ctx.body = {
            code: 100,
            data: err,
            message: '获取专辑列表失败'
        }
    }
}

// 获取专辑 - 支持通过id或name查询参数
exports.getAlbum = async (ctx, next) => {
    try {
        const { id, name } = ctx.query
        let whereCondition = {}
        
        if (id) {
            whereCondition.id = id
        } else if (name) {
            whereCondition.name = decodeURIComponent(name)
        } else {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供id或name参数'
            }
            return
        }

        const album = await Album.findOne({
            where: whereCondition
        })

        if (album) {
            ctx.body = {
                code: 200,
                data: album,
                message: '获取专辑成功'
            }
        } else {
            ctx.body = {
                code: 105,
                data: null,
                message: '专辑不存在'
            }
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            data: err,
            message: '获取专辑失败'
        }
    }
}

// 获取所有歌单
exports.getAllSongLists = async (ctx,next) => {
    try {
        let songLists = await SongList.findAll(
            {
                include: [
                    {
                        model: Consumer,
                        attributes: [ 'username']
                    }
                ]
            }
        )
        songLists = songLists.map(songList => {
            return {
                id: songList.id,
                name: songList.name,
                pic: songList.pic,
                introduction: songList.introduction,
                style: songList.style,
                user_id: songList.user_id,
                username: songList.consumer ? songList.consumer.username : null
            }
        })
        ctx.body = {
            code: 200,
            data: songLists,
            message: '获取歌单列表成功'
        }
    }
    catch (err) {
        ctx.body = {
            code: 100,
            data: err,
            message: '获取歌单列表失败'
        }
    }
}

// 获取歌单 - 支持通过id或name查询参数，并通过user_id关联Consumer表，结果包含username字段
exports.getSongList = async (ctx, next) => {
    try {
        const { id, name } = ctx.query
        let whereCondition = {}

        if (id) {
            whereCondition.id = id
        } else if (name) {
            whereCondition.name = decodeURIComponent(name)
        } else {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供id或name参数'
            }
            return
        }

        const songList = await SongList.findOne({
            where: whereCondition,
            include: [
                {
                    model: Consumer,
                    attributes: ['username']
                }
            ]
        })

        if (songList) {
            ctx.body = {
                code: 200,
                data: {
                    id: songList.id,
                    name: songList.name,
                    pic: songList.pic,
                    introduction: songList.introduction,
                    style: songList.style,
                    user_id: songList.user_id,
                    username: songList.consumer ? songList.consumer.username : null
                },
                message: '获取歌单成功'
            }
        } else {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌单不存在'
            }
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            data: err,
            message: '获取歌单失败'
        }
    }
}

// 获取所有歌单
exports.getAllSongToLists = async (ctx,next) => {
    try {
        const song_to_lists = await SongToList.findAll()
        ctx.body = {
            code: 200,
            data: song_to_lists,
            message: '获取歌单多对多列表成功'
        }
    }
    catch (err) {
        ctx.body = {
            code: 100,
            data: err,
            message: '获取歌单多对多列表失败'
        }
    }
}            

// 获取评论信息，关联 Consumer、Song、Singer 表
exports.getCommentsByUser = async (ctx, next) => {
    try {
        const { id } = ctx.query
        if (!id) {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供user_id参数'
            }
            return
        }
        // 查询该用户的所有评论，关联 Song、Singer、Consumer
        const comments = await Comment.findAll({
            where: { user_id:id },
            order: [['create_time', 'desc']],
            include: [
                {
                    model: Consumer,
                    attributes: ['username']
                },
                {
                    model: Song,
                    attributes: ['name', 'pic'],
                    include: [
                        {
                            model: Singer,
                            attributes: ['name']
                        }
                    ]
                }
            ]
        })

        // 查询被回复评论的信息
        const result = await Promise.all(comments.map(async comment => {
            let up_content = null
            let up_user = null
            let up_user_name = null
            if (comment.up) {
                const upComment = await Comment.findOne({
                    where: { id: comment.up },
                    include: [
                        {
                            model: Consumer,
                            attributes: ['username']
                        }
                    ]
                })
                if (upComment) {
                    up_content = upComment.content
                    up_user = upComment.user_id
                    up_user_name = upComment.consumer ? upComment.consumer.username : null
                }
            }
            return {
                id: comment.id,
                user_id: comment.user_id,
                user_name: comment.consumer ? comment.consumer.username : null,
                song_id: comment.song_id,
                pic: comment.song ? comment.song.pic : null,
                song_name: comment.song ? comment.song.name : null,
                singer: comment.song && comment.song.singer ? comment.song.singer.name : null,
                content: comment.content,
                up_content,
                up_user,
                up_user_name,
                create_time: comment.create_time
            }
        }))

        ctx.body = {
            code: 200,
            data: result,
            message: '获取评论信息成功'
        }
    } catch (err) {
        console.log(err) // 添加详细错误日志
        ctx.body = {
            code: 106,
            data: err,
            message: '获取评论信息失败'
        }
    }
}

// 按照歌曲id获取评论
exports.getCommentsBySong = async (ctx, next) => {
    try {
        const { song_id } = ctx.query
        if (!song_id) {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供song_id参数'
            }
            return
        }

        // 递归获取评论及其所有子回复
        async function getReplies(parentId) {
            const replies = await Comment.findAll({
                where: { song_id, up: parentId },
                order: [['create_time', 'asc']],
                include: [
                    {
                        model: Consumer,
                        attributes: ['username', 'avatar']
                    }
                ]
            })
            // 对每个回复递归查找其子回复
            return await Promise.all(replies.map(async reply => ({
                id: reply.id,
                username: reply.consumer ? reply.consumer.username : null,
                avatar: reply.consumer ? reply.consumer.avatar : null,
                content: reply.content,
                create_time: reply.create_time,
                reply: await getReplies(reply.id)
            })))
        }

        // 获取主评论（up=0）
        const mainComments = await Comment.findAll({
            where: { song_id, up: 0 },
            order: [['create_time', 'desc']],
            include: [
                {
                    model: Consumer,
                    attributes: ['username', 'avatar']
                }
            ]
        })

        // 构造嵌套评论树
        const result = await Promise.all(mainComments.map(async comment => ({
            id: comment.id,
            username: comment.consumer ? comment.consumer.username : null,
            avatar: comment.consumer ? comment.consumer.avatar : null,
            content: comment.content,
            create_time: comment.create_time,
            reply: await getReplies(comment.id)
        })))

        ctx.body = {
            code: 200,
            data: result,
            message: '获取歌曲评论及所有层级回复成功'
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            data: err,
            message: '获取歌曲评论及回复失败'
        }
    }
}
// 提交评论
exports.postComment = async (ctx, next) => {
    try {
        const { user_id, song_id, content, up = 0 } = ctx.request.body
        if (!user_id || !song_id || !content) {
            ctx.body = {
                code: 107,
                message: '请提供user_id、song_id和content参数',
                data: null
            }
            return
        }
        // 获取北京时间
        const beijingTime = new Date(Date.now() + (8 * 60 * 60 * 1000))
        const comment = await Comment.create({
            user_id,
            song_id,
            content,
            up,
            create_time: beijingTime
            // id和create_time由数据库自动生成
        })
        ctx.body = {
            code: 200,
            message: '评论提交成功',
            data: comment
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            message: '评论提交失败',
            data: err
        }
    }
}

// 添加收藏
exports.addCollect = async (ctx, next) => {
    try {
        const { user_id, song_id } = ctx.request.body
        if (!user_id || !song_id) {
            ctx.body = {
                code: 107,
                message: '请提供user_id和song_id参数',
                data: null
            }
            return
        }
        // 检查是否已收藏
        const existingCollect = await Collect.findOne({
            where: { user_id, song_id }
        })
        if (existingCollect) {
            ctx.body = {
                code: 108,
                message: '已收藏该歌曲',
                data: null
            }
            return
        }
        // 添加收藏
        const collect = await Collect.create({ user_id, song_id })
        ctx.body = {
            code: 200,
            message: '收藏成功',
            data: collect
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            message: '收藏失败',
            data: err
        }
    }
}

// 删除收藏
exports.deleteCollect = async (ctx, next) => {
    try {
        const { user_id, song_id } = ctx.request.body
        if (!user_id || !song_id) {
            ctx.body = {
                code: 107,
                message: '请提供user_id和song_id参数',
                data: null
            }
            return
        }
        // 查找收藏记录
        const collect = await Collect.findOne({
            where: { user_id, song_id }
        })
        if (!collect) {
            ctx.body = {
                code: 108,
                message: '未找到该收藏记录',
                data: null
            }
            return
        }
        // 删除收藏
        await collect.destroy()
        ctx.body = {
            code: 200,
            message: '删除收藏成功',
            data: null
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            message: '删除收藏失败',
            data: err
        }
    }
}

// 检查有无收藏，输入song_id和user_id返回布尔值
exports.checkCollect = async (ctx, next) => {
    try {
        const { user_id, song_id } = ctx.query
        if (!user_id || !song_id) {
            ctx.body = {
                code: 107,
                message: '请提供user_id和song_id参数',
                data: null
            }
            return
        }
        const collect = await Collect.findOne({
            where: { user_id, song_id }
        })
        ctx.body = {
            code: 200,
            data: !!collect, // 返回布尔值
            message: '检查收藏状态成功'
        }
    } catch (err) {
        ctx.body = {
            code: 106,
            message: '检查收藏状态失败',
            data: err
        }
    }
}
// 以下是和用户有关的接口
//登录
exports.login = async (ctx,next) => {
    try {
        const {username,password} = ctx.request.body
        const user = await Consumer.findOne({
            where: {
                username,
                password: password  // 直接使用明文密码
            }
        })
        //存token 返回给客户的
        if (user) {
         //表示登录成功
         const token = await generateToken({username:user.username,id:user.id})
         ctx.body = {
             code: 200,
             message: '登录成功',
             data: {
                 user,token
             }
         }
        } else {
            ctx.body = {
                code: 103,
                message: '用户名或密码错误',
                data: null
            }
        }
    }catch (err) {
        ctx.body = {
            code: 101,
            message: '登录失败',
            data: err
        }
    }
}

//获取用户信息，这个需要token的
exports.getUserInfo = async (ctx,next) => {
    try{
        const userId = ctx.user.id
        const user = await Consumer.findByPk(userId, {
            attributes: ['id','username','sex'],
        })
        ctx.body = {
            code: 200,
            message: '获取用户信息成功',
            data: user
        }
    }catch (err) {
        ctx.body = {
            code: 102,
            message: '获取用户信息失败',
            data: err
        }
    }
}

//获取用户收藏的歌曲列表,这个需要token
exports.getUserCollections = async (ctx, next) => {
    try {
        const userId = ctx.user.id
        let collections = await Collect.findAll({
            where: {
                user_id: userId  // 使用数据库中的字段名
            },
            include: [
                {
                    model: Song,
                    include: [
                        {
                            model: Singer,
                            attributes: ['name']
                        },
                        {
                            model: Album,
                            attributes: ['name']
                        }
                    ]
                }
            ],
            order: [['id', 'DESC']] // 按收藏ID倒序排列，最新收藏的在前
        })
        collections = collections.map(collect => {
            return {
                id: collect.id,
                user_id: collect.user_id,
                song_id: collect.song_id,
                song_name: collect.song ? collect.song.name : null,
                song_pic: collect.song ? collect.song.pic : null,
                song_lyric: collect.song ? collect.song.lyric : null,
                song_url: collect.song ? collect.song.url : null,
                song_video_url: collect.song ? collect.song.video_url : null,
                song_click_num: collect.song ? collect.song.click_num : null,
                singer: collect.song && collect.song.singer ? collect.song.singer.name : null,
                album: collect.song && collect.song.album ? collect.song.album.name : null
            }
        })
        ctx.body = {
            code: 200,
            message: '获取收藏列表成功',
            data: collections
        }
    } catch (err) {
        ctx.body = {
            code: 109,
            message: '获取收藏列表失败',
            data: err
        }
    }
}

// 获取歌曲点击量排行榜
exports.getSongsRanking = async (ctx, next) => {
    try {
        let songs = await Song.findAll({
            include: [
                {
                    model: Singer,
                    attributes: ['name']
                },
                {
                    model: Album,
                    attributes: ['name']
                }
            ],
            order: [['click_num', 'DESC']], // 按点击次数降序排列
            // 只取前10条数据
            limit: 10
        })
        
        // 格式化返回数据，包含歌曲所有属性
        songs = songs.map(song => {
            return {
                id: song.id,
                name: song.name,
                pic: song.pic,
                lyric: song.lyric,
                url: song.url,
                video_url: song.video_url,
                click_num: song.click_num,
                singer_id: song.singer_id,
                album_id: song.album_id,
                singer: song.singer ? song.singer.name : null,
                album: song.album ? song.album.name : null
            }
        })
        
        ctx.body = {
            code: 200,
            data: songs,
            message: '获取歌曲点击量排行榜成功'
        }
    } catch (err) {
        console.log(err)
        ctx.body = {
            code: 114,
            data: err,
            message: '获取歌曲点击量排行榜失败'
        }
    }
}

// 根据用户ID获取用户点击记录，降序排列
exports.getUserClicks = async (ctx, next) => {
    try {
        const { user_id } = ctx.query
        
        if (!user_id) {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供user_id参数'
            }
            return
        }

        // 检查用户是否存在
        const user = await Consumer.findByPk(user_id)
        if (!user) {
            ctx.body = {
                code: 108,
                data: null,
                message: '用户不存在'
            }
            return
        }

        // 查询该用户的所有点击记录，按点击次数降序排列
        const userClicks = await UserClick.findAll({
            where: {
                user_id: user_id
            },
            attributes: ['id', 'user_id', 'song_id', 'click_num'],
            order: [['click_num', 'DESC']], // 按点击次数降序排列
            limit: 10
        })

        ctx.body = {
            code: 200,
            data: userClicks,
            message: '获取用户点击记录成功'
        }
    } catch (err) {
        console.log(err)
        ctx.body = {
            code: 113,
            data: err,
            message: '获取用户点击记录失败'
        }
    }
}

// 增加歌曲点击次数
exports.incrementSongClick = async (ctx, next) => {
    try {
        // 先尝试从query获取，再从body获取
        const id = ctx.query.id || (ctx.request.body && ctx.request.body.id)
        
        console.log('接收到的参数:', { query: ctx.query, body: ctx.request.body, id: id })
        
        if (!id) {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供歌曲id参数'
            }
            return
        }

        // 查找歌曲是否存在
        const song = await Song.findByPk(id)
        if (!song) {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌曲不存在'
            }
            return
        }

        // 增加点击次数
        const [updatedRowsCount] = await Song.update(
            { 
                click_num: song.click_num + 1 
            },
            { 
                where: { id: id } 
            }
        )

        if (updatedRowsCount > 0) {
            // 获取更新后的歌曲信息
            const updatedSong = await Song.findByPk(id, {
                attributes: ['id', 'singer_id' , 'name',
                    'pic', 'lyric','url', 'video_url','album_id', 'click_num']  // 所有属性

            })

            ctx.body = {
                code: 200,
                data: updatedSong,
                message: '歌曲点击次数更新成功'
            }
        } else {
            ctx.body = {
                code: 110,
                data: null,
                message: '歌曲点击次数更新失败'
            }
        }
    } catch (err) {
        console.log(err)
        ctx.body = {
            code: 111,
            data: err,
            message: '增加歌曲点击次数失败'
        }
    }
}

// 记录用户点击歌曲
exports.recordUserClick = async (ctx, next) => {
    try {
        const { user_id, song_id } = ctx.query
        
        if (!user_id || !song_id) {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供user_id和song_id参数'
            }
            return
        }

        // 检查用户是否存在
        const user = await Consumer.findByPk(user_id)
        if (!user) {
            ctx.body = {
                code: 108,
                data: null,
                message: '用户不存在'
            }
            return
        }

        // 检查歌曲是否存在
        const song = await Song.findByPk(song_id)
        if (!song) {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌曲不存在'
            }
            return
        }

        // 查找是否已存在该用户对该歌曲的点击记录
        const existingClick = await UserClick.findOne({
            where: {
                user_id: user_id,
                song_id: song_id
            }
        })

        let result
        if (existingClick) {
            // 如果已存在，点击次数+1
            await UserClick.update(
                { click_num: existingClick.click_num + 1 },
                { where: { id: existingClick.id } }
            )
            
            // 返回简化的记录信息
            result = {
                id: existingClick.id,
                user_id: user_id,
                song_id: song_id,
                click_num: existingClick.click_num + 1
            }
        } else {
            // 如果不存在，创建新记录，点击次数初始化为1
            const newClick = await UserClick.create({
                user_id: user_id,
                song_id: song_id,
                click_num: 1
            })
            
            // 返回简化的记录信息
            result = {
                id: newClick.id,
                user_id: user_id,
                song_id: song_id,
                click_num: 1
            }
        }

        ctx.body = {
            code: 200,
            data: result,
            message: '用户点击记录更新成功'
        }
    } catch (err) {
        console.log(err)
        ctx.body = {
            code: 112,
            data: err,
            message: '记录用户点击失败'
        }
    }
}

// 根据歌单ID获取歌单中的所有歌曲信息
exports.getSongListByListId = async (ctx, next) => {
    try {
        const { list_id } = ctx.query
        
        if (!list_id) {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供list_id参数'
            }
            return
        }

        // 检查歌单是否存在
        const songList = await SongList.findByPk(list_id)
        if (!songList) {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌单不存在'
            }
            return
        }

        // 通过song_to_list表关联查询歌单中的所有歌曲
        const songToLists = await SongToList.findAll({
            where: {
                list_id: list_id
            },
            include: [
                {
                    model: Song,
                    include: [
                        {
                            model: Singer,
                            attributes: ['name']
                        },
                        {
                            model: Album,
                            attributes: ['name']
                        }
                    ]
                }
            ]
        })

        // 格式化返回数据
        const songs = songToLists.map(item => {
            const song = item.song
            return {
                id: song.id,
                name: song.name,
                pic: song.pic,
                lyric: song.lyric,
                url: song.url,
                video_url: song.video_url,
                click_num: song.click_num,
                singer_id: song.singer_id,
                album_id: song.album_id,
                singer: song.singer ? song.singer.name : null,
                album: song.album ? song.album.name : null
            }
        })

        ctx.body = {
            code: 200,
            data: songs,
            message: '获取歌单歌曲列表成功'
        }
    } catch (err) {
        console.log(err)
        ctx.body = {
            code: 115,
            data: err,
            message: '获取歌单歌曲列表失败'
        }
    }
}

// 添加歌曲到歌单
exports.addSongToList = async (ctx, next) => {
    try {
        const { song_id, list_id } = ctx.query
        
        if (!song_id || !list_id) {
            ctx.body = {
                code: 107,
                data: null,
                message: '请提供song_id和list_id参数'
            }
            return
        }

        // 检查歌曲是否存在
        const song = await Song.findByPk(song_id)
        if (!song) {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌曲不存在'
            }
            return
        }

        // 检查歌单是否存在
        const songList = await SongList.findByPk(list_id)
        if (!songList) {
            ctx.body = {
                code: 105,
                data: null,
                message: '歌单不存在'
            }
            return
        }

        // 检查歌曲是否已经在歌单中
        const existingRecord = await SongToList.findOne({
            where: {
                song_id: song_id,
                list_id: list_id
            }
        })

        if (existingRecord) {
            ctx.body = {
                code: 116,
                data: null,
                message: '歌曲已存在于该歌单中'
            }
            return
        }

        // 添加歌曲到歌单
        const newRecord = await SongToList.create({
            song_id: song_id,
            list_id: list_id
        })

        ctx.body = {
            code: 200,
            data: {
                id: newRecord.id,
                song_id: song_id,
                list_id: list_id
            },
            message: '歌曲添加到歌单成功'
        }
    } catch (err) {
        console.log(err)
        ctx.body = {
            code: 117,
            data: err,
            message: '添加歌曲到歌单失败'
        }
    }
}

// 创建新歌单
exports.createSongList = async (ctx, next) => {
    try {
        const { name, pic, introduction, style, user_id } = ctx.request.body;
        if (!name || !user_id) {
            ctx.body = {
                code: 400,
                message: '缺少必要参数name或user_id',
                data: null
            };
            return;
        }
        const newSongList = await SongList.create({
            name,
            pic: pic || '',
            introduction: introduction || '',
            style: style || '',
            user_id
        });
        ctx.body = {
            code: 200,
            message: '歌单创建成功',
            data: newSongList
        };
    } catch (err) {
        ctx.body = {
            code: 500,
            message: '歌单创建失败',
            data: err
        };
    }
}

