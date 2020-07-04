import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';

import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  String _authToken;
  String _userId;

  Products() {
    this._authToken = null;
    this._userId = null;
  }

  Products.updateToken(this._authToken, this._userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((element) => element.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((element) => element.id == id);
  }

  Future<void> fetchAndSetProduct([bool filterByUser = false]) async {
    final filterUser =
        filterByUser ? 'orderBy="creatorId"&equalTo="$_userId"' : '';
    final url =
        'https://flutter-shop-a9e5b.firebaseio.com/products.json?auth=$_authToken&$filterUser';
    try {
      final response = await http.get(url);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      if (loadedProducts == null) {
        return;
      }
      final url2 =
          'https://flutter-shop-a9e5b.firebaseio.com/userFavorites/$_userId.json?auth=$_authToken';
      final favoriteRes = await http.get(url2);
      final favoriteInfo = json.decode(favoriteRes.body);
      data.forEach((key, value) {
        loadedProducts.add(Product(
          id: key,
          title: value['title'],
          description: value['description'],
          price: value['price'],
          imageUrl: value['imageUrl'],
          isFavorite: favoriteInfo == null ? false : favoriteInfo[key] ?? false,
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://flutter-shop-a9e5b.firebaseio.com/products.json?auth=$_authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': _userId,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    final index = _items.indexWhere((element) => element.id == id);
    if (index >= 0) {
      final url =
          'https://flutter-shop-a9e5b.firebaseio.com/products/$id.json?auth=$_authToken';
      await http.patch(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
        }),
      );
      _items[index] = product;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://flutter-shop-a9e5b.firebaseio.com/products/$id.json?auth=$_authToken';

    final oldIndex = _items.indexWhere((element) => element.id == id);
    var oldProduct = _items[oldIndex];
    _items.removeAt(oldIndex);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(oldIndex, oldProduct);
      notifyListeners();
      throw HttpException('Invalid request');
    }
    oldProduct = null;
  }
}
