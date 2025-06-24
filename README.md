### flutter-gc-refresh-list

A flutter widget for refreshing list.

#### GCPagingList使用方式

1、声明数据源

```kotlin
class ListDataSource extends PagingDataSource<int, String> {
  @override
  Future<Tuple2<List<String>, int>> loadInitial(int pageSize) async {
    return Tuple2(await fetch(0), 1);
  }

  @override
  Future<Tuple2<List<String>, int>> loadNext(int params, int pageSize) async {
    return Tuple2(await fetch(params), params + 1);
  }
    
  /// 模拟网络请求，参数可以自定义  
  Future<List<String>> fetch(int pageIndex) async {
    List<String> datas = [];
    for (var i = 0; i < 20; i++) {
      datas.add('${i + 20 * pageIndex}');
    }
    if (pageIndex == 3) {
      return Future.delayed(const Duration(seconds: 2), () => ["new1", "new2", "new3"]);
    }
    return Future.delayed(const Duration(seconds: 2), () => datas);
  }
}
```

2、使用

```dart
ListDataSource dataSource = ListDataSource();

GCPagingList<String>(
  pageDataSource: dataSource,
  separatorBuilder: (BuildContext context, int index) {
    return const Divider(height: 1);
  },
  itemBuilder: (BuildContext context, String value, int index) {
    return ListTile(
      title: Text('$value $index'),
    );
  },
),
```