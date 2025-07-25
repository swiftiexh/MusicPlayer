module.exports = (sequelize, DataTypes) => {
    const album = sequelize.define("album",
      {
      id: {
        type: DataTypes.INTEGER(10),
        primaryKey: true,
        autoIncrement: true,
      },
      name: {
        type: DataTypes.STRING(100),
        allowNull: false,
        comment: "专辑名称",
      },
      year: {
        type: DataTypes.STRING(10),
        comment: "发行年份",
      },
      singer_id: {
        type: DataTypes.INTEGER(10),
        allowNull: false,
        comment: "歌手ID",
      },
      introduction: {
        type: DataTypes.TEXT,
        comment: "专辑简介",
      },
      pic: {
        type: DataTypes.STRING(255),
        comment: "专辑封面",
      },
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
    return album;
  };