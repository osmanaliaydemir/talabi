import 'package:flutter/material.dart';

 class CustomConfirmationDialog extends StatelessWidget {
   final String title;
   final String message;
   final String confirmText;
   final String cancelText;
   final VoidCallback onConfirm;
   final VoidCallback? onCancel;
   final IconData? icon;
   final Color? iconColor;
   final Color? confirmButtonColor;
   final Color? confirmTextColor;
   final Widget? content;
   final bool isConfirmEnabled;
 
   const CustomConfirmationDialog({
     super.key,
     required this.title,
     required this.message,
     required this.confirmText,
     required this.cancelText,
     required this.onConfirm,
     this.onCancel,
     this.icon,
     this.iconColor,
     this.confirmButtonColor,
     this.confirmTextColor,
     this.content,
     this.isConfirmEnabled = true,
   });
 
   @override
   Widget build(BuildContext context) {
     return Dialog(
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(20),
       ),
       elevation: 0,
       backgroundColor: Colors.transparent,
       child: Container(
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(20),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.1),
               blurRadius: 10,
               offset: const Offset(0, 4),
             ),
           ],
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: (iconColor ?? Colors.red).withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(
                 icon ?? Icons.warning_amber_rounded,
                 color: iconColor ?? Colors.red,
                 size: 32,
               ),
             ),
             const SizedBox(height: 16),
             Text(
               title,
               style: const TextStyle(
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
                 color: Colors.black87,
               ),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 8),
             Text(
               message,
               style: TextStyle(
                 fontSize: 14,
                 color: Colors.grey[600],
               ),
               textAlign: TextAlign.center,
             ),
             if (content != null) ...[
               const SizedBox(height: 16),
               content!,
             ],
             const SizedBox(height: 24),
             Row(
               children: [
                 Expanded(
                   child: TextButton(
                     onPressed: () {
                       if (onCancel != null) {
                         onCancel!();
                       } else {
                         Navigator.of(context).pop();
                       }
                     },
                     style: TextButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                         side: BorderSide(color: Colors.grey[300]!),
                       ),
                     ),
                     child: Text(
                       cancelText,
                       style: TextStyle(
                         color: Colors.grey[700],
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: isConfirmEnabled ? onConfirm : null,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: confirmButtonColor ?? Colors.red,
                       disabledBackgroundColor: Colors.grey[300],
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       elevation: 0,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                     child: Text(
                       confirmText,
                       style: TextStyle(
                         color: isConfirmEnabled
                             ? (confirmTextColor ?? Colors.white)
                             : Colors.grey[500],
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           ],
         ),
       ),
     );
   }
 }
