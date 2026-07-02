enum ModelDownloadPhase {
  idle,
  downloading,
  verifying,
  ready,
  failed,
}

class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.phase,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.message,
    this.error,
  });

  final ModelDownloadPhase phase;
  final int receivedBytes;
  final int totalBytes;
  final String? message;
  final String? error;

  double get fraction {
    if (totalBytes <= 0) return 0;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  ModelDownloadProgress copyWith({
    ModelDownloadPhase? phase,
    int? receivedBytes,
    int? totalBytes,
    String? message,
    String? error,
  }) {
    return ModelDownloadProgress(
      phase: phase ?? this.phase,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

enum ModelLoadPhase {
  idle,
  checking,
  loading,
  loaded,
  unloading,
  failed,
}

class ModelLoadState {
  const ModelLoadState({
    required this.phase,
    this.message,
    this.error,
    this.modelId,
    this.freeRamMb,
  });

  final ModelLoadPhase phase;
  final String? message;
  final String? error;
  final String? modelId;
  final int? freeRamMb;

  bool get isLoaded => phase == ModelLoadPhase.loaded;
  bool get isLoading =>
      phase == ModelLoadPhase.loading || phase == ModelLoadPhase.checking;

  ModelLoadState copyWith({
    ModelLoadPhase? phase,
    String? message,
    String? error,
    String? modelId,
    int? freeRamMb,
  }) {
    return ModelLoadState(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      error: error ?? this.error,
      modelId: modelId ?? this.modelId,
      freeRamMb: freeRamMb ?? this.freeRamMb,
    );
  }
}
