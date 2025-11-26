import 'package:flutter/material.dart';

class VendorNotificationsScreen extends StatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  State<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'NewOrder',
      'title': 'Yeni Sipariş',
      'message': 'Ahmet Yılmaz adlı müşteriden yeni sipariş',
      'time': '5 dakika önce',
      'isRead': false,
    },
    {
      'type': 'OrderStatusChanged',
      'title': 'Sipariş Durumu Değişti',
      'message': 'Sipariş #1234 teslim edildi',
      'time': '1 saat önce',
      'isRead': true,
    },
    {
      'type': 'NewReview',
      'title': 'Yeni Yorum',
      'message': 'Mehmet Demir 5 yıldız verdi',
      'time': '2 saat önce',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tümü okundu olarak işaretlendi')),
              );
            },
            child: const Text(
              'Tümünü Okundu İşaretle',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bildirim yok',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'NewOrder':
        icon = Icons.shopping_bag;
        iconColor = Colors.green;
        break;
      case 'OrderStatusChanged':
        icon = Icons.update;
        iconColor = Colors.blue;
        break;
      case 'NewReview':
        icon = Icons.star;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: notification['isRead'] ? Colors.white : Colors.orange.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: notification['isRead']
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['message']),
            const SizedBox(height: 4),
            Text(
              notification['time'],
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: !notification['isRead']
            ? Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          setState(() {
            notification['isRead'] = true;
          });
          // Navigate to related screen based on type
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${notification['title']} açıldı')),
          );
        },
      ),
    );
  }
}
