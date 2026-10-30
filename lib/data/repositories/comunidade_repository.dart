import '../../models/postagem_comunidade_model.dart';
import '../../services/dados_service.dart';

/// Repository da Comunidade (Data Layer — skill `flutter-apply-architecture-best-practices`).
///
/// Responsabilidades:
/// - Isolar o acesso aos dados de `DadosService` / `ApiService`, servindo como
///   fonte única da verdade (*Single Source of Truth*) para o `ComunidadeViewModel`.
/// - Gerenciar categorias dinâmicas (`CategoriaComunidadeModel`) e publicações
///   (`PostagemComunidadeModel`) com enquadramento manual de foto (`EnquadramentoFotoModel`).
class ComunidadeRepository {
  ComunidadeRepository({DadosService? dadosService})
      : _dadosService = dadosService ?? DadosService();

  final DadosService _dadosService;

  /// Indica se o usuário autenticado possui perfil de Nutricionista (`NUTRI`).
  bool get isNutri => _dadosService.isNutri;

  /// Nome de exibição da Nutricionista responsável pelo mural.
  String get nomeNutri => _dadosService.nomeNutri;

  /// Sincroniza categorias e publicações com o backend Django (ou fallback local).
  Future<List<PostagemComunidadeModel>> carregarPostagens() async {
    await _dadosService.carregarPostagensComunidade();
    return _dadosService.getPostagensComunidade();
  }

  /// Retorna a lista imutável de categorias disponíveis.
  List<CategoriaComunidadeModel> obterCategoriasEmCache() {
    return _dadosService.getCategoriasComunidade();
  }

  /// Retorna a lista imutável de postagens já carregadas em memória.
  List<PostagemComunidadeModel> obterPostagensEmCache() {
    return _dadosService.getPostagensComunidade();
  }

  /// Adiciona uma nova categoria personalizada criada pela Nutricionista.
  Future<CategoriaComunidadeModel> adicionarCategoria({
    required String nome,
    String iconeKey = 'receita',
  }) {
    return _dadosService.adicionarCategoriaComunidade(
      nome: nome,
      iconeKey: iconeKey,
    );
  }

  /// Edita o nome (e opcionalmente o ícone) de uma categoria existente.
  Future<CategoriaComunidadeModel> renomearCategoria(
    CategoriaComunidadeModel categoria, {
    required String novoNome,
    String? novoIconeKey,
  }) {
    return _dadosService.renomearCategoriaComunidade(
      categoria,
      novoNome: novoNome,
      novoIconeKey: novoIconeKey,
    );
  }

  /// Exclui uma categoria existente e reatribui suas publicações.
  Future<void> excluirCategoria(CategoriaComunidadeModel categoria) {
    return _dadosService.excluirCategoriaComunidade(categoria);
  }

  /// Cria uma nova publicação ou atualiza uma publicação existente a partir do Value Object `dados`.
  Future<PostagemComunidadeModel> salvarPublicacao(
    DadosPublicacaoComunidade dados, {
    PostagemComunidadeModel? postExistente,
  }) async {
    final isEdicao = postExistente != null;
    final postagem = PostagemComunidadeModel(
      id: postExistente?.id ?? 'post_${DateTime.now().millisecondsSinceEpoch}',
      titulo: dados.titulo,
      categoriaSlug: dados.categoriaSlug,
      categoriaNomeCustom: dados.categoriaNome,
      texto: dados.texto,
      fotoUrl: dados.fotoUrl,
      enquadramentoFoto: dados.enquadramentoFoto,
      linkExterno: dados.linkExterno,
      tempoPreparo: dados.tempoPreparo,
      caloriasPorcao: dados.caloriasPorcao,
      autorNome: _dadosService.nomeNutri,
      dataCriacao: postExistente?.dataCriacao ?? DateTime.now().toIso8601String(),
      totalCurtidas: postExistente?.totalCurtidas ?? 0,
      curtidoPorMim: postExistente?.curtidoPorMim ?? false,
      salvoPorMim: postExistente?.salvoPorMim ?? false,
    );

    return _dadosService.salvarPostagemComunidade(
      postagem,
      isEdicao: isEdicao,
    );
  }

  /// Remove uma publicação do mural (no backend e no cache local).
  Future<void> excluirPostagem(String id) async {
    await _dadosService.excluirPostagemComunidade(id);
  }

  /// Alterna o estado de curtida da publicação para o usuário logado.
  Future<void> alternarCurtida(String id) async {
    await _dadosService.alternarCurtidaPostagemComunidade(id);
  }

  /// Alterna o salvamento (favorito) da receita/publicação para o usuário logado.
  Future<void> alternarSalvar(String id) async {
    await _dadosService.alternarSalvarPostagemComunidade(id);
  }
}
