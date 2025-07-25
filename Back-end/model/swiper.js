module.exports = (sequelize, DataTypes) => {
    const swiper = sequelize.define("swiper",
      {
      id: {
        type: DataTypes.INTEGER(10),
        primaryKey: true,
        autoIncrement: true,
      },
      title: {
        type: DataTypes.STRING(100),
        comment: "标题",
      },
      pic: {
        type: DataTypes.STRING(255),
        comment: "轮播图片",
      }
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
  
    return swiper;
  };