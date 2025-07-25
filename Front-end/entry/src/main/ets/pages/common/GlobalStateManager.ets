import preferencesUtil from './PreferencesUtil'
import { Consumer } from '../model/AppModel'

// 全局状态初始化工具
export class GlobalStateManager {
  private static initialized: boolean = false

  // 初始化全局状态，确保所有组件都能正确读取登录状态
  static async initializeGlobalState(): Promise<void> {
    if (GlobalStateManager.initialized) {
      return
    }

    try {
      // 初始化PersistentStorage
      PersistentStorage.PersistProp('isLoggedIn', false)
      PersistentStorage.PersistProp('currentUser', null)
      PersistentStorage.PersistProp('userToken', '')

      // 检查并恢复登录状态
      const token = await preferencesUtil.get("userinfoStore", "token", "") as string
      const userInfoStr = await preferencesUtil.get("userinfoStore", "userInfo", "") as string
      const isLoggedIn = await preferencesUtil.get("userinfoStore", "isLoggedIn", false) as boolean

      if (token && userInfoStr && isLoggedIn) {
        // 恢复登录状态
        const userInfo = JSON.parse(userInfoStr) as Consumer
        AppStorage.SetOrCreate('isLoggedIn', true)
        AppStorage.SetOrCreate('currentUser', userInfo)
        AppStorage.SetOrCreate('userToken', token)

        PersistentStorage.PersistProp('isLoggedIn', true)
        PersistentStorage.PersistProp('currentUser', userInfo)
        PersistentStorage.PersistProp('userToken', token)

        console.log('登录状态已恢复:', userInfo.username)
      } else {
        // 确保未登录状态
        AppStorage.SetOrCreate('isLoggedIn', false)
        AppStorage.SetOrCreate('currentUser', null)
        AppStorage.SetOrCreate('userToken', '')

        PersistentStorage.PersistProp('isLoggedIn', false)
        PersistentStorage.PersistProp('currentUser', null)
        PersistentStorage.PersistProp('userToken', '')

        console.log('未登录状态')
      }

      GlobalStateManager.initialized = true
      console.log('全局状态初始化完成')
    } catch (error) {
      console.error('初始化全局状态失败:', error)
    }
  }

  // 重置全局状态（用于调试）
  static resetInitialized(): void {
    GlobalStateManager.initialized = false
  }
}
