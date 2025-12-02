import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_model.dart';
import '../services/api_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  LatLng _currentCenter = const LatLng(-7.2575, 112.7521);
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final locations = await _apiService.getLocations();
      setState(() {
        _markers = locations.map((loc) {
          return Marker(
            point: LatLng(loc.latitude, loc.longitude),
            width: 120,
            height: 90,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant, color: Colors.orange, size: 35),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(blurRadius: 3, color: Colors.black26)
                    ],
                  ),
                  child: Text(
                    loc.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addRecommendation() async {
    final permission = await _ensurePermission();
    if (!permission) return;

    final position = await Geolocator.getCurrentPosition();
    _currentCenter = LatLng(position.latitude, position.longitude);

    if (!mounted) return;
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rekomendasi Kuliner'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Misal: Nasi Goreng Pak Kumis',
            labelText: 'Nama Tempat / Menu',
            icon: Icon(Icons.fastfood, color: Colors.orange),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              if (nameController.text.isEmpty) return;
              final newLoc = LocationModel(
                id: '',
                name: nameController.text,
                latitude: position.latitude,
                longitude: position.longitude,
              );
              final success = await _apiService.addLocation(newLoc);
              if (success) {
                await _fetchLocations();
                _mapController.move(_currentCenter, 15);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rekomendasi berhasil disimpan!'),
                  ),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menyimpan rekomendasi.'),
                  ),
                );
              }
            },
            child: const Text(
              'Simpan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktifkan layanan lokasi terlebih dahulu.')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi diblokir secara permanen.')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KulinerHunt'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLocations,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kuliner.app',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _addRecommendation,
              backgroundColor: Colors.orange,
              label: const Text(
                'Rekomendasiin!',
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
