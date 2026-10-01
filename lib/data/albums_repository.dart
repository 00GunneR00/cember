import 'package:flutter/material.dart';

import '../models/albums_overview.dart';
import '../models/brand_profile.dart';
import '../models/circle_summary.dart';
import '../models/joined_circle_summary.dart';
import '../models/photo_upload_mode.dart';

abstract class AlbumsRepository {
  const AlbumsRepository();

  Future<AlbumsOverview> fetch();
  Future<CircleSummary> createCircle(
    String name, {
    DateTime? eventDate,
    required bool isOpenJoin,
    String? description,
    PhotoUploadMode uploadMode = PhotoUploadMode.both,
    DateTime? revealAt,
    String? challengeTemplateId,
    List<String>? rules,
  });

  /// Circles joined as a guest via Discover (not owned by the viewer).
  Future<List<JoinedCircleSummary>> fetchJoinedCircles();
}

class MockAlbumsRepository extends AlbumsRepository {
  const MockAlbumsRepository();

  @override
  Future<AlbumsOverview> fetch() async {
    return const AlbumsOverview(
      userName: 'Zeynep',
      live: [
        CircleSummary(
          id: 'mock-live-1',
          name: 'Karaköy Rooftop Lansman & Akustik Gece',
          eventDate: null,
          isArchived: false,
          isOpenJoin: true,
          photoCount: 48,
          participantCount: 14,
          coverUrl: null,
        ),
        CircleSummary(
          id: 'mock-live-2',
          name: 'Ege & Selin Düğünü - Çeşme',
          eventDate: null,
          isArchived: false,
          isOpenJoin: true,
          photoCount: 342,
          participantCount: 68,
          coverUrl: null,
          brand: BrandProfile(
            id: 'mock-brand',
            name: 'Nova Enerji',
            primaryColor: Color(0xFFE8462F),
            secondaryColor: Color(0xFF1B1B1B),
          ),
        ),
      ],
      past: [
        CircleSummary(
          id: 'mock-past-1',
          name: "Kapadokya Balon Turu '24",
          eventDate: null,
          isArchived: true,
          isOpenJoin: true,
          photoCount: 124,
          participantCount: 9,
          coverUrl: null,
        ),
        CircleSummary(
          id: 'mock-past-2',
          name: 'Tasarım Ekibi Offsite Kampı',
          eventDate: null,
          isArchived: true,
          isOpenJoin: false,
          photoCount: 86,
          participantCount: 12,
          coverUrl: null,
        ),
        CircleSummary(
          id: 'mock-past-3',
          name: "Emir'in 30. Yaş Kutlaması",
          eventDate: null,
          isArchived: true,
          isOpenJoin: true,
          photoCount: 195,
          participantCount: 40,
          coverUrl: null,
        ),
      ],
    );
  }

  @override
  Future<CircleSummary> createCircle(
    String name, {
    DateTime? eventDate,
    required bool isOpenJoin,
    String? description,
    PhotoUploadMode uploadMode = PhotoUploadMode.both,
    DateTime? revealAt,
    String? challengeTemplateId,
    List<String>? rules,
  }) async {
    return CircleSummary(
      id: 'mock-new',
      name: name,
      eventDate: eventDate,
      isArchived: false,
      isOpenJoin: isOpenJoin,
      photoCount: 0,
      participantCount: 1,
      coverUrl: null,
      description: description,
      uploadMode: uploadMode,
      revealAt: revealAt,
      isDeveloping: revealAt != null,
    );
  }

  @override
  Future<List<JoinedCircleSummary>> fetchJoinedCircles() async => const [];
}
