// XTREME XAI Dashboard JavaScript
// © Elektronikx-Center-Matte ® | Entwicklung: Alexander Mathey ©

class XAIDashboard {
    constructor() {
        this.updateInterval = 2000; // 2 seconds
        this.isRunning = false;
        this.init();
    }

    init() {
        console.log('XTREME XAI Dashboard v4.0 initialized');
        this.startMonitoring();
    }

    // Start real-time monitoring
    startMonitoring() {
        this.isRunning = true;
        this.updateStats();
        setInterval(() => {
            if (this.isRunning) {
                this.updateStats();
            }
        }, this.updateInterval);
    }

    // Stop monitoring
    stopMonitoring() {
        this.isRunning = false;
    }

    // Update all statistics
    updateStats() {
        this.updateTime();
        this.updateCPU();
        this.updateMemory();
        this.updateDisk();
        this.updateTemperature();
        this.updateNetwork();
    }

    // Update current time
    updateTime() {
        const now = new Date();
        const timeString = now.toLocaleTimeString('de-DE');
        const element = document.getElementById('updateTime');
        if (element) {
            element.textContent = timeString;
        }
    }

    // Simulate CPU usage
    updateCPU() {
        // In real implementation, this would fetch from backend API
        const usage = Math.floor(Math.random() * 40 + 20); // 20-60%
        this.updateStatCard('cpu', usage);
    }

    // Simulate memory usage
    updateMemory() {
        const usage = Math.floor(Math.random() * 30 + 40); // 40-70%
        this.updateStatCard('mem', usage);
    }

    // Simulate disk usage
    updateDisk() {
        const usage = Math.floor(Math.random() * 20 + 50); // 50-70%
        this.updateStatCard('disk', usage);
    }

    // Simulate temperature
    updateTemperature() {
        const temp = Math.floor(Math.random() * 20 + 40); // 40-60°C
        const element = document.getElementById('tempValue');
        if (element) {
            element.textContent = temp + '°C';
            
            // Color code temperature
            if (temp > 75) {
                element.style.color = '#ef4444'; // red
            } else if (temp > 60) {
                element.style.color = '#fbbf24'; // yellow
            } else {
                element.style.color = '#4ade80'; // green
            }
        }
    }

    // Update network stats
    updateNetwork() {
        const download = Math.floor(Math.random() * 1000); // KB/s
        const upload = Math.floor(Math.random() * 500); // KB/s
        
        const dlElement = document.getElementById('netDown');
        const upElement = document.getElementById('netUp');
        
        if (dlElement) dlElement.textContent = download + ' KB/s';
        if (upElement) upElement.textContent = upload + ' KB/s';
    }

    // Update stat card with progress bar
    updateStatCard(type, value) {
        const valueEl = document.getElementById(type + 'Value');
        const barEl = document.getElementById(type + 'Bar');

        if (valueEl) valueEl.textContent = value + '%';
        if (barEl) {
            barEl.style.width = value + '%';
            barEl.textContent = value + '%';

            // Update color based on value
            barEl.className = 'progress-fill';
            if (value > 80) {
                barEl.classList.add('danger');
            } else if (value > 60) {
                barEl.classList.add('warning');
            }
        }
    }

    // Format bytes to human readable
    formatBytes(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }

    // Format uptime
    formatUptime(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return `${days}d ${hours}h ${minutes}m`;
    }
}

// Initialize dashboard when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    window.xaiDashboard = new XAIDashboard();
    console.log('Dashboard loaded successfully');
});

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = XAIDashboard;
}
