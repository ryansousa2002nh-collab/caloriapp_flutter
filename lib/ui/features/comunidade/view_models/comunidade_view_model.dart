import 'package:flutter/foundation.dart';
import '../../../../data/repositories/comunidade_repository.dart';
import '../../../../models/postagem_comunidade_model.dart';

/// ViewModel da Comunidade (UI Layer — MVVM pattern de `flutter-apply-architecture-best-practices`).
/// Gerencia o estado de apresentação, categorias dinâmicas (criar, renomear, apagar),
/// filtros, buscas e comandos de interação, mantendo a View (`ComunidadePage`) enxuta.
class ComunidadeViewModel extends ChangeNotifier {
  ComunidadeViewModel({ComunidadeRepository? repository})
      : _repository = repository ?? ComunidadeRepository();

  final ComunidadeRepository _repository;

  List<PostagemComunidadeModel> _postagens = const [];
  List<CategoriaComunidadeModel> _categorias = CategoriaComunidadeModel.padroesIniciais;
  String _filtroSlug = 'todos'; // 'todos', 'salvos', ou o slug de qualquer categoria ativa
  String _buscaTexto = '';
  bool _isLoading = true;
  final Set<String> _textosExpandidos = {};

  bool get isLoading => _isLoading;
  bool get isNutri => _repository.isNutri;
  String get nomeNutri => _repository.nomeNutri;
  String get filtroSlug => _filtroSlug;
  String get buscaTexto => _buscaTexto;

  FiltroComunidade get filtroSelecionado {
    for (final f in FiltroComunidade.values) {
      if (f.slug == _filtroSlug) return f;
    }
    return FiltroComunidade.todos;
  }

  List<CategoriaComunidadeModel> get categorias => List.unmodifiable(_categorias);
  List<PostagemComunidadeModel> get todasPostagens => List.unmodifiable(_postagens);

  int get totalPostagens => _postagens.length;
  int get totalReceitasEPratos => _postagens.where((p) => p.isReceitaOuPrato).length;
  int get totalSalvos => _postagens.where((p) => p.salvoPorMim).length;

  /// Retorna o nome amigável da categoria a partir do seu slug.
  String nomeCategoriaPorSlug(String slug, {String? fallback}) {
    final encontrada = _categorias.where((c) => c.slug == slug);
    if (encontrada.isNotEmpty) return encontrada.first.nome;
    if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    return CategoriaPostagem.fromSlug(slug).label;
  }

  List<PostagemComunidadeModel> get postagensFiltradas {
    return List.unmodifiable(
      _postagens.where((post) {
        if (_filtroSlug == 'salvos') {
          if (!post.salvoPorMim) return false;
        } else if (_filtroSlug != 'todos') {
          if (post.categoriaSlug != _filtroSlug) return false;
        }

        if (_buscaTexto.trim().isNotEmpty) {
          final termo = _buscaTexto.trim().toLowerCase();
          final matchTitulo = post.titulo.toLowerCase().contains(termo);
          final matchTexto = post.texto.toLowerCase().contains(termo);
          final nomeCat = nomeCategoriaPorSlug(
            post.categoriaSlug,
            fallback: post.categoriaLabel,
          ).toLowerCase();
          final matchCategoria = nomeCat.contains(termo);
          return matchTitulo || matchTexto || matchCategoria;
        }
        return true;
      }),
    );
  }

  bool isTextoExpandido(String id) => _textosExpandidos.contains(id);

  Future<void> carregarPostagens() async {
    _isLoading = true;
    notifyListeners();
    try {
      _postagens = await _repository.carregarPostagens();
      _categorias = _repository.obterCategoriasEmCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selecionarFiltro(FiltroComunidade novoFiltro) {
    selecionarFiltroPorSlug(novoFiltro.slug);
  }

  void selecionarFiltroPorSlug(String slug) {
    if (_filtroSlug == slug) return;
    _filtroSlug = slug;
    notifyListeners();
  }

  void atualizarBusca(String termo) {
    if (_buscaTexto == termo) return;
    _buscaTexto = termo;
    notifyListeners();
  }

  void limparBusca() {
    if (_buscaTexto.isEmpty) return;
    _buscaTexto = '';
    notifyListeners();
  }

  void alternarExpansaoTexto(String id) {
    if (_textosExpandidos.contains(id)) {
      _textosExpandidos.remove(id);
    } else {
      _textosExpandidos.add(id);
    }
    notifyListeners();
  }

  Future<CategoriaComunidadeModel> adicionarCategoria({
    required String nome,
    String iconeKey = 'receita',
  }) async {
    final nova = await _repository.adicionarCategoria(
      nome: nome,
      iconeKey: iconeKey,
    );
    _categorias = _repository.obterCategoriasEmCache();
    _filtroSlug = nova.slug;
    notifyListeners();
    return nova;
  }

  Future<CategoriaComunidadeModel> renomearCategoria(
    CategoriaComunidadeModel categoria, {
    required String novoNome,
    String? novoIconeKey,
  }) async {
    final eraSelecionada = _filtroSlug == categoria.slug;
    final atualizada = await _repository.renomearCategoria(
      categoria,
      novoNome: novoNome,
      novoIconeKey: novoIconeKey,
    );
    _categorias = _repository.obterCategoriasEmCache();
    _postagens = _repository.obterPostagensEmCache();
    if (eraSelecionada) {
      _filtroSlug = atualizada.slug;
    }
    notifyListeners();
    return atualizada;
  }

  Future<void> excluirCategoria(CategoriaComunidadeModel categoria) async {
    final eraSelecionada = _filtroSlug == categoria.slug;
    await _repository.excluirCategoria(categoria);
    _categorias = _repository.obterCategoriasEmCache();
    _postagens = _repository.obterPostagensEmCache();
    if (eraSelecionada) {
      _filtroSlug = 'todos';
    }
    notifyListeners();
  }

  Future<void> salvarPublicacao(
    DadosPublicacaoComunidade dados, {
    PostagemComunidadeModel? postExistente,
  }) async {
    await _repository.salvarPublicacao(dados, postExistente: postExistente);
    _postagens = _repository.obterPostagensEmCache();
    notifyListeners();
  }

  Future<void> excluirPostagem(String id) async {
    await _repository.excluirPostagem(id);
    _postagens = _repository.obterPostagensEmCache();
    notifyListeners();
  }

  Future<void> alternarCurtida(String id) async {
    await _repository.alternarCurtida(id);
    _postagens = _repository.obterPostagensEmCache();
    notifyListeners();
  }

  Future<bool> alternarSalvar(String id) async {
    await _repository.alternarSalvar(id);
    _postagens = _repository.obterPostagensEmCache();
    notifyListeners();
    final atualizado = _postagens.where((p) => p.id == id);
    return atualizado.isNotEmpty ? atualizado.first.salvoPorMim : false;
  }
}
