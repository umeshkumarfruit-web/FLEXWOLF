import 'package:flexwolf/core/errors/app_exception.dart';

class SocialShareRequest {
  const SocialShareRequest({
    required this.title,
    required this.url,
    this.text,
    this.imageUrl,
    this.channel = SocialShareChannel.system,
  });

  final String title;
  final Uri url;
  final String? text;
  final Uri? imageUrl;
  final SocialShareChannel channel;

  void validate() {
    if (title.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Share title is required.',
        code: 'share_title_required',
      );
    }
    if (!url.hasScheme || url.host.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'A valid share URL is required.',
        code: 'share_url_required',
      );
    }
    if (url.scheme != 'https') {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Share URLs must use HTTPS.',
        code: 'share_url_insecure',
      );
    }
    final media = imageUrl;
    if (media != null &&
        (media.scheme != 'https' || media.host.trim().isEmpty)) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Share image URLs must use HTTPS.',
        code: 'share_image_url_insecure',
      );
    }
  }
}

enum SocialShareChannel { system, copyLink, instagram, facebook, x, sms, email }

class SocialShareResult {
  const SocialShareResult({required this.status, this.channel});

  final SocialShareStatus status;
  final SocialShareChannel? channel;
}

enum SocialShareStatus { prepared, shared, copied, unavailable, cancelled }

abstract interface class SocialShareGateway {
  Future<SocialShareResult> share(SocialShareRequest request);
}

class PreparedSocialShareGateway implements SocialShareGateway {
  const PreparedSocialShareGateway();

  @override
  Future<SocialShareResult> share(SocialShareRequest request) async {
    request.validate();
    return SocialShareResult(
      status: request.channel == SocialShareChannel.copyLink
          ? SocialShareStatus.copied
          : SocialShareStatus.prepared,
      channel: request.channel,
    );
  }
}
