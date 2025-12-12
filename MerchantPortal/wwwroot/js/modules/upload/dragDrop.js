/**
 * Drag & Drop File Upload Module
 */

(function() {
    'use strict';

    class DragDropUploader {
        constructor(dropZoneId, options = {}) {
            this.dropZone = document.getElementById(dropZoneId);
            this.options = {
                maxFiles: options.maxFiles || 5,
                maxFileSize: options.maxFileSize || 5 * 1024 * 1024, // 5MB
                acceptedTypes: options.acceptedTypes || ['image/jpeg', 'image/png', 'image/webp'],
                onFilesAdded: options.onFilesAdded || function() {},
                onError: options.onError || function() {}
            };
            
            this.files = [];
            this.init();
        }

        init() {
            if (!this.dropZone) return;

            // Prevent default drag behaviors
            ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
                this.dropZone.addEventListener(eventName, preventDefaults, false);
                document.body.addEventListener(eventName, preventDefaults, false);
            });

            // Highlight drop zone when item is dragged over
            ['dragenter', 'dragover'].forEach(eventName => {
                this.dropZone.addEventListener(eventName, () => this.highlight(), false);
            });

            ['dragleave', 'drop'].forEach(eventName => {
                this.dropZone.addEventListener(eventName, () => this.unhighlight(), false);
            });

            // Handle dropped files
            this.dropZone.addEventListener('drop', (e) => this.handleDrop(e), false);

            // Handle click to browse
            this.dropZone.addEventListener('click', () => this.openFileBrowser());
        }

        highlight() {
            this.dropZone.classList.add('drag-over');
        }

        unhighlight() {
            this.dropZone.classList.remove('drag-over');
        }

        handleDrop(e) {
            const dt = e.dataTransfer;
            const files = [...dt.files];
            this.handleFiles(files);
        }

        openFileBrowser() {
            const input = document.createElement('input');
            input.type = 'file';
            input.multiple = this.options.maxFiles > 1;
            input.accept = this.options.acceptedTypes.join(',');
            input.onchange = (e) => {
                const files = [...e.target.files];
                this.handleFiles(files);
            };
            input.click();
        }

        handleFiles(files) {
            // Validate file count
            if (this.files.length + files.length > this.options.maxFiles) {
                this.options.onError(`En fazla ${this.options.maxFiles} dosya yükleyebilirsiniz`);
                return;
            }

            // Validate each file
            const validFiles = [];
            for (const file of files) {
                if (!this.validateFile(file)) {
                    continue;
                }
                validFiles.push(file);
            }

            if (validFiles.length > 0) {
                this.files = [...this.files, ...validFiles];
                this.options.onFilesAdded(validFiles);
            }
        }

        validateFile(file) {
            // Check file type
            if (!this.options.acceptedTypes.includes(file.type)) {
                this.options.onError(`Geçersiz dosya tipi: ${file.name}`);
                return false;
            }

            // Check file size
            if (file.size > this.options.maxFileSize) {
                const sizeMB = (this.options.maxFileSize / (1024 * 1024)).toFixed(1);
                this.options.onError(`Dosya çok büyük: ${file.name} (Max: ${sizeMB}MB)`);
                return false;
            }

            return true;
        }

        removeFile(index) {
            this.files.splice(index, 1);
        }

        clearFiles() {
            this.files = [];
        }

        getFiles() {
            return this.files;
        }
    }

    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    // Export to global scope
    window.DragDropUploader = DragDropUploader;

})();

