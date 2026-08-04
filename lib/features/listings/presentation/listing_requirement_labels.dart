import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/listing_filters.dart';

String experienceLevelLabel(AppLocalizations l10n, ExperienceLevel level) =>
    switch (level) {
      ExperienceLevel.none => l10n.experienceNone,
      ExperienceLevel.underOneYear => l10n.experienceUnderOneYear,
      ExperienceLevel.oneToThreeYears => l10n.experienceOneToThreeYears,
      ExperienceLevel.threePlusYears => l10n.experienceThreePlusYears,
    };

String educationLevelLabel(AppLocalizations l10n, EducationLevel level) =>
    switch (level) {
      EducationLevel.none => l10n.educationNone,
      EducationLevel.primary => l10n.educationPrimary,
      EducationLevel.highSchool => l10n.educationHighSchool,
      EducationLevel.university => l10n.educationUniversity,
    };
