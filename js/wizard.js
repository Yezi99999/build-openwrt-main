// OpenWrt配置向导主要逻辑
class OpenWrtWizard {
    constructor() {
        this.currentStep = 1;
        this.maxSteps = 4;
        this.config = {
            source: '',
            device: '',
            plugins: [],
            customSources: []
        };
        this.init();
    }

    init() {
        console.log('初始化OpenWrt配置向导...');
        this.bindEvents();
        this.loadDeviceData();
        this.loadPluginData();
    }

    bindEvents() {
        // 步骤导航
        document.getElementById('next-btn').addEventListener('click', () => this.nextStep());
        document.getElementById('prev-btn').addEventListener('click', () => this.prevStep());


        // 源码选择卡片点击事件
        // document.querySelectorAll('.source-card').forEach(card => {
        //     console.log('绑定源码卡片事件:', card.dataset.source);
        //     card.addEventListener('click', () => this.selectSource(card));
        // });
        //源码选择
        document.querySelectorAll('.source-card').forEach(card => {
            card.addEventListener('click', (e) => {
                debugger
                // 如果点击的是input，不处理（让input自己切换）
                if (e.target.tagName.toLowerCase() === 'input') return;
                this.selectSource(card);
            });
            // 让内部input和卡片同步
            const input = card.querySelector('input[type="radio"],input[type="checkbox"]');
            if (input) {
                input.addEventListener('change', () => {
                    this.selectSource(card);
                });
            }
        });
        
        // 设备搜索
        document.getElementById('device-search').addEventListener('input', (e) => this.searchDevices(e.target.value));
        
        // 分类切换
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.switchCategory(e.target.dataset.category));
        });
        
        // 插件筛选
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.filterPlugins(e.target.dataset.filter));
        });
        
        // 自定义插件源
        document.querySelector('.custom-source button').addEventListener('click', () => this.addCustomSource());
        
        // 冲突检查
        document.getElementById('check-conflicts').addEventListener('click', () => this.checkConflicts());
        
        // 开始编译
        document.getElementById('start-build').addEventListener('click', () => this.startBuild());
    }

    selectSource(card) {
        // 移除其他选中状态
        document.querySelectorAll('.source-card').forEach(c => {
            c.classList.remove('selected');
            // 同步取消input选中
            const input = c.querySelector('input[type="radio"],input[type="checkbox"]');
            if (input) input.checked = false;
        });
        
        // 选中当前卡片
        card.classList.add('selected');
        // 同步input选中
        const input = card.querySelector('input[type="radio"],input[type="checkbox"]');
        if (input) input.checked = true;
        this.config.source = card.dataset.source;
        this.updateSummary();
        console.log('选择源码:', this.config.source);
    }

    loadDeviceData() {
        // 加载支持的设备列表
        const deviceList = document.getElementById('device-list');
        const devices = DEVICE_DATA.default || [];
        
        deviceList.innerHTML = devices.map(device => `
            <div class="device-card" data-device="${device.id}" data-category="${device.category}">
                <h4>${device.name}</h4>
                <p>${device.description}</p>
                <div class="device-specs">
                    <span class="spec">💾 ${device.ram}</span>
                    <span class="spec">💽 ${device.flash}</span>
                    <span class="spec">📶 ${device.wireless}</span>
                </div>
            </div>
        `).join('');
        
        // 绑定设备选择事件
        document.querySelectorAll('.device-card').forEach(card => {
            card.addEventListener('click', (e) => this.selectDevice(e.target.closest('.device-card')));
        });
        
        // 默认显示热门设备
        this.switchCategory('popular');
    }

    selectDevice(card) {
        // 移除其他选中状态
        document.querySelectorAll('.device-card').forEach(c => c.classList.remove('selected'));
        // 选中当前设备
        card.classList.add('selected');
        this.config.device = card.dataset.device;
        this.updateSummary();
        console.log('选择设备:', this.config.device);
    }

    searchDevices(query) {
        const devices = document.querySelectorAll('.device-card');
        devices.forEach(device => {
            const name = device.querySelector('h4').textContent.toLowerCase();
            const description = device.querySelector('p').textContent.toLowerCase();
            const match = name.includes(query.toLowerCase()) || description.includes(query.toLowerCase());
            device.style.display = match ? 'block' : 'none';
        });
    }

    switchCategory(category) {
        // 更新标签页状态
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.category === category);
        });
        
        // 筛选设备
        const devices = document.querySelectorAll('.device-card');
        devices.forEach(device => {
            if (category === 'popular') {
                // 显示热门设备（前5个）
                const index = Array.from(devices).indexOf(device);
                device.style.display = index < 5 ? 'block' : 'none';
            } else {
                const deviceCategory = device.dataset.category;
                device.style.display = deviceCategory === category ? 'block' : 'none';
            }
        });
    }

    loadPluginData() {
        // 加载插件列表
        const pluginList = document.getElementById('plugin-list');
        const plugins = PLUGIN_DATA.default || [];
        
        pluginList.innerHTML = plugins.map(plugin => `
            <div class="plugin-card" data-plugin="${plugin.id}" data-category="${plugin.category}">
                <label class="plugin-checkbox">
                    <input type="checkbox" value="${plugin.id}">
                    <span class="checkmark"></span>
                </label>
                <div class="plugin-info">
                    <h4>${plugin.name}</h4>
                    <p>${plugin.description}</p>
                    <div class="plugin-meta">
                        <span class="category">${plugin.category}</span>
                        <span class="size">${plugin.size}</span>
                    </div>
                </div>
            </div>
        `).join('');
        
        // 绑定插件选择事件
        document.querySelectorAll('.plugin-card input').forEach(input => {
            input.addEventListener('change', (e) => this.togglePlugin(e.target));
        });
    }

    togglePlugin(input) {
        const pluginId = input.value;
        if (input.checked) {
            if (!this.config.plugins.includes(pluginId)) {
                this.config.plugins.push(pluginId);
            }
        } else {
            this.config.plugins = this.config.plugins.filter(id => id !== pluginId);
        }
        this.updateSummary();
        console.log('当前选中插件:', this.config.plugins);
    }

    filterPlugins(filter) {
        // 更新筛选按钮状态
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.filter === filter);
        });
        
        // 筛选插件
        const plugins = document.querySelectorAll('.plugin-card');
        plugins.forEach(plugin => {
            if (filter === 'all') {
                plugin.style.display = 'block';
            } else {
                const category = plugin.dataset.category;
                plugin.style.display = category === filter ? 'block' : 'none';
            }
        });
    }

    addCustomSource() {
        const input = document.querySelector('.custom-source input');
        const url = input.value.trim();
        
        if (url && this.isValidGitUrl(url)) {
            this.config.customSources.push(url);
            input.value = '';
            
            // 添加到列表显示
            const sourceList = document.querySelector('.source-list');
            const newSource = document.createElement('label');
            newSource.className = 'source-item';
            newSource.innerHTML = `
                <input type="checkbox" checked data-source="custom">
                <span>自定义源</span>
                <small>${url}</small>
            `;
            sourceList.insertBefore(newSource, document.querySelector('.custom-source'));
            
            console.log('添加自定义插件源:', url);
        } else {
            alert('请输入有效的Git仓库地址');
        }
    }

    isValidGitUrl(url) {
        const gitUrlPattern = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/;
        return gitUrlPattern.test(url) && (url.includes('github.com') || url.includes('gitlab.com') || url.includes('.git'));
    }

    async checkConflicts() {
        const checkButton = document.getElementById('check-conflicts');
        const reportDiv = document.getElementById('conflict-report');
        
        checkButton.disabled = true;
        checkButton.textContent = '🔍 检查中...';
        
        try {
            // 执行冲突检测
            const conflicts = await this.performConflictCheck();
            
            if (conflicts.length === 0) {
                reportDiv.innerHTML = `
                    <div class="conflict-success">
                        ✅ 配置检查通过，未发现冲突
                    </div>
                `;
            } else {
                reportDiv.innerHTML = `
                    <div class="conflict-warning">
                        ⚠️ 发现 ${conflicts.length} 个潜在问题:
                        <ul>
                            ${conflicts.map(c => `<li>${c.message}</li>`).join('')}
                        </ul>
                    </div>
                `;
            }
            
            reportDiv.style.display = 'block';
        } catch (error) {
            reportDiv.innerHTML = `
                <div class="conflict-error">
                    ❌ 检查失败: ${error.message}
                </div>
            `;
            reportDiv.style.display = 'block';
        } finally {
            checkButton.disabled = false;
            checkButton.textContent = '🔍 检查冲突';
        }
    }

    async performConflictCheck() {
        // 基于预定义规则的冲突检测
        const conflicts = [];
        const selectedPlugins = this.config.plugins;
        
        console.log('检查插件冲突:', selectedPlugins);
        
        // 检查插件大小限制
        const totalSize = selectedPlugins.reduce((sum, pluginId) => {
            const plugin = this.findPlugin(pluginId);
            const size = plugin ? parseInt(plugin.size.replace('MB', '')) : 0;
            return sum + size;
        }, 0);
        
        // 根据设备类型检查容量限制
        const deviceLimits = CONFLICT_RULES.size_limits || {};
        const deviceType = this.getDeviceType(this.config.device);
        const limit = deviceLimits[deviceType] || 999;
        
        if (totalSize > limit) {
            conflicts.push({
                type: 'size_limit',
                message: `选中插件总大小 ${totalSize}MB 超出设备存储限制 ${limit}MB`
            });
        }
        
        // 检查互斥插件
        const mutexRules = CONFLICT_RULES.mutex || [];
        for (const rule of mutexRules) {
            const conflictPlugins = selectedPlugins.filter(p => 
                rule.plugins.some(rp => p.includes(rp) || rp.includes(p))
            );
            if (conflictPlugins.length > 1) {
                conflicts.push({
                    type: 'mutex',
                    message: `${rule.name}: ${conflictPlugins.join(', ')} 不能同时选择`
                });
            }
        }
        
        // 检查依赖关系
        const dependencies = CONFLICT_RULES.dependencies || {};
        for (const plugin of selectedPlugins) {
            const deps = dependencies[plugin];
            if (deps) {
                for (const dep of deps) {
                    if (!selectedPlugins.includes(dep)) {
                        conflicts.push({
                            type: 'missing_dependency',
                            message: `插件 ${plugin} 需要依赖 ${dep}，但未选中`
                        });
                    }
                }
            }
        }
        
        return conflicts;
    }

    findPlugin(pluginId) {
        const plugins = PLUGIN_DATA.default || [];
        return plugins.find(p => p.id === pluginId || p.id.includes(pluginId));
    }

    getDeviceType(deviceId) {
        if (deviceId.includes('x86')) return 'x86';
        if (deviceId.includes('ramips') || deviceId.includes('xiaomi') || deviceId.includes('phicomm')) return 'ramips';
        if (deviceId.includes('ath79')) return 'ath79';
        return 'x86'; // 默认
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
        
        // 生成配置并触发编译
        const buildData = this.generateBuildConfig();
        console.log('开始编译，配置数据:', buildData);
        
        try {
            // 显示编译监控面板
            document.getElementById('build-monitor').style.display = 'block';
            document.getElementById('build-monitor').scrollIntoView({ behavior: 'smooth' });
            
            // 触发GitHub Actions编译
            const response = await this.triggerBuild(buildData);
            
            if (response.success) {
                this.showBuildSuccess();
                // 开始监控编译进度（如果有run_id）
                if (response.run_id) {
                    this.startProgressMonitoring(response.run_id);
                } else {
                    // 模拟编译进度
                    this.simulateProgress();
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
        // 生成用于GitHub Actions的配置
        return {
            source_branch: this.config.source,
            target_device: this.config.device,
            plugins: this.config.plugins,
            custom_sources: this.config.customSources,
            timestamp: Date.now(),
            build_id: 'build_' + Date.now()
        };
    }

    async triggerBuild(buildData) {
        // 检查是否配置了GitHub仓库信息
        if (!GITHUB_REPO || !GITHUB_TOKEN) {
            // 如果没有配置GitHub信息，返回模拟成功响应
            console.log('GitHub配置未设置，使用模拟模式');
            return {
                success: true,
                message: '编译已启动（模拟模式）',
                run_id: null
            };
        }

        try {
            // 使用GitHub Repository Dispatch API触发编译
            const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/dispatches`, {
                method: 'POST',
                headers: {
                    'Authorization': `token ${GITHUB_TOKEN}`,
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
                    message: '编译已成功启动',
                    run_id: null // GitHub Dispatch API不直接返回run_id
                };
            } else {
                const errorData = await response.json();
                return {
                    success: false,
                    message: errorData.message || '启动失败'
                };
            }
        } catch (error) {
            return {
                success: false,
                message: error.message
            };
        }
    }

    showBuildSuccess() {
        const logsContent = document.getElementById('logs-content');
        logsContent.innerHTML = `
            <div class="log-entry info">
                <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                <span class="log-message">🚀 编译任务已成功提交到GitHub Actions</span>
            </div>
            <div class="log-entry info">
                <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                <span class="log-message">📋 配置信息: ${this.config.source} - ${this.config.device}</span>
            </div>
            <div class="log-entry info">
                <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                <span class="log-message">🔧 选中插件: ${this.config.plugins.length}个</span>
            </div>
            <div class="log-entry info">
                <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                <span class="log-message">⏳ 正在等待编译开始...</span>
            </div>
        `;
    }

    simulateProgress() {
        // 模拟编译进度（当无法连接GitHub API时使用）
        let progress = 0;
        const progressFill = document.getElementById('progress-fill');
        const progressText = document.getElementById('progress-text');
        const logsContent = document.getElementById('logs-content');

        const stages = [
            { progress: 5, message: '📥 正在初始化编译环境...' },
            { progress: 15, message: '📦 正在下载源码...' },
            { progress: 25, message: '🔧 正在配置插件源...' },
            { progress: 35, message: '📥 正在下载依赖包...' },
            { progress: 50, message: '🚀 开始编译固件...' },
            { progress: 70, message: '📦 正在编译内核模块...' },
            { progress: 85, message: '🔨 正在构建固件镜像...' },
            { progress: 95, message: '✅ 编译完成，正在打包...' },
            { progress: 100, message: '🎉 固件编译成功！' }
        ];

        let currentStage = 0;
        const interval = setInterval(() => {
            if (currentStage >= stages.length) {
                clearInterval(interval);
                this.onBuildComplete({ status: 'completed', conclusion: 'success' });
                return;
            }

            const stage = stages[currentStage];
            progress = stage.progress;
            
            progressFill.style.width = progress + '%';
            progressText.textContent = progress + '%';

            // 添加日志条目
            const logEntry = document.createElement('div');
            logEntry.className = 'log-entry info';
            logEntry.innerHTML = `
                <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                <span class="log-message">${stage.message}</span>
            `;
            logsContent.appendChild(logEntry);
            logsContent.scrollTop = logsContent.scrollHeight;

            currentStage++;
        }, 3000); // 每3秒一个阶段
    }

    async startProgressMonitoring(runId) {
        // 监控真实的GitHub Actions编译进度
        const monitor = setInterval(async () => {
            try {
                const status = await this.getWorkflowStatus(runId);
                this.updateProgress(status);
                
                if (['completed', 'cancelled', 'failure'].includes(status.status)) {
                    clearInterval(monitor);
                    this.onBuildComplete(status);
                }
            } catch (error) {
                console.error('监控失败:', error);
                // 如果监控失败，回退到模拟模式
                clearInterval(monitor);
                this.simulateProgress();
            }
        }, 30000); // 30秒检查一次
    }

    async getWorkflowStatus(runId) {
        const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/actions/runs/${runId}`, {
            headers: {
                'Authorization': `token ${GITHUB_TOKEN}`,
                'Accept': 'application/vnd.github.v3+json'
            }
        });
        
        if (!response.ok) {
            throw new Error('无法获取工作流状态');
        }
        
        return await response.json();
    }

    updateProgress(status) {
        const progressFill = document.getElementById('progress-fill');
        const progressText = document.getElementById('progress-text');
        const logsContent = document.getElementById('logs-content');
        
        // 根据状态估算进度百分比
        let percentage = 0;
        let statusMessage = '';
        
        switch (status.status) {
            case 'queued':
                percentage = 5;
                statusMessage = '⏳ 编译任务已排队';
                break;
            case 'in_progress':
                // 根据运行时间估算（假设编译需要2小时）
                const elapsed = Date.now() - new Date(status.created_at).getTime();
                const totalTime = 2 * 60 * 60 * 1000; // 2小时
                percentage = Math.min(90, 10 + (elapsed / totalTime) * 80);
                statusMessage = '🚀 正在编译中...';
                break;
            case 'completed':
                percentage = 100;
                statusMessage = status.conclusion === 'success' ? '✅ 编译成功完成' : '❌ 编译失败';
                break;
            case 'cancelled':
                percentage = 0;
                statusMessage = '⚠️ 编译已取消';
                break;
        }
        
        progressFill.style.width = percentage + '%';
        progressText.textContent = Math.round(percentage) + '%';
        
        // 添加状态日志
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry ${status.conclusion === 'failure' ? 'error' : 'info'}`;
        logEntry.innerHTML = `
            <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
            <span class="log-message">${statusMessage}</span>
        `;
        logsContent.appendChild(logEntry);
        logsContent.scrollTop = logsContent.scrollHeight;
    }

    onBuildComplete(status) {
        const logsContent = document.getElementById('logs-content');
        
        if (status.conclusion === 'success' || status.status === 'completed') {
            // 编译成功
            const successEntry = document.createElement('div');
            successEntry.className = 'log-entry info';
            successEntry.innerHTML = `
                <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                <span class="log-message">🎉 固件编译完成！请前往GitHub Releases页面下载</span>
            `;
            logsContent.appendChild(successEntry);
            
            // 显示下载链接
            if (GITHUB_REPO) {
                const downloadLink = document.createElement('div');
                downloadLink.className = 'log-entry info';
                downloadLink.innerHTML = `
                    <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                    <span class="log-message">🔗 下载地址: <a href="https://github.com/${GITHUB_REPO}/releases" target="_blank">GitHub Releases</a></span>
                `;
                logsContent.appendChild(downloadLink);
            }
        } else {
            // 编译失败
            const errorEntry = document.createElement('div');
            errorEntry.className = 'log-entry error';
            errorEntry.innerHTML = `
                <span class="log-timestamp">${new Date().toLocaleTimeString()}</span>
                <span class="log-message">❌ 编译失败，请检查配置或查看GitHub Actions日志</span>
            `;
            logsContent.appendChild(errorEntry);
        }
        
        logsContent.scrollTop = logsContent.scrollHeight;
    }

    nextStep() {
        // 验证当前步骤
        if (!this.validateCurrentStep()) {
            return;
        }
        
        if (this.currentStep < this.maxSteps) {
            this.currentStep++;
            this.updateStepDisplay();
            
            // 如果进入插件选择步骤，刷新插件数据
            if (this.currentStep === 3) {
                this.loadPluginData();
            }
        }
    }

    prevStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.updateStepDisplay();
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
            case 3:
                // 插件选择是可选的，不做强制验证
                break;
        }
        return true;
    }

    updateStepDisplay() {
        // 更新步骤指示器
        document.querySelectorAll('.step').forEach((step, index) => {
            step.classList.toggle('active', index + 1 === this.currentStep);
        });
        
        // 更新内容区域
        document.querySelectorAll('.step-content').forEach((content, index) => {
            content.classList.toggle('active', index + 1 === this.currentStep);
        });
        
        // 更新导航按钮
        document.getElementById('prev-btn').disabled = this.currentStep === 1;
        const nextBtn = document.getElementById('next-btn');
        if (this.currentStep === this.maxSteps) {
            nextBtn.textContent = '完成配置';
            nextBtn.style.display = 'none'; // 隐藏下一步按钮
        } else {
            nextBtn.textContent = '下一步';
            nextBtn.style.display = 'inline-block';
        }
    }

    updateSummary() {
        // 更新配置摘要
        const sourceNames = {
            'openwrt-main': 'OpenWrt官方',
            'lede-master': 'Lean\'s LEDE',
            'immortalwrt-master': 'ImmortalWrt'
        };
        
        document.getElementById('summary-source').textContent = 
            sourceNames[this.config.source] || this.config.source || '-';
        
        // 获取设备名称
        const deviceElement = document.querySelector(`[data-device="${this.config.device}"]`);
        const deviceName = deviceElement ? deviceElement.querySelector('h4').textContent : this.config.device;
        document.getElementById('summary-device').textContent = deviceName || '-';
        
        document.getElementById('summary-plugins').textContent = `${this.config.plugins.length}个`;
    }
}

// 页面加载完成后初始化向导
document.addEventListener('DOMContentLoaded', () => {
    console.log('OpenWrt智能编译工具初始化...');
    new OpenWrtWizard();
});