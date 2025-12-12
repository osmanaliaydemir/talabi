class CSVImporter {
	constructor(basePath){
		this.basePath = basePath;
	}

	openImportModal(){
		const modal = new bootstrap.Modal(document.getElementById('csvImportModal'));
		modal.show();
	}

	downloadTemplate(){
		window.location.href = `${this.basePath}/ExportToCSV`;
	}

	async importData(){
		const input = document.getElementById('csvFileInput');
		if(!input || !input.files || input.files.length === 0){
			alert('CSV dosyası seçiniz');
			return;
		}
		const form = new FormData();
		form.append('file', input.files[0]);
		try{
			const res = await fetch(`${this.basePath}/ImportFromCSV`, { method:'POST', body: form });
			const data = await res.json();
			const result = document.getElementById('importResult');
			if(!result) return;
			result.style.display = '';
			result.className = 'alert ' + (data.success ? 'alert-success' : 'alert-danger');
			result.textContent = data.message || 'Bitti';
		} catch(err){
			console.error('Import error', err);
			alert('Import sırasında hata oluştu');
		}
	}
}

window.CSVImporter = CSVImporter;

/**
 * CSV Stock Import/Export Module
 */

(function() {
    'use strict';

    /**
     * Export stocks to CSV
     */
    window.exportStockToCSV = async function() {
        try {
            const response = await fetch('/Stock/ExportToCSV');
            if (!response.ok) {
                alert('CSV export hatası!');
                return;
            }

            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `Stock_Export_${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);

        } catch (error) {
            console.error('Export error:', error);
            alert('CSV export hatası!');
        }
    };

    /**
     * Import stocks from CSV
     */
    window.importStockFromCSV = async function(fileInput) {
        const file = fileInput.files[0];
        if (!file) return;

        const formData = new FormData();
        formData.append('file', file);

        try {
            const response = await fetch('/Stock/ImportFromCSV', {
                method: 'POST',
                body: formData
            });

            const result = await response.json();

            if (result.success) {
                alert(`✅ Import başarılı!\n\nToplam: ${result.totalRows}\nBaşarılı: ${result.successCount}\nHatalı: ${result.errorCount}`);
                
                if (result.errors && result.errors.length > 0) {
                    console.warn('Import errors:', result.errors);
                }

                // Refresh page
                window.location.reload();
            } else {
                alert('❌ Import hatası: ' + (result.message || 'Bilinmeyen hata'));
            }

        } catch (error) {
            console.error('Import error:', error);
            alert('CSV import hatası!');
        }
    };

    /**
     * Download CSV template
     */
    window.downloadCSVTemplate = function() {
        const csv = `ProductName,SKU,CurrentStock,MinStock,MaxStock
Elma,ELM-001,100,10,200
Armut,ARM-002,50,5,100
Süt,SUT-003,75,20,150`;

        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'Stock_Template.csv';
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
    };

})();

