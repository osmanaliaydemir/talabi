/**
 * Order Details Page Module
 * Handles real-time order updates via SignalR
 */

(function() {
    'use strict';

    let orderHubManager = null;

    // Initialize when DOM is ready
    $(document).ready(function() {
        const orderId = getOrderId();
        if (orderId) {
            initializeOrderSignalR(orderId);
        }
    });

    /**
     * Get order ID from page
     */
    function getOrderId() {
        // Order ID should be set as data attribute or global variable
        return window.currentOrderId || null;
    }

    /**
     * Initialize SignalR connection for order updates
     */
    async function initializeOrderSignalR(orderId) {
        try {
            const token = getAuthToken();
            if (!token) {
                console.warn('No auth token found for SignalR');
                return;
            }

            orderHubManager = new SignalRManager('https://localhost:7001/hubs/orders', token);
            await orderHubManager.connect();
            
            setupOrderStatusListeners(orderId);
            
            console.log('✅ Order SignalR connected');
            
        } catch (error) {
            console.error('❌ Order SignalR error:', error);
        }
    }

    /**
     * Get auth token from session
     */
    function getAuthToken() {
        // Try to get from window variable set by view
        return window.jwtToken || '';
    }

    /**
     * Setup order status listeners
     */
    function setupOrderStatusListeners(orderId) {
        if (!orderHubManager) return;
        
        // Order Status Changed
        orderHubManager.on('OrderStatusChanged', function(data) {
            if (data.orderId === orderId) {
                console.log('🔄 This order status changed:', data);
                
                if (typeof showToast === 'function') {
                    showToast(
                        `Sipariş durumu güncellendi: ${getStatusText(data.status)}`,
                        'success',
                        5000
                    );
                }
                
                // Reload page after 1 second to show updated status
                setTimeout(() => {
                    location.reload();
                }, 1000);
            }
        });
        
        // Order Updated
        orderHubManager.on('OrderUpdated', function(data) {
            if (data.orderId === orderId) {
                console.log('📝 Order updated:', data);
                
                if (typeof showToast === 'function') {
                    showToast('Sipariş bilgileri güncellendi', 'info', 5000);
                }
                
                setTimeout(() => {
                    location.reload();
                }, 1000);
            }
        });
    }

    /**
     * Get Turkish status text
     */
    function getStatusText(status) {
        const statusMap = {
            'Pending': 'Bekliyor',
            'Confirmed': 'Onaylandı',
            'Preparing': 'Hazırlanıyor',
            'Ready': 'Hazır',
            'OnTheWay': 'Yolda',
            'Delivered': 'Teslim Edildi',
            'Completed': 'Tamamlandı',
            'Cancelled': 'İptal'
        };
        return statusMap[status] || status;
    }

    // Cleanup on page unload
    $(window).on('beforeunload', function() {
        if (orderHubManager) {
            orderHubManager.disconnect();
        }
    });

})();

