module.exports = (sequelize, DataTypes) => {
    const song_list = sequelize.define("song_list",
      {
      id: {
        type: DataTypes.INTEGER(10),
        primaryKey: true,
        autoIncrement: true,
      },
      name: {
        type: DataTypes.STRING(100),
        allowNull: false,
        comment: "歌单名称",
      },
      pic: {
        type: DataTypes.STRING(255),
        comment: "歌单封面",
      },
      introduction: {
        type: DataTypes.TEXT,
        comment: "歌单简介",
      },
      style: {
        type: DataTypes.STRING(100),
        comment: "风格",
      },
      user_id: {
        type: DataTypes.INTEGER(10),
        allowNull: false,
        comment: "创建用户ID",
      },
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
    return song_list;
  };