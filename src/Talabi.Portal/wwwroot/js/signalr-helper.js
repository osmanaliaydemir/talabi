/**
 * SignalR Helper - Getir Merchant Portal
 * Manages SignalR connections and real-time notifications
 */

class SignalRManager {
    constructor(hubUrl, token) {
        this.hubUrl = hubUrl;
        this.token = token;
        this.connection = null;
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
    }

    async connect() {
        try {
            this.connection = new signalR.HubConnectionBuilder()
                .withUrl(this.hubUrl, {
                    accessTokenFactory: () => this.token,
                    headers: { "Authorization": `Bearer ${this.token}` }
                })
                .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
                .configureLogging(signalR.LogLevel.Information)
                .build();

            // Connection events
            this.connection.onreconnecting(error => {
                console.warn('SignalR Reconnecting...', error);
                this.isConnected = false;
                showToast('Bağlantı kuruluyor...', 'warning');
            });

            this.connection.onreconnected(connectionId => {
                console.log('SignalR Reconnected:', connectionId);
                this.isConnected = true;
                this.reconnectAttempts = 0;
                showToast('Bağlantı yeniden kuruldu', 'success');
            });

            this.connection.onclose(error => {
                console.error('SignalR Connection closed:', error);
                this.isConnected = false;
                
                if (this.reconnectAttempts < this.maxReconnectAttempts) {
                    this.reconnectAttempts++;
                    setTimeout(() => this.connect(), 5000);
                } else {
                    showToast('Bağlantı koptu. Sayfayı yenileyin.', 'danger');
                }
            });

            await this.connection.start();
            this.isConnected = true;
            console.log('SignalR Connected successfully');
            
            return this.connection;
        } catch (error) {
            console.error('SignalR Connection error:', error);
            this.isConnected = false;
            throw error;
        }
    }

    async disconnect() {
        if (this.connection) {
            await this.connection.stop();
            this.isConnected = false;
            console.log('SignalR Disconnected');
        }
    }

    on(eventName, callback) {
        if (this.connection) {
            this.connection.on(eventName, callback);
        }
    }

    off(eventName, callback) {
        if (this.connection) {
            this.connection.off(eventName, callback);
        }
    }

    async invoke(methodName, ...args) {
        if (this.connection && this.isConnected) {
            return await this.connection.invoke(methodName, ...args);
        } else {
            console.error('SignalR not connected');
            throw new Error('SignalR connection not established');
        }
    }
}

// Toast Notification System
function showToast(message, type = 'info', duration = 5000) {
    // Remove existing toast
    const existingToast = document.querySelector('.signalr-toast');
    if (existingToast) {
        existingToast.remove();
    }

    const toast = document.createElement('div');
    toast.className = `signalr-toast signalr-toast-${type}`;
    
    const icon = getToastIcon(type);
    
    toast.innerHTML = `
        <div class="signalr-toast-content">
            <i class="fas ${icon}"></i>
            <span>${message}</span>
        </div>
        <button class="signalr-toast-close" onclick="this.parentElement.remove()">
            <i class="fas fa-times"></i>
        </button>
    `;
    
    document.body.appendChild(toast);
    
    // Animate in
    setTimeout(() => toast.classList.add('show'), 10);
    
    // Auto remove
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, duration);
}

function getToastIcon(type) {
    switch (type) {
        case 'success': return 'fa-check-circle';
        case 'danger': return 'fa-exclamation-circle';
        case 'warning': return 'fa-exclamation-triangle';
        case 'info': return 'fa-info-circle';
        default: return 'fa-bell';
    }
}

// Play notification sound
function playNotificationSound() {
    try {
        // Check if sound is enabled
        const preferences = getNotificationPreferences();
        if (!preferences.soundEnabled) {
            console.log('Sound is disabled in preferences');
            return;
        }
        
        // Check Do Not Disturb mode
        if (isInDoNotDisturbPeriod()) {
            console.log('Do Not Disturb mode is active');
            return;
        }
        
        // Sound file mapping
        const soundFiles = {
            'default': '/sounds/notify-default.wav',
            'chime': '/sounds/notify-1.wav',
            'bell': '/sounds/notify-2.wav',
            'ding': '/sounds/notify-3.wav',
            'ping': '/sounds/notify-4.wav'
        };
        
        const selectedSound = preferences.notificationSound || 'default';
        const soundFile = soundFiles[selectedSound] || soundFiles['default'];
        
        const audio = new Audio(soundFile);
        audio.volume = 0.5;
        audio.play().catch(err => console.log('Sound play failed:', err));
    } catch (err) {
        console.log('Notification sound error:', err);
    }
}

// Get notification preferences from localStorage
function getNotificationPreferences() {
    const saved = localStorage.getItem('notificationPreferences');
    if (saved) {
        return JSON.parse(saved);
    }
    
    // Default preferences
    return {
        soundEnabled: true,
        desktopNotifications: true,
        emailNotifications: false,
        newOrderNotifications: true,
        statusChangeNotifications: true,
        cancellationNotifications: true,
        doNotDisturbEnabled: false,
        notificationSound: 'default'
    };
}

// Check if currently in Do Not Disturb period
function isInDoNotDisturbPeriod() {
    const preferences = getNotificationPreferences();
    
    if (!preferences.doNotDisturbEnabled) {
        return false;
    }
    
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    
    if (preferences.doNotDisturbStart && preferences.doNotDisturbEnd) {
        const [startHour, startMin] = preferences.doNotDisturbStart.split(':');
        const [endHour, endMin] = preferences.doNotDisturbEnd.split(':');
        
        const startMinutes = parseInt(startHour) * 60 + parseInt(startMin);
        const endMinutes = parseInt(endHour) * 60 + parseInt(endMin);
        
        // Handle overnight periods (e.g., 22:00 - 08:00)
        if (startMinutes > endMinutes) {
            return currentTime >= startMinutes || currentTime <= endMinutes;
        } else {
            return currentTime >= startMinutes && currentTime <= endMinutes;
        }
    }
    
    return false;
}

// Send desktop notification
function sendDesktopNotification(title, body, icon = '/favicon.ico') {
    const preferences = getNotificationPreferences();
    
    if (!preferences.desktopNotifications) {
        return;
    }
    
    if (isInDoNotDisturbPeriod()) {
        console.log('In Do Not Disturb period, skipping notification');
        return;
    }
    
    if (!("Notification" in window)) {
        console.log('Desktop notifications not supported');
        return;
    }
    
    if (Notification.permission === "granted") {
        new Notification(title, {
            body: body,
            icon: icon,
            badge: icon
        });
    }
}

// Format date for display
function formatOrderDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffMins < 1) return 'Şimdi';
    if (diffMins < 60) return `${diffMins} dk önce`;
    
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours} saat önce`;
    
    return date.toLocaleDateString('tr-TR', { 
        day: '2-digit', 
        month: 'short', 
        hour: '2-digit', 
        minute: '2-digit' 
    });
}

// Global export
window.SignalRManager = SignalRManager;
window.showToast = showToast;
window.playNotificationSound = playNotificationSound;
window.formatOrderDate = formatOrderDate;

