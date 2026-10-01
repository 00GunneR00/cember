class UserProfile {
  const UserProfile({
    required this.name,
    required this.circleCount,
    required this.photoCount,
    required this.eventCount,
    required this.storageUsedBytes,
    required this.storageTotalBytes,
    required this.onlyUploadOnWifi,
    required this.notifyOnPhotoAdded,
    required this.notifyOnComment,
    required this.notifyOnReaction,
    required this.notifyOnGuestJoined,
    this.linkedGoogleEmail,
  });

  final String name;
  final int circleCount;
  final int photoCount;
  final int eventCount;
  final int storageUsedBytes;
  final int storageTotalBytes;
  final bool onlyUploadOnWifi;
  final bool notifyOnPhotoAdded;
  final bool notifyOnComment;
  final bool notifyOnReaction;
  final bool notifyOnGuestJoined;
  final String? linkedGoogleEmail;

  UserProfile copyWith({
    String? name,
    bool? onlyUploadOnWifi,
    bool? notifyOnPhotoAdded,
    bool? notifyOnComment,
    bool? notifyOnReaction,
    bool? notifyOnGuestJoined,
    String? linkedGoogleEmail,
  }) => UserProfile(
        name: name ?? this.name,
        circleCount: circleCount,
        photoCount: photoCount,
        eventCount: eventCount,
        storageUsedBytes: storageUsedBytes,
        storageTotalBytes: storageTotalBytes,
        onlyUploadOnWifi: onlyUploadOnWifi ?? this.onlyUploadOnWifi,
        notifyOnPhotoAdded: notifyOnPhotoAdded ?? this.notifyOnPhotoAdded,
        notifyOnComment: notifyOnComment ?? this.notifyOnComment,
        notifyOnReaction: notifyOnReaction ?? this.notifyOnReaction,
        notifyOnGuestJoined: notifyOnGuestJoined ?? this.notifyOnGuestJoined,
        linkedGoogleEmail: linkedGoogleEmail ?? this.linkedGoogleEmail,
      );

  double get storageUsedGb => storageUsedBytes / (1024 * 1024 * 1024);
  double get storageTotalGb => storageTotalBytes / (1024 * 1024 * 1024);
  double get storageFraction => storageTotalBytes == 0 ? 0 : storageUsedBytes / storageTotalBytes;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['displayName'] as String,
        circleCount: json['circleCount'] as int,
        photoCount: json['photoCount'] as int,
        eventCount: json['eventCount'] as int,
        storageUsedBytes: json['storageUsedBytes'] as int,
        storageTotalBytes: json['storageTotalBytes'] as int,
        onlyUploadOnWifi: json['onlyUploadOnWifi'] as bool,
        notifyOnPhotoAdded: json['notifyOnPhotoAdded'] as bool,
        notifyOnComment: json['notifyOnComment'] as bool,
        notifyOnReaction: json['notifyOnReaction'] as bool,
        notifyOnGuestJoined: json['notifyOnGuestJoined'] as bool,
        linkedGoogleEmail: json['linkedGoogleEmail'] as String?,
      );
}
