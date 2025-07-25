const jwt = require('jsonwebtoken');
const { cloneDeep } = require('sequelize/lib/utils');
// token 加密(生成)-jwt.sign()
exports.generateToken = async (user,expiresIn=24*60*60) => {
    // 1. 用户对象信息， 2. 加密字符串'secret'， 3. 过期时间
    const token = await jwt.sign(user,'secret',{expiresIn})
    return token
}

// token 解密-jwt.verify()
exports.verifyToken = (required = true) => {
    return async (ctx, next) => {
        const token = ctx.header.authorization;
        if (token) {
           try{
            //现在开始解密token
            const user = await jwt.verify(token,'secret')
            ctx.user = user
            await next() //  token 验证成功，继续执行下一个中间件
           }catch(err){
               ctx.body = {code:801,message:'token已过期'};
               return; //  验证失败，直接返回，不继续执行
           }
        }else if(required){
            ctx.body = {code:802,message:'token不存在'};
            return; // 必须要 token 但没有提供，返回错误，不继续执行
        }else {
            // 不需要 token 验证，继续执行下一个中间件
            await next();
        }
    }
}