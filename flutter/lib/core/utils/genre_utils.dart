/// Split pipe-separated genre string into a deduplicated, sorted list.
List<String> splitGenres(String genreString) {
  if (genreString.isEmpty) return [];
  return genreString
      .split('|||')
      .map((g) => g.trim())
      .where((g) => g.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

/// Join a list of genres into a pipe-separated string.
String joinGenres(List<String> genres) {
  return genres.join('|||');
}
