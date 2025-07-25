module.exports = (sequelize, DataTypes) => {
    const song_to_list = sequelize.define("song_to_list",
      {
      id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      song_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: "歌曲ID",
      },
      list_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: "歌单ID",
      }
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
    return song_to_list;
};