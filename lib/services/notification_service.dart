import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:get_storage/get_storage.dart';
import '../screens/leave/gestion_demande__Screen.dart';

class NotificationService extends GetxService {
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxString lastNotification = ''.obs;
  final _storageKey = 'local_notifications';
  final GetStorage _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadFromLocalStorage();
  }

  void setupListeners() {
    debugPrint('Notification listeners initialized');
  }

  void _loadFromLocalStorage() {
    try {
      final saved = _storage.read<List>(_storageKey);
      if (saved != null) {
        notifications.assignAll(saved.cast<Map<String, dynamic>>());
        unreadCount.value = notifications.where((n) => !n['read']).length;
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  void _saveToLocalStorage() {
    try {
      _storage.write(_storageKey, notifications.toList());
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  void addEmployeeNotification(String message, {String? demandeId}) {
    final newNotif = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': message,
      'type': 'employee_response',
      'demandeId': demandeId,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };
    _addNotification(newNotif, Colors.green);
  }

  void addRHNotification(String message, {String? demandeId, Function()? onTap}) {
    final newNotif = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': message,
      'type': 'new_request',
      'demandeId': demandeId,
      'onTap': onTap,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };
    _addNotification(newNotif, Colors.blue);
  }

  void _addNotification(Map<String, dynamic> notification, Color bgColor) {
    notifications.insert(0, notification);
    unreadCount.value++;
    lastNotification.value = notification['message'];
    _vibrate();
    _showSnackbar(notification, bgColor);
    _saveToLocalStorage();
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  void _showSnackbar(Map<String, dynamic> notification, Color bgColor) {
    Get.snackbar(
      notification['type'] == 'new_request' ? 'Nouvelle demande' : 'Notification',
      notification['message'],
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: bgColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      onTap: (_) {
        if (notification['onTap'] != null) {
          notification['onTap']();
        } else if (notification['type'] == 'new_request') {
          navigateToDemandeScreen(notification['id']);
        }
      },
    );
  }

  void navigateToDemandeScreen(String demandeId) {
  final controller = Get.find<GestionDemandeController>(tag: 'demande');
  Get.to(() => GestionDemandeScreen());
}

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1 && !notifications[index]['read']) {
      notifications[index]['read'] = true;
      unreadCount.value--;
      _saveToLocalStorage();
    }
  }

  void markAllAsRead() {
    for (var notif in notifications) {
      if (!notif['read']) {
        notif['read'] = true;
      }
    }
    unreadCount.value = 0;
    _saveToLocalStorage();
  }

  void clearAll() {
    notifications.clear();
    unreadCount.value = 0;
    lastNotification.value = '';
    _saveToLocalStorage();
  }

  @override
  void onClose() {
    _saveToLocalStorage();
    super.onClose();
  }
}