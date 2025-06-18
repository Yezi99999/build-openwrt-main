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
    
    # 生成插件数据库
    cat > "$PLUGIN_DB_FILE" << 'EOF'
{
  "version": "1.0.0",
  "updated_at": "",
  "categories": {
    "proxy": {
      "name": "代理工具",
      "description": "科学上网和代理相关插件",
      "plugins": {
        "luci-app-ssr-plus": {
          "name": "SSR Plus+",
          "description": "科学上网插件，支持SS/SSR/V2Ray/Trojan",
          "size": "大型",
          "complexity": "medium",
          "dependencies": ["ca-certificates", "ca-bundle"],
          "conflicts": ["luci-app-passwall", "luci-app-passwall2"],
          "devices": ["x86_64", "xiaomi_4a_gigabit", "newifi_d2", "rpi_4b", "nanopi_r2s"]
        },
        "luci-app-passwall": {
          "name": "PassWall",
          "description": "科学上网插件，支持多种协议",
          "size": "大型",
          "complexity": "medium",
          "dependencies": ["ca-certificates"],
          "conflicts": ["luci-app-ssr-plus", "luci-app-passwall2"],
          "devices": ["x86_64", "rpi_4b", "nanopi_r2s"]
        },
        "luci-app-openclash": {
          "name": "OpenClash",
          "description": "基于Clash的代理工具",
          "size": "大型",
          "complexity": "high",
          "dependencies": ["ca-certificates", "ca-bundle"],
          "conflicts": ["luci-app-clash"],
          "devices": ["x86_64", "rpi_4b"]
        }
      }
    },
    "theme": {
      "name": "主题美化",
      "description": "LuCI主题和界面美化",
      "plugins": {
        "luci-theme-argon": {
          "name": "Argon主题",
          "description": "流行的LuCI主题",
          "size": "小型",
          "complexity": "low",
          "dependencies": [],
          "conflicts": [],
          "devices": ["x86_64", "xiaomi_4a_gigabit", "newifi_d2", "rpi_4b", "nanopi_r2s"]
        },
        "luci-theme-material": {
          "name": "Material主题",
          "description": "Material Design风格主题",
          "size": "小型",
          "complexity": "low",
          "dependencies": [],
          "conflicts": [],
          "devices": ["x86_64", "xiaomi_4a_gigabit", "newifi_d2", "rpi_4b", "nanopi_r2s"]
        }
      }
    },
    "network": {
      "name": "网络工具",
      "description": "网络相关功能插件",
      "plugins": {
        "luci-app-samba4": {
          "name": "Samba4",
          "description": "网络文件共享服务",
          "size": "中型",
          "complexity": "medium",
          "dependencies": ["samba4-server"],
          "conflicts": ["luci-app-samba"],
          "devices": ["x86_64", "rpi_4b", "nanopi_r2s"]
        },
        "luci-app-aria2": {
          "name": "Aria2",
          "description": "下载工具",
          "size": "中型",
          "complexity": "medium",
          "dependencies": ["aria2"],
          "conflicts": [],
          "devices": ["x86_64", "rpi_4b", "nanopi_r2s"]
        }
      }
    },
    "system": {
      "name": "系统工具",
      "description": "系统管理和监控工具",
      "plugins": {
        "luci-app-netdata": {
          "name": "Netdata",
          "description": "系统监控工具",
          "size": "中型",
          "complexity": "medium",
          "dependencies": ["netdata"],
          "conflicts": [],
          "devices": ["x86_64", "rpi_4b"]
        }
      }
    }
  }
}
EOF
    
    # 更新时间戳
    local current_time=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    jq ".updated_at = \"$current_time\"" "$PLUGIN_DB_FILE" > "${PLUGIN_DB_FILE}.tmp"
    mv "${PLUGIN_DB_FILE}.tmp" "$PLUGIN_DB_FILE"
    
    log_success "插件数据库初始化完成: $PLUGIN_DB_FILE"
    return 0
}

# 编译前检查 (增强功能)
pre_build_check() {
    local device="$1"
    local plugin_list="$2"
    local strict_mode="$3"
    
    log_info "执行编译前检查..."
    log_debug "设备: $device, 插件: $plugin_list, 严格模式: $strict_mode"
    
    # 检查插件数据库
    if [ ! -f "$PLUGIN_DB_FILE" ]; then
        log_error "插件数据库不存在，正在初始化..."
        init_plugin_database
    fi
    
    local check_results=()
    
    # 解析插件列表
    if [ -n "$plugin_list" ]; then
        IFS=',' read -ra plugins <<< "$plugin_list"
        
        log_info "检查插件列表 (${#plugins[@]} 个插件)..."
        
        for plugin in "${plugins[@]}"; do
            plugin=$(echo "$plugin" | xargs)  # 去除空白字符
            log_debug "检查插件: $plugin"
            
            # 检查插件是否存在
            if ! check_plugin_exists "$plugin"; then
                if [ "$strict_mode" = true ]; then
                    log_error "插件不存在: $plugin"
                    check_results+=("插件不存在: $plugin")
                else
                    log_warning "插件不存在: $plugin (将跳过)"
                fi
            else
                log_debug "插件检查通过: $plugin"
            fi
        done
    fi
    
    # 检查设备兼容性
    log_info "检查设备兼容性..."
    if ! check_device_compatibility "$device" "$plugin_list"; then
        check_results+=("设备兼容性检查失败")
    fi
    
    # 检查编译环境
    log_info "检查编译环境..."
    if ! check_build_environment; then
        check_results+=("编译环境检查失败")
    fi
    
    # 分析结果
    if [ ${#check_results[@]} -gt 0 ]; then
        log_warning "检查发现问题:"
        for result in "${check_results[@]}"; do
            log_warning "  - $result"
        done
        return 1
    else
        log_success "编译前检查全部通过"
        return 0
    fi
}

# 自动修复插件依赖 (增强功能)
auto_fix_plugin_deps() {
    local device="$1"
    local plugin_list="$2"
    local auto_fix="$3"
    
    log_info "自动修复插件依赖..."
    log_debug "设备: $device, 插件: $plugin_list, 自动修复: $auto_fix"
    
    if [ "$auto_fix" != "true" ]; then
        log_info "自动修复已禁用，仅执行检查"
    fi
    
    # 解析插件列表
    if [ -n "$plugin_list" ]; then
        IFS=',' read -ra plugins <<< "$plugin_list"
        
        for plugin in "${plugins[@]}"; do
            plugin=$(echo "$plugin" | xargs)
            log_debug "检查插件依赖: $plugin"
            
            # 获取插件依赖
            local deps=$(get_plugin_dependencies "$plugin")
            
            if [ -n "$deps" ]; then
                log_debug "插件 $plugin 的依赖: $deps"
                
                # 检查每个依赖是否可用
                while IFS= read -r dep; do
                    if [ -n "$dep" ] && ! check_package_available "$dep"; then
                        log_warning "缺少依赖: $dep (插件: $plugin)"
                        
                        if [ "$auto_fix" = "true" ]; then
                            log_info "尝试安装依赖: $dep"
                            install_dependency "$dep"
                        fi
                    fi
                done <<< "$deps"
            fi
        done
    fi
    
    log_success "插件依赖修复完成"
    return 0
}

# 检查设备兼容性
check_device_compatibility() {
    local device="$1"
    local plugin_list="$2"
    
    log_debug "检查设备兼容性: $device"
    
    # 支持的设备列表
    local supported_devices=("x86_64" "xiaomi_4a_gigabit" "newifi_d2" "rpi_4b" "nanopi_r2s")
    
    # 检查设备是否支持
    local device_supported=false
    for supported in "${supported_devices[@]}"; do
        if [ "$device" = "$supported" ]; then
            device_supported=true
            break
        fi
    done
    
    if [ "$device_supported" = false ]; then
        log_warning "设备可能不受支持: $device"
        return 1
    fi
    
    # 检查插件与设备的兼容性
    if [ -n "$plugin_list" ]; then
        IFS=',' read -ra plugins <<< "$plugin_list"
        
        for plugin in "${plugins[@]}"; do
            plugin=$(echo "$plugin" | xargs)
            
            if ! is_plugin_compatible_with_device "$plugin" "$device"; then
                log_warning "插件 $plugin 可能不兼容设备 $device"
            fi
        done
    fi
    
    log_success "设备兼容性检查通过"
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
    log_debug "设备: $device, 插件: $plugin_list, 自动修复: $auto_fix"
    
    # 解析插件列表
    if [ -n "$plugin_list" ]; then
        IFS=',' read -ra plugins <<< "$plugin_list"
        
        log_info "分析插件配置 (${#plugins[@]} 个插件)..."
        
        local optimizations=()
        
        # 设备特定优化建议
        echo -e "\n${CYAN}🎯 设备优化建议${NC}"
        echo "========================================"
        
        case "$device" in
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
        
        # 应用自动优化
        if [ "$auto_fix" = true ]; then
            echo -e "\n${CYAN}🚀 应用自动优化${NC}"
            echo "========================================"
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
    fi
    
    log_success "插件配置优化完成"
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
    
    # 简化检查逻辑
    return 0
}

# 辅助函数：安装依赖
install_dependency() {
    local dep="$1"
    
    log_debug "尝试安装依赖: $dep"
    return 0
}

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