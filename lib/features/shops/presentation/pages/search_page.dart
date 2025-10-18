import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:compareitr/features/shops/presentation/bloc/all_products/all_products_bloc.dart';
import 'package:compareitr/features/shops/presentation/pages/product_details_page.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasTyped = false; // Tracks whether the user has started typing

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _hasTyped = value.isNotEmpty; // Update typing state
                });

                if (value.isNotEmpty) {
                  context
                      .read<AllProductsBloc>()
                      .add(SearchProductsEvent(value));
                  _scrollController.animateTo(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                } else {
                  context.read<AllProductsBloc>().add(GetAllProductsEvent());
                }
              },
            ),
          ),
          Expanded(
            child: _hasTyped
                ? BlocBuilder<AllProductsBloc, AllProductsState>(
                    builder: (context, state) {
                      if (state is GetAllProductsSuccess) {
                        final products = state.products;

                        if (products.isEmpty) {
                          return Center(
                            child: Text(
                              'No results found for "${_searchController.text}".',
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(10),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${product.measure} - ${product.shopName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  'N\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsPage(
                                        product: product,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      } else if (state is GetAllProductsFailure) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Failed to load products: ${state.message}'),
                              ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<AllProductsBloc>()
                                      .add(GetAllProductsEvent());
                                },
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Center(child: CircularProgressIndicator(color: Colors.green));
                    },
                  )
                : Center(
                    child: Text(
                      'Start typing to search for products.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
