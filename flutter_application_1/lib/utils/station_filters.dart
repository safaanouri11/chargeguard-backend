import 'package:flutter/foundation.dart';

// Process-wide station-filter state. Listened to by map_screen and the
// All Stations screen so a change in MapFiltersScreen propagates everywhere.
class StationFilters extends ChangeNotifier {
  static final StationFilters instance = StationFilters._();
  StationFilters._();

  // Power range — null means "no bound"
  double? minPower;
  double? maxPower;

  // Multi-selects
  final Set<String> connectors = {};
  final Set<String> amenities  = {};
  final Set<String> parking    = {};
  final Set<String> networks   = {};

  // Toggles + scalars
  bool   onlyAvailable = false;
  int    minPlugCount  = 0;       // 0 = Any, 2/4/6+
  double minRating     = 0;
  String comingSoon    = 'include'; // include | only | hide

  bool get isEmpty =>
      minPower == null &&
      maxPower == null &&
      connectors.isEmpty &&
      amenities.isEmpty &&
      parking.isEmpty &&
      networks.isEmpty &&
      !onlyAvailable &&
      minPlugCount == 0 &&
      minRating == 0 &&
      comingSoon == 'include';

  int get activeCount {
    var n = 0;
    if (minPower != null || maxPower != null) n++;
    if (connectors.isNotEmpty)  n++;
    if (amenities.isNotEmpty)   n++;
    if (parking.isNotEmpty)     n++;
    if (networks.isNotEmpty)    n++;
    if (onlyAvailable)          n++;
    if (minPlugCount > 0)       n++;
    if (minRating > 0)          n++;
    if (comingSoon != 'include') n++;
    return n;
  }

  Map<String, String> toQuery() {
    final q = <String, String>{};
    if (minPower != null)        q['minPower'] = minPower!.toStringAsFixed(0);
    if (maxPower != null)        q['maxPower'] = maxPower!.toStringAsFixed(0);
    if (connectors.isNotEmpty)   q['connectors'] = connectors.join(',');
    if (amenities.isNotEmpty)    q['amenities']  = amenities.join(',');
    if (parking.isNotEmpty)      q['parking']    = parking.join(',');
    if (networks.isNotEmpty)     q['networks']   = networks.join(',');
    if (onlyAvailable)           q['onlyAvailable'] = 'true';
    if (minPlugCount > 0)        q['minPlugCount']  = '$minPlugCount';
    if (minRating > 0)           q['minRating']     = minRating.toStringAsFixed(1);
    if (comingSoon == 'only')    q['onlyComingSoon']    = 'true';
    if (comingSoon == 'include') q['includeComingSoon'] = 'true';
    return q;
  }

  void reset() {
    minPower = null;
    maxPower = null;
    connectors.clear();
    amenities.clear();
    parking.clear();
    networks.clear();
    onlyAvailable = false;
    minPlugCount = 0;
    minRating = 0;
    comingSoon = 'include';
    notifyListeners();
  }

  void apply() => notifyListeners();
}
