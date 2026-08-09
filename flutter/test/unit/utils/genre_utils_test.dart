import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/core/utils/genre_utils.dart';

void main() {
  group('splitGenres', () {
    test('empty string returns empty list', () {
      expect(splitGenres(''), []);
    });

    test('single genre returns single-element list', () {
      expect(splitGenres('Rock'), ['Rock']);
    });

    test('multiple genres split correctly', () {
      final result = splitGenres('Rock|||Jazz|||Blues');
      expect(result.length, 3);
      expect(result, ['Blues', 'Jazz', 'Rock']); // Sorted
    });

    test('duplicate genres are deduplicated', () {
      final result = splitGenres('Rock|||Jazz|||Rock');
      expect(result.length, 2);
      expect(result, ['Jazz', 'Rock']);
    });

    test('whitespace is trimmed', () {
      final result = splitGenres(' Rock ||| Jazz ||| Blues ');
      expect(result.length, 3);
      expect(result, ['Blues', 'Jazz', 'Rock']);
    });

    test('results are sorted alphabetically', () {
      final result = splitGenres('Zebra|||Apple|||Mango');
      expect(result, ['Apple', 'Mango', 'Zebra']);
    });

    test('excludes empty strings from splitting', () {
      final result = splitGenres('Rock||||||Jazz');
      expect(result.length, 2);
      expect(result, ['Jazz', 'Rock']);
    });

    test('handles genres with varying whitespace', () {
      final result = splitGenres('  Rock  |||    Jazz    |||Blues');
      expect(result.length, 3);
      expect(result, ['Blues', 'Jazz', 'Rock']);
    });
  });

  group('joinGenres', () {
    test('empty list returns empty string', () {
      expect(joinGenres([]), '');
    });

    test('single genre returns single genre', () {
      expect(joinGenres(['Rock']), 'Rock');
    });

    test('multiple genres join correctly', () {
      expect(joinGenres(['Rock', 'Jazz', 'Blues']), 'Rock|||Jazz|||Blues');
    });

    test('genres join in provided order', () {
      expect(joinGenres(['Zebra', 'Apple']), 'Zebra|||Apple');
    });
  });

  group('Round-trip: splitGenres and joinGenres', () {
    test('round-trip preserves genres (sorted)', () {
      final original = ['Rock', 'Jazz', 'Blues'];
      final joined = joinGenres(original);
      final split = splitGenres(joined);
      expect(split, ['Blues', 'Jazz', 'Rock']); // Sorted after split
    });

    test('round-trip with duplicates deduplicates', () {
      final original = ['Rock', 'Jazz', 'Rock'];
      final joined = joinGenres(original);
      final split = splitGenres(joined);
      expect(split, ['Jazz', 'Rock']);
    });

    test('round-trip from pipe-separated string', () {
      final original = 'Rock|||Jazz|||Blues';
      final split = splitGenres(original);
      final joined = joinGenres(split);
      final splitAgain = splitGenres(joined);
      expect(splitAgain, split);
      expect(splitAgain, ['Blues', 'Jazz', 'Rock']);
    });
  });
}
