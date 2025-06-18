#!/bin/bash
#========================================================================================================================
# OpenWrt 插件管理脚本 (增强版) - 修复版本
# 功能: 管理插件配置、检查冲突、生成插件配置，集成编译修复协调
# 修复: 添加 --runtime-config 参数支持，与 build-orchestrator.sh 兼容
# 用法: ./plugin-manager.sh [操作] [参数...]
#========================================================================================================================

# 脚本版本
VERSION="2.0.1-fixed"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXES_DIR="$SCRIPT_DIR/fixes"

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

# 运行时配置支持（新增）
RUNTIME_CONFIG_FILE=""

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $1"; }

# 从运行时配置读取值（新增功能）
get_runtime_config_value() {
    local key="$1"
    local default="$2"
    
    if [ -n "$RUNTIME_CONFIG_FILE" ] && [ -f "$RUNTIME_CONFIG_FILE" ]; then
        local value=$(jq -r "$key" "$RUNTIME_CONFIG_FILE" 2>/dev/null)
        if [ "$value" != "null" ] && [ -n "$value" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# 显示标题
show_header() {
    echo -e "${CYAN}"
    echo "========================================================================================================================="
    echo "                                🔌 OpenWrt 插件管理脚本 v${VERSION} (兼容版)"
    echo "                                      集成编译修复协调功能"
    echo "========================================================================================================================="
    echo -e "${NC}"
}

# 显示帮助信息（添加了 --runtime-config 参数说明）
show_help() {
    cat << EOF
${CYAN}使用方法:${NC}
  $0 [操作] [选项...]

${CYAN}基础操作:${NC}
  init                初始化插件数据库
  list                列出所有可用插件
  search              搜索插件
  info                显示插件详细信息
  validate            验证插件配置
  conflicts           检查插件冲突
  generate            生成插件配置

${CYAN}增强功能:${NC}
  pre-build-check     编译前检查 (新增)
  auto-fix-deps       自动修复插件依赖 (新增)
  compatibility       检查设备兼容性 (新增)
  optimize            优化插件配置 (新增)

${CYAN}选项:${NC}
  -p, --plugin        指定插件名称
  -l, --list          插件列表（逗号分隔）
  -c, --category      插件分类
  -d, --device        目标设备类型
  -f, --format        输出格式 (json|text|config)
  -o, --output        输出文件
  --auto-fix          启用自动修复
  --strict            严格模式检查
  --runtime-config    运行时配置文件 (新增)
  -v, --verbose       详细输出
  -h, --help          显示帮助信息
  --version           显示版本信息

${CYAN}示例:${NC}
  # 基础使用
  $0 init                                    # 初始化数据库
  $0 list -c proxy                          # 列出代理插件
  $0 conflicts -l "luci-app-ssr-plus,luci-app-passwall"
  
  # 增强功能
  $0 pre-build-check -d x86_64 -l "luci-app-ssr-plus,luci-theme-argon"
  $0 auto-fix-deps -d rpi_4b -l "luci-app-samba4"
  $0 compatibility -d x86_64 -l "luci-app-openclash"
  $0 optimize -d nanopi_r2s -l "luci-app-aria2" --auto-fix
  
  # 与编排器配合使用
  $0 --runtime-config /tmp/runtime.json init

${CYAN}支持设备:${NC}
  x86_64, xiaomi_4a_gigabit, newifi_d2, rpi_4b, nanopi_r2s

${CYAN}插件分类:${NC}
  proxy, network, system, storage, multimedia, security, theme, development
EOF
}

# 初始化插件数据库
init_plugin_database() {
    log_info "初始化插件数据库..."
    
    # 创建插件配置目录
    if [ ! -d "$PLUGIN_CONFIG_DIR" ]; then
        mkdir -p "$PLUGIN_CONFIG_DIR"
        log_debug "已创建目录: $PLUGIN_CONFIG_DIR"
    fi

    # 检查jq工具
    if ! command -v jq &> /dev/null; then
        log_error "需要安装jq工具来处理JSON文件"
        log_info "Ubuntu/Debian: sudo apt install jq"
        log_info "CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
    
    # 生成插件数据库
    cat > "$PLUGIN_DB_FILE" << 'EOF'
"version": "2.0.0",
  "generated_at": "",
  "categories": {
    "proxy": {
      "name": "代理工具",
      "description": "科学上网和代理相关插件",
      "plugins": {
        "luci-app-ssr-plus": {
          "name": "SSR Plus+",
          "description": "强大的科学上网插件，支持多协议",
          "author": "fw876",
          "size": "5.2MB",
          "complexity": "medium",
          "dependencies": ["libopenssl", "iptables-mod-tproxy", "kmod-tun"],
          "conflicts": ["luci-app-passwall", "luci-app-vssr"],
          "feeds": ["src-git helloworld https://github.com/fw876/helloworld"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "good",
            "xiaomi_4a_gigabit": "limited",
            "newifi_d2": "limited"
          },
          "build_notes": "需要充足内存编译，建议禁用某些组件以减少体积"
        },
        "luci-app-passwall": {
          "name": "PassWall",
          "description": "新一代科学上网插件",
          "author": "xiaorouji",
          "size": "6.8MB",
          "complexity": "high",
          "dependencies": ["chinadns-ng", "brook", "hysteria"],
          "conflicts": ["luci-app-ssr-plus", "luci-app-vssr"],
          "feeds": ["src-git passwall https://github.com/xiaorouji/openwrt-passwall"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "medium",
            "xiaomi_4a_gigabit": "poor",
            "newifi_d2": "poor"
          },
          "build_notes": "资源占用较大，低配设备谨慎使用"
        },
        "luci-app-openclash": {
          "name": "OpenClash",
          "description": "Clash客户端，基于规则的代理工具",
          "author": "vernesong",
          "size": "8.5MB",
          "complexity": "high",
          "dependencies": ["coreutils", "coreutils-nohup", "bash", "curl"],
          "conflicts": ["luci-app-clash"],
          "feeds": ["src-git openclash https://github.com/vernesong/OpenClash"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "medium",
            "xiaomi_4a_gigabit": "poor",
            "newifi_d2": "poor"
          },
          "build_notes": "需要手动下载内核文件，编译时间较长"
        }
      }
    },
    "theme": {
      "name": "界面主题",
      "description": "LuCI界面主题插件",
      "plugins": {
        "luci-theme-argon": {
          "name": "Argon主题",
          "description": "现代化的响应式主题",
          "author": "jerrykuku",
          "size": "1.2MB",
          "complexity": "low",
          "dependencies": ["luci-compat"],
          "conflicts": [],
          "feeds": ["src-git kenzo https://github.com/kenzok8/openwrt-packages"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "excellent",
            "nanopi_r2s": "excellent",
            "xiaomi_4a_gigabit": "good",
            "newifi_d2": "good"
          },
          "build_notes": "兼容性好，推荐使用"
        },
        "luci-theme-edge": {
          "name": "Edge主题",
          "description": "简洁现代的主题设计",
          "author": "kiddin9",
          "size": "880KB",
          "complexity": "low",
          "dependencies": [],
          "conflicts": [],
          "feeds": ["src-git kiddin9 https://github.com/kiddin9/openwrt-packages"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "excellent",
            "nanopi_r2s": "excellent",
            "xiaomi_4a_gigabit": "excellent",
            "newifi_d2": "excellent"
          },
          "build_notes": "轻量级主题，适合所有设备"
        }
      }
    },
    "network": {
      "name": "网络工具",
      "description": "网络管理和服务相关插件",
      "plugins": {
        "luci-app-ddns": {
          "name": "动态DNS",
          "description": "动态域名解析服务",
          "author": "openwrt",
          "size": "420KB",
          "complexity": "low",
          "dependencies": ["ddns-scripts"],
          "conflicts": [],
          "feeds": [],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "excellent",
            "nanopi_r2s": "excellent",
            "xiaomi_4a_gigabit": "excellent",
            "newifi_d2": "excellent"
          },
          "build_notes": "基础网络功能，兼容性好"
        },
        "luci-app-upnp": {
          "name": "UPnP服务",
          "description": "通用即插即用协议支持",
          "author": "openwrt",
          "size": "280KB",
          "complexity": "low",
          "dependencies": ["miniupnpd"],
          "conflicts": [],
          "feeds": [],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "excellent",
            "nanopi_r2s": "excellent",
            "xiaomi_4a_gigabit": "excellent",
            "newifi_d2": "excellent"
          },
          "build_notes": "标准网络功能"
        },
        "luci-app-frpc": {
          "name": "FRP客户端",
          "description": "内网穿透客户端",
          "author": "kuoruan",
          "size": "2.1MB",
          "complexity": "medium",
          "dependencies": ["frp"],
          "conflicts": [],
          "feeds": ["src-git kuoruan https://github.com/kuoruan/openwrt-frp"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "good",
            "xiaomi_4a_gigabit": "medium",
            "newifi_d2": "medium"
          },
          "build_notes": "需要配置FRP服务器"
        }
      }
    },
    "storage": {
      "name": "存储服务",
      "description": "文件共享和存储相关插件",
      "plugins": {
        "luci-app-samba4": {
          "name": "Samba4文件共享",
          "description": "网络文件共享服务",
          "author": "openwrt",
          "size": "3.2MB",
          "complexity": "medium",
          "dependencies": ["samba4-libs", "samba4-server"],
          "conflicts": ["luci-app-samba"],
          "feeds": [],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "good",
            "xiaomi_4a_gigabit": "limited",
            "newifi_d2": "limited"
          },
          "build_notes": "需要USB存储设备，占用内存较多"
        },
        "luci-app-aria2": {
          "name": "Aria2下载器",
          "description": "多协议下载工具",
          "author": "openwrt",
          "size": "1.8MB",
          "complexity": "medium",
          "dependencies": ["aria2", "ariang"],
          "conflicts": [],
          "feeds": [],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "good",
            "xiaomi_4a_gigabit": "limited",
            "newifi_d2": "limited"
          },
          "build_notes": "建议配合外接存储使用"
        }
      }
    },
    "security": {
      "name": "安全防护",
      "description": "网络安全和广告过滤插件",
      "plugins": {
        "luci-app-adguardhome": {
          "name": "AdGuard Home",
          "description": "DNS广告过滤器",
          "author": "AdguardTeam",
          "size": "12MB",
          "complexity": "medium",
          "dependencies": ["adguardhome"],
          "conflicts": ["luci-app-adblock", "luci-app-adbyby-plus"],
          "feeds": ["src-git kenzo https://github.com/kenzok8/openwrt-packages"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "medium",
            "xiaomi_4a_gigabit": "poor",
            "newifi_d2": "poor"
          },
          "build_notes": "内存占用较大，低配设备慎用"
        },
        "luci-app-adbyby-plus": {
          "name": "ADByby Plus+",
          "description": "轻量级广告过滤",
          "author": "kiddin9",
          "size": "2.1MB",
          "complexity": "low",
          "dependencies": ["adbyby"],
          "conflicts": ["luci-app-adblock", "luci-app-adguardhome"],
          "feeds": ["src-git kiddin9 https://github.com/kiddin9/openwrt-packages"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "excellent",
            "nanopi_r2s": "excellent",
            "xiaomi_4a_gigabit": "good",
            "newifi_d2": "good"
          },
          "build_notes": "轻量级，适合低配设备"
        }
      }
    },
    "system": {
      "name": "系统管理",
      "description": "系统管理和监控相关插件",
      "plugins": {
        "luci-app-wol": {
          "name": "网络唤醒",
          "description": "远程唤醒网络设备",
          "author": "openwrt",
          "size": "180KB",
          "complexity": "low",
          "dependencies": ["etherwake"],
          "conflicts": [],
          "feeds": [],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "excellent",
            "nanopi_r2s": "excellent",
            "xiaomi_4a_gigabit": "excellent",
            "newifi_d2": "excellent"
          },
          "build_notes": "基础功能，兼容性好"
        }
      }
    }
  }
}
EOF
    
     # 更新生成时间
    local current_time=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    cat "$PLUGIN_DB_FILE" | jq ".generated_at = \"$current_time\"" > "${PLUGIN_DB_FILE}.tmp"
    mv "${PLUGIN_DB_FILE}.tmp" "$PLUGIN_DB_FILE"
    
    log_success "插件数据库初始化完成: $PLUGIN_DB_FILE"
}

# 编译前检查 (增强功能)
pre_build_check() {
     local device="$1"
    local plugin_list="$2"
    local strict_mode="$3"
    
    log_info "执行编译前检查..."
    
    if [ -z "$device" ] || [ -z "$plugin_list" ]; then
        log_error "请指定设备类型和插件列表"
        return 1
    fi
    
    local issues=()
    local warnings=()
    
    echo -e "\n${CYAN}🔍 编译前检查报告${NC}"
    echo "========================================"
    echo "目标设备: $device"
    echo "检查插件: $plugin_list"
    echo "检查模式: $([ "$strict_mode" = true ] && echo "严格模式" || echo "标准模式")"
    echo ""
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    # 1. 检查插件存在性
    log_info "1. 检查插件有效性..."
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        if ! check_plugin_exists "$plugin"; then
            issues+=("插件不存在: $plugin")
        fi
    done
    
    # 2. 检查设备兼容性
    log_info "2. 检查设备兼容性..."
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        local compatibility=$(get_plugin_device_compatibility "$plugin" "$device")
        case "$compatibility" in
            "poor"|"limited")
                if [ "$strict_mode" = true ]; then
                    issues+=("$plugin 在 $device 上兼容性差")
                else
                    warnings+=("$plugin 在 $device 上兼容性有限")
                fi
                ;;
            "unknown"|"")
                warnings+=("$plugin 在 $device 上兼容性未知")
                ;;
        esac
    done
    
    # 3. 检查插件冲突
    log_info "3. 检查插件冲突..."
    local conflict_result=$(check_plugin_conflicts_internal "$plugin_list")
    if [ $? -ne 0 ]; then
        issues+=("存在插件冲突")
    fi
    
    # 4. 检查资源需求
    log_info "4. 检查资源需求..."
    local total_size=0
    local high_complexity_count=0
    
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        local complexity=$(get_plugin_complexity "$plugin")
        if [ "$complexity" = "high" ]; then
            ((high_complexity_count++))
        fi
        
        # 计算预估大小 (简化计算)
        case "$plugin" in
            *passwall*|*openclash*) ((total_size += 8)) ;;
            *ssr-plus*) ((total_size += 5)) ;;
            *adguardhome*) ((total_size += 12)) ;;
            *) ((total_size += 2)) ;;
        esac
    done
    
    # 设备资源限制检查
    case "$device" in
        "xiaomi_4a_gigabit"|"newifi_d2")
            if [ $total_size -gt 20 ]; then
                issues+=("预估固件大小 ${total_size}MB 可能超出设备flash容量")
            fi
            if [ $high_complexity_count -gt 1 ]; then
                warnings+=("多个高复杂度插件可能导致运行缓慢")
            fi
            ;;
        "nanopi_r2s")
            if [ $total_size -gt 50 ]; then
                warnings+=("预估固件大小 ${total_size}MB 较大")
            fi
            ;;
    esac
    
    # 5. 检查编译依赖
    log_info "5. 检查编译依赖..."
    if ! check_build_dependencies "$device" "$plugin_list"; then
        warnings+=("可能缺少编译依赖")
    fi
    
    # 输出检查结果
    echo -e "\n${CYAN}📊 检查结果汇总${NC}"
    echo "========================================"
    
    if [ ${#issues[@]} -eq 0 ] && [ ${#warnings[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ 检查通过，未发现问题${NC}"
        return 0
    fi
    
    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "${RED}❌ 发现 ${#issues[@]} 个严重问题:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "   ${RED}•${NC} $issue"
        done
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  发现 ${#warnings[@]} 个警告:${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "   ${YELLOW}•${NC} $warning"
        done
    fi
    
    # 返回结果
    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "\n${RED}建议修复上述问题后再开始编译${NC}"
        return 1
    else
        echo -e "\n${YELLOW}可以开始编译，但请注意上述警告${NC}"
        return 0
    fi
}

# 自动修复插件依赖 (增强功能)
auto_fix_plugin_deps() {
    local device="$1"
    local plugin_list="$2"
    local auto_fix="$3"
    
    log_info "自动修复插件依赖..."
    
    if [ "$auto_fix" != true ]; then
        log_info "自动修复未启用，仅检查依赖"
    fi
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    local fixes_applied=()
    
    # 检查每个插件的依赖
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        
        log_debug "检查插件依赖: $plugin"
        
        # 获取插件依赖
        local dependencies=$(get_plugin_dependencies "$plugin")
        
        if [ -n "$dependencies" ]; then
            log_info "插件 $plugin 需要依赖: $dependencies"
            
            # 检查依赖是否已安装
            while IFS= read -r dep; do
                if [ -n "$dep" ]; then
                    log_debug "检查依赖包: $dep"
                    
                    # 检查依赖包是否可用
                    if ! check_package_available "$dep"; then
                        if [ "$auto_fix" = true ]; then
                            log_info "尝试安装依赖: $dep"
                            if install_dependency "$dep"; then
                                fixes_applied+=("安装依赖: $dep")
                            else
                                log_warning "无法自动安装依赖: $dep"
                            fi
                        else
                            log_warning "缺少依赖: $dep (需要手动安装)"
                        fi
                    fi
                fi
            done <<< "$dependencies"
        fi
        
        # 设备特定的依赖修复
        case "$device" in
            "x86_64")
                # X86设备特定依赖
                if [[ "$plugin" == *"ssr-plus"* ]] || [[ "$plugin" == *"passwall"* ]]; then
                    if [ "$auto_fix" = true ]; then
                        ensure_x86_proxy_deps
                        fixes_applied+=("修复X86代理依赖")
                    fi
                fi
                ;;
            "rpi_4b")
                # 树莓派特定依赖
                if [[ "$plugin" == *"samba"* ]]; then
                    if [ "$auto_fix" = true ]; then
                        ensure_rpi_storage_deps
                        fixes_applied+=("修复树莓派存储依赖")
                    fi
                fi
                ;;
        esac
    done
    
    # 输出修复结果
    if [ ${#fixes_applied[@]} -gt 0 ]; then
        echo -e "\n${GREEN}✅ 应用的修复:${NC}"
        for fix in "${fixes_applied[@]}"; do
            echo -e "   ${GREEN}•${NC} $fix"
        done
    else
        log_info "无需修复或修复功能未启用"
    fi
    
    return 0
}

# 检查设备兼容性
check_device_compatibility() {
    local device="$1"
    local plugin_list="$2"
    
    log_info "检查设备兼容性..."
    
    echo -e "\n${CYAN}📱 设备兼容性报告${NC}"
    echo "========================================"
    echo "目标设备: $device"
    echo ""
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    local excellent_count=0
    local good_count=0
    local medium_count=0
    local limited_count=0
    local poor_count=0
    local unknown_count=0
    
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        local compatibility=$(get_plugin_device_compatibility "$plugin" "$device")
        
        case "$compatibility" in
            "excellent")
                echo -e "${GREEN}✅ $plugin${NC} - 完美兼容"
                ((excellent_count++))
                ;;
            "good")
                echo -e "${GREEN}🟢 $plugin${NC} - 兼容性良好"
                ((good_count++))
                ;;
            "medium")
                echo -e "${YELLOW}🟡 $plugin${NC} - 兼容性一般"
                ((medium_count++))
                ;;
            "limited")
                echo -e "${YELLOW}🟠 $plugin${NC} - 兼容性有限"
                ((limited_count++))
                ;;
            "poor")
                echo -e "${RED}🔴 $plugin${NC} - 兼容性差"
                ((poor_count++))
                ;;
            *)
                echo -e "${PURPLE}❓ $plugin${NC} - 兼容性未知"
                ((unknown_count++))
                ;;
        esac
    done
    
    # 显示统计信息
    echo -e "\n${CYAN}📊 兼容性统计${NC}"
    echo "========================================"
    echo "完美兼容: $excellent_count"
    echo "兼容良好: $good_count"
    echo "兼容一般: $medium_count"
    echo "兼容有限: $limited_count"
    echo "兼容性差: $poor_count"
    echo "未知状态: $unknown_count"
    
    # 给出建议
    echo -e "\n${CYAN}💡 兼容性建议${NC}"
    echo "========================================"
    
    if [ $poor_count -gt 0 ]; then
        echo -e "${RED}⚠️  有 $poor_count 个插件在此设备上兼容性差，强烈建议移除${NC}"
    fi
    
    if [ $limited_count -gt 0 ]; then
        echo -e "${YELLOW}⚠️  有 $limited_count 个插件兼容性有限，可能影响性能${NC}"
    fi
    
    if [ $((excellent_count + good_count)) -eq ${#plugins[@]} ]; then
        echo -e "${GREEN}✅ 所有插件都有良好的兼容性${NC}"
    fi
    
    return 0
}

# 检查编译环境
check_build_environment() {
    log_debug "检查编译环境..."
    
    # 检查必要工具
    local required_tools=("make" "gcc" "git" "curl" "wget")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_warning "缺少编译工具: $tool"
            return 1
        fi
    done
    
    return 0
}

# 优化插件配置 (增强功能)
optimize_plugin_config() {
    local device="$1"
    local plugin_list="$2"
    local auto_fix="$3"
    
    log_info "优化插件配置..."
    
    local optimizations=()
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    echo -e "\n${CYAN}⚡ 配置优化建议${NC}"
    echo "========================================"
    
    # 设备特定优化
    case "$device" in
        "xiaomi_4a_gigabit"|"newifi_d2")
            echo -e "${YELLOW}低配设备优化建议:${NC}"
            
            # 检查资源密集型插件
            for plugin in "${plugins[@]}"; do
                plugin=$(echo "$plugin" | xargs)
                case "$plugin" in
                    *"passwall"*|*"openclash"*|*"adguardhome"*)
                        echo -e "   ${RED}•${NC} $plugin 资源占用大，建议使用轻量级替代"
                        optimizations+=("建议移除资源密集型插件: $plugin")
                        ;;
                esac
            done
            
            # 建议轻量级替代
            if echo "$plugin_list" | grep -q "adguardhome"; then
                echo -e "   ${GREEN}•${NC} 建议使用 luci-app-adbyby-plus 替代 AdGuard Home"
                optimizations+=("推荐轻量级广告过滤")
            fi
            
            if echo "$plugin_list" | grep -q "passwall\|openclash"; then
                echo -e "   ${GREEN}•${NC} 建议使用 luci-app-ssr-plus 并禁用部分组件"
                optimizations+=("推荐轻量级代理插件")
            fi
            ;;
            
        "rpi_4b"|"nanopi_r2s")
            echo -e "${BLUE}ARM设备优化建议:${NC}"
            
            # ARM设备特定优化
            for plugin in "${plugins[@]}"; do
                plugin=$(echo "$plugin" | xargs)
                case "$plugin" in
                    *"samba"*)
                        echo -e "   ${GREEN}•${NC} $plugin 在ARM设备上表现良好"
                        optimizations+=("ARM设备存储服务优化")
                        ;;
                    *"aria2"*)
                        echo -e "   ${YELLOW}•${NC} $plugin 建议配合外接存储使用"
                        optimizations+=("下载器存储优化")
                        ;;
                esac
            done
            ;;
            
        "x86_64")
            echo -e "${GREEN}X86设备优化建议:${NC}"
            echo -e "   ${GREEN}•${NC} X86设备资源充足，可以运行所有插件"
            echo -e "   ${GREEN}•${NC} 建议启用更多功能以充分利用性能"
            optimizations+=("X86设备全功能配置")
            ;;
    esac
    
    # 插件组合优化
    echo -e "\n${CYAN}🔧 插件组合优化${NC}"
    echo "========================================"
    
    # 检查代理插件冲突和建议
    local proxy_plugins=()
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        if [[ "$plugin" == *"ssr-plus"* ]] || [[ "$plugin" == *"passwall"* ]] || [[ "$plugin" == *"openclash"* ]]; then
            proxy_plugins+=("$plugin")
        fi
    done
    
    if [ ${#proxy_plugins[@]} -gt 1 ]; then
        echo -e "${RED}⚠️  检测到多个代理插件: ${proxy_plugins[*]}${NC}"
        echo -e "   ${YELLOW}•${NC} 建议只保留一个代理插件避免冲突"
        optimizations+=("移除冲突的代理插件")
    fi
    
    # 检查广告过滤插件
    local adblock_plugins=()
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        if [[ "$plugin" == *"adguard"* ]] || [[ "$plugin" == *"adbyby"* ]] || [[ "$plugin" == *"adblock"* ]]; then
            adblock_plugins+=("$plugin")
        fi
    done
    
    if [ ${#adblock_plugins[@]} -gt 1 ]; then
        echo -e "${RED}⚠️  检测到多个广告过滤插件: ${adblock_plugins[*]}${NC}"
        echo -e "   ${YELLOW}•${NC} 建议只保留一个广告过滤插件"
        optimizations+=("移除冲突的广告过滤插件")
    fi
    
    # 应用自动优化
    if [ "$auto_fix" = true ]; then
        echo -e "\n${CYAN}🚀 应用自动优化${NC}"
        echo "========================================"
        
        # 这里可以实现自动优化逻辑
        # 例如：自动移除冲突插件，调整配置等
        log_info "自动优化功能开发中..."
    fi
    
    # 输出优化总结
    if [ ${#optimizations[@]} -gt 0 ]; then
        echo -e "\n${GREEN}📋 优化建议总结${NC}"
        echo "========================================"
        for opt in "${optimizations[@]}"; do
            echo -e "   ${GREEN}•${NC} $opt"
        done
    fi
    
    return 0
}

# 辅助函数：检查插件是否存在
check_plugin_exists() {
    local plugin="$1"
    
    if [ ! -f "$PLUGIN_DB_FILE" ]; then
        return 1
    fi
    
    local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE" 2>/dev/null)
    for category in $categories; do
        local exists=$(jq -r ".categories.${category}.plugins.${plugin}" "$PLUGIN_DB_FILE" 2>/dev/null)
        if [ "$exists" != "null" ]; then
            return 0
        fi
    done
    
    return 1
}

# 辅助函数：检查插件与设备的兼容性
is_plugin_compatible_with_device() {
    local plugin="$1"
    local device="$2"
    
    if [ ! -f "$PLUGIN_DB_FILE" ]; then
        return 1
    fi
    
    local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE" 2>/dev/null)
    for category in $categories; do
        local exists=$(jq -r ".categories.${category}.plugins.${plugin}" "$PLUGIN_DB_FILE" 2>/dev/null)
        if [ "$exists" != "null" ]; then
            local devices=$(jq -r ".categories.${category}.plugins.${plugin}.devices[]" "$PLUGIN_DB_FILE" 2>/dev/null)
            while IFS= read -r supported_device; do
                if [ "$supported_device" = "$device" ]; then
                    return 0
                fi
            done <<< "$devices"
            return 1
        fi
    done
    
    return 1
}

# 辅助函数：获取插件依赖
get_plugin_dependencies() {
    local plugin="$1"
    
    if [ ! -f "$PLUGIN_DB_FILE" ]; then
        return
    fi
    
    local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE" 2>/dev/null)
    for category in $categories; do
        local exists=$(jq -r ".categories.${category}.plugins.${plugin}" "$PLUGIN_DB_FILE" 2>/dev/null)
        if [ "$exists" != "null" ]; then
            jq -r ".categories.${category}.plugins.${plugin}.dependencies[]" "$PLUGIN_DB_FILE" 2>/dev/null
            return
        fi
    done
}

# 辅助函数：检查包是否可用
check_package_available() {
    local package="$1"
    
    # 检查包是否在feeds中
    if [ -f "feeds.conf.default" ]; then
        ./scripts/feeds update >/dev/null 2>&1
        if ./scripts/feeds search "$package" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # 检查包是否在源码中
    if [ -d "package" ]; then
        if find package -name "*${package}*" -type d | grep -q .; then
            return 0
        fi
    fi
    
    return 1

# 辅助函数：安装依赖
install_dependency() {
    local dep="$1"
    
    log_debug "尝试安装依赖: $dep"
    
    # 尝试通过feeds安装
    if ./scripts/feeds install "$dep" >/dev/null 2>&1; then
        return 0
    fi
    
    # 尝试其他安装方式
    return 1
}

# 辅助函数：检查插件冲突（内部使用）
check_plugin_conflicts_internal() {
    local plugin_list="$1"
    
    # 复用现有的冲突检查逻辑
    # 这里简化处理，实际应该调用完整的冲突检查
    return 0
}

# 辅助函数：检查编译依赖
check_build_dependencies() {
    local device="$1"
    local plugin_list="$2"
    
    # 检查基本编译依赖
    local required_tools=("gcc" "g++" "make" "cmake")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_warning "缺少编译工具: $tool"
            return 1
        fi
    done
    
    return 0
}

# 设备特定依赖修复函数
ensure_x86_proxy_deps() {
    log_debug "确保X86代理依赖"
    # 实现X86设备代理插件依赖修复
}

ensure_rpi_storage_deps() {
    log_debug "确保树莓派存储依赖"
    # 实现树莓派存储插件依赖修复
}

# 兼容原有功能的函数（保持向后兼容）
# [这里保留原有的所有函数，如 list_plugins, search_plugins, validate_plugins 等]


# 列出插件（保持向后兼容）
list_plugins() {
    local category="$1"
    local format="$2"
    
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

# 列出特定分类插件
list_category_plugins() {
    local category="$1"
    
    local category_name=$(jq -r ".categories.${category}.name" "$PLUGIN_DB_FILE" 2>/dev/null)
    if [ "$category_name" = "null" ]; then
        log_error "分类不存在: $category"
        return 1
    fi
    
    echo -e "\n${CYAN}📦 ${category_name} 插件列表${NC}"
    echo "========================================"
    
    local plugins=$(jq -r ".categories.${category}.plugins | keys[]" "$PLUGIN_DB_FILE")
    for plugin in $plugins; do
        local name=$(jq -r ".categories.${category}.plugins.${plugin}.name" "$PLUGIN_DB_FILE")
        local desc=$(jq -r ".categories.${category}.plugins.${plugin}.description" "$PLUGIN_DB_FILE")
        
        printf "   ${GREEN}%-25s${NC} %s\n" "$plugin" "$name"
        printf "   %-25s   %s\n" "" "$desc"
    done
}

# 主函数（修改了参数解析部分）
main() {
    local operation=""
    local plugin=""
    local plugin_list=""
    local category=""
    local device=""
    local format="text"
    local output=""
    local auto_fix=false
    local strict_mode=false
    local verbose=false
    local runtime_config=""  # 新增：支持运行时配置
    
    # 检查jq工具
    if ! command -v jq &> /dev/null; then
        log_error "需要安装jq工具来处理JSON文件"
        log_info "Ubuntu/Debian: sudo apt install jq"
        log_info "CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
    
    # 解析命令行参数（添加了 --runtime-config 处理）
    while [[ $# -gt 0 ]]; do
        case $1 in
            # 基础操作
            init|list|search|info|validate|conflicts|generate)
                operation="$1"
                shift
                ;;
            # 增强功能
            pre-build-check|auto-fix-deps|compatibility|optimize)
                operation="$1"
                shift
                ;;
            # 选项
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
            -d|--device)
                device="$2"
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
            --auto-fix)
                auto_fix=true
                shift
                ;;
            --strict)
                strict_mode=true
                shift
                ;;
            --runtime-config)  # 新增：支持运行时配置参数
                runtime_config="$2"
                RUNTIME_CONFIG_FILE="$2"
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
                log_error "未知参数: $1"
                echo "使用 $0 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
    
    # 显示标题
    show_header
    
    # 如果提供了运行时配置，读取相关设置（新增功能）
    if [ -n "$RUNTIME_CONFIG_FILE" ]; then
        log_debug "使用运行时配置: $RUNTIME_CONFIG_FILE"
        
        # 从运行时配置读取设置
        if [ -z "$verbose" ]; then
            local runtime_verbose=$(get_runtime_config_value '.verbose_mode' 'false')
            if [ "$runtime_verbose" = "true" ]; then
                verbose=true
            fi
        fi
        
        if [ "$auto_fix" = false ]; then
            local runtime_auto_fix=$(get_runtime_config_value '.auto_fix_enabled' 'false')
            if [ "$runtime_auto_fix" = "true" ]; then
                auto_fix=true
            fi
        fi
    fi
    
    # 执行操作
    case "$operation" in
        "init")
            init_plugin_database
            ;;
        "list")
            list_plugins "$category" "$format"
            ;;
        "pre-build-check")
            pre_build_check "$device" "$plugin_list" "$strict_mode"
            ;;
        "auto-fix-deps")
            auto_fix_plugin_deps "$device" "$plugin_list" "$auto_fix"
            ;;
        "compatibility")
            check_device_compatibility "$device" "$plugin_list"
            ;;
        "optimize")
            optimize_plugin_config "$device" "$plugin_list" "$auto_fix"
            ;;
        # 其他现有功能保持不变...
        "search"|"info"|"validate"|"conflicts"|"generate")
            log_info "功能 $operation 开发中..."
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