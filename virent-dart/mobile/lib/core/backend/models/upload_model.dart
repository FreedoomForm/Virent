/// File-upload metadata model.
///
/// Ported from `backend/v1/models/uploads.js`. The backend stores
/// uploaded files on local disk under `UPLOAD_DIR/{yyyy}/{mm}/` (in
/// production this would be S3/MinIO) and logs metadata to the
/// `uploads` MongoDB collection.
///
/// Allowed file types: JPEG, PNG, WebP. Max size: 5 MB.
library;


import 'json_helpers.dart';
/// Allowed MIME types, mirroring `ALLOWED_TYPES` in `uploads.js`.
const List<String> allowedUploadMimeTypes = [
  'image/jpeg',
  'image/png',
  'image/webp',
];

/// Max upload size in bytes, mirroring `MAX_FILE_SIZE` in `uploads.js`.
const int maxUploadSizeBytes = 5 * 1024 * 1024; // 5 MB

/// Why the file was uploaded (parking proof, breakdown photo, etc.).
enum UploadPurpose {
  /// End-of-ride parking proof photo.
  parkingProof,

  /// Breakdown-report photo attached to a support ticket.
  breakdown,

  /// Maintenance-request completion photo.
  maintenanceCompletion,

  /// Profile avatar.
  avatar,

  /// Anything not categorised above.
  general;

  static UploadPurpose fromString(String? raw) {
    switch (raw) {
      case 'parking_proof':
      case 'parking':
        return UploadPurpose.parkingProof;
      case 'breakdown':
        return UploadPurpose.breakdown;
      case 'maintenance_completion':
      case 'maintenance':
        return UploadPurpose.maintenanceCompletion;
      case 'avatar':
        return UploadPurpose.avatar;
      default:
        return UploadPurpose.general;
    }
  }

  String get wire => switch (this) {
        UploadPurpose.parkingProof => 'parking_proof',
        UploadPurpose.breakdown => 'breakdown',
        UploadPurpose.maintenanceCompletion => 'maintenance_completion',
        UploadPurpose.avatar => 'avatar',
        UploadPurpose.general => 'general',
      };
}

/// Upload metadata document.
class UploadModel {
  /// MongoDB `_id` of the upload record.
  final String id;

  /// `_id` of the user who uploaded the file. `null` for anonymous
  /// (system-initiated) uploads.
  final String? uploadedBy;

  /// Random 24-char hex filename generated server-side (e.g.
  /// `a1b2c3d4e5f6789012345678.jpg`).
  final String filename;

  /// Original client-side filename.
  final String? originalName;

  /// MIME type (one of [allowedUploadMimeTypes]).
  final String mimeType;

  /// File size in bytes.
  final int size;

  /// Absolute path on the server's local disk. `null` when the file
  /// is stored in object storage (S3/MinIO) and only the URL is known.
  final String? path;

  /// Public URL the client can fetch the file from.
  final String url;

  /// Why the file was uploaded.
  final UploadPurpose purpose;

  /// When the upload was recorded.
  final DateTime? createdAt;

  /// Creates an [UploadModel].
  const UploadModel({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.url,
    required this.purpose,
    this.uploadedBy,
    this.originalName,
    this.path,
    this.createdAt,
  });

  /// Parses a JSON object (MongoDB document) into an [UploadModel].
  factory UploadModel.fromJson(Map<String, dynamic> json) => UploadModel(
        id: stringifyId(json['_id'] ?? json['id']),
        uploadedBy:
            stringifyIdNullable(json['user_id'] ?? json['uploadedBy']),
        filename: (json['filename'] ?? '').toString(),
        originalName: asString(json['original_name'] ?? json['originalName']),
        mimeType: (json['mime_type'] ?? json['mimeType'] ??
                'application/octet-stream')
            .toString(),
        size: toInt(json['size']),
        path: asString(json['path']),
        url: (json['public_url'] ?? json['url'] ?? '').toString(),
        purpose:
            UploadPurpose.fromString(json['purpose']?.toString()),
        createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      );

  /// `true` when the file is an image (one of [allowedUploadMimeTypes]).
  bool get isImage => allowedUploadMimeTypes.contains(mimeType);

  /// `true` when the file size is within the allowed limit.
  bool get isWithinSizeLimit => size <= maxUploadSizeBytes;

  /// File extension inferred from [mimeType] (e.g. `jpg`, `png`, `webp`).
  String get extension {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'bin';
    }
  }

  /// Human-readable file size (e.g. `1.2 MB`, `450 KB`).
  String get humanReadableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Serialises the upload back to a JSON map.
  Map<String, dynamic> toJson() => {
        '_id': id,
        if (uploadedBy != null) 'user_id': uploadedBy,
        'filename': filename,
        if (originalName != null) 'original_name': originalName,
        'mime_type': mimeType,
        'size': size,
        if (path != null) 'path': path,
        'public_url': url,
        'purpose': purpose.wire,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  /// Returns a copy of this upload with the given fields replaced.
  UploadModel copyWith({
    String? id,
    String? uploadedBy,
    String? filename,
    String? originalName,
    String? mimeType,
    int? size,
    String? path,
    String? url,
    UploadPurpose? purpose,
    DateTime? createdAt,
  }) {
    return UploadModel(
      id: id ?? this.id,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      path: path ?? this.path,
      url: url ?? this.url,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UploadModel(filename: $filename, size: $size, purpose: $purpose)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Paginated upload-list response wrapper.
class UploadList {
  final List<UploadModel> uploads;
  final int total;
  final int limit;
  final int offset;

  const UploadList({
    required this.uploads,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory UploadList.fromJson(Map<String, dynamic> json) {
    final rawUploads = json['uploads'];
    return UploadList(
      uploads: rawUploads is List
          ? rawUploads
              .whereType<Map>()
              .map((u) => UploadModel.fromJson(u as Map<String, dynamic>))
              .toList(growable: false)
          : const [],
      total: toInt(json['total']),
      limit: toInt(json['limit']),
      offset: toInt(json['offset']),
    );
  }

  /// `true` when more pages exist beyond this one.
  bool get hasMore => offset + uploads.length < total;

  /// Total bytes across all uploads in the page.
  int get totalBytes => uploads.fold(0, (s, u) => s + u.size);

  Map<String, dynamic> toJson() => {
        'uploads': uploads.map((u) => u.toJson()).toList(),
        'total': total,
        'limit': limit,
        'offset': offset,
      };

  @override
  String toString() => 'UploadList(${uploads.length}/$total)';
}

// --- internal helpers ----------------------------------------------------


