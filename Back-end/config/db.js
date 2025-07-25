module.exports = {
  database: 'music_player', // 数据库名称
  username: 'root',       // 用户名
  password: '200509',     // 密码
  option: {
    dialect: 'mysql',     // 使用 MySQL
    host: 'localhost',    // 修改为 localhost
    port: 3306,           // 明确指定端口
    charset: 'utf8mb4'    // 字符编码
  }
}