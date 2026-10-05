import 'package:flutter/foundation.dart';
import '../../core/widgets/states.dart';
import 'data/fund_repository.dart';
import 'data/models.dart';

class FundController extends ChangeNotifier {
  FundController(this.repository);
  final FundRepository repository;
  List<Fund> funds = [];
  int total = 0, page = 0, _generation = 0;
  String query = '';
  String? category, error;
  bool loading = false, loadingMore = false, _disposed = false;
  final List<Fund> selected = [];
  bool get hasMore => funds.length < total;

  Future<void> load({bool more = false}) async {
    if (more && (loading || loadingMore || !hasMore)) return;
    final generation = ++_generation;
    if (more) { loadingMore = true; } else { loading = true; loadingMore = false; }
    error = null;
    notifyListeners();
    try {
      final result = await repository.list(query: query, category: category, page: more ? page + 1 : 1);
      if (_disposed || generation != _generation) return;
      funds = more ? [...funds, ...result.funds] : result.funds;
      page = result.page;
      total = result.total;
    } catch (e) {
      if (_disposed || generation != _generation) return;
      error = errorMessage(e);
    } finally {
      if (!_disposed && generation == _generation) { loading = false; loadingMore = false; notifyListeners(); }
    }
  }

  void search(String value) { query = value; load(); }
  void filter(String? value) { category = value; load(); }
  bool toggle(Fund fund) {
    final index = selected.indexWhere((f) => f.id == fund.id);
    if (index >= 0) { selected.removeAt(index); }
    else if (selected.length < 5) { selected.add(fund); }
    else { return false; }
    notifyListeners();
    return true;
  }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
