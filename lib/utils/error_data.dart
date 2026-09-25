class ErrorData {
  final String title;
  final String body;
  final String? image;
  final String? buttonText;

  const ErrorData({
    required this.title,
    required this.body,
    this.image,
    this.buttonText,
  });
}
