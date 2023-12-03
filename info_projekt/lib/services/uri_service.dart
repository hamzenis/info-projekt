import 'package:universal_io/io.dart';
import 'package:universal_io/io.dart';

abstract class UriService {
  Uri get currentUri;
}

class UriServiceMobile implements UriService {
  @override
  Uri get currentUri => Uri.parse('dummy');
}

class UriServiceWeb implements UriService {
  @override
  Uri get currentUri => Uri.base;
}

UriService getUriService() {
  if (Platform.operatingSystem == 'web') {
    return UriServiceWeb();
  } else {
    return UriServiceMobile();
  }
}
