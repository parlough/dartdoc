// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:dartdoc/src/model/model.dart';
import 'package:dartdoc/src/package_config_provider.dart';
import 'package:dartdoc/src/package_meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'src/test_descriptor_utils.dart' as d;
import 'src/utils.dart';

void main() {
  // We can not use ExperimentalFeature.releaseVersion or even
  // ExperimentalFeature.experimentalReleaseVersion as these are set to null
  // even when partial analyzer implementations are available.
  final enhancedEnumsAllowed =
      VersionRange(min: Version.parse('2.17.0-0'), includeMin: true);
  const libraryName = 'enums';

  late PackageMetaProvider packageMetaProvider;
  late MemoryResourceProvider resourceProvider;
  late FakePackageConfigProvider packageConfigProvider;
  late String packagePath;

  Future<void> setUpPackage(
    PackageMetaProvider packageMetaProvider,
    String name, {
    String? pubspec,
    String? analysisOptions,
  }) async {
    packagePath = await d.createPackage(
      name,
      pubspec: pubspec,
      analysisOptions: analysisOptions,
      resourceProvider:
          packageMetaProvider.resourceProvider as MemoryResourceProvider,
    );

    packageConfigProvider =
        getTestPackageConfigProvider(packageMetaProvider.defaultSdkDir.path);
    packageConfigProvider.addPackageToConfigFor(
        packagePath, name, Uri.file('$packagePath/'));
  }

  Future<Library> bootPackageWithLibrary(String libraryContent) async {
    await d.dir('lib', [
      d.file('lib.dart', '''
library $libraryName;

$libraryContent
'''),
    ]).createInMemory(resourceProvider, packagePath);

    var packageGraph = await bootBasicPackage(
      packagePath,
      packageMetaProvider,
      packageConfigProvider,
    );
    return packageGraph.libraries.named(libraryName);
  }

  group('enums', () {
    const libraryName = 'enums';
    const placeholder = '%%__HTMLBASE_dartdoc_internal__%%';
    const linkPrefix = '$placeholder$libraryName';

    setUp(() async {
      packageMetaProvider = testPackageMetaProvider;
      resourceProvider =
          packageMetaProvider.resourceProvider as MemoryResourceProvider;
      await setUpPackage(packageMetaProvider, libraryName);
    });

    test('an enum is presented with a linked name', () async {
      var library = await bootPackageWithLibrary('enum E { one, two, three }');
      var eEnum = library.enums.named('E');

      expect(eEnum.linkedName, equals('<a href="$linkPrefix/E.html">E</a>'));
    });

    test('an enum has annotations', () async {
      var library = await bootPackageWithLibrary('''
class C {
  const C();
}

@C()
enum E { one, two, three }
''');
      var eEnum = library.enums.named('E');

      expect(eEnum.hasAnnotations, true);
      expect(eEnum.annotations, hasLength(1));
      expect(eEnum.annotations.single.linkedName,
          '<a href="$linkPrefix/C-class.html">C</a>');
    });

    test('an enum has a doc comment', () async {
      var library = await bootPackageWithLibrary('''
/// Doc comment for [E].
enum E { one, two, three }
''');
      var eEnum = library.enums.named('E');

      expect(eEnum.hasDocumentationComment, true);
      expect(eEnum.documentationComment, '/// Doc comment for [E].');
    });

    test('an enum value has a doc comment', () async {
      var library = await bootPackageWithLibrary('''
enum E {
  /// Doc comment for [E.one].
  one,
  two,
  three
}
''');
      var one = library.enums.named('E').constantFields.named('one');

      expect(one.hasDocumentationComment, true);
      expect(one.documentationComment, '/// Doc comment for [E.one].');
    });
  });

  group('enhanced enums', () {
    const placeholder = '%%__HTMLBASE_dartdoc_internal__%%';
    const linkPrefix = '$placeholder$libraryName';

    setUp(() async {
      packageMetaProvider = testPackageMetaProvider;
      resourceProvider =
          packageMetaProvider.resourceProvider as MemoryResourceProvider;
      await setUpPackage(
        packageMetaProvider,
        libraryName,
        pubspec: '''
name: enhanced_enums
version: 0.0.1
environment:
  sdk: '>=2.17.0-0 <3.0.0'
''',
        analysisOptions: '''
analyzer:
  enable-experiment:
    - enhanced-enums
''',
      );
    });

    test('an enum is presented with a linked name', () async {
      var library = await bootPackageWithLibrary('''
class C<T> {}

enum E<T> implements C<T> { one, two, three; }
''');
      var eEnum = library.enums.named('E');

      expect(eEnum.linkedName, '<a href="$linkPrefix/E.html">E</a>');
    });

    test('a generic enum is presented with linked type parameters', () async {
      var library = await bootPackageWithLibrary('''
class C<T> {}

enum E<T> implements C<T> { one, two, three; }
''');
      var eEnum = library.enums.named('E');

      expect(
        eEnum.linkedGenericParameters,
        '<span class="signature">&lt;<wbr><span class="type-parameter">T</span>&gt;</span>',
      );
    });

    test("an enhanced enum's methods are documented", () async {
      var library = await bootPackageWithLibrary('''
enum E {
  one, two, three;

  /// Doc comment.
  int method1(String p) => 7;
}
''');
      var method1 = library.enums.named('E').instanceMethods.named('method1');

      expect(method1.isInherited, false);
      expect(method1.isOperator, false);
      expect(method1.isStatic, false);
      expect(method1.isCallable, true);
      expect(method1.isDocumented, true);
      expect(
        method1.linkedName,
        '<a href="$linkPrefix/E/method1.html">method1</a>',
      );
      expect(method1.documentationComment, '/// Doc comment.');
    });

    test('a generic enum is presented with linked interfaces', () async {
      var library = await bootPackageWithLibrary('''
class C<T> {}

enum E<T> implements C<T> { one, two, three; }
''');
      var eEnum = library.enums.named('E');

      expect(eEnum.interfaces, isNotEmpty);
    }, skip: true /* passes with analyzer at HEAD on 2022-02-23 */);

    // TODO(srawlins): Add rendering tests.
    // * Fix interfaces test.
    // * Add tests for rendered supertypes HTML.
    // * Add tests for rendered interfaces HTML.
    // * Add tests for rendered mixins HTML.
    // * Add tests for rendered static members.
    // * Add tests for rendered fields.
    // * Add tests for rendered getters, setters, operators.
    // * Add tests for rendered field pages.
    // * Add tests for rendered generic enum values.
    // * Add tests for rendered constructors.

    // TODO(srawlins): Add referencing tests (`/// [Enum.method]` etc.)
    // * Add tests for referencing enum static members.
    // * Add tests for referencing enum getters, setters, operators, methods.
    // * Add tests for referencing constructors.
  }, skip: !enhancedEnumsAllowed.allows(platformVersion));
}