module.exports = (sequelize, DataTypes) => {
    const user_click = sequelize.define("user_click", 
      {
      id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
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
      click_num: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        comment: "点击次数",
      }
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
    );
    return user_click;
  };