import 'package:flutter/foundation.dart';

@immutable
class IncidentRecord {
  const IncidentRecord({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.area,
    this.resolution,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final IncidentPriority priority;
  final IncidentStatus status;
  final DateTime createdAt;
  final String? area;
  final String? resolution;
  final DateTime? resolvedAt;

  bool get isOpen =>
      status == IncidentStatus.open || status == IncidentStatus.inProgress;

  IncidentRecord resolve({
    required String resolution,
    required DateTime resolvedAt,
  }) {
    return IncidentRecord(
      id: id,
      title: title,
      priority: priority,
      status: IncidentStatus.resolved,
      createdAt: createdAt,
      area: area,
      resolution: resolution,
      resolvedAt: resolvedAt,
    );
  }
}

enum IncidentPriority { low, medium, high, critical }

enum IncidentStatus { open, inProgress, resolved, closed }

abstract interface class IncidentRepository {
  Future<IncidentRecord> log(IncidentDraft draft);

  Future<IncidentRecord> updateStatus({
    required String id,
    required IncidentStatus status,
    String? resolution,
  });
}

@immutable
class IncidentDraft {
  const IncidentDraft({required this.title, required this.priority, this.area});

  final String title;
  final IncidentPriority priority;
  final String? area;

  bool get isValid => title.trim().isNotEmpty;
}

class ClientDependencyIncidentRepository implements IncidentRepository {
  ClientDependencyIncidentRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, IncidentRecord> _records = <String, IncidentRecord>{};

  @override
  Future<IncidentRecord> log(IncidentDraft draft) async {
    if (!draft.isValid) {
      throw ArgumentError.value(
        draft.title,
        'title',
        'Incident title required',
      );
    }
    final id = 'incident-${_records.length + 1}';
    final record = IncidentRecord(
      id: id,
      title: draft.title.trim(),
      priority: draft.priority,
      status: IncidentStatus.open,
      createdAt: _clock().toUtc(),
      area: draft.area,
    );
    _records[id] = record;
    return record;
  }

  @override
  Future<IncidentRecord> updateStatus({
    required String id,
    required IncidentStatus status,
    String? resolution,
  }) async {
    final previous = _records[id];
    if (previous == null) {
      throw StateError('Incident not found: $id');
    }
    final updated = status == IncidentStatus.resolved
        ? previous.resolve(
            resolution: resolution ?? 'Resolution pending final notes.',
            resolvedAt: _clock().toUtc(),
          )
        : IncidentRecord(
            id: previous.id,
            title: previous.title,
            priority: previous.priority,
            status: status,
            createdAt: previous.createdAt,
            area: previous.area,
            resolution: previous.resolution,
            resolvedAt: previous.resolvedAt,
          );
    _records[id] = updated;
    return updated;
  }
}
