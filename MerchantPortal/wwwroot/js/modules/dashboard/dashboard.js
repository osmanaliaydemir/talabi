/**
 * Dashboard Page Module
 * Handles SignalR real-time updates and dashboard interactions
 */

(function() {
    'use strict';

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        initDashboard();
    });

    /**
     * Initialize dashboard functionality
     */
    function initDashboard() {
        updateLastUpdateTime();
        setupSignalRHandlers();
        initializeCharts();
        setupChartPeriodButtons();
    }

    /**
     * Update last update time every second
     */
    function updateLastUpdateTime() {
        const lastUpdateElement = document.getElementById('lastUpdate');
        if (!lastUpdateElement) return;

        function update() {
            const now = new Date();
            lastUpdateElement.textContent = now.toLocaleTimeString('tr-TR', { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        }

        // Initial update
        update();
        
        // Update every second
        setInterval(update, 1000);
    }

    /**
     * Setup SignalR event handlers
     */
    function setupSignalRHandlers() {
        if (!window.signalRConnection) {
            console.warn('SignalR connection not available');
            return;
        }

        // Listen for new orders
        window.signalRConnection.on("NewOrderReceived", function (data) {
            console.log('New order received:', data);
            
            // Show notification
            if (typeof showToast === 'function') {
                showToast(
                    `#${data.orderNumber} - ${data.customerName} - ₺${data.totalAmount.toFixed(2)}`,
                    'success',
                    5000
                );
            }
            
            // Play sound
            if (typeof playNotificationSound === 'function') {
                playNotificationSound();
            }
            
            // Flash browser tab
            if (typeof flashBrowserTab === 'function') {
                flashBrowserTab();
            }
            
            // Refresh dashboard after 2 seconds
            setTimeout(() => {
                window.location.reload();
            }, 2000);
        });
        
        // Listen for order status changes
        window.signalRConnection.on("OrderStatusChanged", function (data) {
            console.log('Order status changed:', data);
            
            if (typeof showToast === 'function') {
                showToast(
                    `#${data.orderNumber} - ${data.status}`,
                    'info',
                    5000
                );
            }
        });
    }

    /**
     * Initialize all charts
     */
    function initializeCharts() {
        initSalesChart(30);
        initOrdersChart();
        initCategoryChart();
    }

    /**
     * Setup period buttons for sales chart
     */
    function setupChartPeriodButtons() {
        const periodButtons = document.querySelectorAll('[data-period]');
        periodButtons.forEach(button => {
            button.addEventListener('click', function() {
                // Remove active class from all buttons
                periodButtons.forEach(btn => btn.classList.remove('active'));
                // Add active class to clicked button
                this.classList.add('active');
                
                // Reload sales chart with new period
                const days = parseInt(this.getAttribute('data-period'));
                initSalesChart(days);
            });
        });
    }

    /**
     * Initialize Sales Line Chart
     */
    let salesChartInstance = null;
    async function initSalesChart(days = 30) {
        const ctx = document.getElementById('salesChart');
        if (!ctx) return;

        try {
            const response = await fetch(`/Dashboard/GetSalesChartData?days=${days}`);
            const result = await response.json();

            if (!result.success) {
                console.error('Failed to load sales chart data');
                return;
            }

            // Destroy previous instance
            if (salesChartInstance) {
                salesChartInstance.destroy();
            }

            // Create new chart
            salesChartInstance = new Chart(ctx, {
                type: 'line',
                data: result.data,
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    interaction: {
                        mode: 'index',
                        intersect: false,
                    },
                    plugins: {
                        legend: {
                            display: true,
                            position: 'top',
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    let label = context.dataset.label || '';
                                    if (label) {
                                        label += ': ';
                                    }
                                    if (context.parsed.y !== null) {
                                        if (context.dataset.label === 'Ciro (₺)') {
                                            label += '₺' + context.parsed.y.toFixed(2);
                                        } else {
                                            label += context.parsed.y;
                                        }
                                    }
                                    return label;
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            type: 'linear',
                            display: true,
                            position: 'left',
                            title: {
                                display: true,
                                text: 'Ciro (₺)'
                            },
                            ticks: {
                                callback: function(value) {
                                    return '₺' + value.toFixed(0);
                                }
                            }
                        },
                        y1: {
                            type: 'linear',
                            display: true,
                            position: 'right',
                            title: {
                                display: true,
                                text: 'Sipariş Sayısı'
                            },
                            grid: {
                                drawOnChartArea: false,
                            },
                        }
                    }
                }
            });
        } catch (error) {
            console.error('Error initializing sales chart:', error);
        }
    }

    /**
     * Initialize Orders Bar Chart
     */
    async function initOrdersChart() {
        const ctx = document.getElementById('ordersChart');
        if (!ctx) return;

        try {
            const response = await fetch('/Dashboard/GetOrdersChartData');
            const result = await response.json();

            if (!result.success) {
                console.error('Failed to load orders chart data');
                return;
            }

            new Chart(ctx, {
                type: 'bar',
                data: result.data,
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    return context.parsed.y + ' sipariş';
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                stepSize: 1
                            }
                        }
                    }
                }
            });
        } catch (error) {
            console.error('Error initializing orders chart:', error);
        }
    }

    /**
     * Initialize Category Pie Chart
     */
    async function initCategoryChart() {
        const ctx = document.getElementById('categoryChart');
        if (!ctx) return;

        try {
            const response = await fetch('/Dashboard/GetCategoryChartData');
            const result = await response.json();

            if (!result.success) {
                console.error('Failed to load category chart data');
                return;
            }

            new Chart(ctx, {
                type: 'doughnut',
                data: result.data,
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    plugins: {
                        legend: {
                            display: true,
                            position: 'right',
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    const label = context.label || '';
                                    const value = context.parsed || 0;
                                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                    const percentage = ((value / total) * 100).toFixed(1);
                                    return `${label}: ₺${value.toFixed(2)} (${percentage}%)`;
                                }
                            }
                        }
                    }
                }
            });
        } catch (error) {
            console.error('Error initializing category chart:', error);
        }
    }

})();

