import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './pages/products_overview.dart';
import './pages/product_details.dart';
import './pages/orders_overview.dart';
import './pages/cart_overview.dart';
import './pages/user_products.dart';
import './pages/edit_product.dart';
import './pages/auth_overview.dart';
import './pages/splash_overview.dart';

import './providers/products.dart';
import './providers/orders.dart';
import './providers/cart.dart';
import './providers/auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Products>(
            create: (context) => Products(),
            update: (context, auth, product) => Products.updateToken(
                  auth.token,
                  auth.userId,
                  product == null ? [] : product.items,
                )),
        ChangeNotifierProvider.value(
          value: Cart(),
        ),
        ChangeNotifierProxyProvider<Auth, Orders>(
          create: (context) => Orders(),
          update: (context, auth, orders) => Orders.updateToken(
            auth.token,
            auth.userId,
            orders == null ? [] : orders.orders,
          ),
        ),
      ],
      child: Consumer<Auth>(
        builder: (context, auth, child) => MaterialApp(
          title: 'Shopping App',
          theme: ThemeData(
            primaryColor: Colors.purple,
            accentColor: Colors.deepOrange,
            fontFamily: 'Lato',
          ),
          home: auth.isAuth
              ? ProductsOverview()
              : FutureBuilder(
                  future: auth.autoLogin(),
                  builder: (context, authSnapshot) =>
                      authSnapshot.connectionState == ConnectionState.waiting
                          ? SplashOverview()
                          : AuthOverview()),
          routes: {
            ProductDetails.routeName: (ctx) => ProductDetails(),
            CartOverview.rountName: (ctx) => CartOverview(),
            OrdersOverview.routeName: (ctx) => OrdersOverview(),
            UserProducts.routeName: (ctx) => UserProducts(),
            EditProduct.routeName: (ctx) => EditProduct(),
          },
        ),
      ),
    );
  }
}
