import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/publisher.dart';
import '../models/article.dart';
import '../models/topic.dart';
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

  late MapController _mapController;

  List<Publisher> _publishers = [];
  List<Article> _articles = [];
  List<Topic> _topics = [];
  List<String> _suggestions = [];

  bool _isLoadingPublishers = true;
  bool _isLoadingArticles = false;
  bool _isLoadingTopics = false;

  Publisher? _selectedPublisher;

  // Filter
  String? _searchQuery;
  String? _selectedCountry;
  List<int> _selectedTopics = [];
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // UI für Autocomplete
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocus = FocusNode();
  bool _showFilters = false; // Zeigt an, ob Filter unter der Suchleiste angezeigt werden sollen.

  @override
  void initState() {
    super.initState();
    _fabHeight = _initFabHeight;
    _mapController = MapController();
    _fetchPublishersAndTopics();

    // Listener für Fokus auf Suchfeld
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        setState(() {
          _showFilters = true; // Filter anzeigen, wenn Suchfeld fokussiert
        });
      } else {
        // Wenn das Suchfeld den Fokus verliert, könnte man die Filter wieder ausblenden
        // setState(() { _showFilters = false; });
      }
    });

    // Autocomplete beim Tippen
    _searchController.addListener(() {
      final query = _searchController.text;
      if (query.isNotEmpty) {
        _fetchAutocomplete(query);
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _fetchPublishersAndTopics() async {
    try {
      ApiService apiService = ApiService();
      _isLoadingPublishers = true;
      _isLoadingTopics = true;

      final publishers = await apiService.fetchPublishers(country: _selectedCountry);
      final topics = await apiService.fetchTopics();

      setState(() {
        _publishers = publishers;
        _topics = topics;
        _isLoadingPublishers = false;
        _isLoadingTopics = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Basisdaten: $e');
      setState(() {
        _isLoadingPublishers = false;
        _isLoadingTopics = false;
      });
    }
  }

  Future<void> _fetchAutocomplete(String query) async {
    ApiService apiService = ApiService();
    try {
      final suggestions = await apiService.fetchAutocompleteSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      print('Fehler beim Laden der Autocomplete Vorschläge: $e');
    }
  }

  Future<void> _fetchNewsAndPublishers() async {
    setState(() {
      _isLoadingPublishers = true;
      _isLoadingArticles = true;
    });

    ApiService apiService = ApiService();

    try {
      // Publisher neu laden mit Filtern (z. B. country)
      final publishers = await apiService.fetchPublishers(country: _selectedCountry);

      // Wenn ein Publisher ausgewählt ist, zeige dessen News; ansonsten alle News entsprechend Filter
      final articles = await apiService.fetchNews(
        publisherId: _selectedPublisher?.id,
        keywords: _searchQuery,
        topics: _selectedTopics.isNotEmpty ? _selectedTopics : null,
        country: _selectedCountry,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      setState(() {
        _publishers = publishers;
        _articles = articles;
        _isLoadingPublishers = false;
        _isLoadingArticles = false;
      });
    } catch (e) {
      print('Fehler beim Laden von News oder Publishers: $e');
      setState(() {
        _isLoadingPublishers = false;
        _isLoadingArticles = false;
      });
    }
  }

  Future<void> _openArticleLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  void _applyFiltersAndSearch() {
    // Filter anwenden
    _searchQuery = _searchController.text.isNotEmpty ? _searchController.text : null;
    // Nach Anwenden der Filter neu laden
    _fetchNewsAndPublishers();
    FocusScope.of(context).unfocus(); // Tastatur schließen
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
          if (_searchFocus.hasFocus && _suggestions.isNotEmpty) _buildSuggestionsList(),
          if (_showFilters) _buildFilterOptions(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(0, 0),
        initialZoom: 3.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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
                    8.0,
                  );
                  _fetchNewsAndPublishers();
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
    if (_selectedPublisher == null && (_searchQuery == null || _searchQuery!.isEmpty)) {
      return Center(child: Text('Bitte einen Publisher auswählen oder Filter setzen'));
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
              _openArticleLink(article.link);
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
          controller: _searchController,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: 'Suche',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
            suffixIcon: IconButton(
              icon: Icon(Icons.check),
              onPressed: _applyFiltersAndSearch,
              tooltip: 'Filter anwenden und suchen',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final topPosition = MediaQuery.of(context).padding.top + 70; // etwas unter der Suche

    return Positioned(
      top: topPosition,
      left: 16,
      right: 16,
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _suggestions[index];
            return ListTile(
              title: Text(suggestion),
              onTap: () {
                // Vorschlag übernehmen
                _searchController.text = suggestion;
                _searchFocus.unfocus();
                _applyFiltersAndSearch();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    // Ein einfaches Beispiel für Filter: Themen-Dropdown, Land-Textfeld, Zeitraum-Picker
    final topPosition = MediaQuery.of(context).padding.top + 70 + (_suggestions.isNotEmpty ? 200 : 0);

    return Positioned(
      top: topPosition,
      left: 16,
      right: 16,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Themenauswahl (einfach als Checkboxes)
              if (!_isLoadingTopics)
                ExpansionTile(
                  title: Text('Themen auswählen'),
                  children: _topics.map((t) {
                    final selected = _selectedTopics.contains(t.id);
                    return CheckboxListTile(
                      title: Text(t.topicName),
                      value: selected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTopics.add(t.id);
                          } else {
                            _selectedTopics.remove(t.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

              // Land-Filter (einfach ein TextField für ISO Code)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Ländercode (z. B. DE, US)',
                ),
                onChanged: (val) {
                  _selectedCountry = val.isNotEmpty ? val : null;
                },
              ),

              // Zeitraum-Filter
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateFrom = picked;
                          });
                        }
                      },
                      child: Text(_dateFrom == null ? 'Von Datum' : 'Von: ${_dateFrom!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateTo = picked;
                          });
                        }
                      },
                      child: Text(_dateTo == null ? 'Bis Datum' : 'Bis: ${_dateTo!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _applyFiltersAndSearch,
                child: Text('Filter anwenden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
