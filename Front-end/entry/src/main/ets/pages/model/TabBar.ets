export interface  TabBarModel{
  title: string,
  name: string,
  icon: ResourceStr
}

export const tabsData: TabBarModel[] = [
  {
    title: "首页",
    name: "Home",
    icon: $r("app.media.ic_home")
  },
  {
    title: "排行",
    name: "Rank",
    icon: $r("app.media.ic_rank")
  },
  {
    title: "漫游",
    name: "Player",
    icon: $r("app.media.ic_wander")
  },
  {
    title: "我的",
    name: "Mine",
    icon: $r("app.media.ic_mine")
  }
]

export interface SearchTab
{
  title: string,
  name: string
}

export const SearchTabData: SearchTab[] = [
  {
    title: "歌曲",
    name: "Song"
  },
  {
    title: "歌手",
    name: "Singer"
  },
  {
    title: "歌单",
    name: "Song_list"
  },
  {
    title: "专辑",
    name: "Album"
  }
]