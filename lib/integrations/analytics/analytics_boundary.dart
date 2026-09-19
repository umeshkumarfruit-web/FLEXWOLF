abstract interface class AnalyticsGateway {
  Future<void> track(AnalyticsEvent event);
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    this.parameters = const <String, Object?>{},
  });

  final String name;
  final Map<String, Object?> parameters;
}

class NoopAnalyticsGateway implements AnalyticsGateway {
  const NoopAnalyticsGateway();

  @override
  Future<void> track(AnalyticsEvent event) async {}
}

abstract final class AppAnalyticsEvents {
  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingSkipped = 'onboarding_skipped';
  static const guestContinue = 'guest_continue';
  static const preferenceSelected = 'preference_selected';
  static const preferenceSaved = 'preference_saved';
  static const homeView = 'home_view';
  static const homeSectionImpression = 'home_section_impression';
  static const homeSectionClick = 'home_section_click';
  static const homeBannerClick = 'home_banner_click';
  static const homeProductClick = 'home_product_click';
  static const homeCollectionClick = 'home_collection_click';
  static const homeCtaTap = 'home_cta_tap';
  static const homeHeroTap = 'hero_tap';
  static const homeProductTap = 'product_tap';
  static const homeCollectionTap = 'collection_tap';
  static const shoppableVideoTap = 'shoppable_video_tap';
  static const loginSuccess = 'login_success';
  static const loginFailure = 'login_failure';
  static const logout = 'logout';
  static const sessionRestored = 'session_restored';
  static const profileViewed = 'profile_viewed';
  static const addressAdded = 'address_added';
  static const addressUpdated = 'address_updated';
  static const addressDeleted = 'address_deleted';
  static const checkoutStarted = 'checkout_started';
  static const checkoutCompleted = 'checkout_completed';
  static const checkoutAbandoned = 'checkout_abandoned';
  static const discountApplied = 'discount_applied';
  static const ordersViewed = 'orders_viewed';
  static const orderOpened = 'order_opened';
  static const trackingOpened = 'tracking_opened';
  static const reorderClicked = 'reorder_clicked';
  static const returnOpened = 'return_opened';
  static const returnStarted = 'return_started';
  static const returnSubmitted = 'return_submitted';
  static const exchangeStarted = 'exchange_started';
  static const exchangeSubmitted = 'exchange_submitted';
  static const wishlistViewed = 'wishlist_viewed';
  static const productAddedToWishlist = 'product_added_to_wishlist';
  static const productRemovedFromWishlist = 'product_removed_from_wishlist';
  static const wishlistMoveToCart = 'wishlist_move_to_cart';
  static const notificationPermission = 'notification_permission';
  static const notificationReceived = 'notification_received';
  static const notificationOpened = 'notification_opened';
  static const deepLinkOpened = 'deep_link_opened';
  static const notificationNavigation = 'notification_navigation';
  static const destinationLoaded = 'destination_loaded';
  static const recentlyViewed = 'recently_viewed';
  static const recommendationClick = 'recommendation_click';
  static const backInStockRegistration = 'back_in_stock_registration';
  static const priceDropRegistration = 'price_drop_registration';
  static const reviewOpened = 'review_opened';
  static const reviewsViewed = 'reviews_viewed';
  static const writeReviewOpened = 'write_review_opened';
  static const reviewSubmitted = 'review_submitted';
  static const supportOpened = 'support_opened';
  static const faqViewed = 'faq_viewed';
  static const contactSubmitted = 'contact_submitted';
  static const adminLogin = 'admin_login';
  static const adminDashboardViewed = 'admin_dashboard_viewed';
  static const cmsViewed = 'cms_viewed';
  static const bannerUpdated = 'banner_updated';
  static const contentPublished = 'content_published';
  static const reviewModerated = 'review_moderated';
  static const returnUpdated = 'return_updated';
}
