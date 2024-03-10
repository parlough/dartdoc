// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdoc/src/model/enum.dart';

abstract class EnumFieldRenderer {
  String renderValue(EnumField field);

  String renderLinkedName(EnumField field);
}

class EnumFieldRendererHtml implements EnumFieldRenderer {
  const EnumFieldRendererHtml();

  @override
  String renderValue(EnumField field) => field.name == 'values'
      ? 'const List&lt;<wbr>'
          '<span class="type-parameter">${field.enclosingElement.name}</span>'
          '&gt;'
      : field.constantValue;

  @override
  String renderLinkedName(EnumField field) {
    var cssClass = field.isDeprecated ? ' class="deprecated"' : '';
    return '<a$cssClass href="${field.href}#${field.htmlId}">${field.name}</a>';
  }
}
