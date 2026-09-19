class MediaRequest {
  const MediaRequest({required this.url, this.semanticLabel});

  final String url;
  final String? semanticLabel;
}

abstract interface class MediaPolicy {
  bool shouldLazyLoad(MediaRequest request);
}

class DefaultMediaPolicy implements MediaPolicy {
  const DefaultMediaPolicy();

  @override
  bool shouldLazyLoad(MediaRequest request) => true;
}
