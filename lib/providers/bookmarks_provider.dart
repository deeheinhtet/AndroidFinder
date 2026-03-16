import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBookmark {
  final String label;
  final String path;
  final int iconCode;

  const CustomBookmark({
    required this.label,
    required this.path,
    this.iconCode = 0xe2c7, // folder icon
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() =>
      {'label': label, 'path': path, 'iconCode': iconCode};

  factory CustomBookmark.fromJson(Map<String, dynamic> j) => CustomBookmark(
        label: j['label'] as String,
        path: j['path'] as String,
        iconCode: (j['iconCode'] as int?) ?? 0xe2c7,
      );
}

class BookmarksState {
  final List<CustomBookmark> bookmarks;

  const BookmarksState({this.bookmarks = const []});

  BookmarksState copyWith({List<CustomBookmark>? bookmarks}) =>
      BookmarksState(bookmarks: bookmarks ?? this.bookmarks);
}

class BookmarksNotifier extends StateNotifier<BookmarksState> {
  static const _key = 'custom_bookmarks';

  BookmarksNotifier() : super(const BookmarksState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => CustomBookmark.fromJson(e as Map<String, dynamic>))
            .toList();
        state = BookmarksState(bookmarks: list);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.bookmarks.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> addBookmark(String label, String path,
      {int iconCode = 0xe2c7}) async {
    if (state.bookmarks.any((b) => b.path == path)) return;
    final updated = [
      ...state.bookmarks,
      CustomBookmark(label: label, path: path, iconCode: iconCode),
    ];
    state = state.copyWith(bookmarks: updated);
    await _save();
  }

  Future<void> removeBookmark(String path) async {
    final updated = state.bookmarks.where((b) => b.path != path).toList();
    state = state.copyWith(bookmarks: updated);
    await _save();
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, BookmarksState>((ref) {
  return BookmarksNotifier();
});
