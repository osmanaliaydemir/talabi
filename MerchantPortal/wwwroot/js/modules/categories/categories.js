/**
 * Categories Page Module
 * Handles category tree, drag & drop reordering
 */

(function() {
    'use strict';

    let reorderMode = false;
    let draggedElement = null;
    let originalOrders = {};

    // Initialize when DOM is ready
    $(document).ready(function() {
        initCategoryTree();
        initDragAndDrop();
        initReorderMode();
    });

    /**
     * Initialize category tree toggle
     */
    function initCategoryTree() {
        $('.category-toggle').click(function() {
            const $toggle = $(this);
            const targetId = $toggle.data('target');
            const $target = $(targetId);
            
            $target.slideToggle(200);
            $toggle.toggleClass('collapsed');
        });
    }

    /**
     * Initialize drag and drop functionality
     */
    function initDragAndDrop() {
        const nodes = document.querySelectorAll('.category-node');
        
        nodes.forEach(node => {
            // Make node draggable only in reorder mode
            node.setAttribute('draggable', false);
            
            // Drag start
            node.addEventListener('dragstart', function(e) {
                if (!reorderMode) {
                    e.preventDefault();
                    return;
                }
                
                draggedElement = this;
                this.classList.add('dragging');
                e.dataTransfer.effectAllowed = 'move';
                e.dataTransfer.setData('text/html', this.innerHTML);
            });
            
            // Drag over
            node.addEventListener('dragover', function(e) {
                if (!reorderMode || draggedElement === this) return;
                
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                
                const parentId = draggedElement.dataset.parentId;
                const thisParentId = this.dataset.parentId;
                
                // Only allow reorder within same level
                if (parentId === thisParentId) {
                    this.classList.add('drag-over');
                }
            });
            
            // Drag leave
            node.addEventListener('dragleave', function() {
                this.classList.remove('drag-over');
            });
            
            // Drop
            node.addEventListener('drop', function(e) {
                if (!reorderMode || draggedElement === this) return;
                
                e.stopPropagation();
                e.preventDefault();
                
                const parentId = draggedElement.dataset.parentId;
                const thisParentId = this.dataset.parentId;
                
                // Only allow reorder within same level
                if (parentId === thisParentId) {
                    // Swap elements
                    const parent = this.parentNode;
                    const draggedIndex = Array.from(parent.children).indexOf(draggedElement);
                    const targetIndex = Array.from(parent.children).indexOf(this);
                    
                    if (draggedIndex < targetIndex) {
                        parent.insertBefore(draggedElement, this.nextSibling);
                    } else {
                        parent.insertBefore(draggedElement, this);
                    }
                    
                    updateDisplayOrders(parent);
                }
                
                this.classList.remove('drag-over');
            });
            
            // Drag end
            node.addEventListener('dragend', function() {
                this.classList.remove('dragging');
                document.querySelectorAll('.drag-over').forEach(el => {
                    el.classList.remove('drag-over');
                });
            });
        });
    }

    /**
     * Initialize reorder mode buttons
     */
    function initReorderMode() {
        $('#toggleReorderBtn').click(function() {
            toggleReorderMode(true);
        });
        
        $('#cancelOrderBtn').click(function() {
            restoreOriginalOrder();
            toggleReorderMode(false);
        });
        
        $('#saveOrderBtn').click(function() {
            saveNewOrder();
        });
    }

    /**
     * Toggle reorder mode on/off
     */
    function toggleReorderMode(enable) {
        reorderMode = enable;
        
        if (enable) {
            // Save original orders
            saveOriginalOrders();
            
            // Enable dragging for all nodes
            $('.category-node').each(function() {
                $(this).attr('draggable', true);
                $(this).css('cursor', 'move');
            });
            
            // Show reorder UI
            $('.category-tree').addClass('reorder-mode');
            $('#toggleReorderBtn').hide();
            $('#saveOrderBtn, #cancelOrderBtn').show();
            $('#reorderHint').show();
            $('[href*="Create"]').hide();
            $('.btn-group').hide(); // Hide edit/delete buttons
            
            // Show drag handle hint
            $('.drag-handle').css('opacity', '1');
        } else {
            // Disable dragging
            $('.category-node').each(function() {
                $(this).attr('draggable', false);
                $(this).css('cursor', 'default');
            });
            
            $('.category-tree').removeClass('reorder-mode');
            $('#toggleReorderBtn').show();
            $('#saveOrderBtn, #cancelOrderBtn').hide();
            $('#reorderHint').hide();
            $('[href*="Create"]').show();
            $('.btn-group').show(); // Show edit/delete buttons
            
            $('.drag-handle').css('opacity', '0.5');
        }
    }

    /**
     * Save original category orders
     */
    function saveOriginalOrders() {
        originalOrders = {};
        $('.category-node').each(function() {
            const id = $(this).data('category-id');
            const order = $(this).data('display-order');
            originalOrders[id] = {
                element: $(this).clone(),
                order: order,
                parent: $(this).parent()
            };
        });
    }

    /**
     * Restore original category order
     */
    function restoreOriginalOrder() {
        // Restore all nodes to original positions
        Object.keys(originalOrders).forEach(id => {
            const original = originalOrders[id];
            const current = $(`.category-node[data-category-id="${id}"]`);
            original.parent.append(current);
        });
        
        originalOrders = {};
    }

    /**
     * Update display orders after drag
     */
    function updateDisplayOrders(parent) {
        // Update display order data attributes
        $(parent).children('.category-node').each(function(index) {
            $(this).data('display-order', index);
            $(this).attr('data-display-order', index);
        });
    }

    /**
     * Save new category order to backend
     */
    function saveNewOrder() {
        const updates = [];
        
        $('.category-node').each(function(index) {
            const $node = $(this);
            const categoryId = $node.data('category-id');
            const parentId = $node.data('parent-id') || null;
            const newOrder = $node.data('display-order');
            
            updates.push({
                categoryId: categoryId,
                parentCategoryId: parentId,
                displayOrder: newOrder
            });
        });
        
        // Send to backend via AJAX
        $.ajax({
            url: '/Categories/UpdateOrder',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify(updates),
            headers: {
                'RequestVerificationToken': $('input[name="__RequestVerificationToken"]').val()
            },
            success: function(response) {
                if (response.success) {
                    showSuccessToast('Kategori sıralaması güncellendi');
                    
                    // Exit reorder mode
                    toggleReorderMode(false);
                    
                    // Refresh page after 1 second
                    setTimeout(() => window.location.reload(), 1000);
                } else {
                    showErrorToast(response.message || 'Sıralama güncellenirken hata oluştu');
                }
            },
            error: function(xhr, status, error) {
                console.error('Category reorder error:', error);
                showErrorToast('Sıralama güncellenirken hata oluştu');
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
            showLegacyToast('success', 'Başarılı', message);
        }
    }

    function showErrorToast(message) {
        if (typeof showToast === 'function') {
            showToast(message, 'error', 5000);
        } else {
            showLegacyToast('error', 'Hata', message);
        }
    }

    /**
     * Legacy toast (fallback)
     */
    function showLegacyToast(type, title, message) {
        const iconClass = type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle';
        const bgClass = type === 'success' ? 'alert-success' : 'alert-danger';
        
        const toast = $(`
            <div class="alert ${bgClass} alert-dismissible fade show position-fixed" 
                 style="top: 20px; right: 20px; z-index: 9999; min-width: 300px;">
                <i class="fas ${iconClass} me-2"></i>
                <strong>${title}:</strong> ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `);
        
        $('body').append(toast);
        
        setTimeout(() => toast.fadeOut(() => toast.remove()), 5000);
    }

})();

