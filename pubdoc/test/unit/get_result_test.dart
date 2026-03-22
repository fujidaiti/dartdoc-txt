import 'package:pubdoc/src/get_command.dart';
import 'package:test/test.dart';

void main() {
  group('GetResult.format()', () {
    test('single package', () {
      const result = GetResult(
        packages: {
          'dio': PackageGetResult(
            documentation: '/project/.pubdoc/dio',
            source: '/pub-cache/dio-5.3.2',
            version: '5.3.x',
            cacheStatus: CacheStatus.miss,
          ),
        },
      );
      expect(result.format(), '''
dio
  version:       5.3.x
  documentation: /project/.pubdoc/dio
  source:        /pub-cache/dio-5.3.2
  cache:         miss
''');
    });

    test('multiple packages are separated by a blank line', () {
      const result = GetResult(
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
        equals('''
dio
  version:       5.3.x
  documentation: /project/.pubdoc/dio
  source:        /pub-cache/dio-5.3.2
  cache:         miss

http
  version:       1.2.x
  documentation: /project/.pubdoc/http
  source:        /pub-cache/http-1.2.0
  cache:         hit
'''),
      );
    });
  });
}
