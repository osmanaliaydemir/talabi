// i18n.js - Çoklu Dil Desteği
class I18n {
    constructor() {
        this.currentLang = localStorage.getItem('language') || 'ar'; // Varsayılan: Arapça
        this.translations = {};
        this.init();
    }

    async init() {
        await this.loadLanguage(this.currentLang);
        this.applyLanguage();
        this.setupLanguageSwitcher();
    }

    async loadLanguage(lang) {
        try {
            const response = await fetch(`/locales/${lang}.json`);
            this.translations = await response.json();
            this.currentLang = lang;
            localStorage.setItem('language', lang);
        } catch (error) {
            console.error(`Error loading language ${lang}:`, error);
            // Fallback to Arabic if error
            if (lang !== 'ar') {
                await this.loadLanguage('ar');
            }
        }
    }

    translate(key) {
        const keys = key.split('.');
        let value = this.translations;

        for (const k of keys) {
            value = value[k];
            if (value === undefined) {
                return key; // Return key if translation not found
            }
        }

        return value;
    }

    applyLanguage() {
        // Update HTML direction and lang attribute
        const html = document.documentElement;
        html.setAttribute('lang', this.currentLang);
        html.setAttribute('dir', this.currentLang === 'ar' ? 'rtl' : 'ltr');

        // Toggle RTL CSS
        this.toggleRTL();

        // Update all elements with data-i18n attribute
        document.querySelectorAll('[data-i18n]').forEach(element => {
            const key = element.getAttribute('data-i18n');
            element.textContent = this.translate(key);
        });

        // Update placeholders
        document.querySelectorAll('[data-i18n-placeholder]').forEach(element => {
            const key = element.getAttribute('data-i18n-placeholder');
            element.placeholder = this.translate(key);
        });

        // Update active language in switcher
        this.updateLanguageSwitcher();
    }

    toggleRTL() {
        const rtlLink = document.getElementById('rtl-css');

        if (this.currentLang === 'ar') {
            if (!rtlLink) {
                const link = document.createElement('link');
                link.id = 'rtl-css';
                link.rel = 'stylesheet';
                link.href = '/css/rtl.css';
                document.head.appendChild(link);
            }
        } else {
            if (rtlLink) {
                rtlLink.remove();
            }
        }
    }

    setupLanguageSwitcher() {
        const langButtons = document.querySelectorAll('.lang-btn');
        langButtons.forEach(button => {
            button.addEventListener('click', async (e) => {
                e.preventDefault();
                const lang = button.getAttribute('data-lang');
                await this.changeLanguage(lang);
            });
        });
    }

    async changeLanguage(lang) {
        if (lang !== this.currentLang) {
            await this.loadLanguage(lang);
            this.applyLanguage();

            // Add smooth transition effect
            document.body.style.opacity = '0.8';
            setTimeout(() => {
                document.body.style.opacity = '1';
            }, 200);
        }
    }

    updateLanguageSwitcher() {
        document.querySelectorAll('.lang-btn').forEach(button => {
            button.classList.remove('active');
            if (button.getAttribute('data-lang') === this.currentLang) {
                button.classList.add('active');
            }
        });
    }

    // Helper method to get translation
    t(key) {
        return this.translate(key);
    }
}

// Initialize i18n when DOM is ready
let i18n;
document.addEventListener('DOMContentLoaded', () => {
    i18n = new I18n();
});
