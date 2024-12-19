// lib/screens/home_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../models/publisher.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final double _initFabHeight = 120.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 95.0;

  final PanelController _panelController = PanelController();

  List<Publisher> _publishers = [];
  late MapController _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fabHeight = _initFabHeight;
    _mapController = MapController();

    _fetchPublishers();
  }

  Future<void> _fetchPublishers() async {
    try {
      ApiService apiService = ApiService();
      List<Publisher> publishers = await apiService.fetchPublishers();
      print("done");
      setState(() {
        _publishers = publishers;
        print('Publisher geladen: ${_publishers.length}');
        _isLoading = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Publisher: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Publisher? _selectedPublisher;

  @override
  Widget build(BuildContext context) {
    _panelHeightOpen = MediaQuery.of(context).size.height * 0.6;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          _buildMap(),
          _buildSlidingUpPanel(),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(0, 0),
        initialZoom: 2.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        if (!_isLoading) 
          MarkerLayer(
            markers: _publishers.map((publisher) {
              return Marker(
                point: LatLng(
                  publisher.location.latitude,
                  publisher.location.longitude,
                ),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPublisher = publisher;
                    });
                    // Karte zum Marker zentrieren
                    _mapController.move(
                      LatLng(
                        publisher.location.latitude,
                        publisher.location.longitude,
                      ),
                      8.0, // Zoomstufe
                    );
                    // Panel öffnen
                    _panelController.open();
                  },
                  child: Icon(
                    Icons.location_on,
                    color: _selectedPublisher == publisher
                        ? Colors.red
                        : Colors.blue,
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSlidingUpPanel() {
    return SlidingUpPanel(
      controller: _panelController,
      maxHeight: _panelHeightOpen,
      minHeight: _panelHeightClosed,
      parallaxEnabled: true,
      parallaxOffset: 0.5,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(18.0),
        topRight: Radius.circular(18.0),
      ),
      panelBuilder: (ScrollController sc) => _panel(sc),
      onPanelSlide: (double pos) => setState(() {
        _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) +
            _initFabHeight;
      }),
    );
  }

  Widget _panel(ScrollController sc) {
    return _selectedPublisher == null
        ? Center(child: Text('Bitte einen Publisher auswählen'))
        : MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              controller: sc,
              children: <Widget>[
                SizedBox(height: 12.0),
                Center(
                  child: Container(
                    width: 30,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          BorderRadius.all(Radius.circular(12.0)),
                    ),
                  ),
                ),
                SizedBox(height: 18.0),
                ListTile(
                  leading: Icon(Icons.business),
                  title: Text(_selectedPublisher!.name),
                  subtitle: Text(
                    '${_selectedPublisher!.location.city ?? ''}, ${_selectedPublisher!.location.country ?? ''}',
                  ),
                ),
                // Weitere Informationen hinzufügen
              ],
            ),
          );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Suche',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}
