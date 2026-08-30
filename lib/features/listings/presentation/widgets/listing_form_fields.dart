import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/categories.dart';
import '../../../../shared/constants/listing_filters.dart';
import '../../../discovery/domain/tourism_region.dart';
import '../listing_requirement_labels.dart';
import '../season_utils.dart';

/// Field widgets shared between [CreateListingScreen] and [EditListingScreen]
/// (see those files) to avoid duplicating the same dropdown/field markup in
/// both ~900-line screens. Each widget is a thin, stateless wrapper around
/// the exact form field markup that used to be inline in both screens —
/// state (controllers, selected values) still lives in the parent screen.

/// Bold section label above a form field. Pass [isRequired] to append a red
/// asterisk, matching the "* işaretli alanlar zorunludur" convention on the
/// create/edit listing forms.
class ListingFieldLabel extends StatelessWidget {
  const ListingFieldLabel(this.label, {super.key, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);
    if (!isRequired) return Text(label, style: boldStyle);
    return Text.rich(
      TextSpan(
        text: label,
        style: boldStyle,
        children: [
          TextSpan(
            text: ' *',
            style: boldStyle.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-line hint explaining the red asterisk, shown once near the top of the
/// create/edit listing forms.
class RequiredFieldsLegend extends StatelessWidget {
  const RequiredFieldsLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '* ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        Text(
          'işaretli alanlar zorunludur',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class ListingTextFormField extends StatelessWidget {
  const ListingTextFormField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: (hintText == null && labelText == null)
          ? const InputDecoration()
          : InputDecoration(hintText: hintText, labelText: labelText),
      validator: validator,
    );
  }
}

class ListingCategoryDropdown extends StatelessWidget {
  const ListingCategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ListingCategory? value;
  final void Function(ListingCategory?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ListingCategory>(
      initialValue: value,
      items: ListingCategory.values
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(listingCategoryLabels[c]!),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class TourismRegionDropdown extends StatelessWidget {
  const TourismRegionDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final void Function(String?) onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(AppLocalizations.of(context)!.regionSelectHint),
      items: tourismRegions
          .map(
            (region) => DropdownMenuItem(
              value: region.id,
              child: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? region.nameEn
                    : region.nameTr,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class TourismCityDropdown extends StatelessWidget {
  const TourismCityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final void Function(String?) onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: const Text('Şehir seçin'),
      items: turkishTourismCities
          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class EmploymentTypeDropdown extends StatelessWidget {
  const EmploymentTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.showHint = false,
  });

  final EmploymentType? value;
  final void Function(EmploymentType?) onChanged;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<EmploymentType>(
      initialValue: value,
      hint: showHint ? const Text('Çalışma tipi seçin') : null,
      items: EmploymentType.values
          .map(
            (type) =>
                DropdownMenuItem(value: type, child: Text(type.label)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class ExperienceLevelDropdown extends StatelessWidget {
  const ExperienceLevelDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ExperienceLevel? value;
  final void Function(ExperienceLevel?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<ExperienceLevel?>(
      initialValue: value,
      items: [
        DropdownMenuItem<ExperienceLevel?>(
          value: null,
          child: Text(l10n.optionalNotSpecified),
        ),
        ...ExperienceLevel.values.map(
          (level) => DropdownMenuItem<ExperienceLevel?>(
            value: level,
            child: Text(experienceLevelLabel(l10n, level)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class EducationLevelDropdown extends StatelessWidget {
  const EducationLevelDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EducationLevel? value;
  final void Function(EducationLevel?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<EducationLevel?>(
      initialValue: value,
      items: [
        DropdownMenuItem<EducationLevel?>(
          value: null,
          child: Text(l10n.optionalNotSpecified),
        ),
        ...EducationLevel.values.map(
          (level) => DropdownMenuItem<EducationLevel?>(
            value: level,
            child: Text(educationLevelLabel(l10n, level)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Season dropdown plus the conditional contract start/end date row shown
/// only for seasonal contracts.
class SeasonAndContractDatesSection extends StatelessWidget {
  const SeasonAndContractDatesSection({
    super.key,
    required this.season,
    required this.onSeasonChanged,
    required this.contractStartDate,
    required this.contractEndDate,
    required this.onPickContractDate,
  });

  final String? season;
  final void Function(String?) onSeasonChanged;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final void Function({required bool isStart}) onPickContractDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: season,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.seasonNone),
            ),
            ...listingSeasonValues.map(
              (s) => DropdownMenuItem<String?>(
                value: s,
                child: Text(listingSeasonLabel(l10n, s)),
              ),
            ),
          ],
          onChanged: onSeasonChanged,
        ),
        if (isSeasonalContract(season)) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onPickContractDate(isStart: true),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${l10n.contractStartDateLabel}: ${formatContractDate(contractStartDate, l10n)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onPickContractDate(isStart: false),
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(
                    '${l10n.contractEndDateLabel}: ${formatContractDate(contractEndDate, l10n)}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Min/max salary (TL) fields, cross-validated against each other.
class SalaryRangeFields extends StatelessWidget {
  const SalaryRangeFields({
    super.key,
    required this.minController,
    required this.maxController,
  });

  final TextEditingController minController;
  final TextEditingController maxController;

  String? _validator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) return 'Geçerli tutar girin';
    final min = int.tryParse(minController.text.trim());
    final max = int.tryParse(maxController.text.trim());
    if (min != null && max != null && min > max) return 'Aralığı kontrol edin';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: minController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'En düşük maaş (TL)'),
            validator: _validator,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: maxController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'En yüksek maaş (TL)',
            ),
            validator: _validator,
          ),
        ),
      ],
    );
  }
}

/// Collapsible "staff housing" section: room type, amenities, meals, photos.
class ListingHousingSection extends StatelessWidget {
  const ListingHousingSection({
    super.key,
    required this.roomType,
    required this.onRoomTypeChanged,
    required this.hasAc,
    required this.onHasAcChanged,
    required this.hasWifi,
    required this.onHasWifiChanged,
    required this.mealsIncludedInitialValue,
    required this.onMealsIncludedChanged,
    required this.photoCount,
    required this.onAddPhotos,
  });

  final String? roomType;
  final void Function(String?) onRoomTypeChanged;
  final bool hasAc;
  final void Function(bool) onHasAcChanged;
  final bool hasWifi;
  final void Function(bool) onHasWifiChanged;
  final String? mealsIncludedInitialValue;
  final void Function(String) onMealsIncludedChanged;
  final int photoCount;
  final VoidCallback? onAddPhotos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(l10n.housingAddTitle),
      leading: const Icon(Icons.home_work_outlined),
      children: [
        DropdownButtonFormField<String?>(
          initialValue: roomType,
          decoration: InputDecoration(labelText: l10n.housingRoomType),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.optionalNotSpecified),
            ),
            DropdownMenuItem(
              value: 'single',
              child: Text(l10n.housingSingleRoom),
            ),
            DropdownMenuItem(
              value: 'shared',
              child: Text(l10n.housingSharedRoom),
            ),
          ],
          onChanged: onRoomTypeChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.housingHasAc),
          value: hasAc,
          onChanged: onHasAcChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.housingHasWifi),
          value: hasWifi,
          onChanged: onHasWifiChanged,
        ),
        TextFormField(
          initialValue: mealsIncludedInitialValue,
          decoration: InputDecoration(labelText: l10n.housingMealsIncluded),
          keyboardType: TextInputType.number,
          onChanged: onMealsIncludedChanged,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add_photo_alternate_outlined),
          title: Text(l10n.housingPhotos),
          subtitle: Text('$photoCount/5'),
          onTap: photoCount < 5 ? onAddPhotos : null,
        ),
      ],
    );
  }
}

/// Submit button with an inline loading spinner, used by both the create and
/// edit listing forms (with different labels/actions).
class ListingSubmitButton extends StatelessWidget {
  const ListingSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.label,
    required this.onPressed,
  });

  final bool isSubmitting;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
