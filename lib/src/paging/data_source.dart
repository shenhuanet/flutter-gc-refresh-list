import 'package:tuple/tuple.dart';
import 'package:async/async.dart';

abstract class DataSource<T> {
  Future<List<T>> loadPage({bool isRefresh});

  bool get hasMore;
}

const kDefaultPageSize = 20;

abstract class PagingDataSource<K, T> extends DataSource<T> {

  K? currentKey;

  final bool autoDetectEndList;

  final int pageSize;

  @override
  bool hasMore;

  CancelableOperation<Tuple2<List<T>, K>>? _cancelableOperation;

  PagingDataSource({
    this.hasMore = false,
    this.autoDetectEndList = true,
    this.pageSize = kDefaultPageSize,
  });

  Future<Tuple2<List<T>, K>> loadInitial(int pageSize);

  Future<Tuple2<List<T>, K>> loadNext(K params, int pageSize);

  @override
  Future<List<T>> loadPage({bool isRefresh = false}) async {
    if ((currentKey == null) || isRefresh) {
      if (_cancelableOperation != null && !_cancelableOperation!.isCompleted) {
        _cancelableOperation!.cancel();
      }
      _cancelableOperation =
          CancelableOperation.fromFuture(loadInitial(pageSize));
      final results = await _cancelableOperation!.valueOrCancellation();
      if (autoDetectEndList) {
        hasMore = ((results?.item1.length ?? 0) == pageSize);
      }
      currentKey = results?.item2;
      return results?.item1 ?? [];
    } else {
      _cancelableOperation =
          CancelableOperation.fromFuture(loadNext(currentKey as K, pageSize));
      final results = await _cancelableOperation!.valueOrCancellation();
      currentKey = results?.item2;
      if (autoDetectEndList) {
        hasMore = ((results?.item1.length ?? 0) == pageSize);
      }
      return results?.item1 ?? [];
    }
  }
}
