class PagingState<D> {
  const factory PagingState.loading() = PagingStateLoading;

  const factory PagingState(List<D> datas, bool isLoadMore, bool hasMore) =
      PagingStateData;

  const factory PagingState.error(dynamic error) = PagingStateError;
}

class PagingStateLoading<D> implements PagingState<D> {
  const PagingStateLoading();
}

class PagingStateError<D> implements PagingState<D> {
  final dynamic error;

  const PagingStateError(this.error);
}

class PagingStateData<D> implements PagingState<D> {
  final List<D> datas;
  final bool isLoadMore;
  final bool hasMore;

  const PagingStateData(this.datas, this.isLoadMore, this.hasMore);
}

extension PagingStateDataExtension<D> on PagingStateData<D> {
  PagingStateData<D> copyWith({
    List<D>? datas,
    bool? hasMore,
    bool? isLoadMore,
  }) {
    return PagingStateData(
      datas ?? this.datas,
      isLoadMore ?? this.isLoadMore,
      hasMore ?? this.hasMore,
    );
  }
}
