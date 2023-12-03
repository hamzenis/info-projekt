import 'package:universal_io/io.dart';

abstract class StripeService {
  void confirmCardPayment(String? clientSecret);
}

// Web implementation
class StripeServiceWeb implements StripeService {
  @override
  void confirmCardPayment(String? clientSecret) {}
}

// Mobile implementation
class StripeServiceStub implements StripeService {
  @override
  void confirmCardPayment(String? clientSecret) {}
}

StripeService getStripeService() {
  if (Platform.operatingSystem == 'web') {
    return StripeServiceWeb();
  } else {
    return StripeServiceStub();
  }
}
