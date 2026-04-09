/// 식물 마스터 인덱스(plants.json)의 루트 모델.
///
/// tech_spec.md 2.2항 스키마를 정확히 따른다.
class PlantsIndex {
  final int version;
  final DateTime lastUpdated;
  final List<PlantModel> plants;

  const PlantsIndex({
    required this.version,
    required this.lastUpdated,
    required this.plants,
  });

  factory PlantsIndex.empty() => PlantsIndex(
        version: 1,
        lastUpdated: DateTime.now(),
        plants: [],
      );

  factory PlantsIndex.fromJson(Map<String, dynamic> json) => PlantsIndex(
        version: json['version'] as int,
        lastUpdated: DateTime.parse(json['last_updated'] as String),
        plants: (json['plants'] as List<dynamic>)
            .map((e) => PlantModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'last_updated': lastUpdated.toIso8601String(),
        'plants': plants.map((p) => p.toJson()).toList(),
      };

  /// [plant]을 목록에 추가하거나, 같은 id가 있으면 교체한 새 인덱스를 반환한다.
  PlantsIndex upsert(PlantModel plant) {
    final updated = plants.map((p) => p.id == plant.id ? plant : p).toList();
    if (!plants.any((p) => p.id == plant.id)) updated.add(plant);
    return PlantsIndex(
      version: version,
      lastUpdated: DateTime.now(),
      plants: updated,
    );
  }
}

/// 식물 한 그루의 메타데이터 모델.
///
/// id는 UUID v4로 생성되며, 영구 불변이다.
class PlantModel {
  final String id;
  final String displayName;
  final String species;
  final DateTime registeredAt;

  /// 대표 썸네일 파일명 (사진 없으면 null)
  final String? thumbnail;

  /// 물주기 간격 (일)
  final int wateringIntervalDays;

  /// D-Day 계산 기준일 (ISO 8601 Date 문자열, 예: "2026-01-15")
  final String ddayAnchor;

  final List<String> tags;

  /// true이면 삭제 대신 아카이브 처리 — 이력이 보존된다.
  final bool isArchived;

  const PlantModel({
    required this.id,
    required this.displayName,
    required this.species,
    required this.registeredAt,
    this.thumbnail,
    required this.wateringIntervalDays,
    required this.ddayAnchor,
    this.tags = const [],
    this.isArchived = false,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) => PlantModel(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        species: json['species'] as String,
        registeredAt: DateTime.parse(json['registered_at'] as String),
        thumbnail: json['thumbnail'] as String?,
        wateringIntervalDays: json['watering_interval_days'] as int,
        ddayAnchor: json['dday_anchor'] as String,
        tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
        isArchived: json['is_archived'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'species': species,
        'registered_at': registeredAt.toIso8601String(),
        'thumbnail': thumbnail,
        'watering_interval_days': wateringIntervalDays,
        'dday_anchor': ddayAnchor,
        'tags': tags,
        'is_archived': isArchived,
      };

  /// 변경된 필드만 교체한 새 PlantModel을 반환한다.
  PlantModel copyWith({
    String? displayName,
    String? species,
    String? thumbnail,
    int? wateringIntervalDays,
    String? ddayAnchor,
    List<String>? tags,
    bool? isArchived,
  }) {
    return PlantModel(
      id: id,
      displayName: displayName ?? this.displayName,
      species: species ?? this.species,
      registeredAt: registeredAt,
      thumbnail: thumbnail ?? this.thumbnail,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      ddayAnchor: ddayAnchor ?? this.ddayAnchor,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
