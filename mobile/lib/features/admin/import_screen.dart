import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/states.dart';
import '../funds/fund_controller.dart';
import 'import_repository.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}
class _ImportScreenState extends State<ImportScreen> {
  WorkbookAnalysis? book;
  ImportResult? result;
  int selected = 0;
  bool busy = false, committed = false;
  String? error;
  ImportRepository get repository => ImportRepository(context.read<ApiClient>());
  Future<void> pick() async {
    setState(() { busy = true; error = null; });
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (file == null) return;
      final validation = ImportRepository.validateFile(file.name, await file.length() ?? 0);
      if (validation != null) throw ApiException(validation);
      final bytes = await file.readAsBytes();
      final analysis = await repository.analyze(bytes, file.name);
      if (mounted) setState(() { book = analysis; selected = 0; result = null; committed = false; });
    } catch (e) { if (mounted) setState(() => error = errorMessage(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> commit() async {
    final sheet = book!.sheets[selected];
    final approved = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Import NAV history?'), content: Text('Submit ${sheet.rows.length} rows from ${sheet.name}? Existing NAV records may be updated.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Import'))]));
    if (approved != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      final response = await repository.commit(book!, sheet);
      if (mounted) { setState(() { result = response; committed = !response.missing; }); context.read<FundController>().load(); }
    } catch (e) { if (mounted) setState(() => error = errorMessage(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> createMaster() async {
    final r = result!;
    final approved = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Create scheme and plan?'),
      content: Text('${r.provider}\n${r.scheme}\n${r.plan} · ${r.option}'), actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create'))]));
    if (approved != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await repository.createMaster(r);
      if (mounted) setState(() => result = null);
    } catch (e) { if (mounted) setState(() => error = errorMessage(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final sheet = book == null || book!.sheets.isEmpty ? null : book!.sheets[selected];
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Excel data import', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8), const Text('Upload an .xlsx workbook, review its mappings, then import NAV history. Maximum size: 50 MB.'),
      const SizedBox(height: 16), FilledButton.icon(onPressed: busy ? null : pick, icon: const Icon(Icons.upload_file), label: const Text('Choose workbook')),
      if (busy) const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator()),
      if (error != null) StatusView(error!),
      if (book != null) Section('Workbook', [Fact('File', book!.file), Fact('Provider', book!.provider)]),
      if (book != null && sheet == null) const StatusView('No importable sheets were found.'),
      if (sheet != null) ...[
        DropdownButtonFormField<int>(key: ValueKey(book), initialValue: selected, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Worksheet'), items: List.generate(book!.sheets.length, (i) => DropdownMenuItem(value: i, child: Text(book!.sheets[i].name))),
          onChanged: busy ? null : (v) { if (v != null) setState(() { selected = v; result = null; committed = false; }); }),
        Section('Review mappings', [Fact('Dataset', sheet.type), Fact('Rows', '${sheet.count}'),
          ...sheet.mappings.map((m) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: DropdownButtonFormField<String>(
            key: ValueKey('$selected:${m.column}'), initialValue: mappingFields.contains(m.target) ? m.target : '', isExpanded: true,
            decoration: InputDecoration(labelText: m.column), items: mappingFields.map((f) => DropdownMenuItem(value: f, child: Text(f.isEmpty ? 'Ignore column' : f))).toList(),
            onChanged: busy || committed ? null : (v) => setState(() => m.target = v == '' ? null : v)))),
          if (sheet.validation != null) Text(sheet.validation!),
        ]),
        Section('Preview · first 3 rows', sheet.rows.take(3).map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(r.map((v) => v ?? '—').join(' · ')))).toList()),
        if (result?.missing == true) Section('Master data required', [
          Text(result!.canCreate ? 'Review and create the missing scheme, then retry the import.' : 'Required scheme fields are missing. Correct the workbook and upload it again.'),
          OutlinedButton(onPressed: busy || !result!.canCreate ? null : createMaster, child: const Text('Review missing scheme')),
        ]),
        if (result != null && !result!.missing) Section('Import result', [Fact('Inserted', '${result!.inserted}'), Fact('Updated', '${result!.updated}'),
          Fact('Skipped', '${result!.skipped}'), Fact('Failed', '${result!.failed}'),
          if (result!.failed > 0) const Text('Some rows failed validation or import. Review the source workbook and server logs before retrying.'),
        ]),
        FilledButton(onPressed: busy || committed || sheet.validation != null ? null : commit, child: Text(committed ? 'Import submitted' : 'Review and import')),
      ],
    ]);
  }
}
