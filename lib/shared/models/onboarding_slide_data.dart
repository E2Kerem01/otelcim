import 'package:flutter/material.dart';

/// Onboarding slide data model
///
/// Represents the content for a single onboarding slide including:
/// - Title and description text
/// - Icon to display
///
/// Includes static constants for all onboarding slides shown to new users.
class OnboardingSlideData {
  /// Slide title
  final String title;

  /// Slide description/body text
  final String description;

  /// Icon to display on the slide
  final IconData icon;

  /// Creates an OnboardingSlideData instance
  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
  });

  /// Static list of all onboarding slides
  ///
  /// These slides introduce new users to Otelcim's key features:
  /// 1. Browse jobs by category
  /// 2. Direct messaging with employers
  /// 3. Post hotel job openings
  static const List<OnboardingSlideData> slides = [
    OnboardingSlideData(
      title: 'Kategorilere Göre İş İlanlarına Göz Atın',
      description:
          'Otel sektöründeki binlerce iş ilanını kategorilere göre kolayca inceleyin. Mutfak, ön büro, kat hizmetleri ve daha fazlası!',
      icon: Icons.search,
    ),
    OnboardingSlideData(
      title: 'İşverenlere Doğrudan Mesaj Gönderin',
      description:
          'Her ilan için ayrı sohbet özelliği ile işverenlere anında ulaşın. Sorularınızı sorun, detayları öğrenin.',
      icon: Icons.chat_bubble_outline,
    ),
    OnboardingSlideData(
      title: 'Otelinizin İş İlanlarını Yayınlayın',
      description:
          'İşveren misiniz? Otelinizin açık pozisyonlarını kolayca yayınlayın ve nitelikli adaylarla hemen iletişime geçin.',
      icon: Icons.work_outline,
    ),
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingSlideData &&
        other.title == title &&
        other.description == description &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      description,
      icon,
    );
  }

  @override
  String toString() {
    return 'OnboardingSlideData(title: $title, description: $description, icon: $icon)';
  }
}
