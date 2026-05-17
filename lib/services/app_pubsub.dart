import 'package:fbroadcast/fbroadcast.dart';

class AppPubSubTopics {
  static const studentSynced = 'student.synced';
  static const globalSynced = 'global.synced';
  static const globalSyncError = 'global.sync.error';
}

typedef AppPubSubHandler = void Function(dynamic value, dynamic callback);

class AppPubSub {
  static void publish(String key, {dynamic value}) {
    FBroadcast.instance().broadcast(key, value: value);
  }

  static void subscribe({
    required String key,
    required AppPubSubHandler handler,
    required Object context,
  }) {
    FBroadcast.instance().register(key, handler, context: context);
  }

  static void unsubscribe({required Object context}) {
    FBroadcast.instance().unregister(context);
  }
}
