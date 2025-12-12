/**
 * Settings Page Module
 * Handles notification preferences, theme settings, and password change
 */

(function() {
    'use strict';

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        initNotificationPreferences();
        initPasswordChange();
    });

    /**
     * Initialize notification preferences
     */
    function initNotificationPreferences() {
        // Save notification preferences to localStorage
        document.querySelectorAll('[id^="notif-"]').forEach(checkbox => {
            const key = 'merchant_' + checkbox.id;
            
            // Load saved preference
            const saved = localStorage.getItem(key);
            if (saved !== null) {
                checkbox.checked = saved === 'true';
            }
            
            // Save on change
            checkbox.addEventListener('change', function() {
                localStorage.setItem(key, this.checked);
                if (typeof showToast === 'function') {
                    showToast('Bildirim tercihleri kaydedildi', 'success', 3000);
                }
            });
        });
    }

    /**
     * Initialize password change functionality
     */
    function initPasswordChange() {
        const changePasswordForm = document.getElementById('changePasswordForm');
        const savePasswordBtn = document.getElementById('savePasswordBtn');
        const currentPasswordInput = document.getElementById('currentPassword');
        const newPasswordInput = document.getElementById('newPassword');
        const confirmPasswordInput = document.getElementById('confirmPassword');
        const passwordStrengthDiv = document.getElementById('passwordStrength');
        const strengthBar = document.getElementById('strengthBar');
        const strengthText = document.getElementById('strengthText');

        if (!changePasswordForm) return; // Exit if elements not found

        // Password strength checker
        newPasswordInput.addEventListener('input', function() {
            const password = this.value;
            if (password.length === 0) {
                passwordStrengthDiv.style.display = 'none';
                return;
            }

            passwordStrengthDiv.style.display = 'block';
            const strength = calculatePasswordStrength(password);
            
            strengthBar.style.width = strength.percentage + '%';
            strengthBar.className = 'progress-bar ' + strength.class;
            strengthText.textContent = strength.text;
            strengthText.className = 'text-' + strength.color;
        });

        // Password confirmation validation
        confirmPasswordInput.addEventListener('input', function() {
            if (newPasswordInput.value !== confirmPasswordInput.value) {
                confirmPasswordInput.setCustomValidity('Şifreler eşleşmiyor');
            } else {
                confirmPasswordInput.setCustomValidity('');
            }
        });

        // Save password handler
        savePasswordBtn.addEventListener('click', async function() {
            // Validate form
            if (!changePasswordForm.checkValidity()) {
                changePasswordForm.classList.add('was-validated');
                return;
            }

            if (newPasswordInput.value !== confirmPasswordInput.value) {
                confirmPasswordInput.classList.add('is-invalid');
                return;
            }

            // Disable button and show loading
            const btnText = savePasswordBtn.querySelector('.btn-text');
            const btnLoading = savePasswordBtn.querySelector('.btn-loading');
            savePasswordBtn.disabled = true;
            btnText.style.display = 'none';
            btnLoading.style.display = 'inline-block';

            try {
                // Get CSRF token
                const token = document.querySelector('input[name="__RequestVerificationToken"]').value;
                
                const response = await fetch('/Settings/ChangePassword', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'RequestVerificationToken': token
                    },
                    body: JSON.stringify({
                        currentPassword: currentPasswordInput.value,
                        newPassword: newPasswordInput.value,
                        confirmPassword: confirmPasswordInput.value
                    })
                });

                const result = await response.json();

                if (result.success) {
                    // Success - close modal and show toast
                    showSuccessToast(result.message || 'Şifreniz başarıyla değiştirildi');
                    
                    // Close modal after short delay to show success
                    setTimeout(() => {
                        bootstrap.Modal.getInstance(document.getElementById('changePasswordModal')).hide();
                        changePasswordForm.reset();
                        changePasswordForm.classList.remove('was-validated');
                        passwordStrengthDiv.style.display = 'none';
                    }, 300);
                } else {
                    // Error - keep modal open and show error
                    showErrorToast(result.message || 'Şifre değiştirilemedi!');
                    // Modal kalır açık, kullanıcı tekrar deneyebilir
                }
            } catch (error) {
                console.error('Password change error:', error);
                showErrorToast('Bir hata oluştu. Lütfen tekrar deneyin.');
            } finally {
                // Re-enable button
                savePasswordBtn.disabled = false;
                btnText.style.display = 'inline-block';
                btnLoading.style.display = 'none';
            }
        });

        // Reset form when modal is closed
        document.getElementById('changePasswordModal').addEventListener('hidden.bs.modal', function () {
            changePasswordForm.reset();
            changePasswordForm.classList.remove('was-validated');
            passwordStrengthDiv.style.display = 'none';
        });
    }

    /**
     * Calculate password strength
     */
    function calculatePasswordStrength(password) {
        let strength = 0;
        
        if (password.length >= 8) strength += 25;
        if (password.length >= 12) strength += 25;
        if (/[a-z]/.test(password)) strength += 12.5;
        if (/[A-Z]/.test(password)) strength += 12.5;
        if (/[0-9]/.test(password)) strength += 12.5;
        if (/[^a-zA-Z0-9]/.test(password)) strength += 12.5;

        if (strength < 40) {
            return { percentage: strength, class: 'bg-danger', text: 'Zayıf', color: 'danger' };
        } else if (strength < 70) {
            return { percentage: strength, class: 'bg-warning', text: 'Orta', color: 'warning' };
        } else {
            return { percentage: strength, class: 'bg-success', text: 'Güçlü', color: 'success' };
        }
    }

    /**
     * Toast helper functions
     */
    function showSuccessToast(message) {
        if (typeof showToast === 'function') {
            showToast(message, 'success', 5000); // 5 saniye görünür kalır
        } else {
            alert('✅ ' + message);
        }
    }

    function showErrorToast(message) {
        if (typeof showToast === 'function') {
            showToast(message, 'error', 5000); // 5 saniye görünür kalır
        } else {
            alert('❌ ' + message);
        }
    }

})();

