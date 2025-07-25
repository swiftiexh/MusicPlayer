// 1.引入模块 
const Koa = require('koa')
const app = new Koa()
const views = require('koa-views')
const json = require('koa-json')
const onerror = require('koa-onerror')
const bodyparser = require('koa-bodyparser')
const logger = require('koa-logger')

// 2.路由（重要）
const index = require('./routes/index')
require('./model/index.js')

// 3.错误处理中间件（捕获程序错误）
onerror(app)

// 4.注册中间件（middleware）
app.use(bodyparser({
  enableTypes:['json', 'form', 'text']
}))
app.use(json())
app.use(logger())
// *静态资源（重要）
app.use(require('koa-static')(__dirname + '/public'))

app.use(views(__dirname + '/views', {
  extension: 'pug'
}))

// 5.请求日志中间件（手动记录请求时间）
app.use(async (ctx, next) => {
  const start = new Date()
  await next()
  const ms = new Date() - start
  console.log(`${ctx.method} ${ctx.url} - ${ms}ms`)
})

// 6.注册路由
app.use(index.routes(), index.allowedMethods())

// 7.错误日志处理（全局监听错误）
app.on('error', (err, ctx) => {
  console.error('server error', err, ctx)
});

// 8. 模块导出
module.exports = app
