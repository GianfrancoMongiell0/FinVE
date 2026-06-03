// Copyright (c) 2026 Gianfranco Mongiello. MIT License.
// https://github.com/GianfrancoMongiell0/FinVE

import 'package:flutter/material.dart';
import '../../shared/mixins/unsaved_changes_mixin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/priority.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/theme/app_text_styles.dart';
import 'priorities_provider.dart';

class PriorityFormScreen extends ConsumerStatefulWidget {
  const PriorityFormScreen({super.key, this.priority});

  final Priority? priority;

  @override
  ConsumerState<PriorityFormScreen> createState() => _PriorityFormScreenState();
}

class _PriorityFormScreenState extends ConsumerState<PriorityFormScreen>
    with UnsavedChangesMixin<PriorityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  late String _currency;
  late PriorityLevel _level;
  bool _saving = false;
  bool _isDirty = false;

  @override
  bool get hasUnsavedChanges => _isDirty && !_saving;

  bool get _isEditing => widget.priority != null;

  @override
  void initState() {
    super.initState();
    final p = widget.priority;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _amountCtrl =
        TextEditingController(text: p != null ? p.targetAmount.toString() : '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _currency = p?.currencyCode ?? CurrencyCodes.usd;
    _level = p?.priorityLevel ?? PriorityLevel.medium;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

      final priority = Priority(
        id: widget.priority?.id,
        name: _nameCtrl.text.trim(),
        targetAmount: amount,
        currencyCode: _currency,
        priorityLevel: _level,
        isCompleted: widget.priority?.isCompleted ?? false,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: widget.priority?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await ref.read(prioritiesProvider.notifier).updatePriority(priority);
      } else {
        await ref.read(prioritiesProvider.notifier).add(priority);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al guardar: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await confirmDiscard(context);
        if (canLeave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar meta' : 'Nueva meta'),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              TextButton(
                onPressed: _save,
                child: Text('Guardar',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: colorScheme.primary)),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Name ───────────────────────────
              TextFormField(
                controller: _nameCtrl,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _isDirty = true),
                decoration: const InputDecoration(
                  labelText: 'Nombre de la meta',
                  hintText: 'Ej: Viaje a Bogotá, Laptop nueva…',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (v.trim().length > 60) return 'Máximo 60 caracteres';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Priority level ─────────────────
              _Label('Nivel de prioridad'),
              const SizedBox(height: 10),
              Row(
                children: PriorityLevel.values.map((lvl) {
                  final selected = _level == lvl;
                  final (bg, fg, border) = switch (lvl) {
                    PriorityLevel.high => (
                        const Color(0xFFFFE5E5),
                        const Color(0xFFD32F2F),
                        const Color(0xFFD32F2F),
                      ),
                    PriorityLevel.medium => (
                        const Color(0xFFFFF8E1),
                        const Color(0xFFF57F17),
                        const Color(0xFFF57F17),
                      ),
                    PriorityLevel.low => (
                        const Color(0xFFE8F5E9),
                        const Color(0xFF2E7D32),
                        const Color(0xFF2E7D32),
                      ),
                  };

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _level = lvl;
                          _isDirty = true;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? bg
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? border
                                  : colorScheme.outlineVariant,
                              width: selected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(lvl.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                lvl.label,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: selected ? fg : colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Target amount ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Monto objetivo',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() => _isDirty = true),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'El monto es obligatorio';
                        }
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null) return 'Número inválido';
                        if (n <= 0) return 'Debe ser mayor a 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(labelText: 'Moneda'),
                      items: CurrencyCodes.all
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${CurrencyCodes.flag(c)} $c'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _currency = v);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Notes ──────────────────────────
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Detalles, recordatorios…',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
                maxLength: 300,
              ),

              const SizedBox(height: 24),

              // ── Save button ────────────────────
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isEditing ? 'Actualizar meta' : 'Guardar meta',
                  style: AppTextStyles.labelLarge,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLarge
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
