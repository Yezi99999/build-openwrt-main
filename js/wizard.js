/**
 * OpenWrt 智能编译向导 - 安全版本
 * 移除模拟模式，使用安全的Token配置方式
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

        this.init();
    }

    init() {
        console.log('🚀 初始化OpenWrt智能编译向导');
        this.loadConfigData();
        this.bindEvents();
        this.renderStep(1);
        this.checkTokenStatus();
    }

    /**
     * 检查Token配置状态
     */
    checkTokenStatus() {
        const token = this.getValidToken();
        const statusDiv = document.getElementById('token-status');

        if (token) {
            // 显示Token状态（隐藏敏感信息）
            const maskedToken = token.substring(0, 8) + '*'.repeat(12) + token.substring(token.length - 4);
            statusDiv.innerHTML = `
                <div class="token-status-card valid">
                    <span class="status-icon">✅</span>
                    <div class="status-info">
                        <div class="status-title">GitHub Token 已配置</div>
                        <div class="status-detail">${maskedToken}</div>
                    </div>
                    <button class="btn-clear-token" onclick="this.clearToken()">清除</button>
                </div>
            `;
        } else {
            statusDiv.innerHTML = `
                <div class="token-status-card invalid">
                    <span class="status-icon">⚠️</span>
                    <div class="status-info">
                        <div class="status-title">需要配置 GitHub Token</div>
                        <div class="status-detail">点击配置按钮设置Token以启用编译功能</div>
                    </div>
                    <button class="btn-config-token" onclick="showTokenModal()">配置Token</button>
                </div>
            `;
        }
    }

    /**
     * 获取有效的Token
     */
    getValidToken() {
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

        return null;
    }

    /**
     * 验证Token格式
     */
    isValidTokenFormat(token) {
        return token && (token.startsWith('ghp_') || token.startsWith('github_pat_'));
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
            localStorage.removeItem('github_token');
            delete window.GITHUB_TOKEN;

            // 从URL中移除token参数（如果存在）
            const url = new URL(window.location);
            url.searchParams.delete('token');
            window.history.replaceState({}, document.title, url.toString());

            this.checkTokenStatus();
            console.log('🗑️ Token配置已清除');
        }
    }

    loadConfigData() {
        // 加载配置数据（从config-data.js）
        this.sourceBranches = window.SOURCE_BRANCHES || {};
        this.deviceConfigs = window.DEVICE_CONFIGS || {};
        this.pluginConfigs = window.PLUGIN_CONFIGS || {};
        console.log('📋 配置数据加载完成');
    }

    bindEvents() {
        // 绑定事件监听器
        document.addEventListener('click', (e) => {
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
        });

        // 绑定搜索框事件
        const searchInputs = document.querySelectorAll('.search-input');
        searchInputs.forEach(input => {
            input.addEventListener('input', (e) => {
                this.filterOptions(e.target.value, e.target.dataset.filter);
            });
        });
    }

    renderStep(step) {
        this.currentStep = step;

        // 更新步骤指示器
        this.updateStepIndicator();

        // 显示对应步骤内容
        const stepContents = document.querySelectorAll('.step-content');
        stepContents.forEach((content, index) => {
            content.style.display = (index + 1 === step) ? 'block' : 'none';
        });

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
    }

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

    renderSourceSelection() {
        const container = document.getElementById('source-selection');
        if (!container) return;

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
                            <span class="stability-badge ${source.stability}">${source.stability}</span>
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
    }

    renderDeviceSelection() {
        const container = document.getElementById('device-selection');
        if (!container) return;

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
                const warnings = this.getDeviceWarnings(device);

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
                        ${warnings.length > 0 ? `
                            <div class="device-warnings">
                                ${warnings.map(warning => `<div class="warning-item">${warning}</div>`).join('')}
                            </div>
                        ` : ''}
                    </div>
                `;
            });

            html += '</div></div>';
        });

        container.innerHTML = html;
    }

    renderPluginSelection() {
        const container = document.getElementById('plugin-selection');
        if (!container) return;

        let html = '';

        Object.entries(this.pluginConfigs).forEach(([categoryKey, category]) => {
            html += `
                <div class="plugin-category">
                    <h3 class="category-title">${category.name}</h3>
                    <div class="plugin-grid">
            `;

            Object.entries(category.plugins).forEach(([pluginKey, plugin]) => {
                const isSelected = this.config.plugins.includes(pluginKey);
                const conflicts = this.getPluginConflictInfo(pluginKey);
                const isDisabled = this.isPluginDisabled(pluginKey);

                html += `
                    <div class="plugin-item ${isSelected ? 'selected' : ''} ${isDisabled ? 'disabled' : ''}">
                        <label class="plugin-label">
                            <input type="checkbox" 
                                   class="plugin-checkbox" 
                                   data-plugin="${pluginKey}"
                                   ${isSelected ? 'checked' : ''}
                                   ${isDisabled ? 'disabled' : ''}>
                            <div class="plugin-info">
                                <div class="plugin-header">
                                    <span class="plugin-name">${plugin.name}</span>
                                    <span class="plugin-size">${plugin.size || 'N/A'}</span>
                                </div>
                                <div class="plugin-description">${plugin.description}</div>
                                ${conflicts.length > 0 ? `
                                    <div class="plugin-conflicts">
                                        <span class="conflict-label">冲突:</span>
                                        ${conflicts.join(', ')}
                                    </div>
                                ` : ''}
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

    renderConflictDetection() {
        const container = document.getElementById('conflict-detection');
        if (!container) return;

        const conflicts = this.detectPluginConflicts();
        const archIssues = this.checkArchCompatibility();

        let html = '<div class="conflict-panel">';

        if (conflicts.length === 0 && archIssues.length === 0) {
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
                    <span class="status-text">发现 ${conflicts.length + archIssues.length} 个配置问题</span>
                </div>
            `;

            // 显示冲突详情
            conflicts.forEach(conflict => {
                html += `
                    <div class="conflict-item">
                        <div class="conflict-type">插件冲突</div>
                        <div class="conflict-message">${conflict.message}</div>
                    </div>
                `;
            });

            archIssues.forEach(issue => {
                html += `
                    <div class="conflict-item">
                        <div class="conflict-type">架构不兼容</div>
                        <div class="conflict-message">
                            ${issue.plugin} 不支持 ${issue.current_arch} 架构
                        </div>
                    </div>
                `;
            });
        }

        html += '</div>';
        container.innerHTML = html;
    }

    renderConfigSummary() {
        const container = document.getElementById('config-summary');
        if (!container) return;

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
                        <button class="btn btn-secondary" onclick="showTokenModal()">
                            ⚙️ 配置GitHub Token
                        </button>
                    `}
                </div>
            </div>
        `;

        container.innerHTML = html;
    }

    // ... 其他工具方法保持不变，但移除所有模拟模式相关代码

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

    async startBuild() {
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
            showTokenModal();
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

        try {
            // 显示编译监控面板
            document.getElementById('build-monitor').style.display = 'block';
            document.getElementById('build-monitor').scrollIntoView({ behavior: 'smooth' });

            // 触发GitHub Actions编译
            const response = await this.triggerBuild(buildData, token);

            if (response.success) {
                this.showBuildSuccess();
                // 开始监控编译进度
                if (response.run_id) {
                    this.startProgressMonitoring(response.run_id, token);
                } else {
                    // 即使没有run_id，也尝试获取最新的workflow运行
                    this.startProgressMonitoring(null, token);
                }
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
            // 使用GitHub Repository Dispatch API触发编译
            const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/dispatches`, {
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
                    run_id: null // Repository Dispatch不直接返回run_id
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

    /**
     * 开始监控编译进度
     */
    async startProgressMonitoring(runId, token) {
        console.log('📊 开始监控编译进度');

        // 如果没有specific run_id，获取最新的workflow run
        if (!runId) {
            try {
                runId = await this.getLatestWorkflowRun(token);
            } catch (error) {
                console.warn('获取最新workflow run失败:', error);
            }
        }

        if (runId) {
            this.monitorGitHubActions(runId, token);
        } else {
            // 如果无法获取run_id，显示基本的进度信息
            this.showBasicProgress();
        }
    }

    /**
     * 获取最新的workflow运行
     */
    async getLatestWorkflowRun(token) {
        const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/actions/runs?per_page=1`, {
            headers: {
                'Authorization': `token ${token}`,
                'Accept': 'application/vnd.github.v3+json'
            }
        });

        if (response.ok) {
            const data = await response.json();
            if (data.workflow_runs && data.workflow_runs.length > 0) {
                return data.workflow_runs[0].id;
            }
        }
        return null;
    }

    /**
     * 监控GitHub Actions编译进度
     */
    async monitorGitHubActions(runId, token) {
        let attempts = 0;
        const maxAttempts = 180; // 最多监控3小时（每分钟检查一次）

        this.addLogEntry('info', `🔍 开始监控编译进度 (Run ID: ${runId})`);

        const monitorInterval = setInterval(async () => {
            attempts++;

            try {
                const workflowStatus = await this.getWorkflowStatus(runId, token);
                this.processWorkflowStatus(workflowStatus);

                // 如果编译完成或达到最大尝试次数，停止监控
                if (this.isCompletedStatus(workflowStatus.status) || attempts >= maxAttempts) {
                    clearInterval(monitorInterval);

                    if (attempts >= maxAttempts) {
                        this.addLogEntry('warning', '⚠️ 监控超时，请手动检查GitHub Actions页面');
                    } else {
                        this.addLogEntry('success', '✅ 编译监控完成');
                    }
                }

            } catch (error) {
                console.error('监控GitHub Actions失败:', error);
                this.addLogEntry('error', `❌ 监控异常: ${error.message}`);

                // 连续失败10次后停止监控
                if (attempts % 10 === 0) {
                    this.addLogEntry('warning', '⚠️ 监控连接持续异常，已停止自动监控');
                    clearInterval(monitorInterval);
                }
            }
        }, 60000); // 每分钟检查一次

        // 保存interval引用以便手动停止
        this.monitorInterval = monitorInterval;
    }

    /**
     * 获取GitHub工作流状态
     */
    async getWorkflowStatus(runId, token) {
        const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/actions/runs/${runId}`, {
            headers: {
                'Authorization': `token ${token}`,
                'Accept': 'application/vnd.github.v3+json'
            }
        });

        if (response.ok) {
            const data = await response.json();
            return {
                status: data.status,
                conclusion: data.conclusion,
                created_at: data.created_at,
                updated_at: data.updated_at,
                html_url: data.html_url,
                jobs_url: data.jobs_url
            };
        } else {
            throw new Error(`获取工作流状态失败: ${response.status} ${response.statusText}`);
        }
    }

    /**
     * 处理工作流状态
     */
    processWorkflowStatus(status) {
        const progress = this.calculateProgress(status);
        this.updateProgressBar(progress);

        // 根据状态添加日志
        switch (status.status) {
            case 'queued':
                this.addLogEntry('info', '⏳ 编译任务已排队等待执行');
                break;
            case 'in_progress':
                this.addLogEntry('info', '🔄 编译正在进行中...');
                break;
            case 'completed':
                if (status.conclusion === 'success') {
                    this.addLogEntry('success', '🎉 编译成功完成！');
                    this.showBuildComplete(true);
                } else if (status.conclusion === 'failure') {
                    this.addLogEntry('error', '❌ 编译失败，请检查配置和日志');
                    this.showBuildComplete(false);
                } else {
                    this.addLogEntry('warning', `⚠️ 编译完成，结果: ${status.conclusion}`);
                }
                break;
            case 'cancelled':
                this.addLogEntry('warning', '🛑 编译已被取消');
                break;
        }
    }

    /**
     * 计算编译进度
     */
    calculateProgress(status) {
        switch (status.status) {
            case 'queued':
                return 5;
            case 'in_progress':
                // 根据运行时间估算进度
                const startTime = new Date(status.created_at);
                const currentTime = new Date();
                const elapsedMinutes = (currentTime - startTime) / (1000 * 60);

                // 假设编译需要90分钟，计算百分比
                const estimatedProgress = Math.min(10 + (elapsedMinutes / 90) * 80, 90);
                return Math.round(estimatedProgress);
            case 'completed':
                return 100;
            default:
                return 0;
        }
    }

    /**
     * 更新进度条
     */
    updateProgressBar(progress) {
        const progressBar = document.getElementById('progress-bar');
        const progressText = document.getElementById('progress-text');

        if (progressBar) {
            progressBar.style.width = `${progress}%`;
        }

        if (progressText) {
            progressText.textContent = `${progress}%`;
        }
    }

    /**
     * 检查是否为完成状态
     */
    isCompletedStatus(status) {
        return ['completed', 'cancelled'].includes(status);
    }

    /**
     * 显示基本进度（当无法获取详细状态时）
     */
    showBasicProgress() {
        this.addLogEntry('info', '🚀 编译任务已提交到GitHub Actions');
        this.addLogEntry('info', '🔗 请访问GitHub Actions页面查看详细编译进度');
        this.addLogEntry('info', `📋 项目地址: https://github.com/${GITHUB_REPO}/actions`);

        // 显示估计完成时间
        const estimatedTime = new Date(Date.now() + 90 * 60 * 1000); // 90分钟后
        this.addLogEntry('info', `⏰ 预计完成时间: ${estimatedTime.toLocaleString()}`);
    }

    /**
     * 显示编译成功信息
     */
    showBuildSuccess() {
        const logsContent = document.getElementById('logs-content');
        if (!logsContent) return;

        this.addLogEntry('success', '🚀 编译任务已成功提交到GitHub Actions');
        this.addLogEntry('info', `📋 配置信息: ${this.sourceBranches[this.config.source]?.name} - ${this.deviceConfigs[this.config.device]?.name}`);
        this.addLogEntry('info', `🔧 选中插件: ${this.config.plugins.length}个`);
        this.addLogEntry('info', `🕐 提交时间: ${new Date().toLocaleString()}`);
        this.addLogEntry('info', '📊 开始监控编译进度...');
    }

    /**
     * 显示编译完成信息
     */
    showBuildComplete(success) {
        if (success) {
            this.addLogEntry('success', '🎉 恭喜！固件编译成功完成');
            this.addLogEntry('info', '📦 请前往GitHub Releases页面下载编译好的固件');
            this.addLogEntry('info', `🔗 下载地址: https://github.com/${GITHUB_REPO}/releases`);
        } else {
            this.addLogEntry('error', '❌ 编译失败，请检查以下可能的原因：');
            this.addLogEntry('error', '   • 插件配置冲突');
            this.addLogEntry('error', '   • 设备存储空间不足');
            this.addLogEntry('error', '   • 网络连接问题');
            this.addLogEntry('info', '🔍 详细错误信息请查看GitHub Actions日志');
        }
    }

    /**
     * 添加日志条目
     */
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

    /**
     * 停止监控
     */
    stopMonitoring() {
        if (this.monitorInterval) {
            clearInterval(this.monitorInterval);
            this.monitorInterval = null;
            this.addLogEntry('info', '🛑 已停止编译进度监控');
        }
    }

    // === 工具方法 ===

    getRepoShortName(repoUrl) {
        return repoUrl.split('/').slice(-2).join('/');
    }

    getDeviceWarnings(device) {
        const warnings = [];

        if (device.flash_size === '8M') {
            warnings.push('⚠️ 存储空间较小，建议选择必要插件');
        }

        if (!device.recommended) {
            warnings.push('⚠️ 非推荐设备，可能存在兼容性问题');
        }

        return warnings;
    }

    getPluginConflictInfo(pluginKey) {
        const conflicts = [];
        // 实现插件冲突检测逻辑
        return conflicts;
    }

    isPluginDisabled(pluginKey) {
        // 实现插件禁用逻辑（基于架构、冲突等）
        return false;
    }

    detectPluginConflicts() {
        const conflicts = [];
        // 实现冲突检测逻辑
        return conflicts;
    }

    checkArchCompatibility() {
        const issues = [];
        // 实现架构兼容性检查
        return issues;
    }

    getPluginDisplayName(pluginKey) {
        // 遍历所有插件配置，找到对应的显示名称
        for (const category of Object.values(this.pluginConfigs)) {
            if (category.plugins[pluginKey]) {
                return category.plugins[pluginKey].name;
            }
        }
        return pluginKey;
    }

    // === 步骤导航方法 ===

    nextStep() {
        if (this.currentStep < this.totalSteps) {
            // 验证当前步骤
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

    // === 搜索和过滤方法 ===

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
    window.wizardManager = new WizardManager();
});

// 导出向导管理器供调试使用
window.WizardManager = WizardManager;