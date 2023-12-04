import 'package:universal_io/io.dart';

/// This service was implemented differently to support web plattforms and mobile plattforms.
/// Reason for this is that the web implementation uses a package that is not supported on mobile plattforms.
/// It provides an abstract class [StripeService] with a method [confirmCardPayment].
abstract class StripeService {
  void confirmCardPayment(String? clientSecret);
}

///[StripeServiceWeb] is the web implementation of [StripeService].
class StripeServiceWeb implements StripeService {
  @override
  void confirmCardPayment(String? clientSecret) {}
}

/// [StripeServiceStub] is the mobile implementation of [StripeService].
class StripeServiceStub implements StripeService {
  @override
  void confirmCardPayment(String? clientSecret) {}
}

/// The function [getStripeService] returns an instance of [StripeService].
/// It checks the operating system and returns the appropriate implementation.
StripeService getStripeService() {
  if (Platform.operatingSystem == 'web') {
    return StripeServiceWeb();
  } else {
    return StripeServiceStub();
  }
}
