/**
 * Multiple Files Upload Manager
 */

(function() {
    'use strict';

    class MultipleFilesManager {
        constructor(previewContainerId, options = {}) {
            this.previewContainer = document.getElementById(previewContainerId);
            this.options = {
                maxFiles: options.maxFiles || 5,
                onFilesChanged: options.onFilesChanged || function() {},
                onMainImageChanged: options.onMainImageChanged || function() {}
            };
            
            this.files = [];
            this.mainImageIndex = 0;
        }

        addFiles(files) {
            const remainingSlots = this.options.maxFiles - this.files.length;
            const filesToAdd = files.slice(0, remainingSlots);
            
            filesToAdd.forEach(file => {
                this.files.push({
                    file,
                    preview: null,
                    id: this.generateId()
                });
            });

            this.renderPreviews();
            this.options.onFilesChanged(this.files);
        }

        async renderPreviews() {
            if (!this.previewContainer) return;

            this.previewContainer.innerHTML = '';

            for (let i = 0; i < this.files.length; i++) {
                const fileData = this.files[i];
                
                if (!fileData.preview) {
                    fileData.preview = await this.createPreview(fileData.file);
                }

                const isMain = i === this.mainImageIndex;
                const previewHtml = `
                    <div class="image-preview-item ${isMain ? 'main-image' : ''}" data-index="${i}">
                        <img src="${fileData.preview}" alt="Preview ${i + 1}">
                        ${isMain ? '<div class="main-badge"><i class="fas fa-star"></i> Ana</div>' : ''}
                        <div class="preview-actions">
                            ${!isMain ? `<button class="btn btn-sm btn-light" onclick="setMainImage(${i})" title="Ana resim yap">
                                <i class="fas fa-star"></i>
                            </button>` : ''}
                            <button class="btn btn-sm btn-danger" onclick="removeImage(${i})" title="Sil">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                        <div class="preview-order">${i + 1}</div>
                    </div>
                `;
                
                this.previewContainer.insertAdjacentHTML('beforeend', previewHtml);
            }

            // Enable drag to reorder
            this.enableDragReorder();
        }

        createPreview(file) {
            return new Promise((resolve) => {
                const reader = new FileReader();
                reader.onload = (e) => resolve(e.target.result);
                reader.readAsDataURL(file);
            });
        }

        removeImage(index) {
            this.files.splice(index, 1);
            if (this.mainImageIndex === index) {
                this.mainImageIndex = 0;
            } else if (this.mainImageIndex > index) {
                this.mainImageIndex--;
            }
            this.renderPreviews();
            this.options.onFilesChanged(this.files);
        }

        setMainImage(index) {
            this.mainImageIndex = index;
            this.renderPreviews();
            this.options.onMainImageChanged(index);
        }

        enableDragReorder() {
            // Simplified - full drag reorder can be added with Sortable.js
            const items = this.previewContainer.querySelectorAll('.image-preview-item');
            items.forEach((item, index) => {
                item.draggable = true;
                item.addEventListener('dragstart', (e) => {
                    e.dataTransfer.effectAllowed = 'move';
                    e.dataTransfer.setData('text/html', index);
                });
            });
        }

        generateId() {
            return `file-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        }

        getFiles() {
            return this.files.map(f => f.file);
        }

        getMainImage() {
            return this.files[this.mainImageIndex]?.file || null;
        }
    }

    // Global functions
    window.removeImage = function(index) {
        if (window.fileManager) {
            window.fileManager.removeImage(index);
        }
    };

    window.setMainImage = function(index) {
        if (window.fileManager) {
            window.fileManager.setMainImage(index);
        }
    };

    // Export to global scope
    window.MultipleFilesManager = MultipleFilesManager;

})();

