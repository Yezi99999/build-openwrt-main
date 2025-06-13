// OpenWrt配置数据和常量定义
// 请根据你的实际GitHub仓库信息修改以下配置
const GITHUB_REPO = 'your-username/your-repo-name'; // 替换为你的GitHub仓库名
const GITHUB_TOKEN = ''; // 可选：GitHub个人访问令牌，用于API调用

// 支持的设备列表
const DEVICE_DATA = {
  default: [
    {
      id: 'x86_64',
      name: 'X86 64位',
      description: '适用于虚拟机、软路由等X86设备',
      ram: '≥512MB',
      flash: '≥16MB',
      wireless: 'USB/PCIe',
      category: 'x86'
    },
    {
      id: 'raspberry-pi-4',
      name: '树莓派 4B',
      description: 'Raspberry Pi 4 Model B',
      ram: '1GB-8GB',
      flash: 'SD卡',
      wireless: '2.4G/5G',
      category: 'arm'
    },
    {
      id: 'xiaomi-4a-gigabit',
      name: '小米路由器4A千兆版',
      description: 'Mi Router 4A Gigabit Edition',
      ram: '128MB',
      flash: '16MB',
      wireless: '2.4G/5G',
      category: 'router'
    },
    {
      id: 'newifi-d2',
      name: '新路由3 (Newifi D2)',
      description: 'Lenovo Newifi D2',
      ram: '512MB',
      flash: '32MB',
      wireless: '2.4G/5G',
      category: 'router'
    },
    {
      id: 'phicomm-k2p',
      name: '斐讯K2P',
      description: 'Phicomm K2P A1/A2',
      ram: '128MB',
      flash: '16MB',
      wireless: '2.4G/5G',
      category: 'router'
    },
    {
      id: 'linksys-wrt3200acm',
      name: 'Linksys WRT3200ACM',
      description: 'Linksys WRT3200ACM 无线路由器',
      ram: '512MB',
      flash: '256MB',
      wireless: '2.4G/5G',
      category: 'router'
    },
    {
      id: 'netgear-r7800',
      name: 'Netgear R7800',
      description: 'Netgear Nighthawk X4S R7800',
      ram: '512MB',
      flash: '128MB',
      wireless: '2.4G/5G',
      category: 'router'
    },
    {
      id: 'asus-ac68u',
      name: '华硕AC68U',
      description: 'ASUS RT-AC68U 无线路由器',
      ram: '256MB',
      flash: '128MB',
      wireless: '2.4G/5G',
      category: 'router'
    },
    {
      id: 'orange-pi-zero',
      name: 'Orange Pi Zero',
      description: 'Orange Pi Zero 单板计算机',
      ram: '256MB-512MB',
      flash: 'SD卡',
      wireless: '2.4G WiFi',
      category: 'arm'
    },
    {
      id: 'nanopi-r2s',
      name: 'NanoPi R2S',
      description: 'FriendlyElec NanoPi R2S',
      ram: '1GB',
      flash: 'SD卡',
      wireless: 'USB',
      category: 'arm'
    }
  ]
};

// 插件数据库
const PLUGIN_DATA = {
  default: [
    // VPN和代理类
    {
      id: 'ssr-plus',
      name: 'SSR Plus+',
      description: 'ShadowsocksR Plus+ 科学上网工具，支持SS/SSR/V2ray等协议',
      category: 'vpn',
      size: '2MB',
      dependencies: ['libmbedtls', 'coreutils-base64'],
      tags: ['翻墙', '代理', '科学上网']
    },
    {
      id: 'passwall',
      name: 'PassWall',
      description: '科学上网插件，支持多种协议和智能分流',
      category: 'vpn', 
      size: '3MB',
      dependencies: ['unzip', 'dnsmasq-full'],
      tags: ['翻墙', '代理', '分流']
    },
    {
      id: 'openclash',
      name: 'OpenClash',
      description: 'Clash客户端，功能强大的代理工具，支持规则订阅',
      category: 'vpn',
      size: '5MB',
      dependencies: ['coreutils', 'bash'],
      tags: ['Clash', '代理', '规则']
    },
    {
      id: 'v2raya',
      name: 'V2rayA',
      description: 'V2ray的Web管理界面，简单易用',
      category: 'vpn',
      size: '3MB',
      dependencies: ['v2ray-core'],
      tags: ['V2ray', 'Web界面']
    },
    {
      id: 'wireguard',
      name: 'WireGuard VPN',
      description: '现代VPN协议，速度快、安全性高',
      category: 'vpn',
      size: '1MB',
      dependencies: ['kmod-wireguard'],
      tags: ['VPN', '加密']
    },
    {
      id: 'zerotier',
      name: 'ZeroTier',
      description: '全球虚拟局域网，内网穿透神器',
      category: 'vpn',
      size: '2MB',
      dependencies: [],
      tags: ['内网穿透', '虚拟网络']
    },

    // 网络工具类
    {
      id: 'adbyby-plus',
      name: 'AdByby Plus+',
      description: 'AD广告拦截插件，基于规则过滤',
      category: 'network',
      size: '1MB',
      dependencies: ['wget-ssl'],
      tags: ['广告拦截', '规则过滤']
    },
    {
      id: 'adguardhome',
      name: 'AdGuard Home',
      description: '全网广告拦截 DNS 服务器，功能强大',
      category: 'network',
      size: '8MB',
      dependencies: [],
      tags: ['DNS', '广告拦截', '家长控制']
    },
    {
      id: 'frpc',
      name: 'FRP 客户端',
      description: '内网穿透客户端，支持多种协议',
      category: 'network',
      size: '1MB',
      dependencies: [],
      tags: ['内网穿透', 'NAT']
    },
    {
      id: 'ddns',
      name: '动态DNS',
      description: '动态域名解析，支持多种DDNS服务商',
      category: 'network',
      size: '0.5MB',
      dependencies: [],
      tags: ['DDNS', '域名解析']
    },
    {
      id: 'upnp',
      name: 'UPnP',
      description: '通用即插即用协议支持',
      category: 'network',
      size: '0.5MB',
      dependencies: [],
      tags: ['UPnP', '端口映射']
    },
    {
      id: 'mwan3',
      name: '多线负载均衡',
      description: '多WAN口负载均衡和故障转移',
      category: 'network',
      size: '1MB',
      dependencies: [],
      tags: ['负载均衡', '多WAN']
    },

    // 系统管理类
    {
      id: 'docker',
      name: 'Docker CE',
      description: 'Docker容器管理，运行各种应用服务',
      category: 'system',
      size: '20MB',
      dependencies: ['containerd', 'runc'],
      tags: ['容器', '虚拟化']
    },
    {
      id: 'ttyd',
      name: 'TTYD终端',
      description: 'Web终端，通过浏览器访问命令行',
      category: 'system',
      size: '0.5MB',
      dependencies: [],
      tags: ['终端', 'Web界面']
    },
    {
      id: 'webadmin',
      name: 'WebAdmin',
      description: '高级系统管理界面',
      category: 'system',
      size: '2MB',
      dependencies: [],
      tags: ['系统管理', 'Web界面']
    },
    {
      id: 'wol',
      name: '网络唤醒',
      description: '局域网设备远程唤醒功能',
      category: 'system',
      size: '0.2MB',
      dependencies: [],
      tags: ['远程唤醒', 'WOL']
    },
    {
      id: 'nlbwmon',
      name: '网络带宽监控',
      description: '实时监控网络使用情况和流量统计',
      category: 'system',
      size: '1MB',
      dependencies: [],
      tags: ['流量监控', '带宽统计']
    },

    // 多媒体类
    {
      id: 'aria2',
      name: 'Aria2下载器',
      description: '多线程下载工具，支持HTTP/FTP/BT下载',
      category: 'multimedia',
      size: '2MB',
      dependencies: ['ariaNG'],
      tags: ['下载', '多线程', 'BT']
    },
    {
      id: 'transmission',
      name: 'Transmission',
      description: 'BT下载客户端，轻量级种子下载工具',
      category: 'multimedia',
      size: '3MB',
      dependencies: [],
      tags: ['BT下载', '种子']
    },
    {
      id: 'minidlna',
      name: 'MiniDLNA',
      description: 'DLNA媒体服务器，共享音视频文件',
      category: 'multimedia',
      size: '1MB',
      dependencies: [],
      tags: ['DLNA', '媒体服务器']
    },
    {
      id: 'samba4',
      name: 'Samba文件共享',
      description: 'SMB/CIFS文件共享服务',
      category: 'multimedia',
      size: '5MB',
      dependencies: [],
      tags: ['文件共享', 'SMB']
    },
    {
      id: 'usb-printer',
      name: 'USB打印服务器',
      description: '将USB打印机共享给网络中的设备',
      category: 'multimedia',
      size: '1MB',
      dependencies: [],
      tags: ['打印机共享', 'USB']
    },

    // 存储和文件管理
    {
      id: 'kodexplorer',
      name: 'KOD云存储',
      description: '私人网盘系统，支持在线文件管理',
      category: 'storage',
      size: '10MB',
      dependencies: ['php7'],
      tags: ['网盘', '文件管理']
    },
    {
      id: 'nextcloud',
      name: 'Nextcloud',
      description: '开源云存储解决方案',
      category: 'storage',
      size: '15MB',
      dependencies: ['php7', 'mysql'],
      tags: ['云存储', '协作']
    },
    {
      id: 'vsftpd',
      name: 'FTP服务器',
      description: '轻量级FTP文件传输服务',
      category: 'storage',
      size: '0.5MB',
      dependencies: [],
      tags: ['FTP', '文件传输']
    }
  ]
};

// 冲突检测规则
const CONFLICT_RULES = {
  // 互斥插件组
  mutex: [
    {
      name: '科学上网工具互斥',
      plugins: ['ssr-plus', 'passwall', 'openclash', 'v2raya']
    },
    {
      name: '广告拦截工具互斥', 
      plugins: ['adbyby-plus', 'adguardhome']
    },
    {
      name: 'BT下载工具互斥',
      plugins: ['aria2', 'transmission']
    },
    {
      name: '云存储服务互斥',
      plugins: ['kodexplorer', 'nextcloud']
    }
  ],
  
  // 依赖关系
  dependencies: {
    'docker': ['kmod-veth', 'kmod-bridge'],
    'openclash': ['iptables-mod-tproxy', 'kmod-tun'],
    'wireguard': ['kmod-wireguard', 'wireguard-tools'],
    'ssr-plus': ['iptables-mod-tproxy', 'dnsmasq-full'],
    'passwall': ['iptables-mod-tproxy', 'xray-core'],
    'kodexplorer': ['php7', 'php7-mod-zip'],
    'nextcloud': ['php7', 'mysql-server']
  },
  
  // 设备存储限制 (MB)
  size_limits: {
    'ramips': 16,    // MT76xx等芯片，通常16MB flash
    'ath79': 8,      // AR71xx等芯片，通常8MB flash  
    'mediatek': 16,  // 联发科芯片
    'x86': 999,      // X86设备通常无限制
    'arm': 999       // ARM设备通常使用SD卡
  },
  
  // 架构兼容性
  arch_compatibility: {
    'docker': ['x86', 'arm'],           // Docker需要64位系统
    'nextcloud': ['x86', 'arm'],        // 需要较多资源
    'kodexplorer': ['all'],             // 轻量级，支持所有架构
    'openclash': ['x86', 'arm', 'mips'] // 支持多架构
  }
};

// 源码分支配置
const SOURCE_CONFIG = {
  'openwrt-main': {
    name: 'OpenWrt 官方主线',
    repo: 'https://github.com/openwrt/openwrt',
    branch: 'main',
    description: '官方维护的稳定版本，更新及时，兼容性最好'
  },
  'lede-master': {
    name: 'Lean\'s LEDE',
    repo: 'https://github.com/coolsnowwolf/lede', 
    branch: 'master',
    description: '国内最受欢迎的OpenWrt分支，集成大量实用插件'
  },
  'immortalwrt-master': {
    name: 'ImmortalWrt',
    repo: 'https://github.com/immortalwrt/immortalwrt',
    branch: 'master', 
    description: '基于官方的增强版本，保持兼容性同时添加实用功能'
  },
  'lienol-master': {
    name: 'Lienol OpenWrt',
    repo: 'https://github.com/Lienol/openwrt',
    branch: '22.03',
    description: 'Lienol维护的OpenWrt分支，稳定可靠'
  }
};

// 预设配置模板
const CONFIG_TEMPLATES = {
  'home_router': {
    name: '家用路由器',
    description: '适合家庭使用的基础配置',
    plugins: ['adguardhome', 'ddns', 'upnp', 'wol', 'nlbwmon'],
    devices: ['xiaomi-4a-gigabit', 'phicomm-k2p', 'newifi-d2']
  },
  'nas_server': {
    name: 'NAS服务器',
    description: '网络存储和媒体服务器配置',
    plugins: ['samba4', 'minidlna', 'aria2', 'docker', 'vsftpd'],
    devices: ['x86_64', 'raspberry-pi-4', 'nanopi-r2s']
  },
  'bypass_router': {
    name: '科学上网路由器',
    description: '翻墙路由器配置，包含代理工具',
    plugins: ['ssr-plus', 'adguardhome', 'ddns', 'mwan3'],
    devices: ['x86_64', 'newifi-d2', 'linksys-wrt3200acm']
  },
  'minimal': {
    name: '精简配置',
    description: '最小化配置，适合存储空间有限的设备',
    plugins: ['ddns', 'upnp'],
    devices: ['all']
  }
};

// 设备推荐配置
const DEVICE_RECOMMENDATIONS = {
  'x86_64': {
    recommended_plugins: ['docker', 'nextcloud', 'adguardhome', 'openclash'],
    max_plugins: 50,
    notes: 'X86设备性能强劲，可安装大部分插件'
  },
  'raspberry-pi-4': {
    recommended_plugins: ['docker', 'samba4', 'aria2', 'wireguard'],
    max_plugins: 30,
    notes: '树莓派4性能不错，适合做NAS和轻量服务器'
  },
  'xiaomi-4a-gigabit': {
    recommended_plugins: ['ssr-plus', 'adbyby-plus', 'ddns'],
    max_plugins: 10,
    notes: '小米4A存储有限，建议选择轻量级插件'
  },
  'newifi-d2': {
    recommended_plugins: ['passwall', 'adguardhome', 'aria2', 'samba4'],
    max_plugins: 15,
    notes: '新路由3存储充足，可安装较多插件'
  }
};

// 插件分类配置
const PLUGIN_CATEGORIES = {
  'vpn': {
    name: 'VPN/代理',
    icon: '🔐',
    description: '科学上网和VPN工具'
  },
  'network': {
    name: '网络工具',
    icon: '🌐',
    description: '网络管理和优化工具'
  },
  'system': {
    name: '系统管理',
    icon: '⚙️',
    description: '系统监控和管理工具'
  },
  'multimedia': {
    name: '多媒体',
    icon: '🎵',
    description: '媒体服务和下载工具'
  },
  'storage': {
    name: '存储管理',
    icon: '💾',
    description: '文件共享和存储服务'
  }
};

// 常用插件源配置
const PLUGIN_SOURCES = {
  official: {
    name: '官方插件源',
    url: 'https://github.com/openwrt/packages',
    description: 'OpenWrt官方维护的插件包',
    enabled: true
  },
  lean: {
    name: 'Lean插件源',
    url: 'https://github.com/coolsnowwolf/packages',
    description: '包含SSR+、广告屏蔽等实用插件',
    enabled: true
  },
  kenzo: {
    name: 'Kenzo插件源',
    url: 'https://github.com/kenzok8/openwrt-packages',
    description: '第三方插件集合，包含大量实用工具',
    enabled: false
  },
  small: {
    name: 'Small插件源',
    url: 'https://github.com/kenzok8/small',
    description: 'Kenzo维护的轻量级插件源',
    enabled: false
  },
  lienol: {
    name: 'Lienol插件源',
    url: 'https://github.com/Lienol/openwrt-package',
    description: 'Lienol维护的插件包',
    enabled: false
  }
};

// 编译选项配置
const BUILD_OPTIONS = {
  optimization: {
    name: '编译优化',
    options: [
      { key: 'size', name: '体积优化', description: '减小固件体积，适合存储有限的设备' },
      { key: 'speed', name: '性能优化', description: '优化运行性能，适合高性能设备' },
      { key: 'debug', name: '调试版本', description: '包含调试信息，便于问题排查' }
    ],
    default: 'size'
  },
  features: {
    name: '功能特性',
    options: [
      { key: 'ipv6', name: 'IPv6支持', description: '启用IPv6网络支持' },
      { key: 'wifi', name: 'WiFi驱动', description: '包含无线网卡驱动' },
      { key: 'usb', name: 'USB支持', description: '启用USB设备支持' },
      { key: 'pcie', name: 'PCIe支持', description: '启用PCIe设备支持' }
    ]
  }
};

// 帮助提示信息
const HELP_TIPS = {
  source_selection: {
    title: '如何选择源码分支？',
    content: `
      <ul>
        <li><strong>OpenWrt官方</strong>：最稳定，更新及时，适合新手</li>
        <li><strong>Lean's LEDE</strong>：国内热门，集成实用插件，中文友好</li>
        <li><strong>ImmortalWrt</strong>：增强版官方固件，功能丰富</li>
      </ul>
    `
  },
  device_selection: {
    title: '设备选择注意事项',
    content: `
      <ul>
        <li>确认设备型号和硬件版本</li>
        <li>注意flash存储容量限制</li>
        <li>建议先在虚拟机测试</li>
        <li>刷机有风险，请确保有救砖方法</li>
      </ul>
    `
  },
  plugin_selection: {
    title: '插件选择建议',
    content: `
      <ul>
        <li>根据实际需求选择插件</li>
        <li>注意设备存储容量限制</li>
        <li>避免选择功能重复的插件</li>
        <li>可以后续通过opkg安装更多插件</li>
      </ul>
    `
  }
};

// 错误提示信息
const ERROR_MESSAGES = {
  github_not_configured: '未配置GitHub仓库信息，请先fork项目并设置GITHUB_REPO变量',
  device_not_selected: '请先选择目标设备',
  source_not_selected: '请先选择源码分支',
  plugins_too_large: '选择的插件总大小超出设备存储限制',
  api_request_failed: '网络请求失败，请检查网络连接',
  build_failed: '编译失败，请检查配置或查看日志'
};

// 成功提示信息
const SUCCESS_MESSAGES = {
  config_valid: '配置检查通过，可以开始编译',
  build_started: '编译任务已成功提交',
  build_completed: '固件编译完成，请下载使用'
};

// 工具函数
const Utils = {
  // 格式化文件大小
  formatSize: (sizeStr) => {
    const size = parseInt(sizeStr.replace('MB', ''));
    if (size >= 1024) {
      return (size / 1024).toFixed(1) + 'GB';
    }
    return size + 'MB';
  },
  
  // 获取设备类型
  getDeviceType: (deviceId) => {
    if (deviceId.includes('x86')) return 'x86';
    if (deviceId.includes('raspberry') || deviceId.includes('orange') || deviceId.includes('nano')) return 'arm';
    if (deviceId.includes('xiaomi') || deviceId.includes('phicomm') || deviceId.includes('newifi')) return 'ramips';
    if (deviceId.includes('asus') || deviceId.includes('netgear') || deviceId.includes('linksys')) return 'ath79';
    return 'unknown';
  },
  
  // 计算插件总大小
  calculateTotalSize: (pluginIds) => {
    return pluginIds.reduce((total, id) => {
      const plugin = PLUGIN_DATA.default.find(p => p.id === id);
      return total + (plugin ? parseInt(plugin.size.replace('MB', '')) : 0);
    }, 0);
  },
  
  // 检查设备兼容性
  isCompatible: (deviceId, pluginId) => {
    const deviceType = Utils.getDeviceType(deviceId);
    const plugin = PLUGIN_DATA.default.find(p => p.id === pluginId);
    
    if (!plugin) return true;
    
    const archCompat = CONFLICT_RULES.arch_compatibility[pluginId];
    if (!archCompat) return true;
    
    return archCompat.includes('all') || archCompat.includes(deviceType);
  },
  
  // 生成随机ID
  generateId: () => {
    return 'build_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now();
  },
  
  // 本地存储操作
  storage: {
    save: (key, data) => {
      try {
        localStorage.setItem(key, JSON.stringify(data));
      } catch (e) {
        console.warn('无法保存到本地存储:', e);
      }
    },
    
    load: (key, defaultValue = null) => {
      try {
        const data = localStorage.getItem(key);
        return data ? JSON.parse(data) : defaultValue;
      } catch (e) {
        console.warn('无法从本地存储读取:', e);
        return defaultValue;
      }
    },
    
    remove: (key) => {
      try {
        localStorage.removeItem(key);
      } catch (e) {
        console.warn('无法删除本地存储:', e);
      }
    }
  }
};

// 导出配置（如果在Node.js环境中使用）
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    GITHUB_REPO,
    GITHUB_TOKEN,
    DEVICE_DATA,
    PLUGIN_DATA,
    CONFLICT_RULES,
    SOURCE_CONFIG,
    CONFIG_TEMPLATES,
    DEVICE_RECOMMENDATIONS,
    PLUGIN_CATEGORIES,
    PLUGIN_SOURCES,
    BUILD_OPTIONS,
    HELP_TIPS,
    ERROR_MESSAGES,
    SUCCESS_MESSAGES,
    Utils
  };
}