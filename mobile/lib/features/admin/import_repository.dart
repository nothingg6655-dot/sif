import '../../core/network/api_client.dart';

const mappingFields = ['', 'scheme_name', 'plan_type', 'option_type', 'nav', 'nav_date', 'repurchase_price', 'sale_price'];
class ColumnMapping {
  ColumnMapping.fromJson(Json j) : column = j['excelColumn'] as String, target = j['targetField'] as String?;
  final String column;
  String? target;
  Json toJson() => {'excelColumn': column, 'targetField': target, 'confidence': 100};
}
class ImportSheet {
  ImportSheet.fromJson(Json j) : name = j['sheetName'] as String, type = j['datasetType'] as String,
    count = (j['rowCount'] as num).toInt(), mappings = objects(j['mappings']).map(ColumnMapping.fromJson).toList(),
    rows = (j['rawRows'] as List).map((r) => List<Object?>.from(r as List)).toList(), metadata = object(j['sheetMetadata'] ?? {});
  final String name, type;
  final int count;
  final List<ColumnMapping> mappings;
  final List<List<Object?>> rows;
  final Json metadata;
  String? get validation {
    if (type != 'NAV_HISTORY') return 'Only NAV history imports are supported by the server.';
    final targets = mappings.map((m) => m.target).whereType<String>().where((s) => s.isNotEmpty).toList();
    if (!targets.contains('nav') || !targets.contains('nav_date')) return 'Map both NAV and NAV date.';
    if (targets.toSet().length != targets.length) return 'Map each target field only once.';
    if (rows.isEmpty) return 'This sheet contains no rows.';
    return null;
  }
}
class WorkbookAnalysis {
  WorkbookAnalysis.fromJson(Json j) : file = j['fileName'] as String, provider = j['provider'] as String,
    sheets = objects(j['sheets']).map(ImportSheet.fromJson).toList();
  final String file, provider;
  final List<ImportSheet> sheets;
}
class ImportResult {
  ImportResult.fromJson(Json j) : inserted = (j['inserted'] as num?)?.toInt() ?? 0,
    updated = (j['updated'] as num?)?.toInt() ?? 0, skipped = (j['skipped'] as num?)?.toInt() ?? 0,
    failed = (j['failed'] as num?)?.toInt() ?? 0, missing = j['type'] == 'MISSING_MASTER_DATA',
    provider = j['provider'] as String?, scheme = j['schemeName'] as String?, plan = j['planType'] as String?, option = j['optionType'] as String?;
  final int inserted, updated, skipped, failed;
  final bool missing;
  final String? provider, scheme, plan, option;
  bool get canCreate => [provider, scheme, plan, option].every((s) => s != null && s.trim().isNotEmpty);
}
class ImportRepository {
  ImportRepository(this.api);
  final ApiClient api;
  static String? validateFile(String name, int size) {
    if (!name.toLowerCase().endsWith('.xlsx')) return 'Choose an .xlsx workbook.';
    if (size == 0 || size > 50 * 1024 * 1024) return 'Choose a nonempty file up to 50 MB.';
    return null;
  }
  Future<WorkbookAnalysis> analyze(List<int> bytes, String name) async => WorkbookAnalysis.fromJson(
    await api.upload('/api/admin/import/excel/analyze', bytes, name));
  Future<ImportResult> commit(WorkbookAnalysis book, ImportSheet sheet) async {
    if (sheet.validation != null) throw ApiException(sheet.validation!);
    return ImportResult.fromJson(await api.post('/api/admin/import/excel/commit', admin: true, body: {
      'provider': book.provider, 'datasetType': sheet.type, 'mappings': sheet.mappings.map((m) => m.toJson()).toList(),
      'rawRows': sheet.rows, 'sheetMetadata': sheet.metadata,
    }));
  }
  Future<void> createMaster(ImportResult result) async {
    if (!result.canCreate) throw const ApiException('The workbook is missing required master fields. Correct it and upload again.');
    await api.post('/api/admin/import/excel/create-master', admin: true, body: {
      'provider': result.provider, 'schemeName': result.scheme, 'planType': result.plan, 'optionType': result.option,
    });
  }
}
