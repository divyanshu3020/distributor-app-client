import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAdjustStockDialog(BuildContext context, Product product, bool isStaff) {
    final stockController = TextEditingController(text: product.stockQuantity.toString());
    final reasonController = TextEditingController(text: 'Daily morning shift reconciliation');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Adjust Stock: ${product.sku}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: stockController,
                label: 'Physical Stock Count (Units)',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || int.tryParse(val) == null) {
                    return 'Enter a valid whole number';
                  }
                  if (int.parse(val) < 0) {
                    return 'Stock cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: reasonController,
                label: 'Adjustment Reason / Audit Log',
                hint: 'e.g., Morning stock count, Inflow from Line 1',
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newStock = int.parse(stockController.text.trim());
              final reason = reasonController.text.trim();

              final success = await context.read<InventoryService>().updateStockQuantity(
                    productId: product.id,
                    newQuantity: newStock,
                    reason: reason,
                    isStaff: isStaff,
                  );

              if (mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Stock updated to $newStock units!' : 'Failed to update stock.'),
                    backgroundColor: success ? AppTheme.successGreen : AppTheme.alertRed,
                  ),
                );
              }
            },
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }

  void _showPriceAndCapsDialog(BuildContext context, Product product) {
    final priceController = TextEditingController(text: product.unitPrice.toString());
    final thresholdController = TextEditingController(text: product.lowStockThreshold.toString());
    final capController = TextEditingController(text: product.perDistributorMaxCap.toString());
    final queueCapController = TextEditingController(text: product.globalQueueCap.toString());
    final leadDaysController = TextEditingController(text: product.productionLeadDaysPerBatch.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Admin Catalog Controls'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.name} (${product.sku})',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: priceController,
                  label: 'Base Catalog Price (₹/unit)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'Invalid price' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: thresholdController,
                  label: 'Low Stock Threshold (Units)',
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid number' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: capController,
                  label: 'Distributor Max Cap (Packages)',
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid number' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: queueCapController,
                  label: 'Global Queue Cap (Units)',
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid number' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: leadDaysController,
                  label: 'Production Lead Time (Days/Batch)',
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid number' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final price = double.parse(priceController.text.trim());
              final threshold = int.parse(thresholdController.text.trim());
              final cap = int.parse(capController.text.trim());
              final queueCap = int.parse(queueCapController.text.trim());
              final leadDays = int.parse(leadDaysController.text.trim());

              final success = await context.read<InventoryService>().updateProductPriceAndSettings(
                    productId: product.id,
                    newUnitPrice: price,
                    lowStockThreshold: threshold,
                    perDistributorMaxCap: cap,
                    globalQueueCap: queueCap,
                    leadDays: leadDays,
                  );

              if (mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Catalog settings updated successfully!' : 'Failed to update settings.'),
                    backgroundColor: success ? AppTheme.successGreen : AppTheme.alertRed,
                  ),
                );
              }
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final inventoryService = context.watch<InventoryService>();
    final isSuperAdmin = authService.currentProfile?.isSuperAdmin ?? false;
    final isStaff = authService.currentProfile?.isStaff ?? false;

    final products = inventoryService.filteredProducts.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(isSuperAdmin ? 'Inventory & Catalog Controls' : 'Daily Stock Reconciliation'),
      ),
      body: Column(
        children: [
          // Role notice banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isSuperAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
            child: Row(
              children: [
                Icon(
                  isSuperAdmin ? Icons.admin_panel_settings : Icons.lock_outline,
                  size: 18,
                  color: isSuperAdmin ? AppTheme.primaryBlue : const Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSuperAdmin
                        ? 'Super Admin Mode: Full pricing, threshold, cap, and stock control.'
                        : 'Staff Mode: Stock quantity updates only. Product pricing & caps are strictly locked.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSuperAdmin ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Container(
            color: AppTheme.surfaceWhite,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search SKU or product to reconcile...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final product = products[idx];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                          ),
                          Text(
                            product.sku,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Metrics Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Stock (Pieces)',
                              value: '${product.stockQuantity}',
                              isAlert: product.stockQuantity <= 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Base Price',
                              value: CurrencyFormatter.format(product.unitPrice),
                              isLocked: !isSuperAdmin,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              label: 'Cap / Order',
                              value: '${product.perDistributorMaxCap} pkgs',
                              isLocked: !isSuperAdmin,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showAdjustStockDialog(context, product, isStaff),
                              icon: const Icon(Icons.edit_calendar, size: 16),
                              label: const Text('Update Count'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          if (isSuperAdmin) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showPriceAndCapsDialog(context, product),
                                icon: const Icon(Icons.tune, size: 16),
                                label: const Text('Price & Caps'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    bool isAlert = false,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAlert ? const Color(0xFFFECACA) : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock, size: 10, color: Color(0xFF94A3B8)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isAlert ? const Color(0xFFDC2626) : AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
