import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bico_certo/services/location_service.dart';

class LocationNavigationWidget extends StatefulWidget {
  final String locationString;
  final Color color;

  const LocationNavigationWidget({
    super.key,
    required this.locationString,
    this.color = Colors.red,
  });

  @override
  State<LocationNavigationWidget> createState() => _LocationNavigationWidgetState();
}

class _LocationNavigationWidgetState extends State<LocationNavigationWidget> {
  final LocationService _locationService = LocationService();
  String _addressName = 'Carregando localização...';
  bool _isLoading = true;
  double? _latitude;
  double? _longitude;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _parseAndLoadAddress();
  }

  Future<void> _parseAndLoadAddress() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final parts = widget.locationString.split('|');

      if (parts.length != 2) {
        throw Exception('Formato inválido');
      }

      _latitude = double.parse(parts[0].trim());
      _longitude = double.parse(parts[1].trim());

      final suggestion = await _locationService.reverseGeocode(
        _latitude!,
        _longitude!,
      );

      if (mounted) {
        setState(() {
          _addressName = suggestion?.shortAddress ??
              suggestion?.displayName ??
              'Endereço não encontrado';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar localização: $e');
      if (mounted) {
        setState(() {
          _addressName = widget.locationString;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _showNavigationOptions() {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordenadas não disponíveis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NavigationOptionsSheet(
        latitude: _latitude!,
        longitude: _longitude!,
        addressName: _addressName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading || _hasError ? null : _showNavigationOptions,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLoading || _hasError
                ? Colors.grey[200]!
                : widget.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: widget.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Localização',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _isLoading
                      ? Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _addressName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                      : Text(
                    _addressName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _hasError ? Colors.grey[700] : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!_isLoading && !_hasError) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.navigation,
                  color: widget.color,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavigationOptionsSheet extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String addressName;

  const _NavigationOptionsSheet({
    required this.latitude,
    required this.longitude,
    required this.addressName,
  });

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWaze() async {
    final url = Uri.parse(
        'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUber() async {
    final url = Uri.parse(
        'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[latitude]=$latitude&dropoff[longitude]=$longitude&dropoff[nickname]=$addressName'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAppleMaps() async {
    final url = Uri.parse(
        'http://maps.apple.com/?ll=$latitude,$longitude'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyCoordinates(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: '$latitude, $longitude'),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Coordenadas copiadas!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.navigation,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Navegar até',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      addressName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.pin_drop, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lat: ${latitude.toStringAsFixed(6)}, Lon: ${longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[700]),
                  onPressed: () => _copyCoordinates(context),
                  tooltip: 'Copiar coordenadas',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Escolha um aplicativo:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 12),

          _NavigationOption(
            icon: Icons.map,
            label: 'Google Maps',
            color: Colors.green[600]!,
            onTap: () {
              Navigator.pop(context);
              _openGoogleMaps();
            },
          ),

          const SizedBox(height: 10),

          _NavigationOption(
            icon: Icons.directions_car,
            label: 'Waze',
            color: Colors.blue[600]!,
            onTap: () {
              Navigator.pop(context);
              _openWaze();
            },
          ),

          const SizedBox(height: 10),

          _NavigationOption(
            icon: Icons.local_taxi,
            label: 'Uber',
            color: Colors.black,
            onTap: () {
              Navigator.pop(context);
              _openUber();
            },
          ),

          const SizedBox(height: 10),

          if (Theme.of(context).platform == TargetPlatform.iOS)
            _NavigationOption(
              icon: Icons.apple,
              label: 'Apple Maps',
              color: Colors.blue[700]!,
              onTap: () {
                Navigator.pop(context);
                _openAppleMaps();
              },
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavigationOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavigationOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}