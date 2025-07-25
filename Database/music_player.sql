/*
 Navicat Premium Data Transfer

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80019
 Source Host           : localhost:3306
 Source Schema         : music_player

 Target Server Type    : MySQL
 Target Server Version : 80019
 File Encoding         : 65001

 Date: 24/07/2025 23:58:08
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for albums
-- ----------------------------
DROP TABLE IF EXISTS `albums`;
CREATE TABLE `albums`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '专辑名称',
  `year` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '发行年份',
  `singer_id` int NOT NULL COMMENT '歌手ID',
  `introduction` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '专辑简介',
  `pic` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '专辑封面',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `singer_id`(`singer_id`) USING BTREE,
  CONSTRAINT `albums_ibfk_1` FOREIGN KEY (`singer_id`) REFERENCES `singers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 49 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of albums
-- ----------------------------
INSERT INTO `albums` VALUES (1, '叶惠美', '2003', 1, '《叶惠美》是周杰伦第四张国语专辑，2003年7月31日由杰威尔发行，以母亲之名致敬。11首歌融古典、嘻哈、摇滚，复古视觉呼应音乐，人文关怀升级，获金曲奖最佳专辑。', 'album/叶惠美.jpg');
INSERT INTO `albums` VALUES (2, '平凡的一天', '2018', 2, '毛不易首张全创作专辑，2018年5月31日发行。10首歌以温暖声线勾勒日常烟火，平凡瞬间被赋予诗意，旋律松弛，歌词质朴，治愈都市疲惫，被誉为“生活散文诗”。', 'album/平凡的一天.jpg');
INSERT INTO `albums` VALUES (3, 'Xposed', '2012', 3, '邓紫棋2012年7月5日发行专辑《Xposed》，十首全创作，摇滚与R&B交织。高亢嗓音剖析成长脆弱，记录19岁自省与控诉，获IFPI香港销量大奖，奠定“铁肺天后”地位。', 'album/Xposed.jpg');
INSERT INTO `albums` VALUES (4, 'Muse', '2012', 4, '蔡依林2012年9月14日发行专辑《Muse》，以艺术与流行交织，融合电子、舞曲、摇滚。十首歌化身“谬思”，探讨创作与爱情灵感，视觉前卫，获金曲奖提名，展现女王蜕变。', 'album/Muse.jpg');

-- ----------------------------
-- Table structure for collects
-- ----------------------------
DROP TABLE IF EXISTS `collects`;
CREATE TABLE `collects`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '用户ID',
  `song_id` int NOT NULL COMMENT '歌曲ID',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  INDEX `song_id`(`song_id`) USING BTREE,
  CONSTRAINT `collects_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `consumers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `collects_ibfk_2` FOREIGN KEY (`song_id`) REFERENCES `songs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of collects
-- ----------------------------
INSERT INTO `collects` VALUES (16, 1, 3);
INSERT INTO `collects` VALUES (17, 1, 6);

-- ----------------------------
-- Table structure for comments
-- ----------------------------
DROP TABLE IF EXISTS `comments`;
CREATE TABLE `comments`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '用户ID',
  `song_id` int NOT NULL COMMENT '歌曲ID',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '评论内容',
  `up` int NULL DEFAULT 0 COMMENT '回复的评论id',
  `create_time` datetime(0) NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  INDEX `song_id`(`song_id`) USING BTREE,
  CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `consumers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`song_id`) REFERENCES `songs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of comments
-- ----------------------------
INSERT INTO `comments` VALUES (1, 1, 1, '很好', 0, '2025-07-22 15:27:05');
INSERT INTO `comments` VALUES (2, 1, 1, '特别好', 1, '2025-07-22 15:27:36');
INSERT INTO `comments` VALUES (3, 1, 1, '支持', 2, '2025-07-22 17:04:14');
INSERT INTO `comments` VALUES (4, 2, 1, '不对', 2, '2025-07-22 17:09:40');
INSERT INTO `comments` VALUES (5, 2, 1, '特别戳中人心的一首歌', 0, '2025-07-23 21:11:05');
INSERT INTO `comments` VALUES (6, 1, 1, '好', 5, '2025-07-23 22:38:14');
INSERT INTO `comments` VALUES (7, 2, 1, '好', 6, '2025-07-23 22:40:39');
INSERT INTO `comments` VALUES (8, 1, 1, '确实', 5, '2025-07-23 22:49:47');
INSERT INTO `comments` VALUES (9, 1, 1, '嗯', 1, '2025-07-23 22:50:43');
INSERT INTO `comments` VALUES (10, 1, 1, '再听还是会流泪', 0, '2025-07-23 22:52:34');
INSERT INTO `comments` VALUES (11, 1, 1, '对啊', 10, '2025-07-23 23:23:43');
INSERT INTO `comments` VALUES (12, 1, 2, '好', 0, '2025-07-24 11:13:50');

-- ----------------------------
-- Table structure for consumers
-- ----------------------------
DROP TABLE IF EXISTS `consumers`;
CREATE TABLE `consumers`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户名',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码',
  `sex` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '性别',
  `phone_num` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '手机号',
  `birth` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '生日',
  `location` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '地址',
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '头像',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of consumers
-- ----------------------------
INSERT INTO `consumers` VALUES (1, 'epiphany', '123456', '男', '13800138001', '1995-01-15', '天津市', 'avatar/user1.jpg');
INSERT INTO `consumers` VALUES (2, '灿宝永远闪耀', '123456', '男', '15685269632', '1993-11-05', '天津市', 'avatar/user2.jpg');

-- ----------------------------
-- Table structure for singers
-- ----------------------------
DROP TABLE IF EXISTS `singers`;
CREATE TABLE `singers`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '歌手名称',
  `sex` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '性别',
  `pic` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '头像',
  `region` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '地区',
  `introduction` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '简介',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 17 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of singers
-- ----------------------------
INSERT INTO `singers` VALUES (1, '周杰伦', '男', 'singer/周杰伦.jpg', '港台', '周杰伦，华语流行乐坛划时代天王，1979年生于台北，集词曲创作、演唱、导演于一身。融合R&B、古典、中国风，开创“周氏曲风”，代表作《七里香》《青花瓷》等横扫亚洲，获奖无数，引领千禧世代音乐潮流。');
INSERT INTO `singers` VALUES (2, '毛不易', '男', 'singer/毛不易.jpg', '内地', '毛不易，1994年生于黑龙江齐齐哈尔，内地创作型歌手、词曲作者。2017年《明日之子》冠军出道，以《消愁》《像我这样的人》等原创刷屏，词写平凡诗意，嗓音温暖沧桑。专辑《平凡的一天》《小王》口碑销量双赢，多首OST热播，被誉为“用音乐讲故事的人”。');
INSERT INTO `singers` VALUES (3, '邓紫棋', '女', 'singer/邓紫棋.jpg', '港台', '邓紫棋（G.E.M.），1991年生于上海、成长于香港，华语天后级唱作人。2008年16岁出道即横扫香港四台新人奖，2014年《我是歌手2》爆红内地。铁肺高音+创作才华，代表作《泡沫》《光年之外》《句号》等播放量破百亿。巡演场场售罄，首位五登北京鸟巢的华语女歌手，YouTube华语歌手订阅量全球第一。');
INSERT INTO `singers` VALUES (4, '蔡依林', '女', 'singer/蔡依林.jpg', '港台', '蔡依林（Jolin Tsai），1980年生于台湾新北市，华语流行女皇。1999年凭《1019》出道，以《舞娘》《特务J》《呸》等专辑屡破销量与金曲纪录，唱跳全能、造型先锋，被誉为“亚洲唱跳天后”。持续引领潮流，巡演横跨四大洲，是首位在台北小巨蛋连开六场的女歌手，影响力辐射全亚洲。');

-- ----------------------------
-- Table structure for song_lists
-- ----------------------------
DROP TABLE IF EXISTS `song_lists`;
CREATE TABLE `song_lists`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '歌单名称',
  `pic` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '歌单封面',
  `introduction` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '歌单简介',
  `style` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '风格',
  `user_id` int NOT NULL COMMENT '创建用户ID',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `user_id`(`user_id`) USING BTREE,
  CONSTRAINT `song_lists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `consumers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of song_lists
-- ----------------------------
INSERT INTO `song_lists` VALUES (1, '最 · 邓紫棋', 'song_list/1.jpg', '铁肺小天后，女rapper制作人。越勇敢越幸运的邓紫棋，用超强高音能量和你一起嗨翻全场。', '流行', 1);

-- ----------------------------
-- Table structure for song_to_lists
-- ----------------------------
DROP TABLE IF EXISTS `song_to_lists`;
CREATE TABLE `song_to_lists`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `song_id` int NOT NULL COMMENT '歌曲ID',
  `list_id` int NOT NULL COMMENT '歌单ID',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `song_id`(`song_id`) USING BTREE,
  INDEX `list_id`(`list_id`) USING BTREE,
  CONSTRAINT `song_to_lists_ibfk_1` FOREIGN KEY (`song_id`) REFERENCES `songs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `song_to_lists_ibfk_2` FOREIGN KEY (`list_id`) REFERENCES `song_lists` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of song_to_lists
-- ----------------------------
INSERT INTO `song_to_lists` VALUES (1, 6, 1);

-- ----------------------------
-- Table structure for songs
-- ----------------------------
DROP TABLE IF EXISTS `songs`;
CREATE TABLE `songs`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `singer_id` int NOT NULL COMMENT '歌手ID',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '歌曲名称',
  `pic` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '歌曲封面',
  `lyric` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '歌词',
  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '歌曲链接',
  `album_id` int NULL DEFAULT NULL COMMENT '专辑ID',
  `click_num` int NULL DEFAULT 0 COMMENT '点击次数',
  `video_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '视频连接',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `singer_id`(`singer_id`) USING BTREE,
  INDEX `album_id`(`album_id`) USING BTREE,
  CONSTRAINT `songs_ibfk_1` FOREIGN KEY (`singer_id`) REFERENCES `singers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `songs_ibfk_2` FOREIGN KEY (`album_id`) REFERENCES `albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of songs
-- ----------------------------
INSERT INTO `songs` VALUES (1, 1, '以父之名', 'song/以父之名.jpg', '[ti:以父之名]\r\n[ar:周杰伦]\r\n[00:00.00]以父之名\r\n[00:04.00]作词：黄俊郎　作曲：周杰伦\r\n[00:08.00]演唱：周杰伦\r\n[00:12.00]\r\n[00:15.00]微凉的晨露　沾湿黑礼服\r\n[00:18.50]石板路有雾　父在低诉\r\n[00:22.00]无奈的觉悟　只能更残酷\r\n[00:25.50]一切都为了　通往圣堂的路\r\n[00:29.00]吹不散的雾　隐没了意图\r\n[00:32.50]谁轻柔踱步　停住\r\n[00:36.00]还来不及哭　穿过的子弹就带走温度\r\n[00:42.00]\r\n[00:42.50]我们每个人都有罪\r\n[00:45.00]犯着不同的罪\r\n[00:46.50]我能决定谁对\r\n[00:48.00]谁又该要沉睡\r\n[00:49.50]争论不能解决\r\n[00:51.00]在永无止境的夜\r\n[00:52.50]关掉你的嘴\r\n[00:54.00]唯一的恩惠\r\n[00:55.50]\r\n[00:56.00]低头亲吻我的左手\r\n[00:58.00]换取被宽恕的承诺\r\n[01:00.00]老旧管风琴在角落\r\n[01:02.00]一直一直一直伴奏\r\n[01:04.50]黑色帘幕被风吹动\r\n[01:06.50]阳光无言地穿透\r\n[01:08.50]洒向那群被我驯服后的兽\r\n[01:12.00]\r\n[01:12.50]沉默地喊叫　沉默地喊叫\r\n[01:15.50]孤单开始发酵\r\n[01:17.00]不停对着我嘲笑\r\n[01:19.00]回忆逐渐延烧\r\n[01:20.50]曾经纯真的画面\r\n[01:22.00]残忍地温柔出现\r\n[01:24.00]脆弱时间到\r\n[01:25.50]我们一起来祷告\r\n[01:27.50]\r\n[01:28.00]仁慈的父　我已坠入\r\n[01:31.00]看不见罪的国度\r\n[01:33.00]请原谅我的自负\r\n[01:35.50]Ah ya ya check it\r\n[01:38.00]没人能说　没人可说\r\n[01:41.00]好难承受　荣耀的背后\r\n[01:44.00]刻着一道孤独\r\n[01:46.00]\r\n[01:46.50]闭上双眼　我又看见\r\n[01:49.00]当年那梦的画面\r\n[01:51.50]天空是蒙蒙的雾\r\n[01:54.50]\r\n[01:55.00]父亲牵着我的双手\r\n[01:57.50]轻轻走过　清晨那安安静静的石板路\r\n[02:02.00]\r\n[02:02.50]低头亲吻我的左手\r\n[02:05.00]换取被宽恕的承诺\r\n[02:07.00]老旧管风琴在角落\r\n[02:09.00]一直一直一直伴奏\r\n[02:11.50]黑色帘幕被风吹动\r\n[02:13.50]阳光无言地穿透\r\n[02:15.50]洒向那群被我驯服后的兽\r\n[02:19.00]\r\n[02:19.50]沉默地喊叫　沉默地喊叫\r\n[02:22.50]孤单开始发酵\r\n[02:24.00]不停对着我嘲笑\r\n[02:26.00]回忆逐渐延烧\r\n[02:27.50]曾经纯真的画面\r\n[02:29.00]残忍地温柔出现\r\n[02:31.00]脆弱时间到\r\n[02:32.50]我们一起来祷告\r\n[02:34.50]\r\n[02:35.00]仁慈的父　我已坠入\r\n[02:38.00]看不见罪的国度\r\n[02:40.00]请原谅我的自负\r\n[02:42.50]Ah ya ya check it\r\n[02:45.00]没人能说　没人可说\r\n[02:48.00]好难承受　荣耀的背后\r\n[02:51.00]刻着一道孤独\r\n[02:53.00]\r\n[02:53.50]仁慈的父　我已坠入\r\n[02:56.00]看不见罪的国度\r\n[02:58.00]请原谅我的自负\r\n[03:00.50]Ah ya ya check it\r\n[03:03.00]没人能说　没人可说\r\n[03:06.00]好难承受　荣耀的背后\r\n[03:09.00]刻着一道孤独\r\n[03:11.00]\r\n[03:11.50]那斑驳的家徽　我擦拭了一夜\r\n[03:14.50]孤独的光辉　我才懂的感觉\r\n[03:17.50]烛光　不　不　停的摇晃\r\n[03:20.00]猫头鹰在窗棂上　对着远方眺望\r\n[03:23.00]通向大厅的长廊　一样说不出的沧桑\r\n[03:26.50]没有喧嚣　只有宁静围绕\r\n[03:29.00]我　慢慢睡着\r\n[03:31.00]天　刚刚破晓', 'music/以父之名.mp3', 1, 21, 'video/以父之名.mp4');
INSERT INTO `songs` VALUES (2, 1, '东风破', 'song/东风破.jpg', '[ti:东风破]\r\n[ar:周杰伦]\r\n[00:00.00]东风破\r\n[00:01.00]作词：方文山　作曲：周杰伦　编曲：林迈可\r\n[00:03.00]演唱：周杰伦\r\n[00:05.00]专辑：叶惠美\r\n[00:07.00]\r\n[00:13.98]一盏离愁　孤单伫立在窗口\r\n[00:20.54]我在门后　假装你人还没走\r\n[00:27.11]旧地如重游　月圆更寂寞\r\n[00:33.74]夜半清醒的烛火　不忍苛责我\r\n[00:40.30]\r\n[00:40.31]一壶漂泊　浪迹天涯难入喉\r\n[00:46.88]你走之后　酒暖回忆思念瘦\r\n[00:53.47]水向东流　时间怎么偷\r\n[01:00.02]花开就一次成熟　我却错过\r\n[01:09.87]\r\n[01:09.88]谁在用琵琶弹奏　一曲东风破\r\n[01:16.52]岁月在墙上剥落　看见小时候\r\n[01:23.13]犹记得那年我们都还很年幼\r\n[01:29.69]而如今琴声幽幽　我的等候你没听过\r\n[01:36.15]\r\n[01:36.16]谁在用琵琶弹奏　一曲东风破\r\n[01:42.80]枫叶将故事染色　结局我看透\r\n[01:49.38]篱笆外的古道我牵着你走过\r\n[01:55.97]荒烟蔓草的年头　就连分手都很沉默\r\n[02:28.81]\r\n[02:28.82]一壶漂泊　浪迹天涯难入喉\r\n[02:35.41]你走之后　酒暖回忆思念瘦\r\n[02:42.10]水向东流　时间怎么偷\r\n[02:48.70]花开就一次成熟　我却错过\r\n[02:58.63]\r\n[02:58.64]谁在用琵琶弹奏　一曲东风破\r\n[03:05.15]岁月在墙上剥落　看见小时候\r\n[03:11.74]犹记得那年我们都还很年幼\r\n[03:18.28]而如今琴声幽幽　我的等候你没听过\r\n[03:24.85]\r\n[03:24.86]谁在用琵琶弹奏　一曲东风破\r\n[03:31.39]枫叶将故事染色　结局我看透\r\n[03:38.00]篱笆外的古道我牵着你走过\r\n[03:44.57]荒烟蔓草的年头　就连分手都很沉默\r\n[03:51.17]\r\n[03:51.18]谁在用琵琶弹奏　一曲东风破\r\n[03:57.63]岁月在墙上剥落　看见小时候\r\n[04:04.29]犹记得那年我们都还很年幼\r\n[04:10.84]而如今琴声幽幽　我的等候你没听过\r\n[04:17.41]\r\n[04:17.42]谁在用琵琶弹奏　一曲东风破\r\n[04:24.01]枫叶将故事染色　结局我看透\r\n[04:30.68]篱笆外的古道我牵着你走过\r\n[04:37.17]荒烟蔓草的年头　就连分手都很沉默 ', 'music/东风破.mp3', 1, 9, 'video/东风破.mp4');
INSERT INTO `songs` VALUES (3, 1, '夜曲', 'song/夜曲.jpg', '[ti:夜曲]  \r\n[ar:周杰伦]  \r\n[00:00.00]夜曲  \r\n[00:01.00]作词：方文山　作曲：周杰伦　编曲：林迈可  \r\n[00:03.00]演唱：周杰伦  \r\n[00:05.00]专辑：十一月的萧邦  \r\n[00:07.00]  \r\n[00:13.86]一群嗜血的蚂蚁　被腐肉所吸引  \r\n[00:20.44]我面无表情　看孤独的风景  \r\n[00:26.99]失去你　爱恨开始分明  \r\n[00:33.60]失去你　还有什么事好关心  \r\n[00:40.15]  \r\n[00:40.16]当鸽子不再象征和平　我终于被提醒  \r\n[00:46.73]广场上喂食的是秃鹰  \r\n[00:53.29]我用漂亮的押韵　形容被掠夺一空的爱情  \r\n[01:03.12]  \r\n[01:03.13]啊　乌云开始遮蔽　夜色不干净  \r\n[01:09.71]公园里　葬礼的回音　在漫天飞行  \r\n[01:16.28]送你的　白色玫瑰　在纯黑的环境凋零  \r\n[01:22.85]乌鸦在树枝上诡异的很安静  \r\n[01:29.42]  \r\n[01:29.43]静静　听我黑色的大衣　想温暖你  \r\n[01:36.04]日渐冰冷的回忆　走过的　走过的　生命  \r\n[01:42.62]啊　四周弥漫雾气　我在空旷的墓地  \r\n[01:49.19]老去后还爱你  \r\n[01:58.98]  \r\n[01:58.99]为你弹奏萧邦的夜曲　纪念我死去的爱情  \r\n[02:05.57]跟夜风一样的声音　心碎的很好听  \r\n[02:12.14]手在键盘敲很轻　我给的思念很小心  \r\n[02:18.71]你埋葬的地方叫幽冥  \r\n[02:25.27]  \r\n[02:25.28]为你弹奏萧邦的夜曲　纪念我死去的爱情  \r\n[02:31.91]而我为你隐姓埋名　在月光下弹琴  \r\n[02:38.50]对你心跳的感应　还是如此温热亲近  \r\n[02:45.09]怀念你那鲜红的唇印  \r\n[02:58.80]  \r\n[02:58.81]那些断翅的蜻蜓　散落在这森林  \r\n[03:05.40]而我的眼睛　没有丝毫同情  \r\n[03:11.97]失去你　泪水混浊不清  \r\n[03:18.53]失去你　我连笑容都有阴影  \r\n[03:25.10]  \r\n[03:25.11]风在长满青苔的屋顶　嘲笑我的伤心  \r\n[03:31.69]像一口没有水的枯井  \r\n[03:38.24]我用凄美的字型　描绘后悔莫及的那爱情  \r\n[03:48.08]  \r\n[03:48.09]为你弹奏萧邦的夜曲　纪念我死去的爱情  \r\n[03:54.66]跟夜风一样的声音　心碎的很好听  \r\n[04:01.23]手在键盘敲很轻　我给的思念很小心  \r\n[04:07.83]你埋葬的地方叫幽冥  \r\n[04:14.38]  \r\n[04:14.39]为你弹奏萧邦的夜曲　纪念我死去的爱情  \r\n[04:21.00]而我为你隐姓埋名　在月光下弹琴  \r\n[04:27.58]对你心跳的感应　还是如此温热亲近  \r\n[04:34.18]怀念你那鲜红的唇印  \r\n[04:40.75]  \r\n[04:40.76]一群嗜血的蚂蚁　被腐肉所吸引  \r\n[04:47.30]我面无表情　看孤独的风景  \r\n[04:53.87]失去你　爱恨开始分明  \r\n[05:00.45]失去你　还有什么事好关心  \r\n[05:07.02]  \r\n[05:07.03]当鸽子不再象征和平　我终于被提醒  \r\n[05:13.60]广场上喂食的是秃鹰  \r\n[05:20.18]我用漂亮的押韵　形容被掠夺一空的爱情', 'music/夜曲.mp3', 1, 8, 'video/夜曲.mp4');
INSERT INTO `songs` VALUES (4, 2, '无问', 'song/无问.jpg', '[ti:无问]  \r\n[ar:毛不易]  \r\n[00:00.00]无问  \r\n[00:01.00]作词：毛不易　作曲：毛不易　编曲：韦伟  \r\n[00:03.00]演唱：毛不易  \r\n[00:05.00]发行时间：2018-01-15  \r\n[00:07.00]备注：电影《无问西东》宣传曲  \r\n[00:09.00]  \r\n[00:16.88]你问风为什么托着候鸟飞翔  \r\n[00:23.49]却又吹得让他慌张  \r\n[00:29.99]你问雨为什么滋养万物生长  \r\n[00:36.59]却也湿透他的衣裳  \r\n[00:42.18]  \r\n[00:42.19]你问他为什么亲吻他的伤疤  \r\n[00:48.78]却又不能带他回家  \r\n[00:55.36]你问我为什么还是不敢放下  \r\n[01:01.95]明知听不到回答  \r\n[01:08.59]  \r\n[01:08.60]如果光已忘了要将前方照亮  \r\n[01:15.19]你会握着我的手吗  \r\n[01:21.79]如果路会通往不知名的地方  \r\n[01:28.40]你会跟我一起走吗  \r\n[01:34.00]  \r\n[01:34.01]一生太短 一瞬好长  \r\n[01:40.60]我们哭着醒来 又哭着遗忘  \r\n[01:47.20]幸好啊 你的手曾落在我肩膀  \r\n[01:56.99]  \r\n[01:57.00]就像空中漂浮的 渺小的 某颗尘土  \r\n[02:03.59]它到底 为什么 为什么 不肯停驻  \r\n[02:10.19]直到乌云散去 风雨落幕  \r\n[02:16.79]他会带你找到 光的来处  \r\n[02:23.38]  \r\n[02:23.39]就像手边落满了灰尘的 某一本书  \r\n[02:29.99]它可曾 单薄地 承载了 谁的酸楚  \r\n[02:36.59]尽管岁月无声 流向迟暮  \r\n[02:43.19]他会让你想起 你的归途  \r\n[02:50.79]  \r\n[03:12.79]如果光已忘了要将前方照亮  \r\n[03:19.39]你会握着我的手吗  \r\n[03:25.99]如果路会通往不知名的地方  \r\n[03:32.59]你会跟我一起走吗', 'music/无问.mp3', 2, 6, 'video/无问.mp4');
INSERT INTO `songs` VALUES (5, 2, '盛夏', 'song/盛夏.jpg', '[ti:盛夏]  \r\n[ar:毛不易]  \r\n[00:00.00]盛夏  \r\n[00:01.00]作词：毛不易　作曲：毛不易　编曲：赵兆 / 宋涛  \r\n[00:03.00]演唱：毛不易  \r\n[00:05.00]专辑：平凡的一天  \r\n[00:07.00]  \r\n[00:30.00]那是日落时候轻轻发出的叹息啊  \r\n[00:37.85]昨天已经走远了　明天该去哪啊  \r\n[00:45.62]相框里的那些闪闪发光的我们啊  \r\n[00:53.42]在夏天发生的事　你忘了吗  \r\n[01:01.42]  \r\n[01:01.43]铁道旁的老树下　几只乌鸦  \r\n[01:09.44]叫到嗓音沙哑　却再没人回答  \r\n[01:17.34]火车呼啸着驶过　驶过寂寞或繁华  \r\n[01:24.40]曾经年轻的人啊　也想我吗  \r\n[01:33.32]  \r\n[01:33.33]就回来吧　回来吧　有人在等你呢  \r\n[01:41.16]有人在等你说完那句说一半的话  \r\n[01:48.76]就别走了　留下吧　外面它太复杂  \r\n[01:57.34]多少次让你热泪盈眶却不敢流下  \r\n[02:26.97]  \r\n[02:26.98]铁道旁的老树下　几只乌鸦  \r\n[02:34.74]叫到嗓音沙哑　却再没人回答  \r\n[02:42.67]火车呼啸着驶过　驶过寂寞或繁华  \r\n[02:49.38]曾经年轻的人啊　也会想我吗  \r\n[02:58.36]  \r\n[02:58.37]就回来吧　回来吧　有人在等你呢  \r\n[03:07.10]有人在等你说完那句说一半的话  \r\n[03:13.91]就别走了　留下吧　外面它太复杂  \r\n[03:22.47]多少次让你热泪盈眶却不敢流下  \r\n[03:41.00]  \r\n[03:41.01]可时光啊　不听话　总催着人长大  \r\n[03:49.62]这一站到下一站旅途总是停不下  \r\n[03:56.50]就慢慢地　忘了吧　因为回不去啊  \r\n[04:05.13]这闭上眼睛就拥有了一切的盛夏', 'music/盛夏.mp3', 2, 1, 'video/盛夏.mp4');
INSERT INTO `songs` VALUES (6, 3, '泡沫', 'song/泡沫.jpg', '[ti:泡沫]  \r\n[ar:邓紫棋]  \r\n[00:00.00]泡沫  \r\n[00:01.00]词：G.E.M. 曲：G.E.M. 编曲：Lupo Groinig  \r\n[00:03.00]演唱：邓紫棋  \r\n[00:05.00]专辑：Xposed  \r\n[00:07.00]  \r\n[00:15.00]阳光下的泡沫　是彩色的  \r\n[00:19.00]就像被骗的我　是幸福的  \r\n[00:22.50]追究什么对错　你的谎言  \r\n[00:26.00]基于你还爱我  \r\n[00:32.50]  \r\n[00:33.00]美丽的泡沫　虽然一刹花火  \r\n[00:36.50]你所有承诺　虽然都太脆弱  \r\n[00:40.00]但爱像泡沫　如果能够看破　有什么难过  \r\n[00:50.00]  \r\n[00:53.50]早该知道泡沫　一触就破  \r\n[00:57.00]就像已伤的心　不胜折磨  \r\n[01:00.50]也不是谁的错　谎言再多  \r\n[01:04.00]基于你还爱我  \r\n[01:10.00]  \r\n[01:10.50]美丽的泡沫　虽然一刹花火  \r\n[01:14.00]你所有承诺　虽然都太脆弱  \r\n[01:17.50]爱本是泡沫　如果能够看破　有什么难过  \r\n[01:28.00]  \r\n[01:31.00]再美的花朵　盛开过就凋落  \r\n[01:34.50]再亮眼的星　一闪过就坠落  \r\n[01:38.00]爱本是泡沫　如果能够看破　有什么难过  \r\n[01:48.50]  \r\n[01:53.50]为什么难过　有什么难过  \r\n[02:00.50]为什么难过  \r\n[02:07.50]  \r\n[02:10.00]全都是泡沫　只一刹的花火  \r\n[02:13.50]你所有承诺　全部都太脆弱  \r\n[02:17.00]而你的轮廓　怪我没有看破　才如此难过  \r\n[02:27.50]  \r\n[02:30.50]相爱的把握　要如何再搜索  \r\n[02:34.00]相拥着寂寞　难道就不寂寞  \r\n[02:37.50]爱本是泡沫　怪我没有看破　才如此难过  \r\n[02:48.00]  \r\n[02:51.00]在雨下的泡沫　一触就破  \r\n[02:54.50]当初炽热的心　早已沉没  \r\n[02:58.00]说什么你爱我　如果骗我  \r\n[03:01.50]我宁愿你沉默', 'music/泡沫.mp3', 3, 3, 'video/泡沫.mp4');
INSERT INTO `songs` VALUES (7, 4, '舞娘', 'song/舞娘.jpg', '[ti:舞娘]\r\n[ar:蔡依林]\r\n[00:00.00]舞娘\r\n[00:02.28]作词：陈镇川　作曲：Miriam Nervo/Liv Nervo/Greg Kursten\r\n[00:04.49]演唱：蔡依林\r\n[00:06.79]\r\n[00:08.21]月光 放肆在染色的窗边\r\n[00:11.94]转眼 魔幻所有视觉\r\n[00:15.64]再一杯 那古老神秘恒河水\r\n[00:19.38]我镶在额头的猫眼 揭开了庆典\r\n[00:23.85]为爱囚禁数千年的关键\r\n[00:27.13]正诉说遗忘的爱恋\r\n[00:30.73]听所有喜悲系在我的腰间\r\n[00:34.65]让那些画面再出现 再回到从前\r\n[00:39.27]\r\n[00:42.63]旋转 跳跃 我闭著眼\r\n[00:46.62]尘嚣看不见 你沉醉了没\r\n[00:50.26]白雪 夏夜 我不停歇\r\n[00:54.20]模糊了年岁 时光的沙漏被我踩碎\r\n[00:58.76]\r\n[01:02.21]故事 刻画在旋转的指尖\r\n[01:05.77]是谁在痴痴的跟随\r\n[01:09.60]这一夜 那破旧皇宫的台阶\r\n[01:13.41]我忘情掉落的汗水 点亮了庆典\r\n[01:17.85]一层一层把我紧紧包围\r\n[01:21.10]我要让世界忘了睡\r\n[01:24.59]你的心事倒映在我的眉间\r\n[01:28.64]放弃的快乐都实现 难过都摧毁\r\n[01:33.17]\r\n[01:36.55]旋转 跳跃 我闭著眼\r\n[01:40.62]尘嚣看不见 你沉醉了没\r\n[01:44.34]白雪 夏夜 我不停歇\r\n[01:48.30]模糊了年岁 舞娘的喜悲没人看见\r\n[01:52.08]\r\n[02:04.80](旋转 旋转 旋转)\r\n[02:12.36](旋转 旋转 旋转)\r\n[02:19.82]所有喜悲写在我的眼前\r\n[02:23.37]让那些画面再出现 回到从前\r\n[02:29.39]\r\n[02:33.03]旋转 跳跃 我闭著眼\r\n[02:37.02]尘嚣看不见 你沉醉了没\r\n[02:40.81]白雪 夏夜 我不停歇\r\n[02:44.88]模糊了年岁 时光的沙漏被我踩碎\r\n[02:48.53]\r\n[02:56.32]模糊了年岁 舞娘的喜悲没人看见\r\n[03:02.37]END', 'music/舞娘.mp3', 4, 1, 'video/舞娘.mp4');
INSERT INTO `songs` VALUES (8, 4, '花蝴蝶', 'song/花蝴蝶.jpg', '[ti:花蝴蝶]\r\n[ar:蔡依林]\r\n[00:00.00]花蝴蝶\r\n[00:02.50]作词：严云农　作曲：阿沁(F.I.R)\r\n[00:05.00]演唱：蔡依林\r\n[00:07.50]\r\n[00:10.00]我是花蝴蝶 无论冬春夏秋\r\n[00:13.50]随时都最美 准备好了就出手\r\n[00:17.00]身上霓虹 晃呀晃也無辜\r\n[00:20.50]黑黃紅藍我全部都 有\r\n[00:24.00]\r\n[00:26.50]金煌煌 閃呀閃呀閃金光\r\n[00:30.00]我讓世界 變得五彩斑斕\r\n[00:33.50]花蝴蝶 飛呀飛呀飛過山\r\n[00:37.00]我讓美夢 隨風飄到遠方\r\n[00:40.50]\r\n[00:43.00]我愛自己 愛自己最真\r\n[00:46.50]我愛自己 愛自己最美\r\n[00:50.00]我愛自己 無論冬春夏秋\r\n[00:53.50]隨時都最美 準備好了就出手\r\n[00:57.00]\r\n[01:00.50]從不在乎 路上的冷風 繞遠路途\r\n[01:04.00]冷酷 就來自我一種幸福\r\n[01:07.50]抓一把夢 想 用力繡在 翅膀上舞動\r\n[01:11.00]破曉前的等待像重磅狙擊手\r\n[01:14.50]懷疑的心跳聲 尋找確定的回音\r\n[01:18.00]等愛來肯定 心情自由沒停空過秒針\r\n[01:21.50]我準備好了就出動\r\n[01:25.00]\r\n[01:27.50]金煌煌 閃呀閃呀金光煌\r\n[01:31.00]我讓世界 變得五彩斑斕\r\n[01:34.50]花蝴蝶 飛呀飛呀飛過山\r\n[01:38.00]我讓美夢 隨風飄到遠方\r\n[01:41.50]\r\n[01:44.00]我愛自己 我愛自己最美\r\n[01:47.50]我愛自己 我永遠不後悔\r\n[01:51.00]我愛自己 我永遠都最美\r\n[01:54.50]我永遠都是 最美的花蝴蝶\r\n[01:58.00]\r\n[02:00.50]這一刻我揮著翅膀向全世界宣戰\r\n[02:07.50]\r\n[02:10.00]挑戰你心中的 未知的極限\r\n[02:13.50]蛻變後 你別想 找到我的軌跡\r\n[02:17.00]越挫越勇的我 花蝴蝶飛舞的飄逸\r\n[02:20.50]Yeah yeah 不管暴風雨來臨 愛戀依舊放晴 Yeah\r\n[02:24.00]\r\n[02:26.50]看我的千變萬化 看我的翻雲覆雨手\r\n[02:30.00]這迷人的蝴蝶 花都為之開放\r\n[02:33.50]不信賴不逃開不做作我的心始終等待\r\n[02:37.00]未來的路上只跟自己比賽 Hey Hey Hey Hey Hey Hey\r\n[02:40.50]\r\n[02:43.00]飛舞花叢的花蝴蝶 請把愛情的軌跡\r\n[02:46.50]重繪一個燦爛耀眼的結局\r\n[02:50.00]來世的你如果 也記得今生誓言\r\n[02:53.50]眼神的對決是 一場試煉\r\n[02:57.00]要穿越幾世紀的纏綿看 誰的影子跟著花蝴蝶翩遷\r\n[03:00.50]揮動七彩羽翼盤旋 而你是我一生追尋的唯一停歇\r\n[03:04.00]\r\n[03:06.50]我愛自己 我永遠不後悔\r\n[03:10.00]我永遠都是 最美的花蝴蝶\r\n[03:13.50]END', 'music/花蝴蝶.mp3', 4, 0, 'video/花蝴蝶.mp4');

-- ----------------------------
-- Table structure for swipers
-- ----------------------------
DROP TABLE IF EXISTS `swipers`;
CREATE TABLE `swipers`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '标题',
  `pic` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '轮播图片',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of swipers
-- ----------------------------
INSERT INTO `swipers` VALUES (1, 'focus1', 'swiper_pic/focus1.jpg');
INSERT INTO `swipers` VALUES (2, 'focus2', 'swiper_pic/focus2.jpg');
INSERT INTO `swipers` VALUES (3, 'focus3', 'swiper_pic/focus3.jpg');
INSERT INTO `swipers` VALUES (4, 'focus4', 'swiper_pic/focus4.jpg');
INSERT INTO `swipers` VALUES (5, 'focus5', 'swiper_pic/focus5.jpg');

-- ----------------------------
-- Table structure for user_clicks
-- ----------------------------
DROP TABLE IF EXISTS `user_clicks`;
CREATE TABLE `user_clicks`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '用户ID',
  `song_id` int NOT NULL COMMENT '歌曲ID',
  `click_num` int NULL DEFAULT 0 COMMENT '点击次数',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_clicks
-- ----------------------------
INSERT INTO `user_clicks` VALUES (1, 1, 1, 17);
INSERT INTO `user_clicks` VALUES (2, 1, 2, 2);
INSERT INTO `user_clicks` VALUES (3, 1, 3, 3);
INSERT INTO `user_clicks` VALUES (4, 1, 7, 1);
INSERT INTO `user_clicks` VALUES (5, 1, 6, 3);

SET FOREIGN_KEY_CHECKS = 1;
