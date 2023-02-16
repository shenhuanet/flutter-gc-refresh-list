import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'refresh_list_controller.dart';

class GCRefreshListConfig {
  final TextStyle? textStyle;
  final Color? releaseColor;
  final Color? refreshingColor;
  final Color? completeColor;
  final Color? failedColor;
  final double? headerHeight;
  final double? emptyTop;
  final double? emptyImageHeight;
  final Widget? emptyWidget;
  final Widget? initLoadingWidget;

  final String? noDataText;
  final Widget? noDataWidget;

  GCRefreshListConfig({
    this.textStyle,
    this.releaseColor,
    this.refreshingColor,
    this.completeColor,
    this.failedColor,
    this.headerHeight,
    this.emptyTop,
    this.emptyImageHeight,
    this.emptyWidget,
    this.initLoadingWidget,
    this.noDataText,
    this.noDataWidget
  });
}

class GCRefreshListUtil {
  static final GCRefreshListConfig _defaultConfig = GCRefreshListConfig(
    textStyle: const TextStyle(fontSize: 14, color: Color(0xFF41C476)),
    releaseColor: const Color(0xFF41C476),
    refreshingColor: const Color(0xFF41C476),
    completeColor: const Color(0xFF41C476),
    failedColor: const Color(0xFFFF6E6E),
    headerHeight: 40,
    emptyTop: 45,
    emptyImageHeight: 150,
    emptyWidget: const Text("没有找到您想要的数据", style: TextStyle(fontSize: 14, color: Colors.white38)),
    initLoadingWidget: const Text("正在加载数据...", style: TextStyle(fontSize: 14, color: Colors.white38)),
    noDataText: '没有更多数据了'
  );

  static GCRefreshListConfig? _config;
  static GCRefreshListConfig get config => _config ?? _defaultConfig;

  static void initConfig(GCRefreshListConfig config) {
    _config = GCRefreshListConfig(
      textStyle: config.textStyle ?? _defaultConfig.textStyle,
      releaseColor: config.refreshingColor ?? _defaultConfig.refreshingColor,
      refreshingColor: config.refreshingColor ?? _defaultConfig.refreshingColor,
      completeColor: config.completeColor ?? _defaultConfig.completeColor,
      failedColor: config.failedColor ?? _defaultConfig.failedColor,
      headerHeight: config.headerHeight ?? _defaultConfig.headerHeight,
      emptyTop: config.emptyTop ?? _defaultConfig.emptyTop,
      emptyImageHeight: config.emptyImageHeight ?? _defaultConfig.emptyImageHeight,
      emptyWidget: config.emptyWidget ?? _defaultConfig.emptyWidget,
      initLoadingWidget: config.initLoadingWidget ?? _defaultConfig.initLoadingWidget,
      noDataText: config.noDataText ?? _defaultConfig.noDataText,
      noDataWidget: config.noDataWidget
    );
  }

  /// 数据为空的显示样式，可通用
  static Widget emptyWidget({GCRefreshListConfig? config, String emptyImagePath = "assets/images/empty_noData.png"}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          emptyImagePath,
          height: config?.emptyImageHeight ?? GCRefreshListUtil.config.emptyImageHeight!,
        ),
        config?.emptyWidget ?? GCRefreshListUtil.config.emptyWidget!
      ],
    );
  }
}

class GCRefreshList extends StatelessWidget {

  final RefreshListController controller;
  final Widget listView;
  final String? emptyImage;
  final GCRefreshListConfig? config;

  const GCRefreshList({
    Key? key,
    required this.controller,
    required this.listView,
    this.emptyImage = "assets/images/empty_noData.png",
    this.config
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      //列表
      Widget _child = listView;
      //第一次加载
      if (controller.state.value == RefreshListState.initializing) {
        _child = config?.initLoadingWidget ?? GCRefreshListUtil.config.initLoadingWidget!;
      }
      //第一次加载时出错
      else if (controller.state.value == RefreshListState.error) {
        _child = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.onInit();
          },
          child: Center(
            child: Text(
              "加载数据失败，点击重试",
              style: (config?.textStyle ?? GCRefreshListUtil.config.textStyle!).copyWith(color: const Color(0xfff5a623)),
            ),
          ),
        );
      }
      //没有数据
      else if (controller.state.value == RefreshListState.empty) {
        _child = Padding(
          padding: EdgeInsets.only(top: config?.emptyTop ?? GCRefreshListUtil.config.emptyTop!),
          child: emptyImage != null ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                emptyImage!,
                height: config?.emptyImageHeight ?? GCRefreshListUtil.config.emptyImageHeight!,
              ),
              config?.emptyWidget ?? GCRefreshListUtil.config.emptyWidget!
            ],
          ) : (config?.emptyWidget ?? GCRefreshListUtil.config.emptyWidget!)
        );
      }
      return RefreshConfiguration(
        headerTriggerDistance: 60,
        child: SmartRefresher(
          key: controller.key,
          controller: controller.refreshController,
          enablePullUp: controller.enablePullUp.value,
          enablePullDown: controller.enablePullDown.value,
          child: _child,
          header: ClassicHeader(
            height: config?.headerHeight ?? GCRefreshListUtil.config.headerHeight!,
            textStyle: config?.textStyle ?? GCRefreshListUtil.config.textStyle!,
            releaseText: '释放刷新',
            releaseIcon: Icon(Icons.refresh,
              color: config?.releaseColor ?? GCRefreshListUtil.config.releaseColor,
              size: 24
            ),
            refreshingText: '刷新中...',
            refreshingIcon: SizedBox(child: CircularProgressIndicator(
                strokeWidth: 2,
                color: config?.refreshingColor ?? GCRefreshListUtil.config.refreshingColor
              ),
              height: 20.0, width: 20.0
            ),
            completeText: '刷新完成',
            completeIcon: Icon(Icons.check_circle,
              color: config?.completeColor ?? GCRefreshListUtil.config.completeColor,
              size: 20
            ),
            failedText: '刷新失败,请重试',
            failedIcon: const Icon(Icons.error, color: Color(0xfff5a623), size: 20),
            idleText: '下拉刷新',
            idleIcon: Icon(Icons.arrow_downward,
              color: config?.releaseColor ?? GCRefreshListUtil.config.releaseColor,
              size: 24
            ),
          ),
          footer: ClassicFooter(
            height: config?.headerHeight ?? GCRefreshListUtil.config.headerHeight!,
            textStyle: config?.textStyle ?? GCRefreshListUtil.config.textStyle!,
            loadingText: '加载中...',
            loadingIcon: SizedBox(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: config?.releaseColor ?? GCRefreshListUtil.config.releaseColor,
              ),
              height: 20.0,
              width: 20.0
            ),
            noDataText: config?.noDataText ?? GCRefreshListUtil.config.noDataText,
            noMoreIcon: config?.noDataWidget ?? GCRefreshListUtil.config.noDataWidget,
            canLoadingText: '上拉加载更多',
            canLoadingIcon: Icon(Icons.arrow_upward,
              color: config?.releaseColor ?? GCRefreshListUtil.config.releaseColor,
              size: 24
            ),
            failedText: '加载失败，请重试',
            failedIcon: Icon(Icons.error,
              color: config?.failedColor ?? GCRefreshListUtil.config.failedColor,
              size: 20
            ),
            idleText: '上拉加载更多',
            idleIcon: Icon(Icons.arrow_upward,
              color: config?.releaseColor ?? GCRefreshListUtil.config.releaseColor,
              size: 24
            ),
          ),
          onRefresh: controller.onRefresh,
          onLoading: controller.onLoading,
        ),
      );
    });
  }
}
