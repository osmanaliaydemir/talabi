/**
 * Login Page Module
 * Handles login form submission with loading state
 */

(function() {
    'use strict';

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        initLoginForm();
    });

    /**
     * Initialize login form functionality
     */
    function initLoginForm() {
        const loginForm = document.querySelector('form');
        const loginBtn = document.getElementById('loginBtn');
        
        if (!loginForm || !loginBtn) return;

        const btnText = loginBtn.querySelector('.btn-text');
        const btnLoading = loginBtn.querySelector('.btn-loading');
        
        // Handle form submission
        loginForm.addEventListener('submit', function(e) {
            // Check if form is valid
            if (loginForm.checkValidity()) {
                // Disable button
                loginBtn.disabled = true;
                
                // Show loading state
                btnText.style.display = 'none';
                btnLoading.style.display = 'inline-block';
                
                // Add visual feedback
                loginBtn.style.opacity = '0.8';
                loginBtn.style.cursor = 'not-allowed';
            }
        });
        
        // Reset loading state if there's a validation error or back navigation
        window.addEventListener('pageshow', function(event) {
            if (event.persisted) {
                resetButton();
            }
        });

        // Reset button state on validation errors
        loginForm.addEventListener('invalid', function() {
            setTimeout(resetButton, 100);
        }, true);

        function resetButton() {
            loginBtn.disabled = false;
            btnText.style.display = 'inline-block';
            btnLoading.style.display = 'none';
            loginBtn.style.opacity = '1';
            loginBtn.style.cursor = 'pointer';
        }
    }

})();

