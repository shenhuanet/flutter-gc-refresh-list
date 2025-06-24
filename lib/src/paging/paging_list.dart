import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:gc_flutter_refresh_list/src/paging/data_source.dart';
import 'package:gc_flutter_refresh_list/src/paging/load_more_widget.dart';
import 'package:gc_flutter_refresh_list/src/paging/no_more_widget.dart';
import 'package:gc_flutter_refresh_list/src/paging/paging_state.dart';

typedef ValueIndexWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  int index,
);

class GCPagingList<T> extends StatefulWidget {
  final ValueIndexWidgetBuilder<T> itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final DataSource<T> pageDataSource;
  final ValueChanged? errorWhenLoadMore;

  const GCPagingList({
    Key? key,
    required this.itemBuilder,
    required this.pageDataSource,
    this.errorWhenLoadMore,
    this.separatorBuilder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GCPagingListState<T>();
}

class _GCPagingListState<T> extends State<GCPagingList<T>> {
  PagingState<T> _pagingState = const PagingState.loading();

  PagingState<T> get pagingState => _pagingState;
  CancelableOperation? cancelableOperation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    cancelableOperation?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GCPagingList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageDataSource != oldWidget.pageDataSource) {
      emit(const PagingState.loading());
      _loadData();
    }
  }

  void emit(PagingState<T> state) {
    if (mounted) {
      setState(() {
        _pagingState = state;
      });
    }
  }

  List<T> getData() {
    if (_pagingState is PagingStateData<T>) {
      return (_pagingState as PagingStateData<T>).datas;
    }
    return [];
  }

  Future _loadData({bool isRefresh = false}) async {
    if (cancelableOperation != null && !cancelableOperation!.isCompleted) {
      cancelableOperation!.cancel();
    }
    if (isRefresh == true) {
      try {
        emit(PagingState<T>(
            await widget.pageDataSource.loadPage(isRefresh: isRefresh),
            false,
            widget.pageDataSource.hasMore));
      } catch (error) {
        emit(PagingState.error(error));
      }
    } else {
      if (_pagingState is PagingStateLoading<T>) {
        cancelableOperation =
            CancelableOperation.fromFuture(widget.pageDataSource.loadPage());
        cancelableOperation!.value.then((value) {
          emit(PagingState<T>(value, false, widget.pageDataSource.hasMore));
        }, onError: (error) {
          emit(PagingState.error(error));
        });
      } else {
        if (_pagingState is PagingStateError<T>) {
          emit(const PagingState.loading());
        }
        cancelableOperation =
            CancelableOperation.fromFuture(widget.pageDataSource.loadPage());
        cancelableOperation!.value.then((value) {
          if (_pagingState is PagingStateData<T>) {
            final oldState = (_pagingState as PagingStateData<T>);
            if (value.length == 0) {
              emit(oldState.copyWith(isLoadMore: false, hasMore: true));
            } else {
              emit(
                oldState.copyWith(
                  isLoadMore: false,
                  hasMore: widget.pageDataSource.hasMore,
                  datas: oldState.datas..addAll(value),
                ),
              );
            }
          } else {
            emit(PagingState<T>(value, false, widget.pageDataSource.hasMore));
          }
        }, onError: (error) {
          if (widget.errorWhenLoadMore != null) {
            widget.errorWhenLoadMore!(error);
          } else {
            emit(PagingState.error(error));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pagingState is PagingStateError) {
      return Text('error: ${(_pagingState as PagingStateError).error}');
    } else if (_pagingState is PagingStateLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    var state = _pagingState as PagingStateData<T>;
    if (state.datas.isEmpty) {
      return const Center(child: Text('没有数据'));
    }

    Widget child;
    child = widgets.ListView.separated(
      separatorBuilder: (context, index) {
        return widget.separatorBuilder != null
            ? widget.separatorBuilder!(context, index)
            : const SizedBox(height: 16);
      },
      itemBuilder: (context, index) {
        return index == state.datas.length
            ? state.hasMore
                ? const LoadMoreWidget()
                : const NoMoreWidget()
            : widget.itemBuilder(context, state.datas[index], index);
      },
      itemCount: state.datas.length + 1,
    );
    return RefreshIndicator(
      child: NotificationListener<ScrollEndNotification>(
        child: child,
        onNotification: (notification) {
          if (state.hasMore &&
              (notification.metrics.pixels ==
                  notification.metrics.maxScrollExtent)) {
            if (_pagingState is PagingStateData<T> &&
                (state.hasMore && !state.isLoadMore)) {
              _loadData();
              emit(state.copyWith(isLoadMore: true, hasMore: true));
            }
          }
          return false;
        },
      ),
      onRefresh: () {
        return _loadData(isRefresh: true);
      },
    );
  }
}
