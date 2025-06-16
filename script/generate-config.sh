#!/bin/bash
#========================================================================================================================
# OpenWrt 配置生成器
# 功能: 根据设备和插件生成完整的.config文件
# 用法: ./generate-config.sh <device> <plugins>
#========================================================================================================================

# 设备基础配置
get_device_config() {
    local device="$1"
    
    case "$device" in
        "x86_64")
            cat << 'EOF'
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y
CONFIG_GRUB_IMAGES=y
CONFIG_GRUB_EFI_IMAGES=y
CONFIG_VDI_IMAGES=y
CONFIG_VMDK_IMAGES=y
CONFIG_TARGET_KERNEL_PARTSIZE=32
CONFIG_TARGET_ROOTFS_PARTSIZE=500
CONFIG_TARGET_IMAGES_GZIP=y
# X86专用包
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
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_xiaomi_mi-router-4a-gigabit=y
CONFIG_TARGET_IMAGES_GZIP=y
# MT7621专用
CONFIG_PACKAGE_kmod-mt7603=y
CONFIG_PACKAGE_kmod-mt76x2=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
EOF
            ;;
            
        "newifi_d2")
            cat << 'EOF'
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_d-team_newifi-d2=y
CONFIG_TARGET_IMAGES_GZIP=y
# MT7621专用
CONFIG_PACKAGE_kmod-mt7603=y
CONFIG_PACKAGE_kmod-mt76x2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_wpad-basic-wolfssl=y
EOF
            ;;
            
        "rpi_4b")
            cat << 'EOF'
CONFIG_TARGET_bcm27xx=y
CONFIG_TARGET_bcm27xx_bcm2711=y
CONFIG_TARGET_bcm27xx_bcm2711_DEVICE_rpi-4=y
CONFIG_TARGET_KERNEL_PARTSIZE=64
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
CONFIG_TARGET_IMAGES_GZIP=y
# 树莓派专用
CONFIG_PACKAGE_kmod-usb-net-asix=y
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
CONFIG_PACKAGE_bcm27xx-gpu-fw=y
CONFIG_PACKAGE_bcm27xx-userland=y
EOF
            ;;
            
        "nanopi_r2s")
            cat << 'EOF'
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r2s=y
CONFIG_TARGET_KERNEL_PARTSIZE=32
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
CONFIG_TARGET_IMAGES_GZIP=y
# R2S专用
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
EOF
            ;;
            
        *)
            echo "# 未知设备: $device"
            ;;
    esac
}

# 通用基础配置
get_common_config() {
    cat << 'EOF'

#
# ======================== 编译选项 ========================
#

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

#
# ======================== 内核配置 ========================
#

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

#
# ======================== 基础软件包 ========================
#

# LuCI界面
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y

# 主题
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

# 常用依赖
CONFIG_PACKAGE_kmod-nf-nathelper=y
CONFIG_PACKAGE_kmod-nf-nathelper-extra=y

EOF
}

# 获取插件配置
get_plugin_config() {
    local plugin="$1"
    
    case "$plugin" in
        "luci-app-ssr-plus")
            cat << 'EOF'

# SSR Plus+
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Trojan=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_NaiveProxy=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_IPT2Socks=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Kcptun=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Server=y
CONFIG_PACKAGE_luci-i18n-ssr-plus-zh-cn=y
EOF
            ;;
            
        "luci-app-passwall")
            cat << 'EOF'

# PassWall
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Brook=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y
EOF
            ;;
            
        "luci-app-openclash")
            cat << 'EOF'

# OpenClash
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_iptables-mod-tproxy=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_iptables-mod-conntrack-extra=y
EOF
            ;;
            
        "luci-app-dockerman")
            cat << 'EOF'

# Docker
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_docker-ce=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_containerd=y
CONFIG_PACKAGE_runc=y
CONFIG_KERNEL_NAMESPACES=y
CONFIG_KERNEL_CGROUP_DEVICE=y
CONFIG_KERNEL_CGROUP_FREEZER=y
CONFIG_KERNEL_CGROUP_NET_PRIO=y
CONFIG_KERNEL_EXT4_FS_POSIX_ACL=y
CONFIG_KERNEL_FS_POSIX_ACL=y
CONFIG_KERNEL_NET_CLS_CGROUP=y
CONFIG_KERNEL_CFQ_GROUP_IOSCHED=y
CONFIG_KERNEL_CGROUP_PERF=y
CONFIG_KERNEL_MEMCG=y
CONFIG_KERNEL_MEMCG_SWAP=y
CONFIG_KERNEL_MEMCG_SWAP_ENABLED=y
CONFIG_KERNEL_BLK_DEV_THROTTLING=y
CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y
EOF
            ;;
            
        "luci-app-turboacc")
            cat << 'EOF'

# Turbo ACC
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_SHORTCUT_FE=y
CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_BBR_CCA=y
CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_DNSFORWARDER=y
CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_DNSPROXY=y
CONFIG_PACKAGE_luci-i18n-turboacc-zh-cn=y
EOF
            ;;
            
        "luci-app-ttyd")
            cat << 'EOF'

# TTYD终端
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_ttyd=y
CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y
EOF
            ;;
            
        "luci-app-adguardhome")
            cat << 'EOF'

# AdGuard Home
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_adguardhome=y
EOF
            ;;
            
        *)
            echo "# 插件: $plugin"
            echo "CONFIG_PACKAGE_$plugin=y"
            ;;
    esac
}

# 主函数
main() {
    if [ $# -lt 1 ]; then
        echo "使用方法: $0 <device> [plugins]"
        echo "示例: $0 x86_64 'luci-app-ssr-plus,luci-app-dockerman'"
        exit 1
    fi
    
    local device="$1"
    local plugins_str="${2:-}"
    local output_file="${3:-.config}"
    
    echo "📋 生成配置文件..."
    echo "  设备: $device"
    echo "  插件: $plugins_str"
    echo "  输出: $output_file"
    echo ""
    
    # 生成配置文件
    {
        echo "#"
        echo "# OpenWrt 配置文件"
        echo "# 自动生成时间: $(date)"
        echo "# 设备: $device"
        echo "#"
        echo ""
        
        # 设备配置
        echo "#"
        echo "# ======================== 设备配置 ========================"
        echo "#"
        get_device_config "$device"
        
        # 通用配置
        get_common_config
        
        # 插件配置
        if [ -n "$plugins_str" ]; then
            echo ""
            echo "#"
            echo "# ======================== 插件配置 ========================"
            echo "#"
            
            IFS=',' read -ra PLUGINS <<< "$plugins_str"
            for plugin in "${PLUGINS[@]}"; do
                get_plugin_config "$plugin"
            done
        fi
        
    } > "$output_file"
    
    echo "✅ 配置文件生成完成！"
    echo ""
    echo "📄 文件位置: $output_file"
    echo "📏 文件大小: $(wc -l < "$output_file") 行"
}

# 执行主函数
main "$@"