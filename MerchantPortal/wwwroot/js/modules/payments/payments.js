/**
 * Payment History Module
 * Handles DataTables, filtering, and export functionality
 */

(function() {
    'use strict';

    let paymentsTable;

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        initializeDataTable();
        loadStats();
        setupFilters();
    });

    /**
     * Initialize DataTables
     */
    function initializeDataTable() {
        paymentsTable = $('#paymentsTable').DataTable({
            processing: true,
            serverSide: false,
            ajax: {
                url: '/Payments/GetPaymentHistoryData',
                type: 'POST',
                contentType: 'application/json',
                data: function(d) {
                    return JSON.stringify(getCurrentFilters());
                },
                dataSrc: 'data'
            },
            columns: [
                { 
                    data: 'orderNumber',
                    render: function(data) {
                        return `<span class="fw-bold text-primary">${data}</span>`;
                    }
                },
                { 
                    data: 'customerName',
                    render: function(data) {
                        return data || '<span class="text-muted">-</span>';
                    }
                },
                { 
                    data: 'paymentMethod',
                    render: function(data) {
                        const badge = getPaymentMethodBadge(data);
                        return badge;
                    }
                },
                { 
                    data: 'amount',
                    render: function(data) {
                        return `₺${parseFloat(data).toFixed(2)}`;
                    },
                    className: 'text-end fw-bold'
                },
                { 
                    data: 'status',
                    render: function(data) {
                        const badge = getStatusBadge(data);
                        return badge;
                    }
                },
                { 
                    data: 'createdAt',
                    render: function(data) {
                        return new Date(data).toLocaleDateString('tr-TR', {
                            day: '2-digit',
                            month: 'short',
                            year: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit'
                        });
                    }
                },
                { 
                    data: 'completedAt',
                    render: function(data) {
                        if (!data) return '<span class="text-muted">-</span>';
                        return new Date(data).toLocaleDateString('tr-TR', {
                            day: '2-digit',
                            month: 'short',
                            hour: '2-digit',
                            minute: '2-digit'
                        });
                    }
                },
                { 
                    data: 'id',
                    render: function(data, type, row) {
                        return `
                            <button class="btn btn-sm btn-outline-primary" onclick="viewPaymentDetails('${data}')">
                                <i class="fas fa-eye"></i>
                            </button>
                        `;
                    },
                    orderable: false,
                    className: 'text-center'
                }
            ],
            order: [[5, 'desc']], // Sort by created date descending
            pageLength: 25,
            language: {
                url: '//cdn.datatables.net/plug-ins/1.13.7/i18n/tr.json'
            },
            dom: "<'row'<'col-sm-12 col-md-6'l><'col-sm-12 col-md-6'f>>" +
                 "<'row'<'col-sm-12'tr>>" +
                 "<'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>"
        });
    }

    /**
     * Setup filter event listeners
     */
    function setupFilters() {
        // Auto-reload on filter change
        $('#startDate, #endDate, #paymentMethod, #status').on('change', function() {
            // Don't auto-reload, wait for button click
        });
    }

    /**
     * Apply filters and reload table
     */
    window.applyFilters = function() {
        paymentsTable.ajax.reload();
        loadStats();
    };

    /**
     * Get current filter values
     */
    function getCurrentFilters() {
        return {
            startDate: $('#startDate').val() || null,
            endDate: $('#endDate').val() || null,
            paymentMethod: $('#paymentMethod').val() || null,
            paymentStatus: $('#status').val() || null,
            minAmount: null,
            maxAmount: null,
            orderNumber: null
        };
    }

    /**
     * Load payment stats
     */
    async function loadStats() {
        try {
            const filters = getCurrentFilters();
            const response = await fetch('/Payments/GetPaymentHistoryData', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(filters)
            });

            const result = await response.json();
            if (!result.success) return;

            const payments = result.data;

            // Calculate stats
            const completed = payments.filter(p => p.status === 'Completed');
            const pending = payments.filter(p => p.status === 'Pending');
            const totalRevenue = completed.reduce((sum, p) => sum + p.amount, 0);
            const avgAmount = completed.length > 0 ? totalRevenue / completed.length : 0;

            // Update UI
            document.getElementById('completedCount').textContent = completed.length;
            document.getElementById('pendingCount').textContent = pending.length;
            document.getElementById('totalRevenue').textContent = `₺${totalRevenue.toFixed(2)}`;
            document.getElementById('avgAmount').textContent = `₺${avgAmount.toFixed(2)}`;

        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    /**
     * Export to Excel
     */
    window.exportToExcel = async function() {
        try {
            const filters = getCurrentFilters();
            const response = await fetch('/Payments/ExportToExcel', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    startDate: filters.startDate,
                    endDate: filters.endDate,
                    paymentMethod: filters.paymentMethod,
                    status: filters.paymentStatus,
                    format: 'excel'
                })
            });

            if (!response.ok) {
                alert('Excel indirme hatası!');
                return;
            }

            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `Payments_${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);

        } catch (error) {
            console.error('Error exporting to Excel:', error);
            alert('Excel indirme hatası!');
        }
    };

    /**
     * Export to PDF
     */
    window.exportToPdf = async function() {
        try {
            const filters = getCurrentFilters();
            const response = await fetch('/Payments/ExportToPdf', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    startDate: filters.startDate,
                    endDate: filters.endDate,
                    paymentMethod: filters.paymentMethod,
                    status: filters.paymentStatus,
                    format: 'pdf'
                })
            });

            if (!response.ok) {
                alert('PDF indirme hatası!');
                return;
            }

            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `Payments_${new Date().toISOString().split('T')[0]}.pdf`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);

        } catch (error) {
            console.error('Error exporting to PDF:', error);
            alert('PDF indirme hatası!');
        }
    };

    /**
     * View payment details
     */
    window.viewPaymentDetails = function(paymentId) {
        // TODO: Open modal with payment details
        console.log('View payment:', paymentId);
        alert(`Payment ID: ${paymentId}\nDetay görüntüleme özelliği yakında eklenecek!`);
    };

    /**
     * Get payment method badge
     */
    function getPaymentMethodBadge(method) {
        const badges = {
            'Cash': '<span class="badge bg-success"><i class="fas fa-money-bill me-1"></i>Nakit</span>',
            'CreditCard': '<span class="badge bg-primary"><i class="fas fa-credit-card me-1"></i>Kredi Kartı</span>',
            'VodafonePay': '<span class="badge" style="background-color: #e60000;"><i class="fas fa-mobile me-1"></i>Vodafone Pay</span>',
            'BankTransfer': '<span class="badge bg-secondary"><i class="fas fa-university me-1"></i>Havale/EFT</span>',
            'BkmExpress': '<span class="badge bg-warning text-dark"><i class="fas fa-qrcode me-1"></i>BKM Express</span>',
            'Papara': '<span class="badge" style="background-color: #9c27b0;"><i class="fas fa-wallet me-1"></i>Papara</span>',
            'QrCode': '<span class="badge bg-info"><i class="fas fa-qrcode me-1"></i>QR Code</span>'
        };
        return badges[method] || `<span class="badge bg-secondary">${method}</span>`;
    }

    /**
     * Get status badge
     */
    function getStatusBadge(status) {
        const badges = {
            'Completed': '<span class="badge bg-success"><i class="fas fa-check-circle me-1"></i>Tamamlandı</span>',
            'Pending': '<span class="badge bg-warning"><i class="fas fa-clock me-1"></i>Bekliyor</span>',
            'Processing': '<span class="badge bg-info"><i class="fas fa-spinner me-1"></i>İşleniyor</span>',
            'Failed': '<span class="badge bg-danger"><i class="fas fa-times-circle me-1"></i>Başarısız</span>',
            'Cancelled': '<span class="badge bg-secondary"><i class="fas fa-ban me-1"></i>İptal</span>',
            'Refunded': '<span class="badge bg-dark"><i class="fas fa-undo me-1"></i>İade</span>'
        };
        return badges[status] || `<span class="badge bg-secondary">${status}</span>`;
    }

})();

