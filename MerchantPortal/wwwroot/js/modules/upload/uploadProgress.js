/**
 * Upload Progress Tracker Module
 */

(function() {
    'use strict';

    class UploadProgressTracker {
        constructor(containerId) {
            this.container = document.getElementById(containerId);
            this.uploads = new Map();
        }

        startUpload(fileId, fileName, fileSize) {
            const progressHtml = `
                <div class="upload-item" id="upload-${fileId}">
                    <div class="upload-info">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <span class="file-name">
                                <i class="fas fa-file-image me-2"></i>${fileName}
                            </span>
                            <span class="file-size text-muted">${this.formatBytes(fileSize)}</span>
                        </div>
                        <div class="progress" style="height: 6px;">
                            <div class="progress-bar bg-primary" role="progressbar" 
                                 style="width: 0%" id="progress-${fileId}"></div>
                        </div>
                        <div class="upload-stats mt-1 small text-muted">
                            <span id="percent-${fileId}">0%</span>
                            <span class="mx-2">•</span>
                            <span id="speed-${fileId}">0 KB/s</span>
                            <span class="mx-2">•</span>
                            <span id="remaining-${fileId}">Hesaplanıyor...</span>
                        </div>
                    </div>
                    <button class="btn btn-sm btn-link text-danger" onclick="cancelUpload('${fileId}')">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
            `;

            if (this.container) {
                this.container.insertAdjacentHTML('beforeend', progressHtml);
            }

            this.uploads.set(fileId, {
                fileName,
                fileSize,
                startTime: Date.now(),
                loaded: 0
            });
        }

        updateProgress(fileId, loaded, total) {
            const upload = this.uploads.get(fileId);
            if (!upload) return;

            upload.loaded = loaded;
            const percent = Math.round((loaded / total) * 100);
            
            // Update progress bar
            const progressBar = document.getElementById(`progress-${fileId}`);
            if (progressBar) {
                progressBar.style.width = `${percent}%`;
            }

            // Update percentage
            const percentSpan = document.getElementById(`percent-${fileId}`);
            if (percentSpan) {
                percentSpan.textContent = `${percent}%`;
            }

            // Calculate speed
            const elapsed = (Date.now() - upload.startTime) / 1000; // seconds
            const speed = elapsed > 0 ? loaded / elapsed : 0; // bytes per second
            
            const speedSpan = document.getElementById(`speed-${fileId}`);
            if (speedSpan) {
                speedSpan.textContent = this.formatSpeed(speed);
            }

            // Calculate remaining time
            const remaining = speed > 0 ? (total - loaded) / speed : 0;
            const remainingSpan = document.getElementById(`remaining-${fileId}`);
            if (remainingSpan) {
                remainingSpan.textContent = this.formatTime(remaining);
            }
        }

        completeUpload(fileId, success = true) {
            const uploadItem = document.getElementById(`upload-${fileId}`);
            if (uploadItem) {
                if (success) {
                    uploadItem.classList.add('upload-success');
                    setTimeout(() => uploadItem.remove(), 2000);
                } else {
                    uploadItem.classList.add('upload-error');
                }
            }

            this.uploads.delete(fileId);
        }

        formatBytes(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
        }

        formatSpeed(bytesPerSecond) {
            return this.formatBytes(bytesPerSecond) + '/s';
        }

        formatTime(seconds) {
            if (seconds < 1) return 'Az kaldı';
            if (seconds < 60) return `${Math.round(seconds)}s`;
            const minutes = Math.floor(seconds / 60);
            const secs = Math.round(seconds % 60);
            return `${minutes}m ${secs}s`;
        }
    }

    // Export to global scope
    window.UploadProgressTracker = UploadProgressTracker;

})();

