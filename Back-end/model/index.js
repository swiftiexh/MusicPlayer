// 1. 连接mysql的配置
const config = require('../config/db.js');
// 2.连接mysql (使用sequelize )
const { Sequelize, DataTypes } = require('sequelize');
const sequelize = new Sequelize(config.database, config.username, config.password, config.option);

// 3. 引入表结构对象
const consumer = require('./consumer.js')(sequelize, DataTypes);
const singer = require('./singer.js')(sequelize, DataTypes);
const album = require('./album.js')(sequelize, DataTypes);
const song = require('./song.js')(sequelize, DataTypes);
const song_list = require('./song_list.js')(sequelize, DataTypes);
const song_to_list = require('./song_to_list.js')(sequelize, DataTypes);
const collect = require('./collect.js')(sequelize, DataTypes);
const comment = require('./comment.js')(sequelize, DataTypes);
const user_click = require('./user_click.js')(sequelize, DataTypes);
const swiper = require('./swiper.js')(sequelize, DataTypes);

// 4.建立模型之间的关系
// 4.1.歌手和专辑的关系 (一对多)
singer.hasMany(album, { foreignKey: 'singer_id' });
album.belongsTo(singer, { foreignKey: 'singer_id' });

// 4.2.歌手和歌曲的关系 (一对多)
singer.hasMany(song, { foreignKey: 'singer_id' });
song.belongsTo(singer, { foreignKey: 'singer_id' });

// 4.3.专辑和歌曲的关系 (一对多)
album.hasMany(song, { foreignKey: 'album_id' });
song.belongsTo(album, { foreignKey: 'album_id' });

// 4.4.用户和歌单的关系 (一对多)
consumer.hasMany(song_list, { foreignKey: 'user_id' });
song_list.belongsTo(consumer, { foreignKey: 'user_id' });

// 4.5.歌曲和歌单的多对多关系
song.hasMany(song_to_list, { foreignKey: 'song_id' });
song_to_list.belongsTo(song, { foreignKey: 'song_id' });
song_list.hasMany(song_to_list, { foreignKey: 'list_id' });
song_to_list.belongsTo(song_list, { foreignKey: 'list_id' });

// 4.6.用户和歌曲的收藏关系 (多对多)
consumer.hasMany(collect, { foreignKey: 'user_id' });
collect.belongsTo(consumer, { foreignKey: 'user_id' });
song.hasMany(collect, { foreignKey: 'song_id' });
collect.belongsTo(song, { foreignKey: 'song_id' });

// 4.7.用户和歌曲的评论关系 (一对多)
consumer.hasMany(comment, { foreignKey: 'user_id' });
comment.belongsTo(consumer, { foreignKey: 'user_id' });
song.hasMany(comment, { foreignKey: 'song_id' });
comment.belongsTo(song, { foreignKey: 'song_id' });

// 4.8.评论和歌曲的关系 (一对多)
song.hasMany(comment, { foreignKey: 'song_id' });
comment.belongsTo(song, { foreignKey: 'song_id' });

// 5.模型同步   sequelize.sync() 自动同步所有模型
sequelize.sync({ force: false });

// 6. 导出模型
exports.consumer = consumer;
exports.singer = singer;
exports.album = album;
exports.song = song;
exports.song_list = song_list;
exports.song_to_list = song_to_list;
exports.collect = collect;
exports.comment = comment;
exports.user_click = user_click;
exports.swiper = swiper;

exports.sequelize = sequelize;