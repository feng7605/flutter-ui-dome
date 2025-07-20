class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // --- Directory and Path Constants ---
  static const String modulesBaseDir = 'modules';
  static const String resourceTypeModels = 'models';
  static const String resourceTypeDatasets = 'datasets';
  
  // --- Module Names ---
  static const String moduleAsr = 'asr';
  static const String moduleTts = 'tts'; // For future use
  static const String moduleNlu = 'nlu'; // For future use

  // --- Network ---
  static const String headerRange = 'Range';
  static const String headerBytesPrefix = 'bytes=';

  // --- Configuration Keys ---
  // It's often better to let model classes handle this,
  // but for very common keys, they can be here.
  // e.g., static const String configKeyDefaultSupplier = 'defaultSupplier';
}