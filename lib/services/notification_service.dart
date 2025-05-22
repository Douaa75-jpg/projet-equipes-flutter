import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../screens/leave/HistoriqueDemandesPage.dart';
import '../auth_controller.dart';
import '../screens/leave/gestion_demande__Screen.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxString lastNotification = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initNotifications();
  }

  Future<void> initNotifications() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTap(response.payload);
      },
    );
  }

  void _onNotificationTap(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      if (payload.contains('employee_response')) {
        Get.toNamed('/historique-demandes');
      } else if (payload.contains('rh_response')) {
        Get.toNamed('/gestion-demandes');
      }
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gestion_equipe_channel',
      'Gestion Equipe Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      colorized: true,
      color: Color(0xFF8B0000),
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
    
    final newNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'payload': payload ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
      'type': payload?.contains('employee') == true 
          ? 'employee_response' 
          : payload?.contains('rh') == true 
            ? 'rh_response' 
            : 'general',
    };
    
    notifications.add(newNotification);
    lastNotification.value = body;
  }

  Future<void> markAsRead(String notificationId) async {
    final index = notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      notifications[index]['isRead'] = true;
      notifications.refresh();
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in notifications) {
      notification['isRead'] = true;
    }
    notifications.refresh();
  }

  Future<void> addEmployeeNotification(String message, {String? demandeId}) async {
    await showNotification(
      title: 'Réponse à votre demande',
      body: message,
      payload: 'employee_response_${demandeId ?? ''}',
    );
  }

  Future<void> addRHNotification(String message, {String? demandeId}) async {
    await showNotification(
      title: 'Nouvelle demande',
      body: message,
      payload: 'rh_response_${demandeId ?? ''}',
    );
  }

  void showNotificationsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('notifications'.tr),
        content: Obx(() {
          if (notifications.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('no_notifications'.tr),
            );
          }
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Icon(
                    notification['type'] == 'employee_response' 
                      ? Icons.work 
                      : Icons.person,
                    size: 20,
                  ),
                  title: Text(
                    notification['body'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(
                      DateTime.parse(notification['createdAt'] ?? DateTime.now().toIso8601String()),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: notification['type'] == 'employee_response'
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 20),
                        onPressed: () {
                          markAsRead(notification['id'] ?? '');
                          Get.to(() => HistoriqueDemandesPage(
                            employeId: Get.find<AuthProvider>().userId.value,
                          ));
                        },
                      )
                    : null,
                  onTap: () {
                    markAsRead(notification['id'] ?? '');
                    if (notification['type'] == 'employee_response') {
                      Get.to(() => HistoriqueDemandesPage(
                        employeId: Get.find<AuthProvider>().userId.value,
                      ));
                    }
                  },
                );
              },
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () {
              markAllAsRead();
              Get.back();
            },
            child: Text('mark_all_read'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  // أضف هذه الدالة في NotificationService
List<Map<String, dynamic>> getFilteredNotifications(String userId) {
  return notifications.where((n) {
    // تأكد من أن الإشعار خاص بهذا المستخدم
    return n['userId'] == userId || 
           n['type'] == 'general' || 
           (n['type'] == 'employee_response' && n['targetUserId'] == userId);
  }).toList();
}

  void setupListeners() {
    ever(lastNotification, (message) {
      if (message.isNotEmpty) {
        Get.snackbar(
          'Notification',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }


  // أضف هذه الدوال الجديدة في NotificationService
Future<void> showEmployeeNotificationsDialog() async {
  Get.dialog(
    AlertDialog(
      title: Text('notifications'.tr),
      content: Obx(() {
        final employeeNotifications = notifications
            .where((n) => n['type'] == 'employee_response')
            .toList();
            
        if (employeeNotifications.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('no_notifications'.tr),
          );
        }
        
        return _buildNotificationsList(employeeNotifications);
      }),
      actions: _buildDialogActions(),
    ),
  );
}

Future<void> showRHNotificationsDialog() async {
  Get.dialog(
    AlertDialog(
      title: Text('notifications'.tr),
      content: Obx(() {
        final rhNotifications = notifications
            .where((n) => n['type'] == 'rh_response')
            .toList();
            
        if (rhNotifications.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('no_notifications'.tr),
          );
        }
        
        return _buildNotificationsList(rhNotifications);
      }),
      actions: _buildDialogActions(),
    ),
  );
}

Widget _buildNotificationsList(List<Map<String, dynamic>> notificationsList) {
  return SizedBox(
    width: double.maxFinite,
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: notificationsList.length,
      itemBuilder: (context, index) {
        final notification = notificationsList[index];
        return ListTile(
          leading: Icon(
            notification['type'] == 'employee_response' 
              ? Icons.work 
              : Icons.person,
            size: 20,
          ),
          title: Text(
            notification['body'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            DateFormat('dd/MM/yyyy HH:mm').format(
              DateTime.parse(notification['createdAt'] ?? DateTime.now().toIso8601String()),
            ),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: notification['type'] == 'employee_response'
            ? IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20),
                onPressed: () {
                  markAsRead(notification['id'] ?? '');
                  Get.to(() => HistoriqueDemandesPage(
                    employeId: Get.find<AuthProvider>().userId.value,
                  ));
                },
              )
            : null,
          onTap: () {
            markAsRead(notification['id'] ?? '');
            if (notification['type'] == 'employee_response') {
              Get.to(() => HistoriqueDemandesPage(
                employeId: Get.find<AuthProvider>().userId.value,
              ));
            } else if (notification['type'] == 'rh_response') {
              Get.to(() => GestionDemandeScreen());
            }
          },
        );
      },
    ),
  );
}

List<Widget> _buildDialogActions() {
  return [
    TextButton(
      onPressed: () {
        markAllAsRead();
        Get.back();
      },
      child: Text('mark_all_read'.tr),
    ),
    TextButton(
      onPressed: () => Get.back(),
      child: Text('close'.tr),
    ),
  ];
}
}