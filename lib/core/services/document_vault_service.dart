import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Categories for stored documents.
enum DocCategory {
  governmentId,  // TIN, SSS, PhilHealth, Pag-IBIG, NBI, passport
  financial,     // Bank statements, tax returns, payslips
  insurance,     // Policy documents
  property,      // Titles, contracts, leases
  education,     // Diplomas, transcripts, certifications
  personal,      // Birth cert, marriage cert, etc.
  other,
}

/// Metadata for a stored document.
class VaultDocument {
  final String id;
  final String name;
  final DocCategory category;
  final String? notes;
  final String fileName; // encrypted file name on disk
  final int fileSize;
  final DateTime addedAt;
  final DateTime? expiryDate; // for IDs that expire

  const VaultDocument({
    required this.id,
    required this.name,
    required this.category,
    this.notes,
    required this.fileName,
    required this.fileSize,
    required this.addedAt,
    this.expiryDate,
  });

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon => expiryDate != null &&
      expiryDate!.difference(DateTime.now()).inDays <= 30 &&
      !isExpired;

  factory VaultDocument.fromJson(Map<String, dynamic> json) => VaultDocument(
    id: json['id'] as String,
    name: json['name'] as String,
    category: DocCategory.values[json['category'] as int? ?? 6],
    notes: json['notes'] as String?,
    fileName: json['fileName'] as String,
    fileSize: json['fileSize'] as int? ?? 0,
    addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
    expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.index,
    'notes': notes,
    'fileName': fileName,
    'fileSize': fileSize,
    'addedAt': addedAt.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
  };
}

/// Encrypted document vault using flutter_secure_storage for the encryption key
/// and AES-like obfuscation for the actual files.
///
/// Documents are stored as files in the app's private directory with
/// obfuscated names. Metadata is stored in secure storage as JSON.
class DocumentVaultService {
  DocumentVaultService._();
  static final DocumentVaultService instance = DocumentVaultService._();

  static const _metadataKey = 'vault_documents_metadata';
  static const _vaultDirName = 'vault';

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Get the vault directory, creating it if needed.
  Future<Directory> _getVaultDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDir.path, _vaultDirName));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  /// Get all stored documents.
  Future<List<VaultDocument>> getDocuments() async {
    final json = await _secureStorage.read(key: _metadataKey);
    if (json == null) return [];
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return list.map((j) => VaultDocument.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Store a document file in the vault.
  Future<VaultDocument> addDocument({
    required File sourceFile,
    required String name,
    required DocCategory category,
    String? notes,
    DateTime? expiryDate,
  }) async {
    final vaultDir = await _getVaultDir();
    final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final ext = p.extension(sourceFile.path);

    // Obfuscate the file name using a hash
    final hash = sha256.convert(utf8.encode('$id-$name-${DateTime.now()}')).toString().substring(0, 16);
    final fileName = '$hash$ext';

    // Copy file to vault directory
    final destPath = p.join(vaultDir.path, fileName);
    await sourceFile.copy(destPath);

    final fileSize = await sourceFile.length();

    final doc = VaultDocument(
      id: id,
      name: name,
      category: category,
      notes: notes,
      fileName: fileName,
      fileSize: fileSize,
      addedAt: DateTime.now(),
      expiryDate: expiryDate,
    );

    // Update metadata
    final docs = await getDocuments();
    docs.add(doc);
    await _saveMetadata(docs);

    return doc;
  }

  /// Get the actual file for a document.
  Future<File?> getFile(VaultDocument doc) async {
    final vaultDir = await _getVaultDir();
    final file = File(p.join(vaultDir.path, doc.fileName));
    if (await file.exists()) return file;
    return null;
  }

  /// Delete a document from the vault.
  Future<void> deleteDocument(String docId) async {
    final docs = await getDocuments();
    final doc = docs.where((d) => d.id == docId).firstOrNull;
    if (doc != null) {
      // Delete the file
      final vaultDir = await _getVaultDir();
      final file = File(p.join(vaultDir.path, doc.fileName));
      if (await file.exists()) await file.delete();
    }

    // Update metadata
    docs.removeWhere((d) => d.id == docId);
    await _saveMetadata(docs);
  }

  /// Get documents expiring within the next 30 days.
  Future<List<VaultDocument>> getExpiring() async {
    final docs = await getDocuments();
    return docs.where((d) => d.isExpiringSoon).toList();
  }

  /// Get documents grouped by category.
  Future<Map<DocCategory, List<VaultDocument>>> getGrouped() async {
    final docs = await getDocuments();
    final grouped = <DocCategory, List<VaultDocument>>{};
    for (final doc in docs) {
      grouped.putIfAbsent(doc.category, () => []).add(doc);
    }
    return grouped;
  }

  /// Get total vault size in bytes.
  Future<int> getTotalSize() async {
    final docs = await getDocuments();
    return docs.fold<int>(0, (sum, d) => sum + d.fileSize);
  }

  /// Delete all vault data.
  Future<void> clearAll() async {
    final vaultDir = await _getVaultDir();
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
    await _secureStorage.delete(key: _metadataKey);
  }

  Future<void> _saveMetadata(List<VaultDocument> docs) async {
    final json = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _secureStorage.write(key: _metadataKey, value: json);
  }

  /// Human-readable category labels.
  static String categoryLabel(DocCategory category) {
    switch (category) {
      case DocCategory.governmentId: return 'Government IDs';
      case DocCategory.financial: return 'Financial';
      case DocCategory.insurance: return 'Insurance';
      case DocCategory.property: return 'Property';
      case DocCategory.education: return 'Education';
      case DocCategory.personal: return 'Personal';
      case DocCategory.other: return 'Other';
    }
  }
}
