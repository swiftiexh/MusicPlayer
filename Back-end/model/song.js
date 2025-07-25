module.exports = (sequelize, DataTypes) => {
    const song = sequelize.define("song",
      {
      id: {
        type: DataTypes.INTEGER(10),
        primaryKey: true,
        autoIncrement: true,
      },
      singer_id: {
        type: DataTypes.INTEGER(10),
        allowNull: false,
        comment: "歌手ID",
      },
      name: {
        type: DataTypes.STRING(100),
        allowNull: false,
        comment: "歌曲名称",
      },
      pic: {
        type: DataTypes.STRING(255),
        comment: "歌曲封面",
      },
      lyric: {
        type: DataTypes.TEXT,
        comment: "歌词",
      },
      url: {
        type: DataTypes.STRING(255),
        comment: "歌曲链接",
      },
       video_url: {
        type: DataTypes.STRING(255),
        comment: "视频链接",
      },
      album_id: {
        type: DataTypes.INTEGER(10),
        comment: "专辑ID",
      },
      click_num: {
        type: DataTypes.INTEGER(10),
        defaultValue: 0,
        comment: "点击次数",
      },
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );  
    return song;
  };