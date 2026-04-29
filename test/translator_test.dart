import 'dart:convert';

import 'package:flutter_translate_localizer/src/translator/json_translator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Builds a fake Google Translate response body for [translated].
String _fakeResponse(String translated) => jsonEncode([
      [
        [translated, 'original', null, null, 10]
      ],
      null,
      'en',
    ]);

http.Client _mockClient(String translated) => MockClient((request) async {
      return http.Response(_fakeResponse(translated), 200);
    });

http.Client _errorClient(int statusCode) => MockClient((request) async {
      return http.Response('error', statusCode);
    });

void main() {
  group('JsonTranslator.translateJson', () {
    test('translates top-level string values', () async {
      final client = MockClient((request) async {
        final q = request.url.queryParameters['q']!;
        final map = {'Hello': 'Hola', 'Goodbye': 'Adiós'};
        return http.Response(_fakeResponse(map[q] ?? q), 200);
      });

      final translator = JsonTranslator(client: client);
      final result = await translator.translateJson(
        {'hello': 'Hello', 'goodbye': 'Goodbye'},
        'en',
        'es',
      );

      expect(result['hello'], 'Hola');
      expect(result['goodbye'], 'Adiós');
      translator.close();
    });

    test('translates nested maps recursively', () async {
      final translator = JsonTranslator(client: _mockClient('Traducido'));
      final result = await translator.translateJson(
        {
          'level1': {'level2': 'text'},
        },
        'en',
        'es',
      );

      expect((result['level1'] as Map)['level2'], 'Traducido');
      translator.close();
    });

    test('translates string items inside lists', () async {
      final translator = JsonTranslator(client: _mockClient('元素'));
      final result = await translator.translateJson(
        {
          'items': ['item1', 'item2']
        },
        'en',
        'zh',
      );

      expect((result['items'] as List).first, '元素');
      translator.close();
    });

    test('leaves non-string leaf values unchanged', () async {
      // Client should never be called for non-string values.
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response(_fakeResponse('x'), 200);
      });

      final translator = JsonTranslator(client: client);
      final result = await translator.translateJson(
        {'count': 42, 'active': true, 'nothing': null},
        'en',
        'es',
      );

      expect(result['count'], 42);
      expect(result['active'], true);
      expect(result['nothing'], isNull);
      expect(callCount, 0);
      translator.close();
    });

    test('leaves empty strings unchanged without an HTTP call', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response(_fakeResponse('x'), 200);
      });

      final translator = JsonTranslator(client: client);
      final result = await translator.translateJson({'key': ''}, 'en', 'es');

      expect(result['key'], '');
      expect(callCount, 0);
      translator.close();
    });

    test('throws HttpException on non-200 status', () async {
      final translator = JsonTranslator(client: _errorClient(503));

      await expectLater(
        translator.translateJson({'key': 'value'}, 'en', 'es'),
        throwsA(isA<Exception>()),
      );
      translator.close();
    });
  });

  group('JsonTranslator response parsing', () {
    test('concatenates multiple translation fragments', () async {
      final multiFragment = jsonEncode([
        [
          ['Hola', 'Hello'],
          [' ', ' '],
          ['mundo', 'world'],
        ],
        null,
        'en',
      ]);

      final client = MockClient(
        (request) async => http.Response(multiFragment, 200),
      );

      final translator = JsonTranslator(client: client);
      final result = await translator.translateJson(
        {'greeting': 'Hello world'},
        'en',
        'es',
      );
      expect(result['greeting'], 'Hola mundo');
      translator.close();
    });
  });
}
