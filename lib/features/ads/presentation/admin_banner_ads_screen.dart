import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/storage_service.dart';
import '../../admin/presentation/widgets/admin_paged_controller.dart';
import '../../admin/presentation/widgets/admin_paged_view.dart';
import '../domain/banner_ad_model.dart';
import '../services/banner_ad_service.dart';

const _bannerFilters = <AdminFilter>[
  AdminFilter('active', 'Aktif', icon: Icons.visibility_outlined),
  AdminFilter('inactive', 'Pasif', icon: Icons.visibility_off_outlined),
  AdminFilter('all', 'Tümü'),
];

class AdminBannerAdsScreen extends ConsumerWidget {
  const AdminBannerAdsScreen({super.key});

  void _showBannerForm(BuildContext context, WidgetRef ref, [BannerAd? existingAd]) {
    unawaited(showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _BannerAdFormSheet(existingAd: existingAd),
    ));
  }

  Future<bool> _deleteBanner(BuildContext context, WidgetRef ref, BannerAd ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Banner silinsin mi?'),
        content: Text('"${ad.title}" reklam bannerı tamamen silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;
    try {
      await ref.read(bannerAdServiceProvider).deleteBannerAd(ad.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner silindi.')),
        );
      }
      return true;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminBannerAdsScreen._deleteBanner');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banner Reklam Yönetimi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Banner'),
      ),
      body: _AdminBannerAdsBody(
        onEdit: (banner) => _showBannerForm(context, ref, banner),
        onDelete: (banner) => _deleteBanner(context, ref, banner),
      ),
    );
  }
}

class _AdminBannerAdsBody extends StatefulWidget {
  const _AdminBannerAdsBody({
    required this.onEdit,
    required this.onDelete,
  });

  final ValueChanged<BannerAd> onEdit;
  final Future<bool> Function(BannerAd) onDelete;

  @override
  State<_AdminBannerAdsBody> createState() => _AdminBannerAdsBodyState();
}

class _AdminBannerAdsBodyState extends State<_AdminBannerAdsBody> {
  late final AdminPagedController<BannerAd> _controller =
      AdminPagedController<BannerAd>(
        fromDoc: (doc) => BannerAd.fromDoc(doc),
        idOf: (banner) => banner.id,
      );
  String _filter = 'active';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    unawaited(_controller.setQuery(adminBannerAdsQuery(
      FirebaseFirestore.instance,
      filter: _filter,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminFilterBar(
          filters: _bannerFilters,
          selectedId: _filter,
          onSelected: (id) {
            setState(() => _filter = id);
            _reload();
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AdminPagedView<BannerAd>(
            controller: _controller,
            emptyText: 'Bu filtreyle banner bulunamadı.',
            cardBuilder: (_, banner) => _AdminBannerCard(
              banner: banner,
              onEdit: () => widget.onEdit(banner),
              onDelete: () {
                unawaited(widget.onDelete(banner).then((deleted) {
                  if (deleted) {
                    _controller.removeWhere((item) => item.id == banner.id);
                  }
                }));
              },
              onToggleActive: (value) {
                unawaited(
                  BannerAdService(FirebaseFirestore.instance)
                      .toggleActive(banner.id, value)
                      .then((_) => _controller.refresh()),
                );
              },
            ),
            columns: [
              AdminColumn(
                label: 'Banner',
                flex: 3,
                cell: (_, banner) => Text(
                  banner.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AdminColumn(
                label: 'Reklamveren',
                flex: 2,
                cell: (_, banner) => Text(
                  banner.advertiserName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AdminColumn(
                label: 'Sıra',
                cell: (_, banner) => Text(banner.order.toString()),
              ),
              AdminColumn(
                label: 'Durum',
                cell: (_, banner) => Text(banner.isActive ? 'Aktif' : 'Pasif'),
              ),
              AdminColumn(
                label: 'Oluşturma',
                flex: 2,
                cell: (_, banner) => Text(
                  banner.createdAt == null
                      ? '—'
                      : DateFormat('dd.MM.yyyy HH:mm').format(banner.createdAt!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminBannerCard extends StatelessWidget {
  final BannerAd banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _AdminBannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Thumbnail
                Container(
                  width: 80,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: banner.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Icon(Icons.broken_image),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                // Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sponsor: ${banner.advertiserName.isNotEmpty ? banner.advertiserName : '-'}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hedef: ${banner.targetUrl}',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Active Switch
                Switch(
                  value: banner.isActive,
                  onChanged: onToggleActive,
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SÄ±ra: ${banner.order}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                if (banner.endDate != null)
                  Text(
                    'BitiÅŸ: ${banner.endDate!.day}.${banner.endDate!.month}.${banner.endDate!.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  )
                else
                  Text(
                    'SÃ¼resiz',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'DÃ¼zenle',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'Sil',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerAdFormSheet extends ConsumerStatefulWidget {
  final BannerAd? existingAd;

  const _BannerAdFormSheet({this.existingAd});

  @override
  ConsumerState<_BannerAdFormSheet> createState() => _BannerAdFormSheetState();
}

class _BannerAdFormSheetState extends ConsumerState<_BannerAdFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _advertiserController;
  late final TextEditingController _targetUrlController;
  late final TextEditingController _orderController;

  bool _isActive = true;
  String _imageUrl = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _uploadingImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ad = widget.existingAd;
    _titleController = TextEditingController(text: ad?.title ?? '');
    _advertiserController = TextEditingController(text: ad?.advertiserName ?? '');
    _targetUrlController = TextEditingController(text: ad?.targetUrl ?? '');
    _orderController = TextEditingController(text: (ad?.order ?? 0).toString());
    _isActive = ad?.isActive ?? true;
    _imageUrl = ad?.imageUrl ?? '';
    _startDate = ad?.startDate;
    _endDate = ad?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _advertiserController.dispose();
    _targetUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    setState(() => _uploadingImage = true);

    try {
      final storageService = ref.read(storageServiceProvider);
      final downloadUrl = await storageService.uploadBannerImage(pickedFile);
      setState(() {
        _imageUrl = downloadUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GÃ¶rsel yÃ¼klendi.')),
        );
      }
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: '_BannerAdFormSheetState._pickAndUploadImage',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LÃ¼tfen bir banner gÃ¶rseli yÃ¼kleyin veya URL girin.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final bannerService = ref.read(bannerAdServiceProvider);
      final orderVal = int.tryParse(_orderController.text.trim()) ?? 0;

      if (widget.existingAd != null) {
        final updated = widget.existingAd!.copyWith(
          title: _titleController.text.trim(),
          advertiserName: _advertiserController.text.trim(),
          imageUrl: _imageUrl,
          targetUrl: _targetUrlController.text.trim(),
          order: orderVal,
          isActive: _isActive,
          startDate: _startDate,
          endDate: _endDate,
        );
        await bannerService.updateBannerAd(updated);
      } else {
        final newAd = BannerAd(
          id: '',
          title: _titleController.text.trim(),
          advertiserName: _advertiserController.text.trim(),
          imageUrl: _imageUrl,
          targetUrl: _targetUrlController.text.trim(),
          order: orderVal,
          isActive: _isActive,
          startDate: _startDate,
          endDate: _endDate,
        );
        await bannerService.createBannerAd(newAd);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingAd != null ? 'Banner gÃ¼ncellendi.' : 'Banner eklendi.')),
        );
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: '_BannerAdFormSheetState._save');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingAd != null ? 'Banner DÃ¼zenle' : 'Yeni Banner Ekle',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image Preview / Upload Button
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _uploadingImage
                    ? const Center(child: CircularProgressIndicator())
                    : _imageUrl.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: _imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const Center(child: Text('GÃ¶rsel yÃ¼klenemedi')),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                    onPressed: _pickAndUploadImage,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickAndUploadImage,
                                icon: const Icon(Icons.upload_rounded),
                                label: const Text('GÃ¶rsel YÃ¼kle'),
                              ),
                            ],
                          ),
              ),

              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Banner BaÅŸlÄ±ÄŸÄ± *',
                  hintText: 'Ã–rn. Jolly Tur ile Yaz FÄ±rsatlarÄ±',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'BaÅŸlÄ±k gerekli' : null,
              ),

              const SizedBox(height: 12),

              // Advertiser Name Field
              TextFormField(
                controller: _advertiserController,
                decoration: const InputDecoration(
                  labelText: 'Reklamveren Firma AdÄ± *',
                  hintText: 'Ã–rn. Jolly Tur',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Reklamveren adÄ± gerekli' : null,
              ),

              const SizedBox(height: 12),

              // Target URL Field
              TextFormField(
                controller: _targetUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Hedef BaÄŸlantÄ± (URL) *',
                  hintText: 'https://www.jollytur.com',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Hedef URL gerekli' : null,
              ),

              const SizedBox(height: 12),

              // Order Number Field
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SÄ±ralama Ã–nceliÄŸi (0, 1, 2...)',
                  hintText: 'KÃ¼Ã§Ã¼k olan ilk gÃ¶sterilir',
                ),
              ),

              const SizedBox(height: 12),

              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _startDate == null
                            ? 'BaÅŸlangÄ±Ã§ Tarihi'
                            : '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(
                        _endDate == null
                            ? 'BitiÅŸ Tarihi (SÃ¼resiz)'
                            : '${_endDate!.day}.${_endDate!.month}.${_endDate!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Active Switch Row
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif YayÄ±n LansmanÄ±'),
                subtitle: const Text('Pasif yapÄ±lÄ±rsa anasayfada gizlenir'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.existingAd != null ? 'DeÄŸiÅŸiklikleri Kaydet' : 'Banner\'Ä± Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
