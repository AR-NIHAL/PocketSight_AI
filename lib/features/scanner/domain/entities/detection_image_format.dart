/// The raw pixel format carried by a [DetectionImage].
///
/// Mirrors the formats produced by camera frame streams and consumed by
/// platform ML SDKs (e.g. ML Kit `InputImage`).
enum DetectionImageFormat {
  /// YUV 4:2:0 (Android camera frames).
  yuv420,

  /// NV21 (raw Android camera frames).
  nv21,

  /// BGRA 8-bit-per-channel (iOS camera frames).
  bgra8888,

  /// RGBA 8-bit-per-channel.
  rgba8888,

  /// JPEG-encoded bytes.
  jpeg,
}
