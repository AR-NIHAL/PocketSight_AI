class IntakeDetails {
  final String physicalCondition;
  final List<String> suppliedAccessories;
  final String? customAccessoriesNote;
  final List<String> photoPaths;
  final String? stickerPhotoPath;

  const IntakeDetails({
    required this.physicalCondition,
    required this.suppliedAccessories,
    this.customAccessoriesNote,
    this.photoPaths = const [],
    this.stickerPhotoPath,
  });

  Map<String, dynamic> toMap() => {
        'physicalCondition': physicalCondition,
        'suppliedAccessories': suppliedAccessories,
        'customAccessoriesNote': customAccessoriesNote,
        'photoPaths': photoPaths,
        'stickerPhotoPath': stickerPhotoPath,
      };

  factory IntakeDetails.fromMap(Map<String, dynamic> map) => IntakeDetails(
        physicalCondition: map['physicalCondition'] as String? ?? '',
        suppliedAccessories:
            List<String>.from(map['suppliedAccessories'] as List? ?? []),
        customAccessoriesNote: map['customAccessoriesNote'] as String?,
        photoPaths: List<String>.from(map['photoPaths'] as List? ?? []),
        stickerPhotoPath: map['stickerPhotoPath'] as String?,
      );

  IntakeDetails copyWith({
    String? physicalCondition,
    List<String>? suppliedAccessories,
    String? customAccessoriesNote,
    List<String>? photoPaths,
    String? stickerPhotoPath,
  }) {
    return IntakeDetails(
      physicalCondition: physicalCondition ?? this.physicalCondition,
      suppliedAccessories: suppliedAccessories ?? this.suppliedAccessories,
      customAccessoriesNote:
          customAccessoriesNote ?? this.customAccessoriesNote,
      photoPaths: photoPaths ?? this.photoPaths,
      stickerPhotoPath: stickerPhotoPath ?? this.stickerPhotoPath,
    );
  }
}
