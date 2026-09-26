import 'package:flutter_test/flutter_test.dart';
import 'package:no_retiene/util/email.dart';

void main() {
  test('un correo tiene forma de correo', () {
    expect(looksLikeEmail('manuel@gmail.com'), isTrue);
    expect(looksLikeEmail('  vale.rios@vinilo.test '), isTrue);
  });

  test('un @usuario o algo a medias no', () {
    expect(looksLikeEmail('manuel'), isFalse);
    expect(looksLikeEmail('@manuel'), isFalse);
    expect(looksLikeEmail('manuel@gmail'), isFalse);
    expect(looksLikeEmail('manuel@gmail.'), isFalse);
    expect(looksLikeEmail('manu el@gmail.com'), isFalse);
    expect(looksLikeEmail(''), isFalse);
  });
}
