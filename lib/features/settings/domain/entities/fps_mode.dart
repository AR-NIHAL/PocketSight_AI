/// Performance modes for the live frame pipeline (10-15 FPS).
enum FpsMode {
  /// 10 FPS — max battery savings.
  low(10),

  /// 12 FPS — balanced default.
  balanced(12),

  /// 15 FPS — highest responsiveness.
  high(15);

  const FpsMode(this.targetFps);

  /// Target frames per second for this mode.
  final int targetFps;
}
