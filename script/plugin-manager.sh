#!/bin/bash
#========================================================================================================================
# OpenWrt 插件管理脚本
# 功能: 管理插件配置、检查冲突、生成插件配置
# 用法: ./plugin-manager.sh [操作] [参数...]
#========================================================================================================================

# 脚本版本
VERSION="1.0.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 插件配置目录
PLUGIN_CONFIG_DIR="config/plugins"
PLUGIN_DB_FILE="$PLUGIN_CONFIG_DIR/plugin_database.json"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $1"; }

# 显示标题
show_header() {
    echo -e "${CYAN}"
    echo "========================================================================================================================="
    echo "                                    🔌 OpenWrt 插件管理脚本 v${VERSION}"
    echo "========================================================================================================================="
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
${CYAN}使用方法:${NC}
  $0 [操作] [选项...]

${CYAN}操作:${NC}
  init                初始化插件数据库
  list                列出所有可用插件
  search              搜索插件
  info                显示插件详细信息
  validate            验证插件配置
  conflicts           检查插件冲突
  generate            生成插件配置
  install             安装插件配置
  remove              移除插件配置
  update              更新插件数据库

${CYAN}选项:${NC}
  -p, --plugin        指定插件名称
  -l, --list          插件列表（逗号分隔）
  -c, --category      插件分类
  -f, --format        输出格式 (json|text|config)
  -o, --output        输出文件
  -v, --verbose       详细输出
  -h, --help          显示帮助信息
  --version           显示版本信息

${CYAN}示例:${NC}
  # 初始化插件数据库
  $0 init
  
  # 列出所有插件
  $0 list
  
  # 搜索代理插件
  $0 search -c proxy
  
  # 检查插件冲突
  $0 conflicts -l "luci-app-ssr-plus,luci-app-passwall"
  
  # 生成插件配置
  $0 generate -l "luci-app-ssr-plus,luci-theme-argon" -o plugin.config

${CYAN}插件分类:${NC}
  - proxy: 代理相关插件
  - network: 网络工具插件
  - system: 系统管理插件
  - storage: 存储相关插件
  - multimedia: 多媒体插件
  - security: 安全防护插件
  - theme: 主题插件
  - development: 开发工具插件
EOF
}

# 初始化插件数据库
init_plugin_database() {
    log_info "初始化插件数据库..."
    
    # 创建插件配置目录
    mkdir -p "$PLUGIN_CONFIG_DIR"
    
    # 创建插件数据库
    cat > "$PLUGIN_DB_FILE" << 'EOF'
{
  "version": "1.0.0",
  "last_updated": "",
  "categories": {
    "proxy": {
      "name": "代理工具",
      "description": "科学上网和代理相关插件",
      "plugins": {
        "luci-app-ssr-plus": {
          "name": "ShadowSocksR Plus+",
          "description": "强大的代理工具集合",
          "author": "fw876",
          "feeds": ["src-git helloworld https://github.com/fw876/helloworld"],
          "dependencies": ["shadowsocksr-libev-ssr-local", "shadowsocksr-libev-ssr-redir"],
          "conflicts": ["luci-app-passwall", "luci-app-openclash", "luci-app-bypass"],
          "size": "~2MB",
          "complexity": "medium"
        },
        "luci-app-passwall": {
          "name": "PassWall",
          "description": "简单易用的代理工具",
          "author": "xiaorouji",
          "feeds": [
            "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages",
            "src-git passwall https://github.com/xiaorouji/openwrt-passwall"
          ],
          "dependencies": ["brook", "chinadns-ng", "dns2socks"],
          "conflicts": ["luci-app-ssr-plus", "luci-app-openclash", "luci-app-bypass"],
          "size": "~3MB",
          "complexity": "low"
        },
        "luci-app-passwall2": {
          "name": "PassWall 2",
          "description": "PassWall的升级版本",
          "author": "xiaorouji",
          "feeds": ["src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2"],
          "dependencies": ["brook", "chinadns-ng", "dns2socks"],
          "conflicts": ["luci-app-ssr-plus", "luci-app-openclash", "luci-app-passwall"],
          "size": "~3MB",
          "complexity": "low"
        },
        "luci-app-openclash": {
          "name": "OpenClash",
          "description": "Clash客户端，功能强大",
          "author": "vernesong",
          "feeds": ["src-git openclash https://github.com/vernesong/OpenClash"],
          "dependencies": ["coreutils-nohup", "bash", "iptables", "dnsmasq-full"],
          "conflicts": ["luci-app-ssr-plus", "luci-app-passwall", "luci-app-bypass"],
          "size": "~5MB",
          "complexity": "high"
        },
        "luci-app-bypass": {
          "name": "Bypass",
          "description": "轻量级代理工具",
          "author": "kiddin9",
          "feeds": ["src-git bypass https://github.com/kiddin9/openwrt-bypass"],
          "dependencies": ["smartdns", "chinadns-ng"],
          "conflicts": ["luci-app-ssr-plus", "luci-app-passwall", "luci-app-openclash"],
          "size": "~1MB",
          "complexity": "low"
        }
      }
    },
    "network": {
      "name": "网络工具",
      "description": "网络管理和监控工具",
      "plugins": {
        "luci-app-adguardhome": {
          "name": "AdGuard Home",
          "description": "强大的广告拦截和DNS服务器",
          "author": "rufengsuixing",
          "feeds": ["src-git adguardhome https://github.com/rufengsuixing/luci-app-adguardhome"],
          "dependencies": ["AdGuardHome"],
          "conflicts": [],
          "size": "~10MB",
          "complexity": "medium"
        },
        "luci-app-smartdns": {
          "name": "SmartDNS",
          "description": "智能DNS服务器",
          "author": "pymumu",
          "feeds": ["src-git smartdns https://github.com/pymumu/openwrt-smartdns"],
          "dependencies": ["smartdns"],
          "conflicts": [],
          "size": "~1MB",
          "complexity": "low"
        },
        "luci-app-ddns": {
          "name": "动态DNS",
          "description": "动态域名解析服务",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["ddns-scripts"],
          "conflicts": [],
          "size": "~500KB",
          "complexity": "low"
        },
        "luci-app-upnp": {
          "name": "UPnP",
          "description": "通用即插即用协议支持",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["miniupnpd"],
          "conflicts": [],
          "size": "~200KB",
          "complexity": "low"
        }
      }
    },
    "system": {
      "name": "系统管理",
      "description": "系统管理和监控工具",
      "plugins": {
        "luci-app-ttyd": {
          "name": "终端访问",
          "description": "Web终端访问工具",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["ttyd"],
          "conflicts": [],
          "size": "~500KB",
          "complexity": "low"
        },
        "luci-app-htop": {
          "name": "系统监控",
          "description": "系统进程监控工具",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["htop"],
          "conflicts": [],
          "size": "~200KB",
          "complexity": "low"
        },
        "luci-app-pushbot": {
          "name": "消息推送",
          "description": "系统状态消息推送工具",
          "author": "zzsj0928",
          "feeds": ["src-git pushbot https://github.com/zzsj0928/luci-app-pushbot"],
          "dependencies": ["curl", "jsonfilter"],
          "conflicts": [],
          "size": "~300KB",
          "complexity": "medium"
        }
      }
    },
    "storage": {
      "name": "存储管理",
      "description": "存储和文件管理工具",
      "plugins": {
        "luci-app-samba4": {
          "name": "网络共享",
          "description": "Samba网络文件共享",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["samba4-server"],
          "conflicts": ["luci-app-samba"],
          "size": "~2MB",
          "complexity": "low"
        },
        "luci-app-hd-idle": {
          "name": "硬盘休眠",
          "description": "硬盘空闲时自动休眠",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["hd-idle"],
          "conflicts": [],
          "size": "~100KB",
          "complexity": "low"
        },
        "luci-app-dockerman": {
          "name": "Docker管理",
          "description": "Docker容器管理界面",
          "author": "lisaac",
          "feeds": ["src-git dockerman https://github.com/lisaac/luci-app-dockerman"],
          "dependencies": ["docker", "dockerd"],
          "conflicts": [],
          "size": "~5MB",
          "complexity": "high"
        }
      }
    },
    "multimedia": {
      "name": "多媒体",
      "description": "多媒体播放和下载工具",
      "plugins": {
        "luci-app-aria2": {
          "name": "Aria2下载",
          "description": "多线程下载工具",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["aria2", "ariang"],
          "conflicts": [],
          "size": "~3MB",
          "complexity": "medium"
        },
        "luci-app-transmission": {
          "name": "BT下载",
          "description": "BitTorrent下载客户端",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["transmission-daemon"],
          "conflicts": [],
          "size": "~2MB",
          "complexity": "medium"
        }
      }
    },
    "security": {
      "name": "安全防护",
      "description": "网络安全和防护工具",
      "plugins": {
        "luci-app-banip": {
          "name": "IP封禁",
          "description": "自动IP封禁工具",
          "author": "openwrt",
          "feeds": [],
          "dependencies": ["banip"],
          "conflicts": [],
          "size": "~500KB",
          "complexity": "medium"
        },
        "luci-app-accesscontrol": {
          "name": "访问控制",
          "description": "设备访问时间控制",
          "author": "openwrt",
          "feeds": [],
          "dependencies": [],
          "conflicts": [],
          "size": "~200KB",
          "complexity": "low"
        }
      }
    },
    "theme": {
      "name": "界面主题",
      "description": "LuCI界面主题",
      "plugins": {
        "luci-theme-argon": {
          "name": "Argon主题",
          "description": "美观的LuCI主题",
          "author": "jerrykuku",
          "feeds": ["src-git argon https://github.com/jerrykuku/luci-theme-argon"],
          "dependencies": [],
          "conflicts": ["luci-theme-material", "luci-theme-netgear"],
          "size": "~1MB",
          "complexity": "low"
        },
        "luci-app-argon-config": {
          "name": "Argon主题配置",
          "description": "Argon主题配置工具",
          "author": "jerrykuku",
          "feeds": ["src-git argon_config https://github.com/jerrykuku/luci-app-argon-config"],
          "dependencies": ["luci-theme-argon"],
          "conflicts": [],
          "size": "~200KB",
          "complexity": "low"
        },
        "luci-theme-material": {
          "name": "Material主题",
          "description": "Material Design风格主题",
          "author": "LuttyYang",
          "feeds": ["src-git material https://github.com/LuttyYang/luci-theme-material"],
          "dependencies": [],
          "conflicts": ["luci-theme-argon", "luci-theme-netgear"],
          "size": "~800KB",
          "complexity": "low"
        }
      }
    },
    "development": {
      "name": "开发工具",
      "description": "开发和调试工具",
      "plugins": {
        "luci-app-commands": {
          "name": "自定义命令",
          "description": "在Web界面执行自定义命令",
          "author": "openwrt",
          "feeds": [],
          "dependencies": [],
          "conflicts": [],
          "size": "~100KB",
          "complexity": "low"
        }
      }
    }
  }
}
EOF
    
    # 更新时间戳
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    sed -i "s/\"last_updated\": \"\"/\"last_updated\": \"$current_time\"/" "$PLUGIN_DB_FILE"
    
    log_success "插件数据库初始化完成: $PLUGIN_DB_FILE"
}

# 列出所有插件
list_plugins() {
    local category="$1"
    local format="${2:-text}"
    
    if [ ! -f "$PLUGIN_DB_FILE" ]; then
        log_error "插件数据库不存在，请先运行 init 初始化"
        return 1
    fi
    
    log_info "列出插件信息..."
    
    case "$format" in
        "json")
            if [ -n "$category" ]; then
                jq ".categories.${category}.plugins" "$PLUGIN_DB_FILE" 2>/dev/null || {
                    log_error "分类不存在: $category"
                    return 1
                }
            else
                jq ".categories" "$PLUGIN_DB_FILE"
            fi
            ;;
        "text")
            if [ -n "$category" ]; then
                list_category_plugins "$category"
            else
                list_all_plugins
            fi
            ;;
        *)
            log_error "不支持的输出格式: $format"
            return 1
            ;;
    esac
}

# 列出所有插件（文本格式）
list_all_plugins() {
    echo -e "\n${CYAN}📦 可用插件列表${NC}"
    echo "========================================"
    
    # 读取并解析JSON
    local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE")
    
    for category in $categories; do
        local category_name=$(jq -r ".categories.${category}.name" "$PLUGIN_DB_FILE")
        local category_desc=$(jq -r ".categories.${category}.description" "$PLUGIN_DB_FILE")
        
        echo -e "\n${YELLOW}📂 ${category_name} (${category})${NC}"
        echo "   $category_desc"
        echo "   ────────────────────────────────────"
        
        local plugins=$(jq -r ".categories.${category}.plugins | keys[]" "$PLUGIN_DB_FILE")
        for plugin in $plugins; do
            local name=$(jq -r ".categories.${category}.plugins.${plugin}.name" "$PLUGIN_DB_FILE")
            local desc=$(jq -r ".categories.${category}.plugins.${plugin}.description" "$PLUGIN_DB_FILE")
            local size=$(jq -r ".categories.${category}.plugins.${plugin}.size" "$PLUGIN_DB_FILE")
            local complexity=$(jq -r ".categories.${category}.plugins.${plugin}.complexity" "$PLUGIN_DB_FILE")
            
            # 复杂度图标
            local complexity_icon="🟢"
            case "$complexity" in
                "medium") complexity_icon="🟡" ;;
                "high") complexity_icon="🔴" ;;
            esac
            
            printf "   ${GREEN}%-25s${NC} %s %s (%s)\n" "$plugin" "$complexity_icon" "$name" "$size"
            printf "   %-25s   %s\n" "" "$desc"
        done
    done
    
    echo -e "\n${BLUE}图例:${NC} 🟢 简单 🟡 中等 🔴 复杂"
}

# 列出指定分类的插件
list_category_plugins() {
    local category="$1"
    
    local category_name=$(jq -r ".categories.${category}.name" "$PLUGIN_DB_FILE" 2>/dev/null)
    if [ "$category_name" = "null" ]; then
        log_error "分类不存在: $category"
        return 1
    fi
    
    echo -e "\n${CYAN}📂 ${category_name} 插件列表${NC}"
    echo "========================================"
    
    local plugins=$(jq -r ".categories.${category}.plugins | keys[]" "$PLUGIN_DB_FILE")
    for plugin in $plugins; do
        local name=$(jq -r ".categories.${category}.plugins.${plugin}.name" "$PLUGIN_DB_FILE")
        local desc=$(jq -r ".categories.${category}.plugins.${plugin}.description" "$PLUGIN_DB_FILE")
        local size=$(jq -r ".categories.${category}.plugins.${plugin}.size" "$PLUGIN_DB_FILE")
        
        printf "${GREEN}%-25s${NC} %s (%s)\n" "$plugin" "$name" "$size"
        printf "%-25s %s\n" "" "$desc"
        echo
    done
}

# 搜索插件
search_plugins() {
    local keyword="$1"
    local category="$2"
    
    if [ -z "$keyword" ]; then
        log_error "请提供搜索关键词"
        return 1
    fi
    
    log_info "搜索插件: $keyword"
    
    echo -e "\n${CYAN}🔍 搜索结果${NC}"
    echo "========================================"
    
    local found=false
    local categories
    
    if [ -n "$category" ]; then
        categories="$category"
    else
        categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE")
    fi
    
    for cat in $categories; do
        local plugins=$(jq -r ".categories.${cat}.plugins | keys[]" "$PLUGIN_DB_FILE")
        for plugin in $plugins; do
            local name=$(jq -r ".categories.${cat}.plugins.${plugin}.name" "$PLUGIN_DB_FILE")
            local desc=$(jq -r ".categories.${cat}.plugins.${plugin}.description" "$PLUGIN_DB_FILE")
            
            # 检查是否匹配关键词
            if [[ "$plugin" =~ $keyword ]] || [[ "$name" =~ $keyword ]] || [[ "$desc" =~ $keyword ]]; then
                local size=$(jq -r ".categories.${cat}.plugins.${plugin}.size" "$PLUGIN_DB_FILE")
                local cat_name=$(jq -r ".categories.${cat}.name" "$PLUGIN_DB_FILE")
                
                printf "${GREEN}%-25s${NC} %s (%s)\n" "$plugin" "$name" "$size"
                printf "%-25s 分类: %s\n" "" "$cat_name"
                printf "%-25s %s\n" "" "$desc"
                echo
                found=true
            fi
        done
    done
    
    if [ "$found" = false ]; then
        echo "未找到匹配的插件"
    fi
}

# 显示插件详细信息
show_plugin_info() {
    local plugin_name="$1"
    
    if [ -z "$plugin_name" ]; then
        log_error "请指定插件名称"
        return 1
    fi
    
    log_info "查询插件信息: $plugin_name"
    
    # 查找插件
    local found_category=""
    local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE")
    
    for category in $categories; do
        local exists=$(jq -r ".categories.${category}.plugins.${plugin_name}" "$PLUGIN_DB_FILE")
        if [ "$exists" != "null" ]; then
            found_category="$category"
            break
        fi
    done
    
    if [ -z "$found_category" ]; then
        log_error "插件不存在: $plugin_name"
        return 1
    fi
    
    # 显示详细信息
    echo -e "\n${CYAN}🔌 插件详细信息${NC}"
    echo "========================================"
    
    local name=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.name" "$PLUGIN_DB_FILE")
    local desc=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.description" "$PLUGIN_DB_FILE")
    local author=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.author" "$PLUGIN_DB_FILE")
    local size=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.size" "$PLUGIN_DB_FILE")
    local complexity=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.complexity" "$PLUGIN_DB_FILE")
    local cat_name=$(jq -r ".categories.${found_category}.name" "$PLUGIN_DB_FILE")
    
    echo "插件名称: ${GREEN}$plugin_name${NC}"
    echo "显示名称: $name"
    echo "插件描述: $desc"
    echo "开发作者: $author"
    echo "所属分类: $cat_name ($found_category)"
    echo "安装大小: $size"
    echo "复杂程度: $complexity"
    
    # 显示依赖
    local deps=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.dependencies[]" "$PLUGIN_DB_FILE" 2>/dev/null)
    if [ -n "$deps" ]; then
        echo -e "\n${YELLOW}📦 依赖包:${NC}"
        echo "$deps" | while read dep; do
            echo "  - $dep"
        done
    fi
    
    # 显示冲突
    local conflicts=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.conflicts[]" "$PLUGIN_DB_FILE" 2>/dev/null)
    if [ -n "$conflicts" ]; then
        echo -e "\n${RED}⚠️  冲突插件:${NC}"
        echo "$conflicts" | while read conflict; do
            echo "  - $conflict"
        done
    fi
    
    # 显示feeds源
    local feeds=$(jq -r ".categories.${found_category}.plugins.${plugin_name}.feeds[]" "$PLUGIN_DB_FILE" 2>/dev/null)
    if [ -n "$feeds" ]; then
        echo -e "\n${BLUE}🔗 所需Feeds源:${NC}"
        echo "$feeds" | while read feed; do
            echo "  $feed"
        done
    fi
}

# 检查插件冲突
check_conflicts() {
    local plugin_list="$1"
    
    if [ -z "$plugin_list" ]; then
        log_error "请提供插件列表"
        return 1
    fi
    
    log_info "检查插件冲突..."
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    local conflicts_found=false
    local conflict_pairs=()
    
    echo -e "\n${CYAN}⚠️  插件冲突检查${NC}"
    echo "========================================"
    
    # 检查每个插件的冲突
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs) # 去除空格
        
        # 查找插件所在分类
        local found_category=""
        local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE")
        
        for category in $categories; do
            local exists=$(jq -r ".categories.${category}.plugins.${plugin}" "$PLUGIN_DB_FILE")
            if [ "$exists" != "null" ]; then
                found_category="$category"
                break
            fi
        done
        
        if [ -z "$found_category" ]; then
            log_warning "未知插件: $plugin"
            continue
        fi
        
        # 获取冲突列表
        local plugin_conflicts=$(jq -r ".categories.${found_category}.plugins.${plugin}.conflicts[]" "$PLUGIN_DB_FILE" 2>/dev/null)
        
        # 检查是否与其他选中的插件冲突
        for other_plugin in "${plugins[@]}"; do
            other_plugin=$(echo "$other_plugin" | xargs)
            if [ "$plugin" != "$other_plugin" ]; then
                if echo "$plugin_conflicts" | grep -q "^${other_plugin}$"; then
                    conflicts_found=true
                    conflict_pairs+=("$plugin <-> $other_plugin")
                fi
            fi
        done
    done
    
    if [ "$conflicts_found" = true ]; then
        echo -e "${RED}❌ 发现插件冲突:${NC}"
        for pair in "${conflict_pairs[@]}"; do
            echo "  $pair"
        done
        echo
        echo -e "${YELLOW}建议:${NC} 请从冲突的插件中选择一个，移除其他冲突插件"
        return 1
    else
        echo -e "${GREEN}✅ 未发现插件冲突${NC}"
        return 0
    fi
}

# 生成插件配置
generate_plugin_config() {
    local plugin_list="$1"
    local output_file="$2"
    local format="${3:-config}"
    
    if [ -z "$plugin_list" ]; then
        log_error "请提供插件列表"
        return 1
    fi
    
    log_info "生成插件配置..."

    echo "脚本当前目录: $(pwd)"
    echo "生成的 feeds.conf.default 路径: $(realpath "$output_file")"
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    # 验证所有插件
    local valid_plugins=()
    local feeds_sources=()
    
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        
        # 查找插件
        local found_category=""
        local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE")
        
        for category in $categories; do
            local exists=$(jq -r ".categories.${category}.plugins.${plugin}" "$PLUGIN_DB_FILE")
            if [ "$exists" != "null" ]; then
                found_category="$category"
                break
            fi
        done
        
        if [ -n "$found_category" ]; then
            valid_plugins+=("$plugin")
            
            # 收集feeds源
            local plugin_feeds=$(jq -r ".categories.${found_category}.plugins.${plugin}.feeds[]" "$PLUGIN_DB_FILE" 2>/dev/null)
            if [ -n "$plugin_feeds" ]; then
                while IFS= read -r feed; do
                    feeds_sources+=("$feed")
                done <<< "$plugin_feeds"
            fi
        else
            log_warning "跳过未知插件: $plugin"
        fi
    done
    
    if [ ${#valid_plugins[@]} -eq 0 ]; then
        log_error "没有有效的插件"
        return 1
    fi
    
    # 生成配置
    case "$format" in
        "config")
            generate_config_format "${valid_plugins[@]}"
            ;;
        "feeds")
            generate_feeds_format "${feeds_sources[@]}"
            ;;
        "json")
            generate_json_format "${valid_plugins[@]}"
            ;;
        *)
            log_error "不支持的格式: $format"
            return 1
            ;;
    esac
    
    # 输出到文件
    if [ -n "$output_file" ]; then
        case "$format" in
            "config")
                generate_config_format "${valid_plugins[@]}" > "$output_file"
                ;;
            "feeds")
                generate_feeds_format "${feeds_sources[@]}" > "$output_file"
                ;;
            "json")
                generate_json_format "${valid_plugins[@]}" > "$output_file"
                ;;
        esac
        log_success "配置已保存到: $output_file"
    fi

    
}

# 生成配置格式
generate_config_format() {
    local plugins=("$@")
    
    echo "# OpenWrt 插件配置"
    echo "# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# 插件数量: ${#plugins[@]}"
    echo ""
    
    for plugin in "${plugins[@]}"; do
        echo "CONFIG_PACKAGE_${plugin}=y"
    done
}

# 生成feeds格式
generate_feeds_format() {
    local feeds=("$@")
    
    # 去重feeds源
    local unique_feeds=($(printf '%s\n' "${feeds[@]}" | sort -u))
    
    echo "# OpenWrt Feeds配置"
    echo "# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "# 基础feeds源"
    echo "src-git packages https://github.com/coolsnowwolf/packages"
    echo "src-git luci https://github.com/coolsnowwolf/luci"
    echo "src-git routing https://git.openwrt.org/feed/routing.git"
    echo "src-git telephony https://git.openwrt.org/feed/telephony.git"
    echo ""
    echo "# 插件feeds源"
    
    for feed in "${unique_feeds[@]}"; do
        echo "$feed"
    done
}

# 生成JSON格式
generate_json_format() {
    local plugins=("$@")
    
    echo "{"
    echo "  \"generated_at\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
    echo "  \"plugin_count\": ${#plugins[@]},"
    echo "  \"plugins\": ["
    
    for i in "${!plugins[@]}"; do
        local plugin="${plugins[$i]}"
        if [ $i -eq $((${#plugins[@]} - 1)) ]; then
            echo "    \"$plugin\""
        else
            echo "    \"$plugin\","
        fi
    done
    
    echo "  ]"
    echo "}"
}

# 验证插件配置
validate_plugins() {
    local plugin_list="$1"
    
    if [ -z "$plugin_list" ]; then
        log_error "请提供插件列表"
        return 1
    fi
    
    log_info "验证插件配置..."
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    local errors=0
    local warnings=0
    
    echo -e "\n${CYAN}🔍 插件验证结果${NC}"
    echo "========================================"
    
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        
        # 查找插件
        local found_category=""
        local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE")
        
        for category in $categories; do
            local exists=$(jq -r ".categories.${category}.plugins.${plugin}" "$PLUGIN_DB_FILE")
            if [ "$exists" != "null" ]; then
                found_category="$category"
                break
            fi
        done
        
        if [ -z "$found_category" ]; then
            echo -e "${RED}❌ $plugin${NC} - 插件不存在"
            ((errors++))
        else
            echo -e "${GREEN}✅ $plugin${NC} - 验证通过"
            
            # 检查复杂度警告
            local complexity=$(jq -r ".categories.${found_category}.plugins.${plugin}.complexity" "$PLUGIN_DB_FILE")
            if [ "$complexity" = "high" ]; then
                echo -e "   ${YELLOW}⚠️  高复杂度插件，可能需要额外配置${NC}"
                ((warnings++))
            fi
        fi
    done
    
    echo
    echo "验证完成: $((${#plugins[@]} - errors)) 个有效插件，$errors 个错误，$warnings 个警告"
    
    if [ $errors -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# 主函数
main() {
    local operation=""
    local plugin=""
    local plugin_list=""
    local category=""
    local format="text"
    local output=""
    local verbose=false
    
    # 检查jq工具
    if ! command -v jq &> /dev/null; then
        log_error "需要安装jq工具: sudo apt-get install jq"
        exit 1
    fi
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            init|list|search|info|validate|conflicts|generate|install|remove|update)
                operation="$1"
                shift
                ;;
            -p|--plugin)
                plugin="$2"
                shift 2
                ;;
            -l|--list)
                plugin_list="$2"
                shift 2
                ;;
            -c|--category)
                category="$2"
                shift 2
                ;;
            -f|--format)
                format="$2"
                shift 2
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                echo "插件管理脚本 版本 $VERSION"
                exit 0
                ;;
            *)
                # 如果没有指定操作，将第一个参数作为搜索关键词
                if [ -z "$operation" ]; then
                    operation="search"
                    plugin="$1"
                else
                    log_error "未知参数: $1"
                    echo "使用 $0 --help 查看帮助信息"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 显示标题
    show_header
    
    # 执行操作
    case "$operation" in
        "init")
            init_plugin_database
            ;;
        "list")
            list_plugins "$category" "$format"
            ;;
        "search")
            search_plugins "$plugin" "$category"
            ;;
        "info")
            show_plugin_info "$plugin"
            ;;
        "validate")
            validate_plugins "$plugin_list"
            ;;
        "conflicts")
            check_conflicts "$plugin_list"
            ;;
        "generate")
            generate_plugin_config "$plugin_list" "$output" "$format"
            ;;
        "install"|"remove"|"update")
            log_warning "功能开发中: $operation"
            ;;
        "")
            log_error "请指定操作"
            echo "使用 $0 --help 查看帮助信息"
            exit 1
            ;;
        *)
            log_error "未知操作: $operation"
            exit 1
            ;;
    esac
}

# 检查脚本是否被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi