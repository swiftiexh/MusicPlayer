module.exports = (sequelize, DataTypes) => {
    const comment = sequelize.define("comment", 
      {
      id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      user_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: "用户ID",
      },
      song_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: "歌曲ID",
      },
      content: {
        type: DataTypes.TEXT,
        allowNull: false,
        comment: "评论内容",
      },
      up: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        comment: "回复的评论id",
      },
      create_time: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        comment: "创建时间",
      }
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
    return comment;
  };