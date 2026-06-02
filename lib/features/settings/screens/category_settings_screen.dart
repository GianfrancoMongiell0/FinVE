import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/daos/category_dao.dart';
import '../../../core/models/category.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';

final _categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return CategoryDao.instance.getAll();
});

class CategorySettingsScreen extends ConsumerWidget {
  const CategorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) {
          if (cats.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'Sin categorías',
              actionLabel: 'Nueva categoría',
              onAction: () => _showForm(context, ref, null),
            );
          }
          final income = cats.where((c) => c.type == 'income').toList();
          final expense = cats.where((c) => c.type == 'expense').toList();
          final both = cats.where((c) => c.type == 'both').toList();

          return ListView(
            children: [
              if (expense.isNotEmpty) ...[
                _Header('Gastos'),
                ...expense.map((c) => _CatTile(
                    cat: c,
                    onEdit: () => _showForm(context, ref, c),
                    onDelete: () => _delete(context, ref, c))),
              ],
              if (income.isNotEmpty) ...[
                _Header('Ingresos'),
                ...income.map((c) => _CatTile(
                    cat: c,
                    onEdit: () => _showForm(context, ref, c),
                    onDelete: () => _delete(context, ref, c))),
              ],
              if (both.isNotEmpty) ...[
                _Header('Ambos'),
                ...both.map((c) => _CatTile(
                    cat: c,
                    onEdit: () => _showForm(context, ref, c),
                    onDelete: () => _delete(context, ref, c))),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'category_fab',
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref, Category? cat) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryForm(
        category: cat,
        onSaved: () => ref.invalidate(_categoriesProvider),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category cat) async {
    final inUse = await CategoryDao.instance.isInUse(cat.id!);
    if (inUse && context.mounted) {
      context.showSnackBar('No puedes eliminar esta categoría porque está en uso', isError: true);
      return;
    }
    if (!context.mounted) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar categoría',
      message: '¿Eliminar "${cat.name}"?',
    );
    if (confirmed) {
      await CategoryDao.instance.delete(cat.id!);
      ref.invalidate(_categoriesProvider);
    }
  }
}

class _CatTile extends StatelessWidget {
  const _CatTile({required this.cat, required this.onEdit, required this.onDelete});
  final Category cat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = CategoryColorPalette.fromHex(cat.color);

    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 20))),
      ),
      title: Text(cat.name, style: AppTextStyles.bodyMedium),
      subtitle: Text(
        cat.type == 'income' ? 'Ingreso' : cat.type == 'expense' ? 'Gasto' : 'Ambos',
        style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') onEdit();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Row(children: [
            Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Editar'),
          ])),
          PopupMenuItem(value: 'delete', child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
            const SizedBox(width: 10),
            Text('Eliminar', style: TextStyle(color: colorScheme.error)),
          ])),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: AppTextStyles.labelLarge
              .copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}

// ── Category form with color picker ──────────
class _CategoryForm extends StatefulWidget {
  const _CategoryForm({this.category, required this.onSaved});
  final Category? category;
  final VoidCallback onSaved;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _iconCtrl;
  late String _type;
  late Color _selectedColor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _iconCtrl = TextEditingController(text: widget.category?.icon ?? '📦');
    _type = widget.category?.type ?? 'expense';
    _selectedColor = widget.category != null
        ? CategoryColorPalette.fromHex(widget.category!.color)
        : CategoryColorPalette.colors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final cat = Category(
      id: widget.category?.id,
      name: _nameCtrl.text.trim(),
      icon: _iconCtrl.text.trim().isEmpty ? '📦' : _iconCtrl.text.trim(),
      color: CategoryColorPalette.toHex(_selectedColor),
      type: _type,
    );
    if (widget.category != null) {
      await CategoryDao.instance.update(cat);
    } else {
      await CategoryDao.instance.insert(cat);
    }
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.category != null ? 'Editar categoría' : 'Nueva categoría',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),

          // Icon + name row
          Row(
            children: [
              // Preview circle
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _selectedColor, width: 2),
                ),
                child: Center(
                  child: Text(_iconCtrl.text.isEmpty ? '📦' : _iconCtrl.text,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _iconCtrl,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'Ícono'),
                  style: const TextStyle(fontSize: 22),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Color picker
          Text('Color', style: AppTextStyles.labelLarge
              .copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CategoryColorPalette.colors.map((color) {
              final selected = _selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: colorScheme.onSurface, width: 2.5)
                        : Border.all(color: Colors.transparent, width: 2.5),
                    boxShadow: selected
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Type selector
          SegmentedButton<String>(
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Gasto')),
              ButtonSegment(value: 'income', label: Text('Ingreso')),
              ButtonSegment(value: 'both', label: Text('Ambos')),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.category != null ? 'Actualizar' : 'Crear'),
            ),
          ),
        ],
      ),
    );
  }
}
