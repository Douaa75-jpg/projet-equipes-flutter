import 'package:get/get.dart';
import 'fr_FR.dart';
import 'en_US.dart';

class TranslationService extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'fr_FR': fr_FR,
        'en_US': en_US,
      };
}