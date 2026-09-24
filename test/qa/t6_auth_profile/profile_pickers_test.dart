import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/profile/presentation/widgets/intro_video_picker.dart';
import 'package:otelcim/features/profile/presentation/widgets/profile_photo_picker.dart';
import 'package:otelcim/shared/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
  });

  Widget wrapWithTheme(Widget child) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorageService),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('ProfilePhotoPicker Widget Tests', () {
    testWidgets('renders placeholder avatar and camera overlay when photoUrl is null', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          ProfilePhotoPicker(
            photoUrl: null,
            userId: 'user_photo_1',
            onPhotoUploaded: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('tapping picker opens modal bottom sheet with photo sources', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          ProfilePhotoPicker(
            photoUrl: null,
            userId: 'user_photo_1',
            onPhotoUploaded: (_) {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
      // 'Fotoğrafı Kaldır' should not be shown when there is no existing photo
      expect(find.text('Fotoğrafı Kaldır'), findsNothing);
    });

    testWidgets('shows remove photo option in bottom sheet when photoUrl is present', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          ProfilePhotoPicker(
            photoUrl: 'https://example.com/profile.jpg',
            userId: 'user_photo_1',
            onPhotoUploaded: (_) {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Fotoğrafı Kaldır'), findsOneWidget);
    });
  });

  group('IntroVideoPicker Widget Tests', () {
    testWidgets('renders upload prompt when no video is present', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          IntroVideoPicker(
            videoUrl: null,
            userId: 'user_vid_1',
            onVideoChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('15-30 Saniyelik Tanıtım Videosu'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Video Yükle (15-30sn)'), findsOneWidget);
    });

    testWidgets('renders action buttons when video is present and confirms deletion', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          IntroVideoPicker(
            videoUrl: 'https://example.com/intro.mp4',
            userId: 'user_vid_1',
            onVideoChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Tanıtım Videosunu İzle'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Değiştir'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Kaldır'), findsOneWidget);

      // Tap 'Kaldır' to open confirmation dialog
      await tester.tap(find.widgetWithText(OutlinedButton, 'Kaldır'));
      await tester.pumpAndSettle();

      expect(find.text('Videoyu Kaldır'), findsOneWidget);
      expect(find.text('Tanıtım videosunu silmek istediğinize emin misiniz?'), findsOneWidget);
      expect(find.text('Vazgeç'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(find.text('Videoyu Kaldır'), findsNothing);
      verifyNever(() => mockStorageService.deleteIntroVideo(any()));
    });
  });
}
