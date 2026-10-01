enum NotificationType {
  photoAdded,
  commentAdded,
  reactionAdded,
  guestJoined,
  deletionVoteNeeded,
  photosRevealed,
  recapReady;

  static NotificationType fromApi(String value) => switch (value) {
        'PhotoAdded' => NotificationType.photoAdded,
        'CommentAdded' => NotificationType.commentAdded,
        'ReactionAdded' => NotificationType.reactionAdded,
        'GuestJoined' => NotificationType.guestJoined,
        'DeletionVoteNeeded' => NotificationType.deletionVoteNeeded,
        'PhotosRevealed' => NotificationType.photosRevealed,
        'RecapReady' => NotificationType.recapReady,
        _ => NotificationType.photoAdded,
      };
}
