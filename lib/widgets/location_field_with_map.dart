import 'package:flutter/material.dart';
import 'package:bico_certo/services/location_service.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_suggestion.dart';
import 'location_map_picker.dart';

class LocationFieldMapOnly extends StatefulWidget {
  final TextEditingController controller;
  final Function(LocationSuggestion) onLocationSelected;
  final Function(double lat, double lon)? onCoordinatesSelected;
  final String? initialLocation;

  const LocationFieldMapOnly({
    super.key,
    required this.controller,
    required this.onLocationSelected,
    this.onCoordinatesSelected,
    this.initialLocation,
  });

  @override
  State<LocationFieldMapOnly> createState() => _LocationFieldMapOnlyState();
}

class _LocationFieldMapOnlyState extends State<LocationFieldMapOnly> {
  double? _selectedLatitude;
  double? _selectedLongitude;

  Future<void> _openMapPicker() async {
    LatLng? initialLocation;
    if (_selectedLatitude != null && _selectedLongitude != null) {
      initialLocation = LatLng(_selectedLatitude!, _selectedLongitude!);
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationMapPicker(
          initialLocation: initialLocation,
          initialAddress: widget.controller.text,
        ),
      ),
    );

    if (result != null && mounted) {
      final address = result['address'] as String;
      final latitude = result['latitude'] as double;
      final longitude = result['longitude'] as double;

      setState(() {
        _selectedLatitude = latitude;
        _selectedLongitude = longitude;
      });

      widget.controller.text = address;

      final locationSuggestion = LocationSuggestion(
        displayName: address,
        lat: latitude,
        lon: longitude,
      );

      widget.onLocationSelected(locationSuggestion);

      if (widget.onCoordinatesSelected != null) {
        widget.onCoordinatesSelected!(latitude, longitude);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedLatitude != null && _selectedLongitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Localização",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Spacer(),
            if (hasLocation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Localizada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openMapPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasLocation ? Colors.blue[300]! : Colors.grey.shade300,
                      width: hasLocation ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: hasLocation ? Colors.blue[600] : Colors.grey[500],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.controller.text.isEmpty
                              ? 'Toque para selecionar no mapa'
                              : widget.controller.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.controller.text.isEmpty
                                ? Colors.grey[600]
                                : Colors.black87,
                            fontWeight: hasLocation
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.controller.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              widget.controller.clear();
                              _selectedLatitude = null;
                              _selectedLongitude = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 14, 67, 182),
                    const Color.fromARGB(255, 20, 90, 220),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 14, 67, 182).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openMapPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(
                    Icons.map,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: hasLocation ? Colors.blue[700] : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasLocation
                    ? 'Lat: ${_selectedLatitude!.toStringAsFixed(4)}, Lon: ${_selectedLongitude!.toStringAsFixed(4)}'
                    : 'Clique no campo ou no botão do mapa para selecionar',
                style: TextStyle(
                  fontSize: 12,
                  color: hasLocation ? Colors.blue[700] : Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontWeight: hasLocation ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}