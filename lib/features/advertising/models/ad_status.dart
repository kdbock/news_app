enum AdStatus { active, pending, rejected, expired, deleted }

extension AdStatusExtension on AdStatus {
  String get displayName {
    switch (this) {
      case AdStatus.pending:
        return 'Pending';
      case AdStatus.active:
        return 'Active';
      case AdStatus.rejected:
        return 'Rejected';
      case AdStatus.expired:
        return 'Expired';
      case AdStatus.deleted:
        return 'Deleted';
    }
  }

  bool get isActive => this == AdStatus.active;
  bool get isPending => this == AdStatus.pending;
}
