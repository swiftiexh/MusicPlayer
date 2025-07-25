module.exports = (sequelize, DataTypes) => {
    const consumer = sequelize.define("consumer",
       {
      id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      username: {
        type: DataTypes.STRING(50),
        allowNull: false,
        comment: "用户名",
      },
      password: {
        type: DataTypes.STRING(255),
        allowNull: false,
        comment: "密码",
      },
      sex: {
        type: DataTypes.STRING(10),
        comment: "性别",
      },
      phone_num: {
        type: DataTypes.STRING(20),
        comment: "手机号",
      },
      birth: {
        type: DataTypes.STRING(50),
        comment: "生日",
      },
      location: {
        type: DataTypes.STRING(100),
        comment: "地址",
      },
      avatar: {
        type: DataTypes.STRING(255),
        comment: "头像",
      }
    }
      ,
      {
        timestamps: false  // 禁用 createdAt 和 updatedAt
      }
  );
    return consumer;
  };