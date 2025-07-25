import preferencesUtil from "../common/PreferencesUtil"
import { SongModel } from "../model/AppModel"
import { getSongByName } from "../common/Api"

class SongHistoriesService {
  // 通过歌曲名称获取完整歌曲信息
  private async getSongInfoByName(songName: string): Promise<SongModel | null> {
    try {
      const response = await getSongByName(songName)
      if (response.success && response.data) {
        return (Array.isArray(response.data) ? response.data[0] : response.data) as SongModel
      } else {
        console.error('获取歌曲信息失败:', response.message)
        return null
      }
    } catch (error) {
      console.error('请求歌曲信息时出错:', error)
      return null
    }
  }

  // 添加歌曲到用户历史记录（通过歌曲名称）
  async addSongHistoryByName(userId: number, songName: string): Promise<boolean> {
    try {
      // 先通过 API 获取完整歌曲信息
      const songInfo = await this.getSongInfoByName(songName)
      if (!songInfo) {
        console.error(`无法获取歌曲 "${songName}" 的信息`)
        return false
      }

      // 添加到历史记录
      return await this.addSongHistory(userId, songInfo)
    } catch (error) {
      console.error('通过歌曲名称添加历史失败:', error)
      return false
    }
  }

  // 添加歌曲到用户历史记录（直接使用 Song 对象）
  async addSongHistory(userId: number, songInfo: SongModel): Promise<boolean> {
    try {
      const storeName = "SongHistoriesStore"
      const key = `user_${userId}`

      // 获取当前用户的历史记录
      let historyData = await preferencesUtil.get(storeName, key, "")
      let historyList: SongModel[] = []

      if (historyData.toString() !== "") {
        historyList = JSON.parse(historyData.toString())
      }

      // 检查歌曲是否已存在，如果存在则删除旧记录
      const existingIndex = historyList.findIndex(item => item.id === songInfo.id)
      if (existingIndex > -1) {
        historyList.splice(existingIndex, 1)
      }

      // 将新歌曲添加到列表开头
      historyList.unshift(songInfo)

      // 保持最多10条记录
      if (historyList.length > 10) {
        historyList.length = 10
      }

      // 保存更新后的历史记录
      await preferencesUtil.set(storeName, key, JSON.stringify(historyList))
      console.log(`用户 ${userId} 的歌曲历史已更新:`, songInfo.name)
      return true
    } catch (error) {
      console.error('添加歌曲历史失败:', error)
      return false
    }
  }

  // 获取用户的歌曲历史记录
  async getUserSongHistory(userId: number): Promise<SongModel[]> {
    try {
      const storeName = "SongHistoriesStore"
      const key = `user_${userId}`

      let historyData = await preferencesUtil.get(storeName, key, "")
      if (historyData.toString() !== "") {
        return JSON.parse(historyData.toString())
      } else {
        return []
      }
    } catch (error) {
      console.error('获取歌曲历史失败:', error)
      return []
    }
  }

  // 删除用户历史记录中的特定歌曲
  async removeSongFromHistory(userId: number, songId: number): Promise<boolean> {
    try {
      const storeName = "SongHistoriesStore"
      const key = `user_${userId}`

      let historyData = await preferencesUtil.get(storeName, key, "")
      if (historyData.toString() !== "") {
        let historyList: SongModel[] = JSON.parse(historyData.toString())
        historyList = historyList.filter(item => item.id !== songId)

        await preferencesUtil.set(storeName, key, JSON.stringify(historyList))
        console.log(`用户 ${userId} 删除了歌曲 ${songId} 的历史记录`)
        return true
      }
      return false
    } catch (error) {
      console.error('删除歌曲历史失败:', error)
      return false
    }
  }

  // 清空用户的所有歌曲历史记录
  async clearUserSongHistory(userId: number): Promise<boolean> {
    try {
      const storeName = "SongHistoriesStore"
      const key = `user_${userId}`

      await preferencesUtil.set(storeName, key, "")
      console.log(`用户 ${userId} 的歌曲历史已清空`)
      return true
    } catch (error) {
      console.error('清空歌曲历史失败:', error)
      return false
    }
  }

  // 检查歌曲是否在用户历史记录中
  async isSongInHistory(userId: number, songId: number): Promise<boolean> {
    try {
      const historyList = await this.getUserSongHistory(userId)
      return historyList.some(song => song.id === songId)
    } catch (error) {
      console.error('检查歌曲历史失败:', error)
      return false
    }
  }
}

const songHistoriesService = new SongHistoriesService()

export default songHistoriesService