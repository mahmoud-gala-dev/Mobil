import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// خدمة الأصوات للتطبيق
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundsEnabled = true;

  /// تشغيل صوت عند إضافة منتج للسلة
  Future<void> playAddToCartSound() async {
    if (!_soundsEnabled) return;
    
    try {
      // استخدام صوت النظام كبديل
      await SystemSound.play(SystemSoundType.click);
      print('🔊 [SoundService] تم تشغيل صوت الإضافة للسلة');
    } catch (e) {
      print('⚠️ [SoundService] خطأ في تشغيل الصوت: $e');
    }
  }

  /// تشغيل صوت عند إضافة منتج للمفضلة
  Future<void> playAddToFavoriteSound() async {
    if (!_soundsEnabled) return;
    
    try {
      // استخدام صوت النظام كبديل
      await SystemSound.play(SystemSoundType.click);
      print('🔊 [SoundService] تم تشغيل صوت الإضافة للمفضلة');
    } catch (e) {
      print('⚠️ [SoundService] خطأ في تشغيل الصوت: $e');
    }
  }

  /// تفعيل/تعطيل الأصوات
  void toggleSounds(bool enabled) {
    _soundsEnabled = enabled;
    print('🔊 [SoundService] الأصوات: ${enabled ? "مفعلة" : "معطلة"}');
  }

  /// التخلص من الموارد
  void dispose() {
    _player.dispose();
  }
}

