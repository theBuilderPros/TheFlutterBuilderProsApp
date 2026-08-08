import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:the_builder_studio/app/core/base/base_controller.dart';
import 'package:the_builder_studio/app/services/mini_app_asset_server.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MiniAppHostController extends BaseController {
  final MiniAppAssetServer _server = MiniAppAssetServer();

  final RxBool miniAppOpen = false.obs;
  final RxString hostStatus = 'Ready'.obs;
  final Rxn<Uri> miniAppUrl = Rxn<Uri>();

  late final WebViewController webViewController;

  @override
  void onInit() {
    super.onInit();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterHost',
        onMessageReceived: handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => injectBridge()),
      );
  }

  @override
  void onClose() {
    unawaited(_server.stop());
    super.onClose();
  }

  Future<void> openMiniApp() async {
    showLoading();
    try {
      final url = miniAppUrl.value ?? await _server.start();
      miniAppUrl.value = url;
      hostStatus.value = 'QuickPay opened';
      miniAppOpen.value = true;
      await webViewController.loadRequest(url);
    } finally {
      hideLoading();
    }
  }

  void closeMiniApp() {
    hostStatus.value = 'Ready';
    miniAppOpen.value = false;
  }

  Future<void> reloadMiniApp() async {
    await webViewController.reload();
  }

  Future<void> injectBridge() async {
    await webViewController.runJavaScript('''
      window.SuperAppBridge = {
        call: function(action, payload) {
          return new Promise(function(resolve) {
            var requestId = 'req_' + Date.now() + '_' + Math.random().toString(16).slice(2);
            window.__superAppCallbacks = window.__superAppCallbacks || {};
            window.__superAppCallbacks[requestId] = { resolve: resolve };
            FlutterHost.postMessage(JSON.stringify({
              requestId: requestId,
              action: action,
              payload: payload || {}
            }));
          });
        }
      };
    ''');
  }

  Future<void> handleBridgeMessage(JavaScriptMessage message) async {
    final request = jsonDecode(message.message) as Map<String, dynamic>;
    final requestId = request['requestId'] as String;
    final action = request['action'] as String;
    final payload = (request['payload'] as Map?)?.cast<String, dynamic>() ?? {};

    hostStatus.value = _statusLabel(action);

    final response = await _runHostAction(action, payload);
    final encoded = jsonEncode(response);

    await webViewController.runJavaScript('''
      (function() {
        var callback = window.__superAppCallbacks && window.__superAppCallbacks['$requestId'];
        if (!callback) return;
        callback.resolve($encoded);
        delete window.__superAppCallbacks['$requestId'];
      })();
    ''');

    if (action == 'closeMiniApp') {
      closeMiniApp();
    }
  }

  String _statusLabel(String action) {
    return switch (action) {
      'getUserProfile' => 'Builder profile shared',
      'requestPayment' => 'Rewards action approved',
      'getRewards' => 'Rewards updated',
      'closeMiniApp' => 'Closing mini app',
      _ => 'Working',
    };
  }

  Future<Map<String, dynamic>> _runHostAction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));

    switch (action) {
      case 'getUserProfile':
        return {
          'ok': true,
          'data': {
            'id': 'BLD-JR-00142',
            'name': 'Jordan Rivers',
            'tier': 'Builder II',
            'phone': '+95 9 987 654 321',
          },
        };
      case 'requestPayment':
        return {
          'ok': true,
          'data': {
            'transactionId': 'BLD-RWD-${DateTime.now().millisecondsSinceEpoch}',
            'amount': payload['amount'],
            'currency': payload['currency'] ?? 'PTS',
            'status': 'Approved',
          },
        };
      case 'getRewards':
        return {
          'ok': true,
          'data': {
            'points': 2450,
            'level': 'Builder II',
            'nextReward': '500 pts recognition bonus',
          },
        };
      case 'closeMiniApp':
        return {
          'ok': true,
          'data': {'closed': true},
        };
      default:
        return {'ok': false, 'error': 'Action unavailable'};
    }
  }
}
