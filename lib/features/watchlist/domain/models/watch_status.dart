// Watchlist status domain model

enum WatchStatus {
  watching('Watching'),
  planning('Planning'),
  completed('Completed'),
  onHold('On Hold'),
  dropped('Dropped');

  final String displayName;

  const WatchStatus(this.displayName);

  static WatchStatus fromString(String? value) {
    if (value == null) return WatchStatus.planning;
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    switch (normalized) {
      case 'watching':
      case 'current':
        return WatchStatus.watching;
      case 'planning':
      case 'plan':
      case 'plantowatch':
        return WatchStatus.planning;
      case 'completed':
      case 'finish':
      case 'finished':
        return WatchStatus.completed;
      case 'onhold':
      case 'hold':
      case 'paused':
        return WatchStatus.onHold;
      case 'dropped':
        return WatchStatus.dropped;
      default:
        return WatchStatus.planning;
    }
  }

  String toDbString() {
    switch (this) {
      case WatchStatus.watching:
        return 'WATCHING';
      case WatchStatus.planning:
        return 'PLANNING';
      case WatchStatus.completed:
        return 'COMPLETED';
      case WatchStatus.onHold:
        return 'ON_HOLD';
      case WatchStatus.dropped:
        return 'DROPPED';
    }
  }

  static WatchStatus fromDbString(String? dbString) {
    switch (dbString) {
      case 'WATCHING':
        return WatchStatus.watching;
      case 'PLANNING':
        return WatchStatus.planning;
      case 'COMPLETED':
        return WatchStatus.completed;
      case 'ON_HOLD':
        return WatchStatus.onHold;
      case 'DROPPED':
        return WatchStatus.dropped;
      default:
        return fromString(dbString);
    }
  }
}
