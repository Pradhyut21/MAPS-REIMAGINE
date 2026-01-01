import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/models/collection.dart';
import 'package:wayfinder/models/saved_place.dart';
import 'package:wayfinder/screens/home_page.dart';
import 'package:wayfinder/services/collection_service.dart';
import 'package:wayfinder/services/saved_place_service.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/widgets/app_background.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final _collectionService = CollectionService();
  final _savedService = SavedPlaceService();
  final _nameController = TextEditingController();
  final _userId = 'local_user';

  List<Collection> _collections = [];
  Map<String, List<SavedPlace>> _items = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cols = await _collectionService.getCollections(_userId);
    final Map<String, List<SavedPlace>> items = {};
    for (final c in cols) {
      items[c.id] = await _collectionService.getPlacesInCollection(userId: _userId, collectionId: c.id);
    }
    setState(() {
      _collections = cols;
      _items = items;
      _loading = false;
    });
  }

  Future<void> _createCollection() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final c = Collection(id: 'col_${DateTime.now().millisecondsSinceEpoch}', userId: _userId, name: name, createdAt: DateTime.now(), updatedAt: DateTime.now());
    await _collectionService.upsertCollection(c);
    _nameController.clear();
    await _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collections', style: context.textStyles.titleLarge),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: AppGradientBackground(
        child: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : Padding(
              padding: AppSpacing.paddingMd,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(hintText: 'New collection name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _createCollection,
                    icon: Icon(Icons.add),
                    label: Text('Create'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                  ),
                ]),
                SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _collections.isEmpty
                      ? Center(child: Text('No collections yet. Create one to organize saved places.'))
                      : ListView.separated(
                          itemCount: _collections.length,
                          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) {
                            final c = _collections[i];
                            final places = _items[c.id] ?? [];
                            return Container(
                              padding: AppSpacing.paddingMd,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2))),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(child: Text(c.name, style: context.textStyles.titleMedium)),
                                  Text('${places.length}'),
                                ]),
                                if (places.isNotEmpty) ...[
                                  SizedBox(height: AppSpacing.sm),
                                  Column(children: places.map((p) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.place),
                                        title: Text(p.placeName),
                                        subtitle: Text(p.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      )).toList()),
                                ],
                              ]),
                            );
                          },
                        ),
                )
              ]),
            ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
