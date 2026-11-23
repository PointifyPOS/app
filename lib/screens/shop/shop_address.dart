import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/place_service.dart';

class AddressSearch extends SearchDelegate<Suggestion> {
  AddressSearch(this.sessionToken) {
    apiClient = PlaceApiProvider(sessionToken);
  }

  final String sessionToken;
  PlaceApiProvider? apiClient;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Get.back();
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Text('Enter your address'),
      );
    }
    // Typed text can always be used as-is, so a shop can be created even
    // without a Google Places API key (or when the lookup fails).
    final typed = ListTile(
      leading: const Icon(Icons.edit_location_alt_outlined),
      title: Text('Use "${query.trim()}"'),
      onTap: () => close(context, Suggestion("", query.trim())),
    );
    return FutureBuilder<List<Suggestion>>(
      future: apiClient?.fetchSuggestions(
          query, Localizations.localeOf(context).languageCode),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Suggestion>[];
        return ListView(
          children: [
            typed,
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Searching...'),
              ),
            ...items.map((s) => ListTile(
                  title: Text(s.description),
                  onTap: () => close(context, s),
                )),
          ],
        );
      },
    );
  }
}
