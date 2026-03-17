import 'package:pubdoc/src/get_command.dart';
import 'package:test/test.dart';

void main() {
  group('GetResult.format()', () {
    test('single package', () {
      final result = GetResult(
        packages: {
          'dio': PackageGetResult(
            documentation: '/project/.pubdoc/dio',
            source: '/pub-cache/dio-5.3.2',
            version: '5.3.x',
            cacheStatus: CacheStatus.miss,
          ),
        },
      );
      expect(result.format(), r'''
dio
  documentation: /project/.pubdoc/dio
  version:       5.3.x
  source:        /pub-cache/dio-5.3.2
  cache:         miss
''');
    });

    test('multiple packages are separated by a blank line', () {
      final result = GetResult(
        packages: {
          'dio': PackageGetResult(
            documentation: '/project/.pubdoc/dio',
            source: '/pub-cache/dio-5.3.2',
            version: '5.3.x',
            cacheStatus: CacheStatus.miss,
          ),
          'http': PackageGetResult(
            documentation: '/project/.pubdoc/http',
            source: '/pub-cache/http-1.2.0',
            version: '1.2.x',
            cacheStatus: CacheStatus.hit,
          ),
        },
      );
      expect(
        result.format(),
        equals(r'''
dio
  documentation: /project/.pubdoc/dio
  version:       5.3.x
  source:        /pub-cache/dio-5.3.2
  cache:         miss

http
  documentation: /project/.pubdoc/http
  version:       1.2.x
  source:        /pub-cache/http-1.2.0
  cache:         hit
'''),
      );
    });
  });
}
