import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 分页下拉刷新
abstract class GCGetxRefreshListController<T> extends FullLifeCycleController {
  late RefreshListController refreshListController;
  // 自动调用刷新？默认true
  final bool initDoRefresh;
  GCGetxRefreshListController({this.initDoRefresh = true});

  int pageNum = 0;
  int pageSize = 20;
  Key? key;
  //数据列表
  final RxList<T> list = RxList.empty();
  //下拉刷新
  Future? refreshData();
  //上拉加载
  Future? loadData();
  //判断是否加载完
  bool hasMore(Map result);
  //数据转换
  List<T> formatData(bool isRefresh, Map result);
  // 防止数据错乱，判断序号是否正确，默认正确
  bool dataSequenceSure(bool isRefresh, Map result) => true;

  @override
  void onInit() {
    super.onInit();
    refreshListController = RefreshListController(
      onLoading: () {
        if (refreshListController.state.value == RefreshListState.initializing) {
          refreshListController.loadComplete();
        } else {
          _onLoadData();
        }
      },
      onRefresh: () => _onRefresh(),
      onInit: () {
        refreshListController.setInit();
        _onRefresh();
      },
      key: key,
    );
    if (initDoRefresh) {
      refreshListController.onInit();
    }
    ever<List<T>>(list, (value) {
      value.isEmpty ? refreshListController.setEmpty() : refreshListController.setNormal();
    });
  }

  // 下拉刷新方法
  Future<void> _onRefresh() async {
    refreshListController.resetNoData();
    var result = await refreshData();
    if (result == null) {
      refreshListController.refreshFailed();
      return;
    }
    if (dataSequenceSure(true, result)) {
      pageNum = 0;
      list.value = formatData(true, result);
      if (!hasMore(result)) {
        refreshListController.loadNoData();
      } else {
        refreshListController.loadComplete();
      }
      // 刷新完成
      refreshListController.refreshCompleted();
    } else {
      refreshListController.refreshFailed();
    }
  }

  // 上拉加载方法
  Future<void> _onLoadData() async {
    var result = await loadData();
    if (result == null) {
      refreshListController.loadFailed();
      return;
    }
    if (dataSequenceSure(false, result)) {
      pageNum += 1;
      list.addAll(formatData(false, result));
      if (hasMore(result)) {
        // 加载完成
        refreshListController.loadComplete();
      } else {
        refreshListController.loadNoData();
      }
    } else {
      refreshListController.loadFailed();
    }
  }
}

class RefreshListController {
  //下拉刷新方法
  Function() onRefresh;

  //上拉加载方法
  Function() onLoading;

  //首次加载
  /// 注意：对于看不见ListView，refreshListController 可以 使用onInit()去做请求，刷新列表
  Function() onInit;

  Key? key;

  RefreshListController({required this.onRefresh, required this.onLoading, required this.onInit, this.key});

  final RefreshController refreshController = RefreshController();

  //列表状态
  final Rx<RefreshListState> state = RefreshListState.normal.obs;

  //能否下拉刷新
  final RxBool enablePullDown = true.obs;

  //能否上拉加载
  final RxBool enablePullUp = true.obs;

  //重置
  void resetNoData() => refreshController.resetNoData();

  //刷新失败
  void refreshFailed() => refreshController.refreshFailed();

  //刷新完成
  void refreshCompleted() => refreshController.refreshCompleted();

  //触发下拉刷新
  void doRefresh() => refreshController.requestRefresh(duration: const Duration(milliseconds: 1));

  //上拉加载失败
  void loadFailed() => refreshController.loadFailed();

  //上拉加载没有数据了
  void loadNoData() => refreshController.loadNoData();

  //上拉加载完成
  void loadComplete() => refreshController.loadComplete();

  //列表正在初始加载
  void setInit() => state.value = RefreshListState.initializing;

  //列表数据为空
  void setEmpty() => state.value = RefreshListState.empty;

  //列表数据加载正常
  void setNormal() => state.value = RefreshListState.normal;

  //用在首次加载失败的情况下
  void setError() => state.value = RefreshListState.error;
}

enum RefreshListState { normal, empty, initializing, error }
