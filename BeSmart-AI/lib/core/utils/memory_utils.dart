import 'dart:io';

class MemoryUtils {
  MemoryUtils._();

  /// Estimation grossière de la RAM disponible (Mo).
  /// Sur Android, une détection précise nécessite un plugin natif ;
  /// llama_flutter_android expose detectGpu().freeRamBytes au chargement.
  static Future<int?> estimateAvailableRamMb() async {
    if (!Platform.isAndroid) return null;
    return null;
  }

  static bool hasEnoughRam({
    required int? availableRamMb,
    required int requiredRamMb,
  }) {
    if (availableRamMb == null) return true;
    return availableRamMb >= requiredRamMb;
  }
}
