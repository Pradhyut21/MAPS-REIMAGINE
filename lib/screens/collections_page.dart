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

  Future<void> _confirmDeleteCollection(Collection c) async {
    final theme = Theme.of(context);
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.delete_forever, color: theme.colorScheme.error),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Delete collection', style: context.textStyles.titleLarge)),
            ]),
            SizedBox(height: AppSpacing.sm),
            Text("This will remove ‘${c.name}’ and unlink its places. Your saved places remain intact.", style: context.textStyles.bodyMedium),
            SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.close, color: theme.colorScheme.onSurface),
                    SizedBox(width: 6),
                    Text('Cancel', style: (context.textStyles.labelLarge ?? const TextStyle()).copyWith(color: theme.colorScheme.onSurface))
                  ]),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.delete_outline, color: theme.colorScheme.onError),
                    SizedBox(width: 6),
                    Text('Delete', style: (context.textStyles.labelLarge ?? const TextStyle()).copyWith(color: theme.colorScheme.onError))
                  ]),
                ),
              ),
            ])
          ]),
        );
      },
    );
    if (result == true) {
      try {
        await _collectionService.deleteCollection(_userId, c.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${c.name}')));
        }
        await _load();
      } catch (e) {
        debugPrint('Failed to delete collection: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete. Please try again.')));
        }
      }
    }
  }

  Future<void> _removePlace(String collectionId, SavedPlace p) async {
    try {
      await _collectionService.removePlaceFromCollection(collectionId: collectionId, savedPlaceId: p.id);
      await _load();
    } catch (e) {
      debugPrint('Failed to remove place from collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove place')));
      }
    }
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
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
                                    child: Text('${places.length}'),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete collection',
                                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                    onPressed: () => _confirmDeleteCollection(c),
                                  ),
                                ]),
                                if (places.isNotEmpty) ...[
                                  SizedBox(height: AppSpacing.sm),
                                  Column(children: places.map((p) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.place, color: Theme.of(context).colorScheme.secondary),
                                        title: Text(p.placeName),
                                        subtitle: Text(p.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        trailing: IconButton(
                                          tooltip: 'Remove from collection',
                                          icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.tertiary),
                                          onPressed: () => _removePlace(c.id, p),
                                        ),
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
