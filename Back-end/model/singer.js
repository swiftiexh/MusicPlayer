module.exports = (sequelize, DataTypes) => {
    const singer = sequelize.define("singer",
      {
      id: {
        type: DataTypes.INTEGER(10),
        primaryKey: true,
        autoIncrement: true,
      },
      name: {
        type: DataTypes.STRING(50),
        allowNull: false,
        comment: "歌手名称",
      },
      sex: {
        type: DataTypes.STRING(10),
        comment: "性别",
      },
      pic: {
        type: DataTypes.STRING(255),
        comment: "头像",
      },
      region: {
        type: DataTypes.STRING(50),
        comment: "地区",
      },
      introduction: {
        type: DataTypes.TEXT,
        comment: "简介",
      },
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
    return singer;
  };