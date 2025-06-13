/**
 * OpenWrt 智能编译向导 - 修复版本
 * 解决DOM元素引用和初始化问题
 */

class WizardManager {
    constructor() {
        this.currentStep = 1;
        this.totalSteps = 4;
        this.config = {
            source: '',
            device: '',
            plugins: [],
            customSources: [],
            optimization: 'balanced'
        };

        this.isInitialized = false;

        // 延迟初始化，确保DOM加载完成
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.init());
        } else {
            setTimeout(() => this.init(), 100);
        }
    }

    init() {
        if (this.isInitialized) return;

        console.log('🚀 初始化OpenWrt智能编译向导');

        try {
            this.loadConfigData();
            this.bindEvents();
            this.renderStep(1);
            this.checkTokenStatus();
            this.isInitialized = true;
            console.log('✅ 向导初始化完成');
        } catch (error) {
            console.error('❌ 向导初始化失败:', error);
            this.showInitError(error);
        }
    }

    /**
     * 显示初始化错误
     */
    showInitError(error) {
        const errorMessage = `
            <div class="init-error">
                <h3>⚠️ 初始化失败</h3>
                <p>向导初始化时出现错误：${error.message}</p>
                <button onclick="location.reload()" class="btn btn-primary">🔄 重新加载</button>
            </div>
        `;

        const container = document.querySelector('.wizard-content') || document.body;
        container.innerHTML = errorMessage;
    }

    /**
     * 检查Token配置状态
     */
    checkTokenStatus() {
        // 安全地获取DOM元素
        const statusContainer = document.getElementById('token-status') ||
            document.getElementById('token-status-indicator');

        if (!statusContainer) {
            console.warn('⚠️ Token状态容器未找到，跳过状态更新');
            return;
        }

        const token = this.getValidToken();

        if (token) {
            // 显示Token状态（隐藏敏感信息）
            const maskedToken = token.substring(0, 8) + '*'.repeat(12) + token.substring(token.length - 4);
            statusContainer.innerHTML = `
                <div class="token-status-card valid">
                    <span class="status-icon">✅</span>
                    <div class="status-info">
                        <div class="status-title">GitHub Token 已配置</div>
                        <div class="status-detail">${maskedToken}</div>
                    </div>
                    <button class="btn-clear-token" onclick="window.wizardManager.clearToken()">清除</button>
                </div>
            `;
        } else {
            statusContainer.innerHTML = `
                <div class="token-status-card invalid">
                    <span class="status-icon">⚠️</span>
                    <div class="status-info">
                        <div class="status-title">需要配置 GitHub Token</div>
                        <div class="status-detail">点击配置按钮设置Token以启用编译功能</div>
                    </div>
                    <button class="btn-config-token" onclick="window.tokenModal?.show()">配置Token</button>
                </div>
            `;
        }
    }

    /**
     * 获取有效的Token
     */
    getValidToken() {
        try {
            // 优先级：URL参数 > LocalStorage > 全局变量
            const urlParams = new URLSearchParams(window.location.search);
            const urlToken = urlParams.get('token');
            if (urlToken && this.isValidTokenFormat(urlToken)) {
                return urlToken;
            }

            const storedToken = localStorage.getItem('github_token');
            if (storedToken && this.isValidTokenFormat(storedToken)) {
                return storedToken;
            }

            if (window.GITHUB_TOKEN && this.isValidTokenFormat(window.GITHUB_TOKEN)) {
                return window.GITHUB_TOKEN;
            }
        } catch (error) {
            console.warn('获取Token时出错:', error);
        }

        return null;
    }

    /**
     * 验证Token格式
     */
    isValidTokenFormat(token) {
        return token && typeof token === 'string' &&
            (token.startsWith('ghp_') || token.startsWith('github_pat_'));
    }

    /**
     * Token配置完成回调
     */
    onTokenConfigured(token) {
        console.log('✅ Token配置完成');
        this.checkTokenStatus();

        // 如果在编译步骤，重新启用编译按钮
        const buildBtn = document.getElementById('start-build-btn');
        if (buildBtn) {
            buildBtn.disabled = false;
            buildBtn.innerHTML = '🚀 开始编译';
        }
    }

    /**
     * 清除Token配置
     */
    clearToken() {
        if (confirm('确定要清除Token配置吗？清除后将无法进行编译。')) {
            try {
                localStorage.removeItem('github_token');
                delete window.GITHUB_TOKEN;

                // 从URL中移除token参数（如果存在）
                const url = new URL(window.location);
                if (url.searchParams.has('token')) {
                    url.searchParams.delete('token');
                    window.history.replaceState({}, document.title, url.toString());
                }

                this.checkTokenStatus();
                console.log('🗑️ Token配置已清除');
            } catch (error) {
                console.error('清除Token失败:', error);
            }
        }
    }

    /**
     * 加载配置数据
     */
    loadConfigData() {
        try {
            // 从全局变量加载配置数据
            this.sourceBranches = window.SOURCE_BRANCHES || this.getDefaultSourceBranches();
            this.deviceConfigs = window.DEVICE_CONFIGS || this.getDefaultDeviceConfigs();
            this.pluginConfigs = window.PLUGIN_CONFIGS || this.getDefaultPluginConfigs();
            console.log('📋 配置数据加载完成');
        } catch (error) {
            console.warn('配置数据加载失败，使用默认配置:', error);
            this.loadDefaultConfigs();
        }
    }

    /**
     * 获取默认源码分支配置
     */
    getDefaultSourceBranches() {
        return {
            'lede-master': {
                name: "Lean's LEDE",
                description: '国内热门分支，集成大量插件',
                repo: 'https://github.com/coolsnowwolf/lede',
                branch: 'master',
                recommended: true,
                stability: '稳定',
                plugins: '丰富'
            },
            'openwrt-main': {
                name: 'OpenWrt 官方',
                description: '最新稳定版本，兼容性最好',
                repo: 'https://github.com/openwrt/openwrt',
                branch: 'openwrt-23.05',
                recommended: true,
                stability: '高',
                plugins: '基础'
            }
        };
    }

    /**
     * 获取默认设备配置
     */
    getDefaultDeviceConfigs() {
        return {
            'x86_64': {
                name: 'X86 64位 (通用)',
                category: 'x86',
                arch: 'x86',
                target: 'x86/64',
                profile: 'generic',
                flash_size: '可变',
                ram_size: '可变',
                recommended: true,
                features: ['efi', 'legacy', 'kvm', 'docker']
            },
            'xiaomi_4a_gigabit': {
                name: '小米路由器4A千兆版',
                category: 'router',
                arch: 'ramips',
                target: 'ramips/mt7621',
                profile: 'xiaomi_mi-router-4a-gigabit',
                flash_size: '16M',
                ram_size: '128M',
                recommended: true,
                features: ['wifi', 'gigabit', 'usb']
            }
        };
    }

    /**
     * 获取默认插件配置
     */
    getDefaultPluginConfigs() {
        return {
            proxy: {
                name: '🔐 网络代理',
                plugins: {
                    'luci-app-ssr-plus': {
                        name: 'SSR Plus+',
                        description: 'ShadowsocksR代理工具',
                        size: '5M',
                        stability: 'stable'
                    },
                    'luci-app-passwall': {
                        name: 'PassWall',
                        description: '多协议代理，智能分流',
                        size: '8M',
                        stability: 'stable'
                    }
                }
            },
            system: {
                name: '⚙️ 系统管理',
                plugins: {
                    'luci-app-ttyd': {
                        name: 'TTYD终端',
                        description: 'Web终端访问',
                        size: '1M',
                        stability: 'stable'
                    },
                    'luci-app-upnp': {
                        name: 'UPnP',
                        description: '端口自动映射',
                        size: '0.5M',
                        stability: 'stable'
                    }
                }
            }
        };
    }

    /**
     * 加载默认配置（备用方案）
     */
    loadDefaultConfigs() {
        this.sourceBranches = this.getDefaultSourceBranches();
        this.deviceConfigs = this.getDefaultDeviceConfigs();
        this.pluginConfigs = this.getDefaultPluginConfigs();
    }

    /**
     * 绑定事件监听器
     */
    bindEvents() {

    
        // 使用事件委托避免元素不存在的问题
        document.addEventListener('click', (e) => {
            try {
                if (e.target.matches('.next-step-btn')) {
                    this.nextStep();
                } else if (e.target.matches('.prev-step-btn')) {
                    this.prevStep();
                } else if (e.target.matches('.source-option')) {
                    this.selectSource(e.target.dataset.source);
                } else if (e.target.matches('.device-option')) {
                    this.selectDevice(e.target.dataset.device);
                } else if (e.target.matches('.plugin-checkbox')) {
                    this.togglePlugin(e.target.dataset.plugin);
                } else if (e.target.matches('#start-build-btn')) {
                    this.startBuild();
                }
            } catch (error) {
                console.error('事件处理失败:', error);
            }
        });

        // 绑定搜索框事件
        document.addEventListener('input', (e) => {
            if (e.target.matches('.search-input')) {
                const filterType = e.target.dataset.filter;
                if (filterType) {
                    this.filterOptions(e.target.value, filterType);
                }
            }
        });
    }

    /**
     * 渲染步骤
     */
    renderStep(step) {
        this.currentStep = step;

        try {
            // 更新步骤指示器
            this.updateStepIndicator();

            // 显示对应步骤内容
            this.showStepContent(step);

            // 根据步骤渲染内容
            switch (step) {
                case 1:
                    this.renderSourceSelection();
                    break;
                case 2:
                    this.renderDeviceSelection();
                    break;
                case 3:
                    this.renderPluginSelection();
                    break;
                case 4:
                    this.renderConfigSummary();
                    break;
            }
        } catch (error) {
            console.error(`渲染步骤${step}失败:`, error);
        }
    }

    /**
     * 更新步骤指示器
     */
    updateStepIndicator() {
        const indicators = document.querySelectorAll('.step-indicator');
        indicators.forEach((indicator, index) => {
            const stepNum = index + 1;
            indicator.className = 'step-indicator';

            if (stepNum < this.currentStep) {
                indicator.classList.add('completed');
            } else if (stepNum === this.currentStep) {
                indicator.classList.add('active');
            }
        });
    }

    /**
     * 显示步骤内容
     */
    showStepContent(step) {
        // 隐藏所有步骤内容
        const stepContents = document.querySelectorAll('.step-content');
        stepContents.forEach(content => {
            content.style.display = 'none';
        });

        // 显示当前步骤
        const currentStepContent = document.getElementById(`step-${step}`);
        if (currentStepContent) {
            currentStepContent.style.display = 'block';
        } else {
            console.warn(`步骤${step}的内容容器未找到`);
        }
    }

    /**
     * 渲染源码选择
     */
    renderSourceSelection() {
        const container = document.getElementById('source-selection');
        if (!container) {
            console.warn('源码选择容器未找到');
            return;
        }

        let html = '<div class="options-grid">';

        Object.entries(this.sourceBranches).forEach(([key, source]) => {
            const isSelected = this.config.source === key;
            const recommendedBadge = source.recommended ? '<span class="recommended-badge">推荐</span>' : '';

            html += `
                <div class="source-option ${isSelected ? 'selected' : ''}" data-source="${key}">
                    ${recommendedBadge}
                    <div class="option-header">
                        <h3>${source.name}</h3>
                        <div class="option-meta">
                            <span class="stability-badge">${source.stability}</span>
                            <span class="plugins-badge">${source.plugins}</span>
                        </div>
                    </div>
                    <p class="option-description">${source.description}</p>
                    <div class="option-details">
                        <div class="detail-item">
                            <span class="detail-label">仓库:</span>
                            <span class="detail-value">${this.getRepoShortName(source.repo)}</span>
                        </div>
                        <div class="detail-item">
                            <span class="detail-label">分支:</span>
                            <span class="detail-value">${source.branch}</span>
                        </div>
                    </div>
                </div>
            `;
        });

        html += '</div>';
        container.innerHTML = html;

        this.bindSourceOptionEvents();
    }

    /**
     * 绑定源码选项卡片事件
     */
    bindSourceOptionEvents() {
        document.querySelectorAll('.source-option').forEach(card => {
            card.addEventListener('click', (e) => {
                // 阻止 a、button、input 的默认行为
                if (
                    e.target.tagName === 'A' ||
                    e.target.tagName === 'BUTTON' ||
                    e.target.tagName === 'INPUT'
                ) return;
                this.selectSource(card.dataset.source);
            });
            // 让input点击也能选中
            const input = card.querySelector('input[type="radio"]');
            if (input) {
                input.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.selectSource(card.dataset.source);
                });
            }
        });
    }

    /**
     * 渲染设备选择
     */
    renderDeviceSelection() {
        const container = document.getElementById('device-selection');
        if (!container) {
            console.warn('设备选择容器未找到');
            return;
        }

        // 按分类组织设备
        const categories = {
            router: '🔀 路由器设备',
            arm: '💻 ARM开发板',
            x86: '🖥️ X86设备'
        };

        let html = '';

        Object.entries(categories).forEach(([category, title]) => {
            const devices = Object.entries(this.deviceConfigs)
                .filter(([key, device]) => device.category === category);

            if (devices.length === 0) return;

            html += `
                <div class="device-category">
                    <h3 class="category-title">${title}</h3>
                    <div class="options-grid">
            `;

            devices.forEach(([key, device]) => {
                const isSelected = this.config.device === key;
                const recommendedBadge = device.recommended ? '<span class="recommended-badge">推荐</span>' : '';

                html += `
                    <div class="device-option ${isSelected ? 'selected' : ''}" data-device="${key}">
                        ${recommendedBadge}
                        <div class="option-header">
                            <h4>${device.name}</h4>
                            <div class="device-specs">
                                <span class="spec-item">Flash: ${device.flash_size}</span>
                                <span class="spec-item">RAM: ${device.ram_size}</span>
                            </div>
                        </div>
                        <div class="device-features">
                            ${device.features?.map(feature => `<span class="feature-tag">${feature}</span>`).join('') || ''}
                        </div>
                    </div>
                `;
            });

            html += '</div></div>';
        });

        container.innerHTML = html;
        this.bindDeviceOptionEvents();
    }

    /**
     * 绑定源码选项卡片事件
     */
    bindDeviceOptionEvents() {
        document.querySelectorAll('.device-option').forEach(card => {
            card.addEventListener('click', (e) => {
                // 阻止 a、button、input 的默认行为
                if (
                    e.target.tagName === 'A' ||
                    e.target.tagName === 'BUTTON' ||
                    e.target.tagName === 'INPUT'
                ) return;
                this.selectDevice(card.dataset.device);
            });
            // 让input点击也能选中
            const input = card.querySelector('input[type="radio"]');
            if (input) {
                input.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.selectDevice(card.dataset.device);
                });
            }
        });
    }


    /**
     * 渲染插件选择
     */
    renderPluginSelection() {
        const container = document.getElementById('plugin-selection');
        if (!container) {
            console.warn('插件选择容器未找到');
            return;
        }

        let html = '';

        Object.entries(this.pluginConfigs).forEach(([categoryKey, category]) => {
            html += `
                <div class="plugin-category">
                    <h3 class="category-title">${category.name}</h3>
                    <div class="plugin-grid">
            `;

            Object.entries(category.plugins).forEach(([pluginKey, plugin]) => {
                const isSelected = this.config.plugins.includes(pluginKey);

                html += `
                    <div class="plugin-item ${isSelected ? 'selected' : ''}">
                        <label class="plugin-label">
                            <input type="checkbox" 
                                   class="plugin-checkbox" 
                                   data-plugin="${pluginKey}"
                                   ${isSelected ? 'checked' : ''}>
                            <div class="plugin-info">
                                <div class="plugin-header">
                                    <span class="plugin-name">${plugin.name}</span>
                                    <span class="plugin-size">${plugin.size || 'N/A'}</span>
                                </div>
                                <div class="plugin-description">${plugin.description}</div>
                            </div>
                        </label>
                    </div>
                `;
            });

            html += '</div></div>';
        });

        container.innerHTML = html;

        // 添加冲突检测面板
        this.renderConflictDetection();
    }

    /**
     * 渲染冲突检测
     */
    renderConflictDetection() {
        const container = document.getElementById('conflict-detection');
        if (!container) return;

        const conflicts = this.detectPluginConflicts();

        let html = '<div class="conflict-panel">';

        if (conflicts.length === 0) {
            html += `
                <div class="conflict-status success">
                    <span class="status-icon">✅</span>
                    <span class="status-text">配置检查通过，无冲突问题</span>
                </div>
            `;
        } else {
            html += `
                <div class="conflict-status error">
                    <span class="status-icon">⚠️</span>
                    <span class="status-text">发现 ${conflicts.length} 个配置问题</span>
                </div>
            `;

            conflicts.forEach(conflict => {
                html += `
                    <div class="conflict-item">
                        <div class="conflict-type">插件冲突</div>
                        <div class="conflict-message">${conflict.message}</div>
                    </div>
                `;
            });
        }

        html += '</div>';
        container.innerHTML = html;
    }

    /**
     * 渲染配置摘要
     */
    renderConfigSummary() {
        const container = document.getElementById('config-summary');
        if (!container) {
            console.warn('配置摘要容器未找到');
            return;
        }

        const sourceInfo = this.sourceBranches[this.config.source];
        const deviceInfo = this.deviceConfigs[this.config.device];

        let html = `
            <div class="summary-section">
                <h3>📋 配置摘要</h3>
                <div class="summary-grid">
                    <div class="summary-item">
                        <div class="summary-label">源码分支</div>
                        <div class="summary-value">${sourceInfo?.name || '未选择'}</div>
                    </div>
                    <div class="summary-item">
                        <div class="summary-label">目标设备</div>
                        <div class="summary-value">${deviceInfo?.name || '未选择'}</div>
                    </div>
                    <div class="summary-item">
                        <div class="summary-label">选中插件</div>
                        <div class="summary-value">${this.config.plugins.length} 个</div>
                    </div>
                </div>
            </div>
            
            <div class="summary-section">
                <h3>🔧 插件列表</h3>
                <div class="plugin-summary">
                    ${this.config.plugins.length > 0 ?
                this.config.plugins.map(plugin => this.getPluginDisplayName(plugin)).join(', ') :
                '未选择插件'
            }
                </div>
            </div>
            
            <div class="summary-section">
                <h3>🚀 编译控制</h3>
                <div class="build-actions">
                    ${this.getValidToken() ? `
                        <button id="start-build-btn" class="btn btn-primary btn-large">
                            🚀 开始编译
                        </button>
                    ` : `
                        <button id="start-build-btn" class="btn btn-primary btn-large" disabled>
                            🔒 需要配置Token
                        </button>
                        <button class="btn btn-secondary" onclick="window.tokenModal?.show()">
                            ⚙️ 配置GitHub Token
                        </button>
                    `}
                </div>
            </div>
        `;

        container.innerHTML = html;
    }

    // === 选择操作方法 ===

    selectSource(sourceKey) {
        this.config.source = sourceKey;
        this.renderSourceSelection();
        console.log('✅ 选择源码:', sourceKey);
    }

    selectDevice(deviceKey) {
        this.config.device = deviceKey;
        this.renderDeviceSelection();
        console.log('✅ 选择设备:', deviceKey);
    }

    togglePlugin(pluginKey) {
        const index = this.config.plugins.indexOf(pluginKey);
        if (index > -1) {
            this.config.plugins.splice(index, 1);
        } else {
            this.config.plugins.push(pluginKey);
        }

        this.renderPluginSelection();
        console.log('🔧 插件状态更新:', pluginKey, index > -1 ? '移除' : '添加');
    }

    // === 编译相关方法 ===

    async startBuild() {
        try {
            // 验证配置完整性
            if (!this.config.source) {
                alert('请先选择源码分支');
                return;
            }

            if (!this.config.device) {
                alert('请先选择目标设备');
                return;
            }

            // 验证Token
            const token = this.getValidToken();
            if (!token) {
                alert('请先配置GitHub Token');
                if (window.tokenModal) {
                    window.tokenModal.show();
                }
                return;
            }

            // 检查冲突
            const conflicts = this.detectPluginConflicts();
            if (conflicts.length > 0) {
                const proceed = confirm(`检测到 ${conflicts.length} 个插件冲突，是否继续？\n\n${conflicts.map(c => c.message).join('\n')}`);
                if (!proceed) return;
            }

            // 生成配置并触发编译
            const buildData = this.generateBuildConfig();
            console.log('🚀 开始编译，配置数据:', buildData);

            // 显示编译监控面板
            const buildMonitor = document.getElementById('build-monitor');
            if (buildMonitor) {
                buildMonitor.style.display = 'block';
                buildMonitor.scrollIntoView({ behavior: 'smooth' });
            }

            // 触发GitHub Actions编译
            const response = await this.triggerBuild(buildData, token);

            if (response.success) {
                this.showBuildSuccess();
                // 开始监控编译进度
                this.startProgressMonitoring(response.run_id, token);
            } else {
                alert('编译启动失败: ' + response.message);
            }
        } catch (error) {
            console.error('编译启动失败:', error);
            alert('编译启动失败: ' + error.message);
        }
    }

    generateBuildConfig() {
        return {
            source_branch: this.config.source,
            target_device: this.config.device,
            plugins: this.config.plugins,
            custom_sources: this.config.customSources,
            optimization: this.config.optimization,
            timestamp: Date.now(),
            build_id: 'build_' + Date.now()
        };
    }

    async triggerBuild(buildData, token) {
        try {
            const repoUrl = window.GITHUB_REPO || 'your-username/your-repo';

            const response = await fetch(`https://api.github.com/repos/${repoUrl}/dispatches`, {
                method: 'POST',
                headers: {
                    'Authorization': `token ${token}`,
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    event_type: 'web_build',
                    client_payload: buildData
                })
            });

            if (response.ok) {
                return {
                    success: true,
                    message: '编译任务已成功提交到GitHub Actions',
                    run_id: null
                };
            } else {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.message || `HTTP ${response.status}: ${response.statusText}`);
            }

        } catch (error) {
            console.error('触发编译失败:', error);
            throw new Error(`编译启动失败: ${error.message}`);
        }
    }

    startProgressMonitoring(runId, token) {
        console.log('📊 开始编译进度监控');
        this.showBasicProgress();
    }

    showBasicProgress() {
        this.addLogEntry('info', '🚀 编译任务已提交到GitHub Actions');
        this.addLogEntry('info', '🔗 请访问GitHub Actions页面查看详细编译进度');

        const repoUrl = window.GITHUB_REPO || 'your-username/your-repo';
        this.addLogEntry('info', `📋 项目地址: https://github.com/${repoUrl}/actions`);

        const estimatedTime = new Date(Date.now() + 90 * 60 * 1000);
        this.addLogEntry('info', `⏰ 预计完成时间: ${estimatedTime.toLocaleString()}`);
    }

    showBuildSuccess() {
        this.addLogEntry('success', '🚀 编译任务已成功提交到GitHub Actions');
        this.addLogEntry('info', `📋 配置信息: ${this.sourceBranches[this.config.source]?.name} - ${this.deviceConfigs[this.config.device]?.name}`);
        this.addLogEntry('info', `🔧 选中插件: ${this.config.plugins.length}个`);
        this.addLogEntry('info', `🕐 提交时间: ${new Date().toLocaleString()}`);
    }

    addLogEntry(type, message) {
        const logsContent = document.getElementById('logs-content');
        if (!logsContent) return;

        const timestamp = new Date().toLocaleTimeString();
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry ${type}`;
        logEntry.innerHTML = `
            <span class="log-timestamp">${timestamp}</span>
            <span class="log-message">${message}</span>
        `;

        logsContent.appendChild(logEntry);
        logsContent.scrollTop = logsContent.scrollHeight;
    }

    stopMonitoring() {
        console.log('🛑 停止编译监控');
    }

    // === 工具方法 ===

    getRepoShortName(repoUrl) {
        try {
            return repoUrl.split('/').slice(-2).join('/');
        } catch (error) {
            return repoUrl;
        }
    }

    getPluginDisplayName(pluginKey) {
        // 遍历所有插件配置，找到对应的显示名称
        for (const category of Object.values(this.pluginConfigs)) {
            if (category.plugins && category.plugins[pluginKey]) {
                return category.plugins[pluginKey].name;
            }
        }
        return pluginKey;
    }

    detectPluginConflicts() {
        // 简单的冲突检测逻辑
        const conflicts = [];
        const selectedPlugins = this.config.plugins;

        // 检查常见冲突
        const proxyPlugins = ['luci-app-ssr-plus', 'luci-app-passwall', 'luci-app-openclash'];
        const selectedProxy = selectedPlugins.filter(plugin => proxyPlugins.includes(plugin));

        if (selectedProxy.length > 1) {
            conflicts.push({
                type: 'mutual_exclusive',
                plugins: selectedProxy,
                message: `代理插件冲突：${selectedProxy.join(', ')} 不能同时选择`
            });
        }

        return conflicts;
    }

    filterOptions(searchTerm, filterType) {
        const term = searchTerm.toLowerCase();
        let options = [];

        switch (filterType) {
            case 'source':
                options = document.querySelectorAll('.source-option');
                break;
            case 'device':
                options = document.querySelectorAll('.device-option');
                break;
            case 'plugin':
                options = document.querySelectorAll('.plugin-item');
                break;
        }

        options.forEach(option => {
            const text = option.textContent.toLowerCase();
            option.style.display = text.includes(term) ? 'block' : 'none';
        });
    }

    // === 步骤导航方法 ===

    nextStep() {
        if (this.currentStep < this.totalSteps) {
            if (this.validateCurrentStep()) {
                this.renderStep(this.currentStep + 1);
            }
        }
    }

    prevStep() {
        if (this.currentStep > 1) {
            this.renderStep(this.currentStep - 1);
        }
    }

    validateCurrentStep() {
        switch (this.currentStep) {
            case 1:
                if (!this.config.source) {
                    alert('请选择源码分支');
                    return false;
                }
                break;
            case 2:
                if (!this.config.device) {
                    alert('请选择目标设备');
                    return false;
                }
                break;
        }
        return true;
    }
}

// === 全局函数（供HTML调用）===

// Token配置完成回调
function onTokenConfigured(token) {
    if (window.wizardManager) {
        window.wizardManager.onTokenConfigured(token);
    }
}

// 页面加载完成后初始化向导
document.addEventListener('DOMContentLoaded', function () {
    console.log('🎯 页面加载完成，初始化编译向导');

    // 延迟初始化，确保所有资源加载完成
    setTimeout(() => {
        window.wizardManager = new WizardManager();
    }, 500);
});

// 导出向导管理器供调试使用
window.WizardManager = WizardManager;