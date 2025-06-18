#!/bin/bash
#========================================================================================================================
# OpenWrt 配置生成器 (增强版)
# 功能: 根据设备和插件生成完整的.config文件，集成自动修复功能
# 用法: ./generate-config.sh <device> <plugins> [output_file] [--auto-fix]
#========================================================================================================================

# 脚本版本
SCRIPT_VERSION="2.0.0"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXES_DIR="$SCRIPT_DIR/fixes"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $1"; }

# 显示脚本标题
show_header() {
    echo -e "${CYAN}"
    echo "========================================================================================================================="
    echo "                             🔧 OpenWrt 配置生成器 v${SCRIPT_VERSION} (增强版)"
    echo "                                      集成自动修复功能"
    echo "========================================================================================================================="
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
${CYAN}使用方法:${NC}
  $0 <device> <plugins> [output_file] [options]

${CYAN}参数说明:${NC}
  device              目标设备类型
  plugins             插件列表 (逗号分隔，可为空)
  output_file         输出文件路径 (默认: .config)

${CYAN}选项:${NC}
  --auto-fix          启用自动修复功能
  --no-validate       跳过配置验证
  --dry-run           仅生成配置，不写入文件
  --verbose           详细输出
  --help              显示帮助信息

${CYAN}支持的设备:${NC}
  x86_64              X86 64位设备
  xiaomi_4a_gigabit   小米路由器4A千兆版
  newifi_d2           新路由3
  rpi_4b              树莓派4B
  nanopi_r2s          NanoPi R2S

${CYAN}示例:${NC}
  # 基本使用
  $0 x86_64 "luci-app-ssr-plus,luci-theme-argon"
  
  # 启用自动修复
  $0 x86_64 "luci-app-ssr-plus" .config --auto-fix
  
  # 树莓派设备，无插件
  $0 rpi_4b ""
  
  # 仅生成，不保存
  $0 x86_64 "luci-app-ssr-plus" --dry-run

${CYAN}自动修复功能:${NC}
  自动检测并修复常见编译问题:
  - udebug/ucode 依赖错误 (X86设备)
  - imx219 摄像头补丁错误 (树莓派)
  - 内核补丁冲突
  - feeds 依赖问题
  - 其他设备特定问题
EOF
}

# 检查环境和依赖
check_environment() {
    log_info "检查运行环境..."
    
    # 检查是否在OpenWrt源码根目录
    if [ ! -f "package/Makefile" ] || [ ! -d "target/linux" ]; then
        log_error "请在OpenWrt源码根目录下运行此脚本"
        return 1
    fi
    
    # 检查修复脚本目录
    if [ ! -d "$FIXES_DIR" ]; then
        log_warning "修复脚本目录不存在，创建: $FIXES_DIR"
        mkdir -p "$FIXES_DIR"
    fi
    
    # 确保修复脚本有执行权限
    if [ -d "$FIXES_DIR" ]; then
        chmod +x "$FIXES_DIR"/*.sh 2>/dev/null || true
    fi
    
    log_success "环境检查完成"
    return 0
}

# 设备基础配置
get_device_config() {
    local device="$1"
    
    log_debug "生成设备配置: $device"
    
    case "$device" in
        "x86_64")
            cat << 'EOF'
# ======================== X86_64 设备配置 ========================
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y

# 引导配置
CONFIG_GRUB_IMAGES=y
CONFIG_GRUB_EFI_IMAGES=y
CONFIG_VDI_IMAGES=y
CONFIG_VMDK_IMAGES=y

# 分区大小
CONFIG_TARGET_KERNEL_PARTSIZE=32
CONFIG_TARGET_ROOTFS_PARTSIZE=500
CONFIG_TARGET_IMAGES_GZIP=y

# X86网卡驱动
CONFIG_PACKAGE_kmod-e1000=y
CONFIG_PACKAGE_kmod-e1000e=y
CONFIG_PACKAGE_kmod-igb=y
CONFIG_PACKAGE_kmod-igbvf=y
CONFIG_PACKAGE_kmod-ixgbe=y
CONFIG_PACKAGE_kmod-r8125=y
CONFIG_PACKAGE_kmod-r8168=y
CONFIG_PACKAGE_kmod-vmxnet3=y
EOF
            ;;
            
        "xiaomi_4a_gigabit")
            cat << 'EOF'
# ======================== 小米4A千兆版配置 ========================
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_xiaomi_mi-router-4a-gigabit=y

# 图像压缩
CONFIG_TARGET_IMAGES_GZIP=y

# MT7621无线驱动
CONFIG_PACKAGE_kmod-mt7603=y
CONFIG_PACKAGE_kmod-mt76x2=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
EOF
            ;;
            
        "newifi_d2")
            cat << 'EOF'
# ======================== 新路由3配置 ========================
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_d-team_newifi-d2=y

# 图像压缩
CONFIG_TARGET_IMAGES_GZIP=y

# MT7621无线和USB驱动
CONFIG_PACKAGE_kmod-mt7603=y
CONFIG_PACKAGE_kmod-mt76x2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
EOF
            ;;
            
        "rpi_4b")
            cat << 'EOF'
# ======================== 树莓派4B配置 ========================
CONFIG_TARGET_bcm27xx=y
CONFIG_TARGET_bcm27xx_bcm2711=y
CONFIG_TARGET_bcm27xx_bcm2711_DEVICE_rpi-4=y

# 分区大小
CONFIG_TARGET_KERNEL_PARTSIZE=64
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
CONFIG_TARGET_IMAGES_GZIP=y

# 树莓派特定驱动
CONFIG_PACKAGE_kmod-usb-net-asix=y
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
CONFIG_PACKAGE_bcm27xx-gpu-fw=y
CONFIG_PACKAGE_bcm27xx-userland=y
EOF
            ;;
            
        "nanopi_r2s")
            cat << 'EOF'
# ======================== NanoPi R2S配置 ========================
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r2s=y

# 分区大小
CONFIG_TARGET_KERNEL_PARTSIZE=32
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
CONFIG_TARGET_IMAGES_GZIP=y

# R2S特定驱动
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
EOF
            ;;
            
        *)
            log_warning "未知设备类型: $device，使用通用配置"
            cat << 'EOF'
# ======================== 通用设备配置 ========================
# 请根据实际设备修改目标配置
CONFIG_TARGET_IMAGES_GZIP=y
EOF
            ;;
    esac
}

# 通用基础配置
get_common_config() {
    cat << 'EOF'

# ======================== 编译选项 ========================

# 编译工具链
CONFIG_MAKE_TOOLCHAIN=y
CONFIG_IB=y
CONFIG_SDK=y

# 文件系统
CONFIG_TARGET_ROOTFS_EXT4FS=y
CONFIG_TARGET_ROOTFS_SQUASHFS=y

# 构建设置
CONFIG_SIGNED_PACKAGES=y
CONFIG_SIGNATURE_CHECK=y
CONFIG_BUILD_LOG=y

# ======================== 内核配置 ========================

# IPv6支持
CONFIG_IPV6=y
CONFIG_KERNEL_IPV6=y
CONFIG_PACKAGE_ipv6helper=y

# 文件系统支持
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-ntfs=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_ntfs-3g=y

# USB支持
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y

# 网络优化
CONFIG_PACKAGE_kmod-tcp-bbr=y
CONFIG_PACKAGE_kmod-tun=y

# ======================== 基础软件包 ========================

# LuCI界面
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y

# 默认主题
CONFIG_PACKAGE_luci-theme-bootstrap=y

# 系统工具
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_iperf3=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_vim=y
CONFIG_PACKAGE_wget-ssl=y

# 网络基础依赖
CONFIG_PACKAGE_kmod-nf-nathelper=y
CONFIG_PACKAGE_kmod-nf-nathelper-extra=y

EOF
}

# 获取插件配置
get_plugin_config() {
    local plugin="$1"
    
    log_debug "生成插件配置: $plugin"
    
    case "$plugin" in
        "luci-app-ssr-plus")
            cat << 'EOF'

# ======================== SSR Plus+ 插件 ========================
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Simple_Obfs=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Trojan=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_NaiveProxy=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Redsocks2=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Client=y
CONFIG_PACKAGE_luci-i18n-ssr-plus-zh-cn=y
EOF
            ;;
            
        "luci-app-passwall")
            cat << 'EOF'

# ======================== PassWall 插件 ========================
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Brook=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ChinaDNS_NG=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y
EOF
            ;;
            
        "luci-app-openclash")
            cat << 'EOF'

# ======================== OpenClash 插件 ========================
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-i18n-openclash-zh-cn=y
# OpenClash 内核文件需要手动下载
EOF
            ;;
            
        "luci-theme-argon")
            cat << 'EOF'

# ======================== Argon 主题 ========================
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
EOF
            ;;
            
        "luci-theme-edge")
            cat << 'EOF'

# ======================== Edge 主题 ========================
CONFIG_PACKAGE_luci-theme-edge=y
EOF
            ;;
            
        "luci-app-frpc")
            cat << 'EOF'

# ======================== FRP 客户端 ========================
CONFIG_PACKAGE_luci-app-frpc=y
CONFIG_PACKAGE_luci-i18n-frpc-zh-cn=y
CONFIG_PACKAGE_frp=y
EOF
            ;;
            
        "luci-app-ddns")
            cat << 'EOF'

# ======================== 动态DNS ========================
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-i18n-ddns-zh-cn=y
CONFIG_PACKAGE_ddns-scripts=y
CONFIG_PACKAGE_ddns-scripts-services=y
EOF
            ;;
            
        "luci-app-upnp")
            cat << 'EOF'

# ======================== UPnP 服务 ========================
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-i18n-upnp-zh-cn=y
CONFIG_PACKAGE_miniupnpd=y
EOF
            ;;
            
        "luci-app-samba4")
            cat << 'EOF'

# ======================== Samba4 文件共享 ========================
CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_luci-i18n-samba4-zh-cn=y
CONFIG_PACKAGE_samba4-libs=y
CONFIG_PACKAGE_samba4-server=y
EOF
            ;;
            
        "luci-app-aria2")
            cat << 'EOF'

# ======================== Aria2 下载器 ========================
CONFIG_PACKAGE_luci-app-aria2=y
CONFIG_PACKAGE_luci-i18n-aria2-zh-cn=y
CONFIG_PACKAGE_aria2=y
CONFIG_PACKAGE_ariang=y
EOF
            ;;
            
        "luci-app-adbyby-plus")
            cat << 'EOF'

# ======================== ADByby Plus+ 广告过滤 ========================
CONFIG_PACKAGE_luci-app-adbyby-plus=y
CONFIG_PACKAGE_luci-i18n-adbyby-plus-zh-cn=y
CONFIG_PACKAGE_adbyby=y
EOF
            ;;
            
        "luci-app-adguardhome")
            cat << 'EOF'

# ======================== AdGuard Home ========================
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-i18n-adguardhome-zh-cn=y
CONFIG_PACKAGE_adguardhome=y
EOF
            ;;
            
        "luci-app-wol")
            cat << 'EOF'

# ======================== 网络唤醒 ========================
CONFIG_PACKAGE_luci-app-wol=y
CONFIG_PACKAGE_luci-i18n-wol-zh-cn=y
CONFIG_PACKAGE_etherwake=y
EOF
            ;;
            
        *)
            log_warning "未知插件: $plugin，生成基本配置"
            echo ""
            echo "# 未知插件配置: $plugin"
            echo "CONFIG_PACKAGE_${plugin}=y"
            ;;
    esac
}

# 加载自动修复函数
load_auto_fix_functions() {
    local common_script="$FIXES_DIR/common.sh"
    
    if [ -f "$common_script" ]; then
        log_debug "加载修复函数: $common_script"
        source "$common_script"
        return 0
    else
        log_warning "修复函数文件不存在: $common_script"
        return 1
    fi
}

# 检测潜在编译问题
detect_potential_issues() {
    local device="$1"
    local plugins="$2"
    
    log_info "检测潜在编译问题..."
    
    local potential_issues=()
    
    # 设备特定问题检测
    case "$device" in
        "x86_64")
            # X86设备常见udebug问题
            potential_issues+=("udebug_dependency")
            log_debug "X86设备: 可能遇到udebug依赖问题"
            ;;
        "rpi_4b")
            # 树莓派摄像头补丁问题
            potential_issues+=("imx219_patch")
            log_debug "树莓派: 可能遇到摄像头补丁问题"
            ;;
        "nanopi_r2s")
            # R2S设备特定问题
            potential_issues+=("arm_build")
            log_debug "NanoPi R2S: 可能遇到ARM编译问题"
            ;;
    esac
    
    # 插件特定问题检测
    if echo "$plugins" | grep -q "ssr-plus\|passwall\|openclash"; then
        potential_issues+=("proxy_dependency")
        log_debug "代理插件: 可能需要额外依赖"
    fi
    
    if echo "$plugins" | grep -q "theme"; then
        potential_issues+=("theme_conflict")
        log_debug "主题插件: 可能与默认主题冲突"
    fi
    
    if [ ${#potential_issues[@]} -gt 0 ]; then
        log_warning "检测到潜在问题: ${potential_issues[*]}"
        echo "${potential_issues[@]}"
    else
        log_success "未检测到明显问题"
        echo ""
    fi
}

# 应用自动修复
apply_auto_fixes() {
    local device="$1"
    local auto_fix="$2"
    
    if [ "$auto_fix" != true ]; then
        log_debug "自动修复功能未启用"
        return 0
    fi
    
    log_info "开始应用自动修复..."
    
    # 确保修复脚本存在且可执行
    local main_fix_script="$FIXES_DIR/fix-build-issues.sh"
    
    if [ ! -f "$main_fix_script" ]; then
        log_warning "主修复脚本不存在: $main_fix_script"
        return 1
    fi
    
    chmod +x "$main_fix_script"
    
    # 执行自动修复
    log_info "执行设备特定修复: $device"
    if "$main_fix_script" "$device" "auto"; then
        log_success "自动修复完成"
        return 0
    else
        log_warning "自动修复执行时遇到问题，但继续处理"
        return 0
    fi
}

# 验证生成的配置
validate_config() {
    local config_content="$1"
    local device="$2"
    
    log_info "验证生成的配置..."
    
    local issues=()
    
    # 检查基本配置项
    if ! echo "$config_content" | grep -q "CONFIG_TARGET_"; then
        issues+=("缺少目标平台配置")
    fi
    
    if ! echo "$config_content" | grep -q "CONFIG_PACKAGE_luci=y"; then
        issues+=("缺少LuCI界面")
    fi
    
    # 设备特定验证
    case "$device" in
        "x86_64")
            if ! echo "$config_content" | grep -q "CONFIG_TARGET_x86_64=y"; then
                issues+=("X86_64配置不正确")
            fi
            ;;
        "rpi_4b")
            if ! echo "$config_content" | grep -q "CONFIG_TARGET_bcm27xx=y"; then
                issues+=("树莓派配置不正确")
            fi
            ;;
    esac
    
    if [ ${#issues[@]} -gt 0 ]; then
        log_warning "配置验证发现问题:"
        for issue in "${issues[@]}"; do
            log_warning "  - $issue"
        done
        return 1
    else
        log_success "配置验证通过"
        return 0
    fi
}

# 生成完整配置
generate_full_config() {
    local device="$1"
    local plugins="$2"
    local auto_fix="$3"
    
    log_info "生成完整配置 - 设备: $device"
    
    # 生成配置内容
    local config_content=""
    
    # 配置文件头
    config_content+="# ========================================================================================================================
# OpenWrt 编译配置文件
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 生成工具: generate-config.sh v${SCRIPT_VERSION}
# 目标设备: $device
# 选择插件: $plugins
# 自动修复: $auto_fix
# ========================================================================================================================"$'\n'
    
    # 设备配置
    config_content+="$(get_device_config "$device")"
    
    # 通用配置
    config_content+="$(get_common_config)"
    
    # 插件配置
    if [ -n "$plugins" ]; then
        log_info "处理插件列表: $plugins"
        
        # 解析插件列表
        IFS=',' read -ra plugin_array <<< "$plugins"
        
        for plugin in "${plugin_array[@]}"; do
            # 清理插件名称（去除空格）
            plugin=$(echo "$plugin" | xargs)
            
            if [ -n "$plugin" ]; then
                config_content+="$(get_plugin_config "$plugin")"
            fi
        done
    else
        log_info "未指定插件，仅生成基础配置"
    fi
    
    # 配置文件尾
    config_content+="
# ======================== 配置文件结束 ========================
# 注意事项:
# 1. 首次编译前请执行: make menuconfig 检查配置
# 2. 建议使用: make -j\$(nproc) V=s 进行编译
# 3. 如遇到问题，可使用 --auto-fix 选项重新生成
# ========================================================================================================================"
    
    echo "$config_content"
}

# 主函数
main() {
    local device=""
    local plugins=""
    local output_file=".config"
    local auto_fix=false
    local validate=true
    local dry_run=false
    local verbose=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-fix)
                auto_fix=true
                shift
                ;;
            --no-validate)
                validate=false
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version)
                echo "generate-config.sh v${SCRIPT_VERSION}"
                exit 0
                ;;
            -*)
                log_error "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
            *)
                if [ -z "$device" ]; then
                    device="$1"
                elif [ -z "$plugins" ]; then
                    plugins="$1"
                elif [ -z "$output_file" ] || [ "$output_file" = ".config" ]; then
                    output_file="$1"
                fi
                shift
                ;;
        esac
    done
    
    # 显示标题
    show_header
    
    # 检查必需参数
    if [ -z "$device" ]; then
        log_error "请指定设备类型"
        echo "使用 --help 查看帮助信息"
        exit 1
    fi
    
    # 检查环境
    if ! check_environment; then
        exit 1
    fi
    
    # 加载自动修复函数
    if [ "$auto_fix" = true ]; then
        load_auto_fix_functions
    fi
    
    # 检测潜在问题
    if [ "$verbose" = true ]; then
        detect_potential_issues "$device" "$plugins"
    fi
    
    # 应用自动修复（在生成配置之前）
    if [ "$auto_fix" = true ]; then
        apply_auto_fixes "$device" "$auto_fix"
    fi
    
    # 生成配置
    log_info "开始生成配置文件..."
    local config_content=$(generate_full_config "$device" "$plugins" "$auto_fix")
    
    # 验证配置
    if [ "$validate" = true ]; then
        if ! validate_config "$config_content" "$device"; then
            log_warning "配置验证失败，但继续处理"
        fi
    fi
    
    # 输出配置
    if [ "$dry_run" = true ]; then
        log_info "仅显示配置内容 (dry-run模式):"
        echo "----------------------------------------"
        echo "$config_content"
        echo "----------------------------------------"
    else
        # 备份现有配置文件
        if [ -f "$output_file" ]; then
            local backup_file="${output_file}.backup.$(date +%Y%m%d_%H%M%S)"
            log_warning "备份现有配置文件: $backup_file"
            cp "$output_file" "$backup_file"
        fi
        
        # 写入配置文件
        echo "$config_content" > "$output_file"
        
        if [ $? -eq 0 ]; then
            log_success "配置文件已生成: $output_file"
            
            # 显示文件信息
            local file_size=$(stat -c%s "$output_file" 2>/dev/null || wc -c < "$output_file")
            local line_count=$(wc -l < "$output_file")
            log_info "文件大小: ${file_size} 字节，共 ${line_count} 行"
            
            # 设置执行权限
            chmod +x "$output_file"
            
            # 显示后续操作建议
            show_next_steps "$device" "$plugins" "$auto_fix"
        else
            log_error "写入配置文件失败: $output_file"
            exit 1
        fi
    fi
    
    log_success "配置生成完成"
}

# 显示后续操作建议
show_next_steps() {
    local device="$1"
    local plugins="$2"
    local auto_fix="$3"
    
    echo -e "\n${CYAN}📋 后续操作建议${NC}"
    echo "========================================"
    echo -e "${GREEN}1. 更新和安装feeds:${NC}"
    echo "   ./scripts/feeds update -a"
    echo "   ./scripts/feeds install -a"
    echo ""
    echo -e "${GREEN}2. 检查和调整配置:${NC}"
    echo "   make menuconfig"
    echo ""
    echo -e "${GREEN}3. 开始编译:${NC}"
    echo "   make download -j8 V=s"
    echo "   make -j\$(nproc) V=s"
    echo ""
    
    # 设备特定建议
    case "$device" in
        "x86_64")
            echo -e "${YELLOW}X86设备特别注意:${NC}"
            echo "   - 确保有足够的磁盘空间 (建议20GB+)"
            echo "   - 编译时间较长，建议使用多线程"
            if [ "$auto_fix" = true ]; then
                echo "   - 已应用udebug问题自动修复"
            fi
            ;;
        "rpi_4b")
            echo -e "${YELLOW}树莓派特别注意:${NC}"
            echo "   - 使用32GB以上SD卡"
            echo "   - 首次启动可能需要扩展分区"
            if [ "$auto_fix" = true ]; then
                echo "   - 已修复摄像头补丁冲突问题"
            fi
            ;;
        "nanopi_r2s")
            echo -e "${YELLOW}NanoPi R2S特别注意:${NC}"
            echo "   - 确保使用高速SD卡 (Class 10+)"
            echo "   - 编译后固件大小约100-300MB"
            ;;
    esac
    
    if [ -n "$plugins" ]; then
        echo ""
        echo -e "${BLUE}插件相关提示:${NC}"
        echo "   - 部分插件可能需要额外配置文件"
        echo "   - 代理插件需要手动配置服务器信息"
        echo "   - 主题插件在LuCI界面-系统-系统设置中切换"
    fi
    
    if [ "$auto_fix" = true ]; then
        echo ""
        echo -e "${GREEN}✅ 自动修复功能已启用${NC}"
        echo "   如仍遇到编译问题，请查看编译日志并:"
        echo "   1. 运行 make clean 清理编译缓存"
        echo "   2. 重新执行本脚本并添加 --verbose 选项"
        echo "   3. 检查 script/fixes/ 目录下的修复脚本"
    else
        echo ""
        echo -e "${YELLOW}💡 提示: 如遇到编译问题${NC}"
        echo "   可使用 --auto-fix 选项重新生成配置以应用自动修复"
    fi
}

# 检查脚本是否被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi