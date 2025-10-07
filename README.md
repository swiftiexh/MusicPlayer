# 基于鸿蒙与 AI 智能助手的音乐 App

> **HarmonyOS + AI 智能助手 + 全栈开发实训项目**

本项目是一个基于 **鸿蒙系统（HarmonyOS）** 与 **AI 智能助手** 的音乐应用，旨在为用户提供一个集音乐播放、个性化推荐、社交互动和跨设备协同于一体的综合性音乐平台。项目由中软国际教育科技集团指导开发，涵盖了从前端到后端再到数据库的完整开发流程。

---

## 📱 项目简介

随着移动互联网和智能设备的普及，音乐应用成为人们日常生活的重要组成部分。本项目结合鸿蒙系统的分布式特性与 AI 技术，打造出智能化、个性化的音乐体验平台，主要功能包括：

* 🎵 音乐播放与歌单管理
* 💬 登录、评论、收藏、评分等社交互动
* 🤖 AI 语音识别搜索


---

## 🧩 技术栈

| 模块    | 技术                                      |
| ----- | --------------------------------------- |
| 前端    | HarmonyOS ArkTS、ArkUI、TypeScript、声明式 UI |
| 后端    | Node.js、Koa 框架           |
| 数据库   | MySQL                                   |

---

## 📂 项目结构

```
📦 Project-Name
├── Font-end/           # 前端代码（HarmonyOS ArkTS 实现）
│   └── ...          # 略
│
├── Back-end/           # 后端服务（Node.js + Koa）
│   ├── routes/         # 路由定义
│   ├── controller/    # 控制器逻辑
│   ├── model/         # 数据库模型定义
|   ├── ...
│   └── app.js          # 主服务入口
|   
│
└── Database/           # 数据库初始化脚本
    └──  music_player.sql        # 数据表与基础数据初始化
```

---

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/swiftiexh/MusicPlayer.git
cd MusicPlayer
```

### 2. 数据库初始化

```bash
cd Database
mysql -u root -p < music_player.sql
```

### 3. 启动后端服务

```bash
cd Back-end
npm install
npm start
```

### 4. 运行前端项目（DevEco Studio）

1. 打开 `Font-end` 文件夹
2. 使用 DevEco Studio 导入项目
3. 连接模拟器或真机运行

---

## 🤝 实训背景

本项目由 **中软国际教育科技集团（ETC）** 与 **南开大学计算机学院** 联合实训，主题为《基于鸿蒙与AI智能助手的音乐App的设计与开发》。

### 实训目标：

* 掌握鸿蒙系统开发流程与 ArkTS 编程范式
* 理解前后端分离架构及数据库设计
* 掌握 AI 智能助手（语音/图像识别）的集成方法
* 提升项目管理、团队协作与创新能力

---

## 🏆 致谢

感谢中软国际提供的实训机会与指导支持。
感谢所有团队成员在开发中的努力与创新。

---

> © 2025 中软国际 & 南开大学实训项目. All rights reserved.
