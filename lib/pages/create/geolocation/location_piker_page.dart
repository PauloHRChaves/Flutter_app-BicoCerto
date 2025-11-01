// location_picker_page.dart

import 'package:flutter/material.dart';
// ATENÇÃO: Substituímos 'flutter_map' pelo 'google_maps_flutter'
// e removemos 'latlong2', pois o LatLng do Google Maps será usado.
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'package:geocoding/geocoding.dart';

// Classe de modelo para retornar os dados (sem alteração)
class LocationResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationResult({required this.address, required this.latitude, required this.longitude});
}


class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // Coordenada inicial (AGORA USANDO LatLng do Google Maps)
  // As coordenadas de Salvador que definiste foram mantidas.
  LatLng _selectedLocation = const LatLng(-12.959293627763913, -38.43353729808076); 
  String _selectedAddress = "Toque no mapa para selecionar a localização";
  bool _isLoadingAddress = false;

  // Variável de controlo do mapa (necessária para manipular o GoogleMap)
  GoogleMapController? _mapController;

  // Método chamado quando o GoogleMap estiver pronto
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Opcional: Carregar o endereço da localização inicial quando o mapa carrega.
    _getAddressFromLatLng(_selectedLocation);
  }

  // Método que obtém o endereço a partir das coordenadas (sem grandes alterações)
  Future<void> _getAddressFromLatLng(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
      _selectedAddress = "Buscando endereço...";
    });

    try {
          // Uso do pacote geocoding para Geocodificação Reversa
          List<Placemark> placemarks = await placemarkFromCoordinates(
            point.latitude,
            point.longitude,
          );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        // Constrói um endereço formatado
        final String address = [
          place.thoroughfare, // Rua
          place.subThoroughfare, // Número
          place.subLocality, // Bairro
          place.locality, // Cidade
          place.administrativeArea, // Estado
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address.isEmpty ? "Endereço encontrado (não detalhado)" : address;
          _selectedLocation = point; // Atualiza a localização
        });
      } else {
        setState(() {
          _selectedAddress = "Nenhum endereço encontrado para este ponto.";
        });
      }
    } catch (e) {
      print("Erro ao buscar endereço: $e");
      setState(() {
        _selectedAddress = "Erro ao buscar endereço. Tente novamente.";
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  // Função para retornar a localização selecionada para a tela anterior
  void _selectLocationAndReturn() {
    // Retorna a Localização e o Endereço como um objeto LocationResult
    final result = LocationResult(
      address: _selectedAddress,
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
    );
    Navigator.of(context).pop(result);
  }


  @override
  Widget build(BuildContext context) {
    // Define a posição inicial da câmara
    final CameraPosition initialCameraPosition = CameraPosition(
      target: _selectedLocation,
      zoom: 15.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione a Localização'),
        backgroundColor: const Color.fromARGB(255, 14, 67, 182),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. O Widget do Mapa (GoogleMap)
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            onMapCreated: _onMapCreated, // Captura o controlador do mapa

            // Com o Google Maps, podemos usar onCameraIdle para saber onde o mapa parou.
            // Isso substitui a lógica de 'onTap' do FlutterMap.
            onCameraIdle: () {
              if (_mapController != null) {
                // Obtém o centro da câmara quando o utilizador para de arrastar o mapa
                _mapController!.getVisibleRegion().then((LatLngBounds bounds) {
                  final LatLng center = LatLng(
                    (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
                    (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
                  );
                  _getAddressFromLatLng(center); // Busca o endereço do centro
                });
              }
            },

            // Marcador: No Google Maps, é comum usar um Marker que se move com o centro do ecrã.
            // Para simular o 'alfinete' fixo no centro, podemos usar a lógica de onCameraIdle
            // para atualizar a posição do marcador.
            markers: {
              Marker(
                markerId: const MarkerId('selectedLocation'),
                position: _selectedLocation, // A posição será atualizada em _getAddressFromLatLng
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                // Para o modo 'pin no centro do ecrã', a InfoWindow pode não ser necessária, mas mantive-a.
              ),
            },
          ),
          
          // Opcional: Para ter um alfinete fixo no centro do ecrã (como na imagem original)
          // enquanto o mapa é arrastado por baixo:
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 50.0), // Ajuste para que o pin fique acima do painel
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40.0,
              ),
            ),
          ),


          // 2. Painel de Confirmação na parte inferior da tela (sem alteração)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Localização Selecionada:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _isLoadingAddress
                      ? const LinearProgressIndicator()
                      : Text(_selectedAddress, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoadingAddress || _selectedAddress.startsWith("Toque") ? null : _selectLocationAndReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 14, 67, 182),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirmar Localização', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}