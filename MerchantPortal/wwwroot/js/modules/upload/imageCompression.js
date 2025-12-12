/**
 * Image Compression Module using Canvas API
 */

(function() {
    'use strict';

    class ImageCompressor {
        constructor(options = {}) {
            this.options = {
                maxWidth: options.maxWidth || 1920,
                maxHeight: options.maxHeight || 1080,
                quality: options.quality || 0.85,
                outputFormat: options.outputFormat || 'image/jpeg'
            };
        }

        async compressImage(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                
                reader.onload = (e) => {
                    const img = new Image();
                    
                    img.onload = () => {
                        const compressed = this.compress(img);
                        resolve(compressed);
                    };
                    
                    img.onerror = () => reject(new Error('Image load failed'));
                    img.src = e.target.result;
                };
                
                reader.onerror = () => reject(new Error('File read failed'));
                reader.readAsDataURL(file);
            });
        }

        compress(img) {
            const canvas = document.createElement('canvas');
            let { width, height } = img;

            // Calculate new dimensions
            if (width > this.options.maxWidth || height > this.options.maxHeight) {
                const ratio = Math.min(
                    this.options.maxWidth / width,
                    this.options.maxHeight / height
                );
                width = Math.floor(width * ratio);
                height = Math.floor(height * ratio);
            }

            canvas.width = width;
            canvas.height = height;

            const ctx = canvas.getContext('2d');
            ctx.drawImage(img, 0, 0, width, height);

            // Convert to blob
            return new Promise((resolve) => {
                canvas.toBlob(
                    (blob) => resolve(blob),
                    this.options.outputFormat,
                    this.options.quality
                );
            });
        }

        async compressBatch(files) {
            const promises = files.map(file => this.compressImage(file));
            return Promise.all(promises);
        }
    }

    // Export to global scope
    window.ImageCompressor = ImageCompressor;

})();

