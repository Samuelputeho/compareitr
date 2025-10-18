import 'package:compareitr/features/sales/presentation/pages/sale_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Importing the collection package
import 'package:compareitr/features/sales/presentation/bloc/salecard_bloc.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch the event to get sales when the page is initialized
    context.read<SalecardBloc>().add(GetAllSaleCardEvent());
  }

  int calculateDaysLeft(DateTime? endDate) {
    if (endDate == null) return 0; // If endDate is null, return 0 days left
    final currentDate = DateTime.now();
    return endDate.difference(currentDate).inDays;
  }

  // Helper function to check if the date range overlaps
  bool checkDateOverlap(DateTime productStart, DateTime productEnd, DateTime widgetStart, DateTime widgetEnd) {
    // Overlap occurs when:
    // 1. Product's start date is before or same as widget's end date.
    // 2. Product's end date is after or same as widget's start date.
    return (productStart.isBefore(widgetEnd) || productStart.isAtSameMomentAs(widgetEnd)) && 
           (productEnd.isAfter(widgetStart) || productEnd.isAtSameMomentAs(widgetStart));
  }

  Widget buildSaleItem(
      String image, DateTime? startDate, DateTime? endDate, String? storeName) {
    if (startDate == null || endDate == null) {
      return const SizedBox.shrink(); // Don't show invalid sales
    }

    final currentDate = DateTime.now();
    
    // Hide sales where the end date has already passed
    if (endDate.isBefore(currentDate)) {
      return const SizedBox.shrink(); // Don't show expired sales
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaleDetailsPage(
              storeName: storeName,
              startDate: startDate,  // Pass startDate here
              endDate: endDate,      // Pass endDate here
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade700 
                : Colors.grey,
          ),
        ),
        child: Stack(
          children: [
            // Image Container
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: HiveImageWidget(
                imageUrl: image,  // Image URL fetched from the database
                hiveKey: 'saleCardImage_${storeName.hashCode}',  // Use storeName for unique key
                width: double.infinity,
                height: 200,  // Fixed height for the image
                fit: BoxFit.cover,
              ),
            ),
            // End Date Text at the bottom
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'End Date: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated parameter to accept a List<Map<String, Object?>> instead of List<Map<String, DateTime?>>
  Widget buildStoreSection(
      String? storeName, List<Map<String, Object?>> sales) {
    final displayStoreName = storeName ?? "Unknown Store";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            displayStoreName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: sales.length,
          itemBuilder: (context, index) {
            return buildSaleItem(
              (sales[index]['imageUrl'] as String?) ?? '', 
              sales[index]['startDate'] as DateTime?,
              sales[index]['endDate'] as DateTime?,
              storeName,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SalecardBloc, SalecardState>(builder: (context, state) {
        if (state is SalecardLoading) {
          return Center(child: CircularProgressIndicator(color: Colors.green));
        } else if (state is SalecardSuccess) {
          final currentDate = DateTime.now();
          
          // Filter out expired sales before grouping
          final activeSales = state.saleCard.where((sale) {
            return sale.endDate != null && 
                   sale.startDate != null && 
                   sale.endDate!.isAfter(currentDate);
          }).toList();
          
          if (activeSales.isEmpty) {
            return const Center(
              child: Text(
                'No active sales available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          
          final groupedSales = groupBy(activeSales, (sale) => sale.storeName);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedSales.entries.map((entry) {
                final storeName = entry.key;
                final sales = entry.value.map((sale) {
                  return {
                    'startDate': sale.startDate,
                    'endDate': sale.endDate,
                    'imageUrl': sale.image,
                  };
                }).toList();

                return buildStoreSection(storeName, sales);
              }).toList(),
            ),
          );
        } else if (state is SalecardFailure) {
          return Center(
            child: Text(
              'Error loading sales: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return const Center(child: Text('No sales available.'));
      }),
    );
  }
}
