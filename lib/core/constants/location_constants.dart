class LocationConstants {
  LocationConstants._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDU3HsRLHhXezZ8cFgN_BWpx1auMZr3Kwo',
  );

  static const bool useGoogleMaps = bool.fromEnvironment(
    'SALAHNY_USE_GOOGLE_MAPS',
    defaultValue: true,
  );

  static bool get googleMapsConfigured => googleMapsApiKey.trim().isNotEmpty;

  static const double cairoLatitude = 30.0444;
  static const double cairoLongitude = 31.2357;
}
