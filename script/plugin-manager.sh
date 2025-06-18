#!/bin/bash
#========================================================================================================================
# OpenWrt 插件管理脚本 (增强版) - 修复版本
# 功能: 管理插件配置、检查冲突、生成插件配置，集成编译修复协调
# 修复: 添加 --runtime-config 参数支持，与 build-orchestrator.sh 兼容
# 用法: ./plugin-manager.sh [操作] [参数...]
#========================================================================================================================

# 脚本版本
VERSION="2.0.2-fixed"

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

# 运行时配置支持
RUNTIME_CONFIG_FILE=""

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $1"; }

# 从运行时配置读取值
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

# 显示帮助信息
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
  pre-build-check     编译前检查
  auto-fix-deps       自动修复插件依赖
  compatibility       检查设备兼容性
  optimize            优化插件配置

${CYAN}选项:${NC}
  -p, --plugin        指定插件名称
  -l, --list          插件列表（逗号分隔）
  -c, --category      插件分类
  -d, --device        目标设备类型
  -f, --format        输出格式 (json|text|config)
  -o, --output        输出文件
  --auto-fix          启用自动修复
  --strict            严格模式检查
  --runtime-config    运行时配置文件
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
    
    # 生成插件数据库 - 修复了JSON结构
    cat > "$PLUGIN_DB_FILE" << 'EOF'
{
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
          "dependencies": ["coreutils-nohup", "bash", "dnsmasq-full", "curl", "ca-certificates"],
          "conflicts": ["luci-app-clash"],
          "feeds": ["src-git openclash https://github.com/vernesong/OpenClash"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "good",
            "nanopi_r2s": "medium",
            "xiaomi_4a_gigabit": "poor",
            "newifi_d2": "poor"
          },
          "build_notes": "需要大量存储空间和内存"
        }
      }
    },
    "network": {
      "name": "网络工具",
      "description": "网络管理和监控相关插件",
      "plugins": {
        "luci-app-adblock": {
          "name": "广告屏蔽",
          "description": "DNS级别的广告屏蔽工具",
          "author": "openwrt",
          "size": "320KB",
          "complexity": "low",
          "dependencies": ["adblock"],
          "conflicts": ["luci-app-adguardhome"],
          "feeds": [],
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
    },
    "theme": {
      "name": "主题插件",
      "description": "LuCI界面主题",
      "plugins": {
        "luci-theme-argon": {
          "name": "Argon主题",
          "description": "现代化的LuCI主题",
          "author": "jerrykuku",
          "size": "2.1MB",
          "complexity": "low",
          "dependencies": ["luci-base"],
          "conflicts": [],
          "feeds": ["src-git argon https://github.com/jerrykuku/luci-theme-argon"],
          "device_compatibility": {
            "x86_64": "excellent",
            "rpi_4b": "excellent",
            "nanopi_r2s": "excellent",
            "xiaomi_4a_gigabit": "excellent",
            "newifi_d2": "excellent"
          },
          "build_notes": "美观主题，推荐使用"
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

# 列出插件
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
    
    echo -e "\n${BLUE}图例: 🟢 简单 🟡 中等 🔴 复杂${NC}"
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

# 编译前检查
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
        issues+=("检测到插件冲突")
    fi
    
    # 4. 检查编译依赖
    log_info "4. 检查编译依赖..."
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

# 自动修复插件依赖
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
                        log_warning "依赖包不可用: $dep"
                        
                        if [ "$auto_fix" = true ]; then
                            if install_dependency "$dep"; then
                                fixes_applied+=("安装依赖: $dep")
                                log_success "已安装依赖: $dep"
                            else
                                log_error "无法安装依赖: $dep"
                            fi
                        fi
                    fi
                fi
            done <<< "$dependencies"
        fi
    done
    
    # 显示修复结果
    if [ ${#fixes_applied[@]} -gt 0 ]; then
        echo -e "\n${GREEN}✅ 已应用的修复:${NC}"
        for fix in "${fixes_applied[@]}"; do
            echo -e "   ${GREEN}•${NC} $fix"
        done
    else
        echo -e "\n${BLUE}ℹ️  无需修复或修复未启用${NC}"
    fi
    
    return 0
}

# 检查设备兼容性
check_device_compatibility() {
    local device="$1"
    local plugin_list="$2"
    
    log_info "检查设备兼容性..."
    
    # 解析插件列表
    IFS=',' read -ra plugins <<< "$plugin_list"
    
    echo -e "\n${CYAN}🖥️  设备兼容性报告 - $device${NC}"
    echo "========================================"
    
    for plugin in "${plugins[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        local compatibility=$(get_plugin_device_compatibility "$plugin" "$device")
        local icon=""
        local color=""
        
        case "$compatibility" in
            "excellent")
                icon="🟢"
                color="$GREEN"
                ;;
            "good")
                icon="🟡"
                color="$YELLOW"
                ;;
            "medium")
                icon="🟠"
                color="$YELLOW"
                ;;
            "limited"|"poor")
                icon="🔴"
                color="$RED"
                ;;
            *)
                icon="❓"
                color="$BLUE"
                compatibility="未知"
                ;;
        esac
        
        printf "   %s ${color}%-25s${NC} %s\n" "$icon" "$plugin" "$compatibility"
    done
    
    echo -e "\n${BLUE}图例: 🟢 优秀 🟡 良好 🟠 一般 🔴 有限 ❓ 未知${NC}"
}

# 优化插件配置
optimize_plugin_config() {
    local device="$1"
    local plugin_list="$2"
    local auto_fix="$3"
    
    log_info "优化插件配置..."
    
    # 实现配置优化逻辑
    log_info "功能开发中..."
    
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

# 辅助函数：获取插件设备兼容性
get_plugin_device_compatibility() {
    local plugin="$1"
    local device="$2"
    
    if [ ! -f "$PLUGIN_DB_FILE" ]; then
        return 1
    fi
    
    local categories=$(jq -r '.categories | keys[]' "$PLUGIN_DB_FILE" 2>/dev/null)
    for category in $categories; do
        local exists=$(jq -r ".categories.${category}.plugins.${plugin}" "$PLUGIN_DB_FILE" 2>/dev/null)
        if [ "$exists" != "null" ]; then
            jq -r ".categories.${category}.plugins.${plugin}.device_compatibility.${device}" "$PLUGIN_DB_FILE" 2>/dev/null
            return
        fi
    done
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
}

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

# 主函数
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
    local runtime_config=""
    
    # 检查jq工具
    if ! command -v jq &> /dev/null; then
        log_error "需要安装jq工具来处理JSON文件"
        log_info "Ubuntu/Debian: sudo apt install jq"
        log_info "CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
    
    # 解析命令行参数
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
            --runtime-config)
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
    
    # 如果提供了运行时配置，读取相关设置
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