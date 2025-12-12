/**
 * Products Page Module
 * Handles bulk stock update functionality
 */

(function() {
    'use strict';

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        initBulkStockUpdate();
    });

    /**
     * Initialize bulk stock update functionality
     */
    function initBulkStockUpdate() {
        const checkboxes = document.querySelectorAll('.product-checkbox');
        const selectedCountSpan = document.getElementById('selectedCount');
        const bulkUpdateBtn = document.getElementById('bulkUpdateBtn');

        if (!bulkUpdateBtn) return; // Exit if elements not found

        // Update selected count
        function updateSelectedCount() {
            const selectedCount = document.querySelectorAll('.product-checkbox:checked').length;
            selectedCountSpan.textContent = selectedCount + ' ürün seçildi';
            bulkUpdateBtn.disabled = selectedCount === 0;
        }
        
        checkboxes.forEach(cb => {
            cb.addEventListener('change', updateSelectedCount);
        });
        
        // Bulk update handler
        bulkUpdateBtn.addEventListener('click', async function() {
            const selectedProducts = [];
            const reason = document.getElementById('bulkUpdateReason').value;
            
            document.querySelectorAll('.product-checkbox:checked').forEach(cb => {
                const productId = cb.value;
                const newStock = document.querySelector(`.stock-input[data-product-id="${productId}"]`).value;
                
                selectedProducts.push({
                    ProductId: productId,
                    NewStockQuantity: parseInt(newStock),
                    Reason: reason || 'Toplu güncelleme'
                });
            });
            
            if (selectedProducts.length === 0) {
                showErrorToast('Lütfen en az bir ürün seçin');
                return;
            }
            
            // Disable button during request
            bulkUpdateBtn.disabled = true;
            bulkUpdateBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Güncelleniyor...';
            
            try {
                const response = await fetch('/Stock/BulkUpdate', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'RequestVerificationToken': document.querySelector('input[name="__RequestVerificationToken"]')?.value
                    },
                    body: JSON.stringify({
                        StockUpdates: selectedProducts,
                        Reason: reason
                    })
                });
                
                const result = await response.json();
                
                if (result.success) {
                    showSuccessToast(result.message || 'Stok seviyeleri başarıyla güncellendi');
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                } else {
                    showErrorToast(result.message || 'Stok güncellemesi başarısız oldu');
                }
            } catch (error) {
                console.error('Bulk update error:', error);
                showErrorToast('Bir hata oluştu. Lütfen tekrar deneyin.');
            } finally {
                bulkUpdateBtn.disabled = false;
                bulkUpdateBtn.innerHTML = '<i class="fas fa-save me-2"></i>Güncelle';
            }
        });
    }

    /**
     * Toast helper functions
     */
    function showSuccessToast(message) {
        if (typeof showToast === 'function') {
            showToast(message, 'success', 5000);
        } else {
            alert('✅ ' + message);
        }
    }

    function showErrorToast(message) {
        if (typeof showToast === 'function') {
            showToast(message, 'error', 5000);
        } else {
            alert('❌ ' + message);
        }
    }

})();

