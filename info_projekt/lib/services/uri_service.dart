import 'package:universal_io/io.dart';

/// This service was implemented differently to support web plattforms and mobile plattforms.
/// Reason for this is that the web implementation uses a package that is not supported on mobile plattforms.
/// It provides an abstract class [UriService] with a getter [currentUri].
abstract class UriService {
  Uri get currentUri;
}

/// [UriServiceMobile] is the mobile implementation of [UriService].
class UriServiceMobile implements UriService {
  @override
  Uri get currentUri => Uri.parse('dummy');
}

/// [UriServiceWeb] is the web implementation of [UriService].
class UriServiceWeb implements UriService {
  @override
  Uri get currentUri => Uri.base;
}

/// The function [getUriService] returns an instance of [UriService].
/// It checks the operating system and returns the appropriate implementation.
UriService getUriService() {
  if (Platform.operatingSystem == 'web') {
    return UriServiceWeb();
  } else {
    return UriServiceMobile();
  }
}
