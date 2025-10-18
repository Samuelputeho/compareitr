import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/entities/shop_entity.dart';
import '../../../../init_dependencies.dart';
import '../bloc/all_categories/all_categories_bloc.dart';
import '../bloc/all_shops/all_shops_bloc.dart';
import '../bloc/branches/branches_bloc.dart';
import '../widgets/category_tile.dart';

class CategoriesPage extends StatelessWidget {
  final String storeName;

  const CategoriesPage({
    super.key,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[800] 
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              iconSize: 20,
            ),
          ),
        ),
        title: BlocBuilder<AllShopsBloc, AllShopsState>(
          builder: (context, state) {
            if (state is AllShopsSuccess) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    initialValue: storeName,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          storeName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                    onSelected: (String newStore) {
                      if (newStore != storeName) {
                        // Get categories for the selected shop
                        context.read<AllCategoriesBloc>().add(
                               GetCategoriesByShopNameEvent(shopName: newStore ),
                            );
                        // Navigate to new categories page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoriesPage(
                              storeName: newStore,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return state.shops.map((shop) {
                        return PopupMenuItem<String>(
                          value: shop.shopName,
                          child: Text(shop.shopName),
                        );
                      }).toList();
                    },
                  ),
                  // Today's operating hours
                  _buildTodaysHours(state.shops, storeName, context),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  storeName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<AllShopsBloc, AllShopsState>(
            builder: (context, state) {
              if (state is AllShopsSuccess) {
                // Find the shop ID for the current store name
                print("Looking for shop with name: $storeName");
                print("Available shops: ${state.shops.map((s) => s.shopName).toList()}");
                
                ShopEntity? shop;
                try {
                  shop = state.shops.firstWhere(
                    (shop) => shop.shopName == storeName,
                  );
                  print("Found shop: ${shop.shopName} with ID: ${shop.id}");
                } catch (e) {
                  print("Shop not found, using fallback");
                  // Shop not found, use first shop as fallback
                  shop = state.shops.isNotEmpty ? state.shops.first : null;
                  if (shop != null) {
                    print("Using fallback shop: ${shop.shopName} with ID: ${shop.id}");
                  }
                }
                
                if (shop == null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[800] 
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: null,
                        icon: Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black,
                        ),
                        iconSize: 20,
                      ),
                    ),
                  );
                }
                
                return BlocProvider(
                  create: (context) => serviceLocator<BranchesBloc>()
                    ..add(GetBranchesByShopEvent(shopId: shop!.id)),
                  child: BlocBuilder<BranchesBloc, BranchesState>(
                    builder: (context, branchState) {
                      if (branchState is BranchesSuccess) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[800] 
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.location_on_outlined),
                              iconSize: 20,
                              onSelected: (String branchId) {
                                if (branchId == 'all') {
                                  context.read<BranchesBloc>().add(ClearBranchSelectionEvent());
                                } else {
                                  final selectedBranch = branchState.branches.firstWhere(
                                    (branch) => branch.id == branchId,
                                  );
                                  context.read<BranchesBloc>().add(SelectBranchEvent(branch: selectedBranch));
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'all',
                                    child: Row(
                                      children: [
                                        Icon(
                                          branchState.selectedBranch == null 
                                              ? Icons.radio_button_checked 
                                              : Icons.radio_button_unchecked,
                                          color: branchState.selectedBranch == null 
                                              ? Colors.green 
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('All Branches'),
                                      ],
                                    ),
                                  ),
                                  ...branchState.branches.map((branch) => PopupMenuItem<String>(
                                    value: branch.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          branchState.selectedBranch?.id == branch.id 
                                              ? Icons.radio_button_checked 
                                              : Icons.radio_button_unchecked,
                                          color: branchState.selectedBranch?.id == branch.id 
                                              ? Colors.green 
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(branch.branchName),
                                      ],
                                    ),
                                  )),
                                ];
                              },
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[800] 
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: null,
                            icon: Icon(
                              Icons.location_on_outlined,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.black,
                            ),
                            iconSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.location_on_outlined,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                    ),
                    iconSize: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AllCategoriesBloc, AllCategoriesState>(
        builder: (context, state) {
          if (state is AllCategoriesLoading) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (state is AllCategoriesFailure) {
            return Center(child: Text(state.message));
          }

          if (state is CategoriesByShopNameSuccess) {
            if (state.categories.isEmpty) {
              return const Center(child: Text('No categories found'));
            }
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return CategoryTile(
                    catName: category.categoryName,
                    imageUrl: category.categoryUrl,
                    storeName: category.shopName,
                  );
                },
              ),
            );
          }

          return const Center(child: Text('No categories found'));
        },
      ),
    );
  }

  Widget _buildTodaysHours(List<ShopEntity> shops, String storeName, BuildContext context) {
    try {
      final shop = shops.firstWhere((shop) => shop.shopName == storeName);
      
      if (shop.operatingHours != null) {
        final todayHours = shop.operatingHours!.getTodayHours();
        
        if (todayHours.isOpen && todayHours.openTime != null && todayHours.closeTime != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${todayHours.openTime} - ${todayHours.closeTime}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Closed Today',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Shop not found
    }
    
    return const SizedBox.shrink();
  }
}
