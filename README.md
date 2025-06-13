# 🛠️ OpenWrt 智能编译工具

> 基于 GitHub Actions 的可视化 OpenWrt 固件编译平台，让固件编译变得简单高效！

## ✨ 项目特色

- 🎯 **可视化配置** - 通过Web界面轻松选择设备和插件
- 🚀 **智能编译** - 基于GitHub Actions云端编译，无需本地环境
- 🔍 **冲突检测** - 自动检测插件冲突和依赖关系
- 📊 **实时监控** - 编译进度实时反馈和日志查看
- 🌐 **多源支持** - 支持官方OpenWrt、Lean's LEDE、ImmortalWrt等源码
- 📱 **响应式设计** - 完美适配桌面和移动设备

## 🚀 快速开始

### 1. Fork 本项目

点击右上角的 `Fork` 按钮，将项目复制到你的GitHub账户下。

### 2. 启用 GitHub Actions

1. 进入你Fork的项目
2. 点击 `Actions` 标签页
3. 如果提示启用工作流，点击 `I understand my workflows, go ahead and enable them`

### 3. 配置项目设置

在项目的 `js/config-data.js` 文件中修改以下配置：

```javascript
// 替换为你的GitHub仓库信息
const GITHUB_REPO = 'your-username/your-repo-name';
```

### 4. 开始使用

1. 访问 GitHub Pages 部署的网站（通常是 `https://your-username.github.io/your-repo-name`）
2. 或者直接打开 `index.html` 文件
3. 按照向导选择源码、设备和插件
4. 点击开始编译

## 📋 支持的源码分支

| 源码 | 描述 | 推荐用途 |
|------|------|----------|
| **OpenWrt 官方** | 最新稳定版本，兼容性最好 | 新手用户、稳定使用 |
| **Lean's LEDE** | 国内热门分支，集成大量插件 | 中国用户、功能丰富 |
| **ImmortalWrt** | 增强版官方固件 | 平衡稳定性和功能 |

## 🎯 支持的设备

### 路由器设备
- 小米路由器4A千兆版
- 新路由3 (Newifi D2)
- 斐讯K2P
- 华硕AC68U
- 网件R7800
- 领势WRT3200ACM

### ARM设备
- 树莓派4B
- NanoPi R2S
- Orange Pi Zero

### X86设备
- 虚拟机 (VMware/VirtualBox)
- 软路由/工控机
- X86迷你主机

## 🔧 功能插件

### 🔐 网络代理
- **SSR Plus+** - ShadowsocksR代理工具
- **PassWall** - 多协议代理，智能分流
- **OpenClash** - Clash客户端，规则订阅
- **WireGuard** - 现代VPN协议
- **ZeroTier** - 虚拟局域网

### 🌐 网络工具  
- **AdGuard Home** - DNS广告拦截
- **AdByby Plus+** - 广告过滤
- **动态DNS** - 域名解析服务
- **UPnP** - 端口自动映射
- **多线负载均衡** - 多WAN支持

### ⚙️ 系统管理
- **Docker CE** - 容器服务
- **TTYD终端** - Web终端访问
- **网络唤醒** - 远程开机
- **带宽监控** - 流量统计

### 🎵 多媒体服务
- **Aria2** - 多线程下载
- **Transmission** - BT下载
- **Samba** - 文件共享
- **DLNA服务器** - 媒体流

## 🔍 智能冲突检测

系统会自动检测以下类型的冲突：

- **互斥插件** - 功能重复的插件不能同时选择
- **依赖关系** - 自动检查插件依赖
- **存储限制** - 根据设备存储容量提醒
- **架构兼容性** - 检查插件是否支持目标设备

## 📊 编译监控

编译过程中可以实时查看：

- 📈 **编译进度** - 百分比进度条显示
- 📝 **实时日志** - 详细的编译日志输出  
- ⏱️ **耗时统计** - 编译开始和结束时间
- 📦 **产物信息** - 固件大小和文件列表

## 🛠️ 项目结构

```
openwrt-smart-builder/
├── index.html              # 主页面
├── css/
│   └── style.css           # 样式文件
├── js/
│   ├── config-data.js      # 配置数据
│   ├── wizard.js           # 向导逻辑
│   └── builder.js          # 编译控制
├── .github/
│   └── workflows/
│       └── smart-build.yml # 编译工作流
└── README.md              # 项目说明
```

## ⚙️ 高级配置

### 自定义插件源

可以添加自定义的Git插件源：

```
https://github.com/your-username/your-openwrt-packages
```

### 编译选项

支持以下编译优化选项：

- **体积优化** - 适合存储有限的设备
- **性能优化** - 适合高性能设备  
- **调试版本** - 包含调试信息

### 设备特定配置

针对不同设备类型自动应用相应配置：

- **X86设备** - 启用EFI、VDI、VMDK镜像
- **ARM设备** - 优化ARM架构特性
- **路由器** - 预配置无线和网络设置

## 🔧 故障排除

### 编译失败

1. **检查配置冲突** - 使用内置冲突检测
2. **减少插件数量** - 避免选择过多插件
3. **选择稳定源码** - 推荐使用官方OpenWrt源码
4. **查看编译日志** - 根据错误信息调整配置

### GitHub Actions配额

- 免费账户每月有2000分钟的运行时间
- 编译通常需要1-3小时
- 建议合理安排编译频率

### 固件刷写

⚠️ **刷机有风险，请谨慎操作**

1. 确认设备型号和硬件版本
2. 备份原厂固件
3. 确保有救砖方法
4. 建议先在虚拟机测试

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 添加新设备支持

1. 在 `js/config-data.js` 中添加设备信息
2. 在编译工作流中添加设备配置映射
3. 测试编译流程

### 添加新插件

1. 在插件数据库中添加插件信息
2. 配置依赖关系和冲突规则
3. 更新说明文档

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。

## 🙏 致谢  

- [OpenWrt](https://openwrt.org/) - 开源路由器固件项目
- [Lean's LEDE](https://github.com/coolsnowwolf/lede) - 国内OpenWrt分支
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) - OpenWrt增强版
- [GitHub Actions](https://github.com/features/actions) - 自动化构建服务

## 📞 联系我们

- 🐛 [提交Bug](https://github.com/your-username/your-repo/issues)
- 💡 [功能建议](https://github.com/your-username/your-repo/discussions)
- 📖 [使用文档](https://github.com/your-username/your-repo/wiki)

---

⭐ 如果这个项目对你有帮助，请给一个星星支持！