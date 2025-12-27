
// import 'package:flutter/foundation.dart';

abstract class DatabaseRepository<T> {
  Future<List<T>> getItems();
  Future<T?> getItem(String id);
  Future<String> createItem(T item);
  Future<void> updateItem(T item);
  Future<void> deleteItem(String id);
  Stream<List<T>> watchItems();
}
