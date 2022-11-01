// Copyright 2019-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter_store/model/app_state_model.dart';
import 'package:flutter_store/model/product.dart';
import 'package:flutter_store/styles.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider<AppStateModel>(
      create: (context) => AppStateModel()..loadProducts(),
      child: const ShoppingApp(),
    ),
  );
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const HomePage(title: 'Material Store'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const _navBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.add_shopping_cart),
      label: 'Products',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_basket),
      label: 'Check out',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            ProductsPage(),
            CheckOutPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        onTap: (selectedIndex) {
          setState(() {
            _selectedIndex = selectedIndex;
          });
        },
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, model, child) {
        final products = model.getProducts();
        return ProductList(products: products);
      },
    );
  }
}

class ProductList extends StatelessWidget {
  const ProductList({Key? key, required this.products}) : super(key: key);
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductItem(
          product: products[index],
          last: index == products.length - 1,
        );
      },
    );
  }
}

class ProductItem extends StatelessWidget {
  const ProductItem({
    Key? key,
    required this.product,
    required this.last,
  }) : super(key: key);

  final Product product;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        top: 16,
        bottom: last ? 16 : 0,
        right: 8,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              product.assetName,
              package: product.assetPackage,
              fit: BoxFit.cover,
              width: 76,
              height: 76,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Styles.productRowItemName,
                  ),
                  const Padding(padding: EdgeInsets.only(top: 8)),
                  Text(
                    '\$${product.price}',
                    style: Styles.productRowItemPrice,
                  )
                ],
              ),
            ),
          ),
          MaterialButton(
            minWidth: 48,
            onPressed: () {
              Provider.of<AppStateModel>(context, listen: false)
                  .addProductToCart(product.id);
            },
            child: const Icon(Icons.add_shopping_cart),
          )
        ],
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<Product?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searchResults = Provider.of<AppStateModel>(context).search(query);
    return SafeArea(
      child: ProductList(products: searchResults),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final searchResults = Provider.of<AppStateModel>(context).search(query);
    return SafeArea(
      child: ProductList(products: searchResults),
    );
  }
}

class CheckOutPage extends StatelessWidget {
  const CheckOutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, model, child) {
        final cartProductQuantities = model.productsInCart;
        final currencyFormat = NumberFormat.currency(symbol: '\$');

        return ListView(
          children: [
            for (var id in cartProductQuantities.keys.toList()
              ..sort((a, b) => model
                  .getProductById(a)
                  .name
                  .compareTo(model.getProductById(b).name)))
              ShoppingCartItem(
                product: model.getProductById(id),
                quantity: cartProductQuantities[id],
                formatter: currencyFormat,
              ),
            if (cartProductQuantities.isNotEmpty)
              ShoppingCartTotals(currencyFormat: currencyFormat),
            if (cartProductQuantities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No items in the shopping cart yet...',
                  style: Styles.productRowItemName,
                ),
              ),
          ],
        );
      },
    );
  }
}

class ShoppingCartItem extends StatelessWidget {
  const ShoppingCartItem({
    Key? key,
    required this.product,
    required this.quantity,
    required this.formatter,
  }) : super(key: key);

  final Product product;
  final int? quantity;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        top: 16,
        bottom: 0,
        right: 8,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              product.assetName,
              package: product.assetPackage,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: Styles.productRowItemName,
                      ),
                      Text(
                        formatter.format(quantity! * product.price),
                        style: Styles.productRowItemName,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${quantity! > 1 ? '$quantity x ' : ''}'
                    '${formatter.format(product.price)}',
                    style: Styles.productRowItemPrice,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingCartTotals extends StatelessWidget {
  const ShoppingCartTotals({
    Key? key,
    required this.currencyFormat,
  }) : super(key: key);

  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, model, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Shipping '
                    '${currencyFormat.format(model.shippingCost)}',
                    style: Styles.productRowItemPrice,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tax ${currencyFormat.format(model.tax)}',
                    style: Styles.productRowItemPrice,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total  ${currencyFormat.format(model.totalCost)}',
                    style: Styles.productRowTotal,
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
