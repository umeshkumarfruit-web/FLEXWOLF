enum SupportCategory { helpCenter, faq, contact, order, product }

class FaqCategory {
  const FaqCategory({required this.id, required this.title});

  final String id;
  final String title;
}

class FaqItem {
  const FaqItem({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.answer,
  });

  final String id;
  final String categoryId;
  final String question;
  final String answer;
}

class SupportReference {
  const SupportReference({this.orderNumber, this.productId, this.productTitle});

  final String? orderNumber;
  final String? productId;
  final String? productTitle;
}

class SupportRequest {
  const SupportRequest({
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    this.orderNumber,
    this.productId,
    this.productTitle,
  });

  final String name;
  final String email;
  final String subject;
  final String message;
  final String? orderNumber;
  final String? productId;
  final String? productTitle;
}

class SupportTicketResult {
  const SupportTicketResult({required this.id, required this.clientDependency});

  final String id;
  final bool clientDependency;
}
