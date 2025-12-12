/**
 * Theme Manager for Getir Merchant Portal
 * Manages light/dark/auto theme switching with localStorage persistence
 */

const ThemeManager = {
    STORAGE_KEY: 'merchant_theme_preference',
    THEMES: {
        LIGHT: 'light',
        DARK: 'dark',
        AUTO: 'auto'
    },

    /**
     * Initialize theme manager
     */
    init() {
        this.applyStoredTheme();
        this.setupEventListeners();
        this.watchSystemPreference();
    },

    /**
     * Get current theme preference
     */
    getCurrentTheme() {
        return localStorage.getItem(this.STORAGE_KEY) || this.THEMES.AUTO;
    },

    /**
     * Set theme preference
     */
    setTheme(theme) {
        if (!Object.values(this.THEMES).includes(theme)) {
            console.error('Invalid theme:', theme);
            return;
        }

        localStorage.setItem(this.STORAGE_KEY, theme);
        this.applyTheme(theme);
        this.updateThemeSelector(theme);
        this.notifyThemeChange(theme);
    },

    /**
     * Apply theme to document
     */
    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        
        // Determine if dark mode is active
        const isDark = theme === this.THEMES.DARK || (theme === this.THEMES.AUTO && this.isSystemDarkMode());
        
        if (isDark) {
            document.body.classList.add('dark-mode');
        } else {
            document.body.classList.remove('dark-mode');
        }

        // Update theme toggle button icon
        this.updateToggleButtonIcon(isDark);
    },

    /**
     * Update theme toggle button icon
     */
    updateToggleButtonIcon(isDark) {
        const moonIcon = document.querySelector('.theme-toggle-icon.moon');
        const sunIcon = document.querySelector('.theme-toggle-icon.sun');
        
        if (moonIcon && sunIcon) {
            if (isDark) {
                moonIcon.style.display = 'none';
                sunIcon.style.display = 'inline';
            } else {
                moonIcon.style.display = 'inline';
                sunIcon.style.display = 'none';
            }
        }
    },

    /**
     * Apply stored theme on page load
     */
    applyStoredTheme() {
        const savedTheme = this.getCurrentTheme();
        this.applyTheme(savedTheme);
    },

    /**
     * Check if system prefers dark mode
     */
    isSystemDarkMode() {
        return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    },

    /**
     * Watch for system preference changes
     */
    watchSystemPreference() {
        if (window.matchMedia) {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                const currentTheme = this.getCurrentTheme();
                if (currentTheme === this.THEMES.AUTO) {
                    this.applyTheme(currentTheme); // Re-apply auto theme
                }
            });
        }
    },

    /**
     * Setup event listeners for theme selectors
     */
    setupEventListeners() {
        // Theme dropdown in settings
        const themeSelect = document.getElementById('themeSelect');
        if (themeSelect) {
            themeSelect.value = this.getCurrentTheme();
            themeSelect.addEventListener('change', (e) => {
                this.setTheme(e.target.value);
            });
        }

        // Theme toggle buttons (if any)
        document.querySelectorAll('[data-theme-toggle]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const theme = e.currentTarget.dataset.themeToggle;
                this.setTheme(theme);
            });
        });
    },

    /**
     * Update theme selector UI
     */
    updateThemeSelector(theme) {
        const themeSelect = document.getElementById('themeSelect');
        if (themeSelect) {
            themeSelect.value = theme;
        }

        // Update any theme indicator buttons
        document.querySelectorAll('[data-theme-toggle]').forEach(btn => {
            const btnTheme = btn.dataset.themeToggle;
            if (btnTheme === theme) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });
    },

    /**
     * Notify theme change (show toast)
     */
    notifyThemeChange(theme) {
        const messages = {
            light: 'Açık tema aktif',
            dark: 'Koyu tema aktif',
            auto: 'Otomatik tema aktif (sistem tercihine göre)'
        };

        const message = messages[theme] || 'Tema değiştirildi';
        
        // Use existing toast function if available
        if (typeof showToast === 'function') {
            showToast('success', 'Tema Değiştirildi', message);
        } else if (typeof window.showNotification === 'function') {
            window.showNotification(message, 'success');
        }
    },

    /**
     * Toggle between light and dark themes
     */
    toggle() {
        const current = this.getCurrentTheme();
        const effectiveTheme = (current === this.THEMES.AUTO) 
            ? (this.isSystemDarkMode() ? this.THEMES.DARK : this.THEMES.LIGHT)
            : current;

        const newTheme = effectiveTheme === this.THEMES.LIGHT 
            ? this.THEMES.DARK 
            : this.THEMES.LIGHT;

        this.setTheme(newTheme);
    },

    /**
     * Get theme icon
     */
    getThemeIcon(theme) {
        const icons = {
            light: '<i class="fas fa-sun"></i>',
            dark: '<i class="fas fa-moon"></i>',
            auto: '<i class="fas fa-circle-half-stroke"></i>'
        };
        return icons[theme] || icons.auto;
    },

    /**
     * Get theme display name
     */
    getThemeName(theme) {
        const names = {
            light: 'Açık Tema',
            dark: 'Koyu Tema',
            auto: 'Otomatik'
        };
        return names[theme] || 'Otomatik';
    }
};

// Initialize theme manager when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => ThemeManager.init());
} else {
    ThemeManager.init();
}

// Export for global access
window.ThemeManager = ThemeManager;

