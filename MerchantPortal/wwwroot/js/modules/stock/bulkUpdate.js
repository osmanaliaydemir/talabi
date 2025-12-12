/**
 * Bulk Stock Update Module
 */

(function() {
    'use strict';

    let selectedProducts = [];

    /**
     * Show bulk update modal
     */
    window.showBulkUpdateModal = function() {
        const selectedCheckboxes = document.querySelectorAll('.product-checkbox:checked');
        if (selectedCheckboxes.length === 0) {
            alert('Lütfen en az bir ürün seçin');
            return;
        }

        selectedProducts = Array.from(selectedCheckboxes).map(cb => cb.value);
        document.getElementById('selectedCount').textContent = selectedProducts.length;

        const modal = new bootstrap.Modal(document.getElementById('bulkStockModal'));
        modal.show();
    };

    /**
     * Apply bulk stock update
     */
    window.applyBulkStockUpdate = async function() {
        const updateType = document.querySelector('input[name="updateType"]:checked').value;
        const stockValue = parseInt(document.getElementById('bulkStockValue').value);
        const reason = document.getElementById('bulkUpdateReason').value;

        if (isNaN(stockValue)) {
            alert('Lütfen geçerli bir stok miktarı girin');
            return;
        }

        const requestData = {
            productIds: selectedProducts,
            stockQuantity: updateType === 'set' ? stockValue : null,
            adjustmentAmount: updateType !== 'set' ? (updateType === 'add' ? stockValue : -stockValue) : null,
            reason: reason,
            isAdjustment: updateType !== 'set'
        };

        try {
            const response = await fetch('/Stock/BulkUpdate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            });

            const result = await response.json();

            if (result.success) {
                alert(`✅ ${selectedProducts.length} ürün güncellendi!`);
                bootstrap.Modal.getInstance(document.getElementById('bulkStockModal')).hide();
                window.location.reload();
            } else {
                alert('❌ Güncelleme hatası: ' + (result.message || 'Bilinmeyen hata'));
            }

        } catch (error) {
            console.error('Bulk update error:', error);
            alert('Toplu güncelleme hatası!');
        }
    };

    /**
     * Select/Deselect all products
     */
    window.toggleAllProducts = function(checked) {
        document.querySelectorAll('.product-checkbox').forEach(cb => {
            cb.checked = checked;
        });
    };

})();

