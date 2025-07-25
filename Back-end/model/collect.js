module.exports = (sequelize, DataTypes) => {
    const collect = sequelize.define("collect",
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
      }
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
    return collect;
};