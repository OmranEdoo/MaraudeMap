import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maraude_map/config/current_session.dart';
import 'package:maraude_map/screens/login_screen.dart';
import 'package:maraude_map/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final transparentImage = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7Z0foAAAAASUVORK5CYII=',
    );
    final assetManifest = const StandardMessageCodec().encodeMessage(
      <String, List<Map<String, Object?>>>{
        'assets/images/logo.png': <Map<String, Object?>>[
          <String, Object?>{'asset': 'assets/images/logo.png'},
        ],
      },
    );
    final assetManifestJson = ByteData.sublistView(
      Uint8List.fromList(
        utf8.encode(
          '{"assets/images/logo.png":["assets/images/logo.png"]}',
        ),
      ),
    );
    final emptyJsonObject = ByteData.sublistView(
      Uint8List.fromList(utf8.encode('{}')),
    );
    final emptyJsonArray = ByteData.sublistView(
      Uint8List.fromList(utf8.encode('[]')),
    );
    final transparentImageData = ByteData.sublistView(
      Uint8List.fromList(transparentImage),
    );

    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());

        switch (key) {
          case 'AssetManifest.bin':
            return assetManifest;
          case 'AssetManifest.json':
            return assetManifestJson;
          case 'FontManifest.json':
            return emptyJsonArray;
          case 'assets/images/logo.png':
            return transparentImageData;
          default:
            return emptyJsonObject;
        }
      },
    );
  });

  tearDown(() {
    CurrentSession.resetToDemo();
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      MaterialApp(
        home: screen,
      ),
    );
    await tester.pump();
  }

  Future<void> finishTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
    'annuler l inscription ferme le dialogue sans exception Flutter',
    (WidgetTester tester) async {
      await pumpScreen(tester, const LoginScreen());

      await tester.tap(find.text('S\'inscrire'));
      await finishTransition(tester);

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await finishTransition(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'un mot de passe invalide garde le dialogue ouvert et preserve les champs',
    (WidgetTester tester) async {
      await pumpScreen(tester, const LoginScreen());

      await tester.tap(find.text('S\'inscrire'));
      await finishTransition(tester);

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(0), 'Alice Martin');
      await tester.enterText(dialogFields.at(1), 'Association Solidaire');
      await tester.enterText(dialogFields.at(2), 'alice@example.com');
      await tester.enterText(dialogFields.at(3), '123');
      await tester.enterText(dialogFields.at(4), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Creer le compte'));
      await finishTransition(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Le mot de passe doit contenir au moins 6 caracteres.'),
        findsOneWidget,
      );

      final fields = tester.widgetList<TextField>(dialogFields).toList();
      expect(fields[0].controller?.text, 'Alice Martin');
      expect(fields[1].controller?.text, 'Association Solidaire');
      expect(fields[2].controller?.text, 'alice@example.com');
      expect(fields[3].controller?.text, '123');
      expect(fields[4].controller?.text, '123');
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'envoyer mot de passe oublie ne declenche pas d exception framework',
    (WidgetTester tester) async {
      await pumpScreen(tester, const LoginScreen());

      await tester.tap(find.text('Mot de passe oublié ?'));
      await finishTransition(tester);

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.first, 'test@example.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Envoyer'));
      await finishTransition(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'valider mon email reste accessible sous l inscription',
    (WidgetTester tester) async {
      await pumpScreen(tester, const LoginScreen());

      expect(find.text('Valider mon email'), findsOneWidget);

      await tester.tap(find.text('Valider mon email'));
      await finishTransition(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Code de confirmation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'le profil peut etre modifie en mode local',
    (WidgetTester tester) async {
      CurrentSession.resetToDemo();

      await pumpScreen(tester, const ProfileScreen());

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await finishTransition(tester);

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(0), 'Alice Martin');
      await tester.enterText(dialogFields.at(1), 'alice@example.com');
      await tester.enterText(dialogFields.at(2), 'Association Solidaire');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
      await finishTransition(tester);

      expect(CurrentSession.displayName, 'Alice Martin');
      expect(CurrentSession.email, 'alice@example.com');
      expect(CurrentSession.associationName, 'Association Solidaire');
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('Association Solidaire'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'un email de profil invalide garde le dialogue ouvert',
    (WidgetTester tester) async {
      CurrentSession.resetToDemo();

      await pumpScreen(tester, const ProfileScreen());

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await finishTransition(tester);

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(0), 'Alice Martin');
      await tester.enterText(dialogFields.at(1), 'alice-at-example.com');
      await tester.enterText(dialogFields.at(2), 'Association Solidaire');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
      await finishTransition(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Renseignez un email valide.'), findsOneWidget);

      final fields = tester.widgetList<TextField>(dialogFields).toList();
      expect(fields[0].controller?.text, 'Alice Martin');
      expect(fields[1].controller?.text, 'alice-at-example.com');
      expect(fields[2].controller?.text, 'Association Solidaire');
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
