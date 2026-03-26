import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/services/document_vault_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/utils/snackbar_helper.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<VaultDocument> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final docs = await DocumentVaultService.instance.getDocuments();
    if (mounted) setState(() { _docs = docs; _loading = false; });
  }

  Future<void> _addDocument() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (picked == null || picked.files.single.path == null) return;
    if (!mounted) return;

    final file = File(picked.files.single.path!);
    final fileName = picked.files.single.name;

    // Show naming dialog
    final result = await showDialog<_AddDocResult>(
      context: context,
      builder: (ctx) => _AddDocDialog(defaultName: fileName),
    );
    if (result == null) return;

    await DocumentVaultService.instance.addDocument(
      sourceFile: file,
      name: result.name,
      category: result.category,
      notes: result.notes,
      expiryDate: result.expiryDate,
    );
    await _loadDocs();
    if (mounted) showSuccessSnackBar(context, 'Document saved to vault');
  }

  Future<void> _openDocument(VaultDocument doc) async {
    final file = await DocumentVaultService.instance.getFile(doc);
    if (file == null) {
      if (mounted) showAppSnackBar(context, 'File not found', isError: true);
      return;
    }
    await OpenFilex.open(file.path);
  }

  Future<void> _deleteDocument(VaultDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?', style: TextStyle(fontSize: 16)),
        content: Text('This will permanently delete "${doc.name}" from the vault.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DocumentVaultService.instance.deleteDocument(doc.id);
    await _loadDocs();
    if (mounted) showSuccessSnackBar(context, 'Document deleted');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Header
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Document Vault',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_docs.isEmpty
                ? 'Store important documents securely'
                : '${_docs.length} document${_docs.length == 1 ? '' : 's'} stored',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
          FilledButton.icon(
            onPressed: _addDocument,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
        ]),
        const SizedBox(height: 16),

        // Security notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.06),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(LucideIcons.shieldCheck, size: 18, color: Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Expanded(child: Text('Files are stored locally on your device with encrypted metadata. They never leave your phone.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
          ]),
        ),
        const SizedBox(height: 16),

        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )),

        if (!_loading && _docs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.folderLock, size: 48, color: cs.onSurfaceVariant.withOpacity(0.2)),
              const SizedBox(height: 12),
              Text('No documents yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Store IDs, contracts, and important files securely.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ])),
          ),

        // Expiring soon
        if (_docs.any((d) => d.isExpiringSoon)) ...[
          _SectionLabel('EXPIRING SOON'),
          const SizedBox(height: 6),
          for (final doc in _docs.where((d) => d.isExpiringSoon))
            _DocTile(doc: doc, onTap: () => _openDocument(doc), onDelete: () => _deleteDocument(doc),
                highlight: true),
          const SizedBox(height: 12),
        ],

        // By category
        if (_docs.isNotEmpty) ...[
          for (final cat in DocCategory.values) ...[
            if (_docs.any((d) => d.category == cat && !d.isExpiringSoon)) ...[
              _SectionLabel(DocumentVaultService.categoryLabel(cat).toUpperCase()),
              const SizedBox(height: 6),
              for (final doc in _docs.where((d) => d.category == cat && !d.isExpiringSoon))
                _DocTile(doc: doc, onTap: () => _openDocument(doc), onDelete: () => _deleteDocument(doc)),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
        letterSpacing: 0.8, color: Theme.of(context).colorScheme.onSurfaceVariant));
  }
}

class _DocTile extends StatelessWidget {
  final VaultDocument doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool highlight;

  const _DocTile({required this.doc, required this.onTap, required this.onDelete, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight ? Colors.red.withOpacity(0.04) : cs.surface,
            border: Border.all(color: highlight ? Colors.red.withOpacity(0.2) : cs.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(_iconForCategory(doc.category), size: 20,
                color: highlight ? Colors.red : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (doc.expiryDate != null)
                Text('Expires ${formatDate(doc.expiryDate!)}',
                    style: TextStyle(fontSize: 11,
                        color: highlight ? Colors.red : cs.onSurfaceVariant)),
            ])),
            Text(_formatSize(doc.fileSize),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }

  IconData _iconForCategory(DocCategory cat) {
    switch (cat) {
      case DocCategory.governmentId: return LucideIcons.creditCard;
      case DocCategory.financial: return LucideIcons.landmark;
      case DocCategory.insurance: return LucideIcons.shield;
      case DocCategory.property: return LucideIcons.building2;
      case DocCategory.education: return LucideIcons.graduationCap;
      case DocCategory.personal: return LucideIcons.user;
      case DocCategory.other: return LucideIcons.file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─── Add Document Dialog ────────────────────────────────────────────────────────

class _AddDocResult {
  final String name;
  final DocCategory category;
  final String? notes;
  final DateTime? expiryDate;
  const _AddDocResult({required this.name, required this.category, this.notes, this.expiryDate});
}

class _AddDocDialog extends StatefulWidget {
  final String defaultName;
  const _AddDocDialog({required this.defaultName});

  @override
  State<_AddDocDialog> createState() => _AddDocDialogState();
}

class _AddDocDialogState extends State<_AddDocDialog> {
  late final TextEditingController _nameController;
  final _notesController = TextEditingController();
  DocCategory _category = DocCategory.other;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    // Strip extension from default name
    final nameWithoutExt = widget.defaultName.contains('.')
        ? widget.defaultName.substring(0, widget.defaultName.lastIndexOf('.'))
        : widget.defaultName;
    _nameController = TextEditingController(text: nameWithoutExt);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Document name'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DocCategory>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: DocCategory.values.map((c) => DropdownMenuItem(
              value: c,
              child: Text(DocumentVaultService.categoryLabel(c), style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => _category = v ?? DocCategory.other),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(
              _expiryDate != null ? 'Expires: ${formatDate(_expiryDate!)}' : 'No expiry date',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            )),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
              child: Text(_expiryDate != null ? 'Change' : 'Set'),
            ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : () {
            Navigator.pop(context, _AddDocResult(
              name: _nameController.text.trim(),
              category: _category,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              expiryDate: _expiryDate,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
