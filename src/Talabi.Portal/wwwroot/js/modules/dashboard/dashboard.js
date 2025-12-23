document.addEventListener('DOMContentLoaded', function () {
    initDashboard();
});

function initDashboard() {
    const data = window.dashboardData;
    if (!data) return;

    initSalesChart(data.salesTrend);
    initOrdersChart(data.orderStatus);
    initCategoryChart(data.categoryRevenue);
}

function initSalesChart(trendData) {
    const ctx = document.getElementById('salesChart');
    if (!ctx) return;

    if (!trendData || trendData.length === 0) return;

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: trendData.map(d => d.date),
            datasets: [{
                label: 'Satış (TL)',
                data: trendData.map(d => d.amount),
                borderColor: '#4e73df',
                backgroundColor: 'rgba(78, 115, 223, 0.05)',
                pointRadius: 3,
                pointBackgroundColor: '#4e73df',
                pointBorderColor: '#4e73df',
                pointHoverRadius: 3,
                pointHoverBackgroundColor: '#4e73df',
                pointHoverBorderColor: '#4e73df',
                pointHitRadius: 10,
                pointBorderWidth: 2,
                tension: 0.3,
                fill: true
            }]
        },
        options: {
            maintainAspectRatio: false,
            layout: {
                padding: {
                    left: 10,
                    right: 25,
                    top: 25,
                    bottom: 0
                }
            },
            scales: {
                x: {
                    grid: {
                        display: false,
                        drawBorder: false
                    },
                    ticks: {
                        maxTicksLimit: 7
                    }
                },
                y: {
                    ticks: {
                        maxTicksLimit: 5,
                        padding: 10,
                        callback: function (value) {
                            return '₺' + value;
                        }
                    },
                    grid: {
                        color: "rgb(234, 236, 244)",
                        zeroLineColor: "rgb(234, 236, 244)",
                        drawBorder: false,
                        borderDash: [2],
                        zeroLineBorderDash: [2]
                    }
                }
            },
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });
}

function initOrdersChart(statusData) {
    const ctx = document.getElementById('ordersChart');
    if (!ctx) return;

    if (!statusData || statusData.length === 0) return;

    // Fixed colors for specific statuses
    const colorMap = {
        'Pending': '#f6c23e',
        'Preparing': '#36b9cc',
        'Ready': '#4e73df',
        'Delivered': '#1cc88a',
        'Cancelled': '#e74a3b'
    };

    const colors = statusData.map(item => colorMap[item.status] || '#858796');

    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: statusData.map(d => d.status),
            datasets: [{
                data: statusData.map(d => d.count),
                backgroundColor: colors,
                hoverBackgroundColor: colors,
                hoverBorderColor: "rgba(234, 236, 244, 1)",
            }],
        },
        options: {
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: true,
                    position: 'bottom',
                    labels: {
                        usePointStyle: true,
                        boxWidth: 6
                    }
                }
            },
            cutout: '70%',
        },
    });
}

function initCategoryChart(categoryData) {
    const ctx = document.getElementById('categoryChart');
    if (!ctx) return;

    if (!categoryData || categoryData.length === 0) return;

    const backgroundColors = [
        '#4e73df', '#1cc88a', '#36b9cc', '#f6c23e', '#e74a3b', '#858796'
    ];

    new Chart(ctx, {
        type: 'pie',
        data: {
            labels: categoryData.map(d => d.categoryName),
            datasets: [{
                data: categoryData.map(d => d.revenue),
                backgroundColor: backgroundColors.slice(0, categoryData.length),
                hoverBackgroundColor: backgroundColors.slice(0, categoryData.length),
                hoverBorderColor: "rgba(234, 236, 244, 1)",
            }],
        },
        options: {
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: true,
                    position: 'right',
                    labels: {
                        usePointStyle: true,
                        boxWidth: 6
                    }
                },
                tooltip: {
                    callbacks: {
                        label: function (context) {
                            let label = context.label || '';
                            if (label) {
                                label += ': ';
                            }
                            if (context.parsed !== null) {
                                label += '₺' + context.parsed.toFixed(2);
                            }
                            return label;
                        }
                    }
                }
            },
        },
    });
}
