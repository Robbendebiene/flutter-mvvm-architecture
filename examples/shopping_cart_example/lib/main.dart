
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart' hide View, Notification;
import 'package:flutter_mvvm_architecture/base.dart';
import 'package:flutter_mvvm_architecture/extras.dart';

void main() {
  runApp(const MainWidget());
}

class MainWidget extends StatelessWidget {
  const MainWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Create an provide ShoppingCart model to View "require" functions
    // Usually you would have a class like "GlobalStore" that contains/instantiates all your globally shared models.
    return SharedModel(
      create: ShoppingCart.new,
      child: MaterialApp(
        scaffoldMessengerKey: GlobalNotificationHandler.globalKey,
        home: ProductsView(),
      ),
    );
  }
}

// MODELS \\

class ShoppingCart {
  final items = ObservableList<Product>();
}

class Product {
  final String name;
  Product(this.name);
}

// PRODUCTS - VIEW + VIEW MODEL \\

class ProductsViewModel extends ViewModel {
  final ShoppingCart _cart;
  ProductsViewModel(this._cart);

  // imagine they are fetched via a service/repo
  late final products = UnmodifiableListView([
    Product('Dummy1'),
    Product('Delicious'),
    Product('No refund'),
    Product('Great product'),
  ]);

  late final _productsCount = Computed<int>(() => _cart.items.length);
  int get productsCount => _productsCount.value;

  void add(int index) {
    final product = products[index];
    final productCartIndex = _cart.items.length;
    runInAction(() => _cart.items.add(product));
    request(Notification(
      '"${product.name}" has been added to your cart.',
      actionLabel: 'Revert',
      action: () => _cart.items.removeAt(productCartIndex),
    )).ignore();
  }
}

class ProductsView extends View<ProductsViewModel> with GlobalNotificationHandler {
  ProductsView({super.key}) : super(
    create: (require) => ProductsViewModel(
      require<ShoppingCart>(),
    ),
  );

  @override
  Widget build(context, viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Nice Shop'),
        actions: [
          IconButton(
            icon: Badge.count(
              count: viewModel.productsCount,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ShoppingCartView()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: viewModel.products.length,
        itemBuilder: (context, index) => ProductCard(
          name: viewModel.products[index].name,
          onAddToCart: () => viewModel.add(index),
          onCardTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductPage(
              product:  viewModel.products[index],
            )),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final VoidCallback onAddToCart;
  final VoidCallback onCardTap;

  const ProductCard({
    required this.name,
    required this.onAddToCart,
    required this.onCardTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCardTap,
        child: Column(
          children: [
            Container(
              color: Colors.primaries[Random(name.hashCode).nextInt(Colors.primaries.length)],
              height: 100,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name),
                  IconButton(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SHOPPING CART - VIEW AND + MODEL \\

class ShoppingCartViewModel extends ViewModel {
  final ShoppingCart _cart;
  ShoppingCartViewModel(this._cart);

  late final items = UnmodifiableListView(_cart.items);

  void remove(int index) {
    runInAction(() => _cart.items.removeAt(index));
  }

  void clear() async {
    final response = await request(Choice(
      message: 'Do you really want to remove all your precious products?',
      isDismissible: true,
      choices: {
        'Yes': true,
        'No': null,
      }
    ));
    if (response == true) {
      runInAction(() => _cart.items.clear());
    }
  }
}

class ShoppingCartView extends View<ShoppingCartViewModel> with ChoiceHandler {
  ShoppingCartView({super.key}) : super(
    create: (require) => ShoppingCartViewModel(
      require<ShoppingCart>(),
    ),
  );

  @override
  Widget build(context, viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_shopping_cart_outlined),
            onPressed: viewModel.clear,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: viewModel.items.length,
        itemBuilder: (context, index) => ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductPage(
                product:  viewModel.items[index],
              )),
            );
          },
          title: Text(viewModel.items[index].name),
          trailing: IconButton(
            onPressed: () => viewModel.remove(index),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ),
    );
  }
}

// PRODUCT PAGE - VIEW AND + MODEL \\

class ProductPageViewModel extends ViewModel with MakeTickerProvider {
  final Product _product;

  ProductPageViewModel(this._product);

  String get name => _product.name;

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  late final animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  void runAnimation() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ProductPage extends View<ProductPageViewModel> with TickerProviderHandler {
  ProductPage({
    required Product product,
    super.key,
  }) : super(
    create: (_) => ProductPageViewModel(product),
  );

  @override
  Widget build(context, viewModel) {
    return Scaffold(
      floatingActionButton: RotationTransition(
        turns: viewModel.animation,
        child: FloatingActionButton.small(
          tooltip: 'Just for demonstrating animation controller',
          onPressed: viewModel.runAnimation,
          child: const Icon(Icons.screen_rotation_alt_rounded),
        ),
      ),
      appBar: AppBar(
        title: Text(viewModel.name),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Container(
        color: Colors.primaries[Random(viewModel.name.hashCode).nextInt(Colors.primaries.length)],
      )
    );
  }
}
