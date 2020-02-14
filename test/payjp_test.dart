/*
 * Copyright (c) 2020 PAY, Inc.
 *
 * Use of this source code is governed by a MIT License that can by found in the LICENSE file.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payjp_flutter/payjp_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final log = <MethodCall>[];
  setUp(() {
    Payjp.channel.setMockMethodCallHandler((methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'isApplePayAvailable':
          return Future.value(true);
      }
      return null;
    });
    log.clear();
  });

  group('initialize', () {
    test('init with all params', () async {
      final publicKey = 'pk_test_123';
      await Payjp.init(
          publicKey: publicKey, debugEnabled: true, locale: Locale('ja'));
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'initialize',
            arguments: <String, dynamic>{
              'publicKey': publicKey,
              'debugEnabled': true,
              'locale': 'ja',
            },
          ),
        ],
      );
    });
    test('init with pk only', () async {
      const publicKey = 'pk_test_123';
      await Payjp.init(publicKey: publicKey);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'initialize',
            arguments: <String, dynamic>{
              'publicKey': publicKey,
              'debugEnabled': false,
              'locale': null,
            },
          ),
        ],
      );
    });
  });

  group('card form', () {
    test('start card form', () async {
      await Payjp.startCardForm();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'startCardForm',
            arguments: <String, dynamic>{
              'tenantId': null,
            },
          ),
        ],
      );
    });
    test('start card form with tenant', () async {
      const tenantId = "ten_xxx";
      await Payjp.startCardForm(tenantId: tenantId);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'startCardForm',
            arguments: <String, dynamic>{
              'tenantId': tenantId,
            },
          ),
        ],
      );
    });
    test('complete card form', () async {
      await Payjp.completeCardForm();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'completeCardForm',
            arguments: null,
          ),
        ],
      );
    });
    test('show error on card form', () async {
      const message = 'Oops!';
      await Payjp.showTokenProcessingError(message);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'showTokenProcessingError',
            arguments: <String, dynamic>{
              'message': message,
            },
          ),
        ],
      );
    });
    test('set ios card form style', () async {
      await Payjp.setIOSCardFormStyle(
          labelTextColor: Color(0xFFFFFFF0),
          inputTextColor: Color(0xFFFFFFF1),
          errorTextColor: Color(0xFFFFFFF2),
          tintColor: Color(0xFFFFFFF3),
          inputFieldBackgroundColor: Color(0xFFFFFFF4),
          submitButtonColor: Color(0xFFFFFFF5));
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'setFormStyle',
            arguments: <String, dynamic>{
              'labelTextColor': 0xFFFFFFF0,
              'inputTextColor': 0xFFFFFFF1,
              'errorTextColor': 0xFFFFFFF2,
              'tintColor': 0xFFFFFFF3,
              'inputFieldBackgroundColor': 0xFFFFFFF4,
              'submitButtonColor': 0xFFFFFFF5,
            },
          ),
        ],
      );
    });
    test('set ios card form style with nothing', () async {
      await Payjp.setIOSCardFormStyle();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'setFormStyle',
            arguments: <String, dynamic>{
              'labelTextColor': null,
              'inputTextColor': null,
              'errorTextColor': null,
              'tintColor': null,
              'inputFieldBackgroundColor': null,
              'submitButtonColor': null,
            },
          ),
        ],
      );
    });
    test('listen card form canceled', () async {
      final handler = Completer<void>();
      await Payjp.startCardForm(onCardFormCanceledCallback: handler.complete);
      await FakeNativeMessenger.sendMessage(MethodCall(
        'onCardFormCanceled',
        null,
      ));
      expect(handler.future, completion(isNull));
    });
    test('listen card form completed', () async {
      final handler = Completer<void>();
      await Payjp.startCardForm(onCardFormCompletedCallback: handler.complete);
      await FakeNativeMessenger.sendMessage(MethodCall(
        'onCardFormCompleted',
        null,
      ));
      expect(handler.future, completion(isNull));
    });
    test('listen card form produced token', () async {
      final handler = Completer<String>();
      await Payjp.startCardForm(onCardFormProducedTokenCallback: (token) {
        handler.complete(token.id);
        return CallbackResultOk();
      });
      const tokenId = "tok_xxx";
      final token = Token()..id = tokenId;
      await FakeNativeMessenger.sendMessage(MethodCall(
        'onCardFormProducedToken',
        token.toJson(),
      ));
      expect(handler.future, completion(equals(tokenId)));
    });
  });

  group('apple pay', () {
    test('is apple pay available', () async {
      final available = await Payjp.isApplePayAvailable();
      expect(available, isTrue);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'isApplePayAvailable',
            arguments: null,
          ),
        ],
      );
    });
    test('make apple pay token', () async {
      await Payjp.makeApplePayToken(
          appleMerchantId: 'merchant.example',
          currencyCode: 'JPY',
          countryCode: 'JP',
          summaryItemLabel: 'item',
          summaryItemAmount: '1,000',
          requiredBillingAddress: true);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'makeApplePayToken',
            arguments: <String, dynamic>{
              'appleMerchantId': 'merchant.example',
              'currencyCode': "JPY",
              'countryCode': 'JP',
              'summaryItemLabel': 'item',
              'summaryItemAmount': '1,000',
              'requiredBillingAddress': true
            },
          ),
        ],
      );
    });
    test('listen apple pay completed', () async {
      final handler = Completer<void>();
      await Payjp.makeApplePayToken(
          appleMerchantId: 'merchant.example',
          currencyCode: 'JPY',
          countryCode: 'JP',
          summaryItemLabel: 'item',
          summaryItemAmount: '1,000',
          requiredBillingAddress: true,
          onApplePayCompletedCallback: handler.complete);
      await FakeNativeMessenger.sendMessage(MethodCall(
        'onApplePayCompleted',
        null,
      ));
      expect(handler.future, completion(isNull));
    });
    test('listen apple pay failed request token', () async {
      final handler = Completer<ErrorInfo>();
      await Payjp.makeApplePayToken(
          appleMerchantId: 'merchant.example',
          currencyCode: 'JPY',
          countryCode: 'JP',
          summaryItemLabel: 'item',
          summaryItemAmount: '1,000',
          requiredBillingAddress: true,
          onApplePayFailedRequestTokenCallback: (error) {
            handler.complete(error);
            return CallbackResultError(error.errorMessage);
          });
      final errorInfo = ErrorInfo((b) => b
        ..errorType = 'applepay'
        ..errorMessage = 'Oops!'
        ..errorCode = 0);
      await FakeNativeMessenger.sendMessage(
          MethodCall('onApplePayFailedRequestToken', <String, dynamic>{
        'errorType': errorInfo.errorType,
        'errorMessage': errorInfo.errorMessage,
        'errorCode': errorInfo.errorCode,
      }));
      expect(handler.future, completion(equals(errorInfo)));
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'makeApplePayToken',
            arguments: <String, dynamic>{
              'appleMerchantId': 'merchant.example',
              'currencyCode': "JPY",
              'countryCode': 'JP',
              'summaryItemLabel': 'item',
              'summaryItemAmount': '1,000',
              'requiredBillingAddress': true
            },
          ),
          isMethodCall(
            'completeApplePay',
            arguments: <String, dynamic>{
              'isSuccess': false,
              'errorMessage': errorInfo.errorMessage,
            },
          ),
        ],
      );
    });
    test('listen apple pay produced token, processing succss', () async {
      final handler = Completer<String>();
      await Payjp.makeApplePayToken(
          appleMerchantId: 'merchant.example',
          currencyCode: 'JPY',
          countryCode: 'JP',
          summaryItemLabel: 'item',
          summaryItemAmount: '1,000',
          requiredBillingAddress: true,
          onApplePayProducedTokenCallback: (token) {
            handler.complete(token.id);
            return CallbackResultOk();
          });
      const tokenId = "tok_xxx";
      final token = Token()..id = tokenId;
      await FakeNativeMessenger.sendMessage(MethodCall(
        'onApplePayProducedToken',
        token.toJson(),
      ));
      expect(handler.future, completion(equals(tokenId)));
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'makeApplePayToken',
            arguments: <String, dynamic>{
              'appleMerchantId': 'merchant.example',
              'currencyCode': "JPY",
              'countryCode': 'JP',
              'summaryItemLabel': 'item',
              'summaryItemAmount': '1,000',
              'requiredBillingAddress': true
            },
          ),
          isMethodCall(
            'completeApplePay',
            arguments: <String, dynamic>{
              'isSuccess': true,
              'errorMessage': null,
            },
          ),
        ],
      );
    });
    test('listen apple pay produced token, processing failure', () async {
      final handler = Completer<String>();
      final message = 'Oops!';
      await Payjp.makeApplePayToken(
          appleMerchantId: 'merchant.example',
          currencyCode: 'JPY',
          countryCode: 'JP',
          summaryItemLabel: 'item',
          summaryItemAmount: '1,000',
          requiredBillingAddress: true,
          onApplePayProducedTokenCallback: (token) {
            handler.complete(token.id);
            return CallbackResultError(message);
          });
      const tokenId = "tok_xxx";
      final token = Token()..id = tokenId;
      await FakeNativeMessenger.sendMessage(MethodCall(
        'onApplePayProducedToken',
        token.toJson(),
      ));
      expect(handler.future, completion(equals(tokenId)));
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'makeApplePayToken',
            arguments: <String, dynamic>{
              'appleMerchantId': 'merchant.example',
              'currencyCode': "JPY",
              'countryCode': 'JP',
              'summaryItemLabel': 'item',
              'summaryItemAmount': '1,000',
              'requiredBillingAddress': true
            },
          ),
          isMethodCall(
            'completeApplePay',
            arguments: <String, dynamic>{
              'isSuccess': false,
              'errorMessage': message,
            },
          ),
        ],
      );
    });
  });
}

class FakeNativeMessenger {
  static Future<void> sendMessage(MethodCall methodCall) async {
    final codec = const StandardMethodCodec();
    final data = codec.encodeMethodCall(methodCall);
    await ServicesBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(Payjp.channel.name, data, (data) {});
  }
}
