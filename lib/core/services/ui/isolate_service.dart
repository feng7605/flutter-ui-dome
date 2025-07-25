import 'dart:async';
import 'dart:isolate';

// 定义传递给流式任务的函数签名
// 它接收一个 SendPort (用于回传数据) 和一个参数
typedef IsolateStreamHandler<Q, R> = void Function(SendPort sendPort, Q params);

// 定义传递给一次性任务的函数签名
typedef IsolateOnceHandler<Q, R> = R Function(Q params);


class IsolateService {
  // 1. 单例模式实现
  IsolateService._internal();
  static final IsolateService instance = IsolateService._internal();

  /// 执行一个一次性的后台任务，类似于 Flutter 的 compute()
  /// [handler] 是将在新 Isolate 中执行的函数 (必须是顶层函数或静态方法)
  /// [params] 是要传递给该函数的参数
  Future<R> runOnce<Q, R>(IsolateOnceHandler<Q, R> handler, Q params) async {
    final completer = Completer<R>();
    final receivePort = ReceivePort();

    receivePort.listen((message) {
      if (message is R) {
        completer.complete(message);
      } else if (message is Exception) {
        completer.completeError(message);
      }
      receivePort.close();
    });

    try {
      // 创建 Isolate 的入口，它执行 handler 并将结果发送回来
      await Isolate.spawn(
        _onceRunner,
        [receivePort.sendPort, handler, params],
        onError: receivePort.sendPort,
        onExit: receivePort.sendPort,
      );
    } catch (e) {
      completer.completeError(Exception("Failed to spawn Isolate: $e"));
      receivePort.close();
    }

    return completer.future;
  }

  /// 执行一个后台任务并返回一个数据流
  /// [handler] 是将在新 Isolate 中执行的函数 (必须是顶层函数或静态方法)
  /// [params] 是要传递给该函数的参数
  Stream<R> runStream<Q, R>(IsolateStreamHandler<Q, R> handler, Q params) {
    final controller = StreamController<R>();
    ReceivePort? receivePort;

    controller.onListen = () async {
      receivePort = ReceivePort();
      
      receivePort!.listen((message) {
        if (message is R) {
          controller.add(message);
        } else if (message is Exception) {
          controller.addError(message);
          controller.close();
          receivePort?.close();
        } else if (message == 'done') {
          controller.close();
          receivePort?.close();
        }
      });

      try {
        // *** 这是关键的修正 ***
        // 我们传递通用的 _streamRunner 作为入口点
        await Isolate.spawn(
          _streamRunner, 
          // 并将所有需要的参数打包成一个列表
          [receivePort!.sendPort, handler, params],
          onError: receivePort!.sendPort,
          onExit:receivePort!.sendPort);
        } catch (e) {
        controller.addError(Exception("Failed to spawn Isolate: $e"));
        controller.close();
        receivePort?.close();
      }
    };
    
    controller.onCancel = () {
      receivePort?.close();
    };

    return controller.stream;
  }
}

void _streamRunner<Q, R>(List<dynamic> args) {
  // 1. 解包参数
  final sendPort = args[0] as SendPort;
  final handler = args[1] as IsolateStreamHandler<Q, R>;
  final params = args[2] as Q;
  
  // 2. 使用解包后的参数调用用户提供的 handler
  handler(sendPort, params);
}

/// 内部辅助函数，用于执行一次性任务
void _onceRunner<Q, R>(List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  final handler = args[1] as IsolateOnceHandler<Q, R>;
  final params = args[2] as Q;
  
  try {
    final result = handler(params);
    sendPort.send(result);
  } catch(e) {
    sendPort.send(Exception(e.toString()));
  }
}