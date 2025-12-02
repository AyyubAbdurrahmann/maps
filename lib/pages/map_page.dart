import 'dart:ui' as ui;

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

  final LatLng _initialCenter = const LatLng(-7.2575, 112.7521);
  List<Marker> _markers = [];
  
  // State untuk Pin Point mode
  bool _isPinPointMode = false;
  LatLng? _tempPinLocation;

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
            width: 140,
            height: 100,
            alignment: Alignment.topCenter,
            child: _buildCustomMarker(loc.name),
          );
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Tugas 3: Visual Polish - Custom Marker yang lebih menarik
  Widget _buildCustomMarker(String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withAlpha(77),
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Pin pointer
        CustomPaint(
          size: const Size(12, 12),
          painter: _TrianglePainter(),
        ),
      ],
    );
  }

  // Tugas 1: Implementasi pilihan metode lokasi
  Future<void> _showLocationMethodDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_location_alt, color: Colors.orange),
            SizedBox(width: 8),
            Text('Pilih Metode Lokasi'),
          ],
        ),
        content: const Text('Bagaimana Anda ingin menentukan lokasi kuliner?'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _useGPSLocation();
            },
            icon: const Icon(Icons.gps_fixed, color: Colors.blue),
            label: const Text('Gunakan GPS'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _startPinPointMode();
            },
            icon: const Icon(Icons.push_pin),
            label: const Text('Pilih di Peta'),
          ),
        ],
      ),
    );
  }

  // Gunakan GPS untuk mendapatkan lokasi
  Future<void> _useGPSLocation() async {
    final permission = await _ensurePermission();
    if (!permission) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      
      _mapController.move(location, 16);
      
      if (!mounted) return;
      _showBottomSheetForName(location);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi GPS: $e')),
      );
    }
  }

  // Aktifkan mode Pin Point
  void _startPinPointMode() {
    setState(() {
      _isPinPointMode = true;
      _tempPinLocation = _mapController.camera.center;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ketuk peta untuk memilih lokasi kuliner'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Batalkan mode Pin Point
  void _cancelPinPointMode() {
    setState(() {
      _isPinPointMode = false;
      _tempPinLocation = null;
    });
  }

  // Konfirmasi lokasi Pin Point
  void _confirmPinPoint() {
    if (_tempPinLocation != null) {
      _showBottomSheetForName(_tempPinLocation!);
      setState(() {
        _isPinPointMode = false;
      });
    }
  }

  // Tugas 2: Bottom Sheet untuk input nama
  void _showBottomSheetForName(LatLng location) {
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fastfood, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendasi Kuliner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bagikan tempat kuliner favoritmu!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Input Field
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Misal: Nasi Goreng Pak Kumis',
                labelText: 'Nama Tempat / Menu',
                prefixIcon: const Icon(Icons.edit_location, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _tempPinLocation = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nama tempat tidak boleh kosong!'),
                          ),
                        );
                        return;
                      }
                      
                      Navigator.pop(context);
                      await _saveLocation(nameController.text, location);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Simpan Rekomendasi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _tempPinLocation = null;
      });
    });
  }

  // Simpan lokasi ke API
  Future<void> _saveLocation(String name, LatLng location) async {
    final newLoc = LocationModel(
      id: '',
      name: name,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    
    final success = await _apiService.addLocation(newLoc);
    
    if (success) {
      await _fetchLocations();
      _mapController.move(location, 16);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('$name berhasil ditambahkan!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan rekomendasi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  // Build temporary pin marker
  List<Marker> _buildTempMarker() {
    if (_tempPinLocation == null) return [];
    
    return [
      Marker(
        point: _tempPinLocation!,
        width: 60,
        height: 60,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.red.withAlpha(128),
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(Icons.push_pin, color: Colors.white, size: 24),
            ),
            CustomPaint(
              size: const Size(12, 12),
              painter: _TrianglePainter(color: Colors.red),
            ),
          ],
        ),
      ),
    ];
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
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                if (_isPinPointMode) {
                  setState(() {
                    _tempPinLocation = point;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kuliner.app',
              ),
              MarkerLayer(markers: _markers),
              if (_isPinPointMode) MarkerLayer(markers: _buildTempMarker()),
            ],
          ),
          
          // Pin Point Mode Controls
          if (_isPinPointMode)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ketuk peta untuk memilih lokasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _cancelPinPointMode,
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Batal',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Floating Action Buttons
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Confirm Pin Button (only in pin point mode)
                if (_isPinPointMode && _tempPinLocation != null) ...[
                  FloatingActionButton.extended(
                    onPressed: _confirmPinPoint,
                    backgroundColor: Colors.green,
                    heroTag: 'confirm',
                    label: const Text(
                      'Konfirmasi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Add Location Button
                if (!_isPinPointMode)
                  FloatingActionButton.extended(
                    onPressed: _showLocationMethodDialog,
                    backgroundColor: Colors.orange,
                    heroTag: 'add',
                    label: const Text(
                      'Rekomendasiin!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.add_location_alt, color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter untuk segitiga pointer di bawah marker
class _TrianglePainter extends CustomPainter {
  final Color color;
  
  _TrianglePainter({this.color = Colors.deepOrange});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
