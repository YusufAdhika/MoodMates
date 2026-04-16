import 'package:flutter_test/flutter_test.dart';
import 'package:moodmates/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores multiple child profiles and deletes one by id', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    final first = await storage.addProfile('Alya');
    final second = await storage.addProfile('Bima');
    await storage.setActiveProfileId(second.id);
    await storage.setPin('1234');

    expect(storage.loadAllProfiles().map((p) => p.childName), [
      'Alya',
      'Bima',
    ]);
    expect(storage.activeProfileId, second.id);
    expect(storage.validatePin('1234'), isTrue);
    expect(storage.validatePin('0000'), isFalse);

    final deleted = await storage.deleteProfile(first.id);

    expect(deleted, isTrue);
    expect(storage.loadAllProfiles().map((p) => p.childName), ['Bima']);
    expect(storage.activeProfileId, second.id);
  });
}
