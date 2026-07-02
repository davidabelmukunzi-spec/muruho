/// Configuration des modèles GGUF téléchargeables.
///
/// Les empreintes SHA-256 peuvent être mises à jour depuis Hugging Face :
/// `sha256sum qwen2.5-1.5b-instruct-q4_k_m.gguf`
class ModelConfig {
  ModelConfig._();

  static const primary = ModelDefinition(
    id: 'qwen2.5-1.5b-instruct-q4_k_m',
    displayName: 'Qwen2.5 1.5B Instruct',
    fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    downloadUrl:
        'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    expectedSizeBytes: 986000000,
    sha256: '',
    chatTemplate: 'chatml',
    minRamMb: 4096,
  );

  static const fallback = ModelDefinition(
    id: 'qwen2.5-0.5b-instruct-q4_k_m',
    displayName: 'Qwen2.5 0.5B Instruct (léger)',
    fileName: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
    downloadUrl:
        'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
    expectedSizeBytes: 398000000,
    sha256: '',
    chatTemplate: 'chatml',
    minRamMb: 3072,
  );

  static const all = [primary, fallback];
}

class ModelDefinition {
  const ModelDefinition({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.downloadUrl,
    required this.expectedSizeBytes,
    required this.sha256,
    required this.chatTemplate,
    required this.minRamMb,
  });

  final String id;
  final String displayName;
  final String fileName;
  final String downloadUrl;
  final int expectedSizeBytes;
  final String sha256;
  final String chatTemplate;
  final int minRamMb;
}
