import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_photo_controller.dart';
import '../core/api_client.dart';
import '../data/http/http_upload_repository.dart';
import '../data/photo_picker_service.dart';
import '../data/upload_repository.dart';
import '../models/brand_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/add_photo/commercial_consent_checkbox.dart';
import '../widgets/add_photo/gallery_tile.dart';
import '../widgets/add_photo/upload_progress_card.dart';

class AddPhotoScreen extends StatefulWidget {
  const AddPhotoScreen({
    super.key,
    required this.circleId,
    this.pickerService = const MockPhotoPickerService(),
    this.uploadRepository = const MockUploadRepository(),
    this.apiClient,
    this.brand,
  });

  final String circleId;
  final PhotoPickerService pickerService;
  final UploadRepository uploadRepository;
  final ApiClient? apiClient;

  /// Non-null when this circle is a branded circle — shows the commercial-use consent checkbox.
  final BrandProfile? brand;

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  late final PhotoPickerService _effectivePickerService =
      widget.apiClient != null ? const ImagePickerPhotoPickerService() : widget.pickerService;
  late final UploadRepository _effectiveUploadRepository =
      widget.apiClient != null ? HttpUploadRepository(widget.apiClient!) : widget.uploadRepository;
  late final AddPhotoController controller = Get.put(
    AddPhotoController(_effectivePickerService, _effectiveUploadRepository, widget.circleId),
    tag: 'add-photo-${widget.circleId}',
  );

  bool _commercialConsentAccepted = false;

  @override
  void initState() {
    super.initState();
    controller.pickFromGallery();
  }

  @override
  void dispose() {
    Get.delete<AddPhotoController>(tag: 'add-photo-${widget.circleId}');
    super.dispose();
  }

  Future<void> _confirmUpload() async {
    final success = await controller.upload(commercialConsent: _commercialConsentAccepted);
    if (success && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('İptal', style: AppTextStyles.labelLg.copyWith(color: colors.onSurfaceVariant)),
        ),
        leadingWidth: 80,
        title: Obx(() => Text('${controller.picked.length} seçildi', style: AppTextStyles.headlineSm.copyWith(color: colors.primary))),
        centerTitle: true,
        actions: [
          Obx(() => TextButton(
                onPressed: controller.picked.isEmpty || controller.uploading.value ? null : _confirmUpload,
                child: Text(
                  'Yükle',
                  style: AppTextStyles.labelLg.copyWith(color: controller.picked.isEmpty ? colors.outlineVariant : colors.secondary),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.picked.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Henüz fotoğraf seçmedin', style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: controller.pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeriden Seç'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: controller.captureFromCamera,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Kamerayla Çek'),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.xs),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: controller.picked.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.picked.length) {
                    return GestureDetector(
                      onTap: controller.pickFromGallery,
                      child: Container(
                        decoration: BoxDecoration(color: colors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.card)),
                        child: Icon(Icons.add, color: colors.onSurfaceVariant),
                      ),
                    );
                  }
                  final file = controller.picked[index];
                  return GalleryTile(file: file, onRemove: () => controller.remove(file));
                },
              ),
            ),
            if (widget.brand != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0),
                child: CommercialConsentCheckbox(
                  brand: widget.brand!,
                  value: _commercialConsentAccepted,
                  onChanged: (v) => setState(() => _commercialConsentAccepted = v),
                ),
              ),
            if (controller.uploading.value)
              UploadProgressCard(selectedCount: controller.picked.length, progress: controller.uploadFraction.value),
            if (controller.error.value != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(controller.error.value!, style: AppTextStyles.bodySm.copyWith(color: colors.error)),
              ),
          ],
        );
      }),
    );
  }
}
