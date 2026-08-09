import 'package:flutter/material.dart';

typedef FilterCallback = void Function(String? selectedKey);
typedef KeyValuePair = ({String key, String value});

/// A reusable modal bottom sheet widget for filter selection.
/// Supports both key-value pairs (e.g., venue ID + name) and simple string items.
class FilterBottomSheet extends StatelessWidget {
  final String title;
  final List<dynamic> items; // List<KeyValuePair> or List<String>
  final String? selectedKey;
  final FilterCallback onSelected;
  final bool _isKeyValue;

  /// Constructor for key-value filters (e.g., venues with ID + name)
  const FilterBottomSheet.keyValue({
    super.key,
    required this.title,
    required List<KeyValuePair> items,
    required this.selectedKey,
    required this.onSelected,
  })  : _isKeyValue = true,
        items = items;

  /// Constructor for simple string filters (e.g., genres, neighborhoods)
  const FilterBottomSheet.simple({
    super.key,
    required this.title,
    required List<String> items,
    required this.selectedKey,
    required this.onSelected,
  })  : _isKeyValue = false,
        items = items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              // Filter list
              Flexible(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // "All" option (clears filter)
                    ListTile(
                      title: const Text('All'),
                      selected: selectedKey == null,
                      onTap: () {
                        onSelected(null);
                        Navigator.pop(sheetContext);
                      },
                      trailing: selectedKey == null
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                    ),
                    // Filter items
                    ..._buildItems(theme, sheetContext),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build list tile widgets for all items
  List<Widget> _buildItems(ThemeData theme, BuildContext context) {
    if (_isKeyValue) {
      return (items as List<KeyValuePair>).map((item) {
        return ListTile(
          title: Text(item.value),
          selected: selectedKey == item.key,
          onTap: () {
            onSelected(item.key);
            Navigator.pop(context);
          },
          trailing: selectedKey == item.key
              ? Icon(Icons.check, color: theme.colorScheme.primary)
              : null,
        );
      }).toList();
    } else {
      return (items as List<String>).map((item) {
        return ListTile(
          title: Text(item),
          selected: selectedKey == item,
          onTap: () {
            onSelected(item);
            Navigator.pop(context);
          },
          trailing: selectedKey == item
              ? Icon(Icons.check, color: theme.colorScheme.primary)
              : null,
        );
      }).toList();
    }
  }
}
