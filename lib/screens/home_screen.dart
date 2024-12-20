import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../models/publisher.dart';
import '../models/article.dart';
import '../services/api_service.dart';
import '../models/topic.dart';

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
  List<Article> _articles = [];
  late MapController _mapController;
  bool _isLoadingPublishers = true;
  bool _isLoadingArticles = false;

  Publisher? _selectedPublisher;

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
      setState(() {
        _publishers = publishers;
        _isLoadingPublishers = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Publisher: $e');
      setState(() {
        _isLoadingPublishers = false;
      });
    }
  }

  Future<void> _fetchNewsForPublisher(int publisherId) async {
    setState(() {
      _isLoadingArticles = true;
      _articles = [];
    });
    try {
      ApiService apiService = ApiService();
      List<Article> articles = await apiService.fetchNews(publisherId: publisherId);
      setState(() {
        _articles = articles;
        _isLoadingArticles = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Nachrichten: $e');
      setState(() {
        _isLoadingArticles = false;
      });
    }
  }

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
      options: const MapOptions(
        initialCenter: LatLng(0, 0),
        initialZoom: 4.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        if (!_isLoadingPublishers) MarkerLayer(
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
                  _mapController.move(
                    LatLng(
                      publisher.location.latitude,
                      publisher.location.longitude,
                    ),
                    9.0,
                  );
                  // Nachrichten für den ausgewählten Publisher laden
                  _fetchNewsForPublisher(publisher.id);
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
    if (_selectedPublisher == null) {
      return Center(child: Text('Bitte einen Publisher auswählen'));
    }

    if (_isLoadingArticles) {
      return Center(child: CircularProgressIndicator());
    }

    if (_articles.isEmpty) {
      return Center(child: Text('Keine Nachrichten verfügbar'));
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.builder(
        controller: sc,
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return ListTile(
            leading: Icon(Icons.article),
            title: Text(article.title),
            subtitle: Text(
              '${article.formattedDate}\n${article.publisher?.name ?? ''}',
            ),
            isThreeLine: true,
            onTap: () {
              // Artikel-Interaktion: Öffne Link im Browser oder zeige Detailseite
              // Beispiel (Link im Browser öffnen):
              // _openArticleLink(article.link);
            },
          );
        },
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
