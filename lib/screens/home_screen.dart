import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/publisher_with_articles.dart';
import '../models/publishers_articles_list_response.dart';
import '../models/topic.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Panel
  final double _initFabHeight = 120.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 95.0;
  final PanelController _panelController = PanelController();

  // Map
  late MapController _mapController;

  // Daten aus dem Search-Endpunkt
  List<PublisherWithArticles> _publisherArticleGroups = [];

  // Topics (falls du sie für die Filter brauchst)
  List<Topic> _topics = [];

  // UI / Loading Flags
  bool _isLoading = false;
  bool _isLoadingTopics = false;

  // Ausgewählter Publisher inkl. Artikel
  PublisherWithArticles? _selectedPublisherWithArticles;

  // Filter
  String? _searchQuery;
  String? _selectedCountry;
  List<int> _selectedTopics = [];
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Autocomplete
  List<String> _suggestions = [];
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocus = FocusNode();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _fabHeight = _initFabHeight;
    _mapController = MapController();

    _searchPublishersWithArticles();
    _fetchTopics();

    // Listener für Fokus auf Suchfeld
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        setState(() {
          _showFilters = true; // Filter anzeigen, wenn Suchfeld fokussiert
        });
      } else {
        // Falls du die Filter wieder ausblenden möchtest, wenn
        // das Textfeld den Fokus verliert:
        
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

  /// Lädt Topics für die Filter
  Future<void> _fetchTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final apiService = ApiService();
      final fetchedTopics = await apiService.fetchTopics();
      setState(() {
        _topics = fetchedTopics;
        _isLoadingTopics = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Topics: $e');
      setState(() => _isLoadingTopics = false);
    }
  }

  /// Lädt Autocomplete-Vorschläge
  Future<void> _fetchAutocomplete(String query) async {
    final apiService = ApiService();
    try {
      final suggestions = await apiService.fetchAutocompleteSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      print('Fehler beim Laden der Autocomplete Vorschläge: $e');
    }
  }

  /// Fragt den /api/v01/search-Endpunkt ab und speichert die Ergebnisse
  Future<void> _searchPublishersWithArticles() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.searchPublishersWithArticles(
        keywords: _searchQuery,
        country: _selectedCountry,
        topics: _selectedTopics.isNotEmpty ? _selectedTopics : null,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        page: 1,
        pageSize: 200,
      );

      // Wir erhalten PublishersArticlesListResponse
      setState(() {
        _publisherArticleGroups = response.items; 
        _isLoading = false;
      });
    } catch (e) {
      print('Fehler beim Laden von Publishers & Articles: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Methode zum Öffnen eines Artikel-Links im Browser
  Future<void> _openArticleLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  /// Anwenden der Filter (z. B. wenn auf den Check-Button in der Suchleiste geklickt wird)
  void _applyFiltersAndSearch() {
    _searchQuery = _searchController.text.isNotEmpty ? _searchController.text : null;
    setState(() {
          _showFilters = false;
        });
    FocusScope.of(context).unfocus(); // Tastatur schließen
    _searchPublishersWithArticles();
  }

  /// Wird aufgerufen, wenn ein Publisher auf der Karte getappt wird
  void _selectPublisher(PublisherWithArticles pwa) {
    setState(() {
      _selectedPublisherWithArticles = pwa;
    });
    // Karte zentrieren
    _mapController.move(
      LatLng(
        pwa.publisher.location.latitude ?? 0.0,
        pwa.publisher.location.longitude ?? 0.0,
      ),
      8.0,
    );
    // Panel öffnen
    _panelController.open();
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // Baue Marker nur für die gelisteten Publisher (aus _publisherArticleGroups)
    final markers = _publisherArticleGroups.map((pwa) {
      final pub = pwa.publisher;
      return Marker(
        point: LatLng(
          pub.location.latitude ?? 0.0,
          pub.location.longitude ?? 0.0,
        ),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _selectPublisher(pwa),
          child: Icon(
            Icons.location_on,
            color: _selectedPublisherWithArticles?.publisher.id == pub.id
                ? Colors.red
                : Colors.blue,
            size: 40,
          ),
        ),
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(0, 0),
        initialZoom: 3.0,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        MarkerLayer(markers: markers),
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
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18.0),
        topRight: Radius.circular(18.0),
      ),
      panelBuilder: (ScrollController sc) => _panel(sc),
      onPanelSlide: (double pos) => setState(() {
        _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
      }),
    );
  }

  Widget _panel(ScrollController sc) {
    if (_selectedPublisherWithArticles == null &&
        (_searchQuery == null || _searchQuery!.isEmpty)) {
      return const Center(child: Text('Bitte einen Publisher auswählen oder Filter setzen'));
    }

    final articles = _selectedPublisherWithArticles?.articles ?? [];
    if (articles.isEmpty) {
      return const Center(child: Text('Keine Nachrichten verfügbar'));
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.builder(
        controller: sc,
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return ListTile(
            leading: const Icon(Icons.article),
            title: Text(article.title),
            subtitle: Text(
              '${article.formattedDate}\n'
              '${article.publisher?.name ?? ''}',
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
          boxShadow: const [
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
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: _applyFiltersAndSearch,
              tooltip: 'Filter anwenden und suchen',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final topPosition = MediaQuery.of(context).padding.top + 70;

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
    final topPosition = MediaQuery.of(context).padding.top + 70 +
        (_suggestions.isNotEmpty ? 200 : 0);

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
                  title: const Text('Themen auswählen'),
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

              // Land-Filter
              TextField(
                decoration: const InputDecoration(
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
                      child: Text(_dateFrom == null
                          ? 'Von Datum'
                          : 'Von: ${_dateFrom!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateTo = picked;
                          });
                        }
                      },
                      child: Text(_dateTo == null
                          ? 'Bis Datum'
                          : 'Bis: ${_dateTo!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _applyFiltersAndSearch,
                child: const Text('Filter anwenden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
