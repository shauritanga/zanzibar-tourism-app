import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zanzibar_tourism/models/cultural_site.dart';
import 'package:zanzibar_tourism/providers/cultural_site_provider.dart';
import 'package:zanzibar_tourism/services/navigation_service.dart';

// Screen for navigating cultural sites
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  CulturalSite? _selectedSite;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // Initialize user location
  Future<void> _initializeLocation() async {
    try {
      final location =
          await ref.read(navigationServiceProvider).getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: location,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(location));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  // Show route to selected site
  Future<void> _showRoute(CulturalSite site) async {
    if (_currentLocation == null || site.location == null) return;

    try {
      final routePoints = await ref
          .read(navigationServiceProvider)
          .getRoute(
            _currentLocation!,
            LatLng(site.location!.latitude, site.location!.longitude),
          );
      if (mounted) {
        setState(() {
          _selectedSite = site;
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching route: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(culturalSitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Navigate Sites')),
      body: sitesAsync.when(
        data: (sites) {
          _markers.removeWhere(
            (marker) => marker.markerId.value != 'current_location',
          );
          for (var site in sites) {
            if (site.location != null) {
              _markers.add(
                Marker(
                  markerId: MarkerId(site.id),
                  position: LatLng(
                    site.location!.latitude,
                    site.location!.longitude,
                  ),
                  infoWindow: InfoWindow(title: site.name),
                  onTap: () => _showRoute(site),
                ),
              );
            }
          }
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-6.1659, 39.2026), // Zanzibar center
                  zoom: 12,
                ),
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_currentLocation != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLng(_currentLocation!),
                    );
                  }
                },
              ),
              if (_selectedSite != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Route to ${_selectedSite!.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _polylines.clear();
                                _selectedSite = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
