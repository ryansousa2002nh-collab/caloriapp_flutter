import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/postagem_comunidade_model.dart';
import '../theme/app_theme.dart';
import '../ui/features/comunidade/view_models/comunidade_view_model.dart';
import '../utils/comunidade_platform.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';

class ComunidadePage extends StatefulWidget {
  final ComunidadeViewModel? viewModel;

  const ComunidadePage({
    super.key,
    this.viewModel,
  });

  @override
  State<ComunidadePage> createState() => _ComunidadePageState();
}

class _ComunidadePageState extends State<ComunidadePage> {
  late final ComunidadeViewModel _viewModel;
  late final bool _ownsViewModel;
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? ComunidadeViewModel();
    _viewModel.carregarPostagens();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _abrirLinkConteudoCompleto(String url) async {
    final abriu = await ComunidadePlatform.abrirLinkExterno(url);
    if (!mounted) return;

    final primaryColor = Theme.of(context).colorScheme.primary;
    if (!abriu) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link copiado para a área de transferência: $url'),
          backgroundColor: primaryColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abrindo publicação completa...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _visualizarImagemAmpliada(PostagemComunidadeModel post) {
    if (post.fotoUrl == null) return;
    final compTheme = ComunidadeTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: compTheme.cardSurface,
                constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: InteractiveViewer(
                        child: _ImagemPratoComunidade(
                          fotoUrl: post.fotoUrl!,
                          titulo: post.titulo,
                          enquadramento: post.enquadramentoFoto,
                          altura: 420,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        post.titulo,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: CircleAvatar(
                backgroundColor: BrandColors.black.withValues(alpha: 0.55),
                child: IconButton(
                  icon: const Icon(Icons.close, color: BrandColors.white, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(PostagemComunidadeModel post) {
    final compTheme = ComunidadeTheme.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: compTheme.cardSurface,
        title: Text(
          'Excluir publicação?',
          style: TextStyle(
            color: AppColors.getTextoPrincipal(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Deseja remover "${post.titulo}" do mural da Comunidade?',
          style: TextStyle(color: AppColors.getTextoSecundario(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.getTextoSecundario(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              minimumSize: const Size(100, 42),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _viewModel.excluirPostagem(post.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Publicação excluída do mural.'),
                ),
              );
            },
            child: const Text('Excluir publicação'),
          ),
        ],
      ),
    );
  }

  /// Abre o modal para a Nutricionista adicionar uma nova categoria ou
  /// editar o nome / apagar uma categoria existente ao clicar nela.
  void _abrirModalCategoria({CategoriaComunidadeModel? categoriaExistente}) {
    final isEdicao = categoriaExistente != null;
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;
    final nomeCtrl = TextEditingController(text: categoriaExistente?.nome ?? '');
    String iconeEscolhido = categoriaExistente?.iconeKey ?? 'receita';

    const opcoesIcones = [
      {'key': 'receita', 'label': 'Receita', 'icon': Icons.cake_outlined},
      {'key': 'prato', 'label': 'Prato', 'icon': Icons.restaurant_menu_outlined},
      {'key': 'dica', 'label': 'Dica', 'icon': Icons.lightbulb_outline},
      {'key': 'texto', 'label': 'Texto', 'icon': Icons.article_outlined},
      {'key': 'lanche', 'label': 'Lanche', 'icon': Icons.bakery_dining_outlined},
      {'key': 'bebida', 'label': 'Bebida', 'icon': Icons.local_cafe_outlined},
      {'key': 'suplemento', 'label': 'Suplemento', 'icon': Icons.bolt_outlined},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: compTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: compTheme.highlightSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isEdicao ? Icons.edit_outlined : Icons.create_new_folder_outlined,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdicao ? 'Gerenciar Categoria' : 'Nova Categoria',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.getTextoPrincipal(context),
                                    ),
                                  ),
                                  Text(
                                    isEdicao
                                        ? 'Edite o nome desta categoria ou apague-a do mural'
                                        : 'Crie uma nova aba para organizar suas publicações',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.getTextoSecundario(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: nomeCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome da categoria (ex: Lanches Fit, Sobremesas)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Ícone da aba',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: opcoesIcones.map((op) {
                      final key = op['key'] as String;
                      final label = op['label'] as String;
                      final icon = op['icon'] as IconData;
                      final selecionado = iconeEscolhido == key;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setModalState(() => iconeEscolhido = key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: selecionado ? primaryColor : compTheme.cardSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selecionado ? primaryColor : compTheme.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 15,
                                color: selecionado
                                    ? BrandColors.white
                                    : AppColors.getTextoSecundario(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selecionado
                                      ? BrandColors.white
                                      : AppColors.getTextoPrincipal(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      if (isEdicao) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: errorColor,
                              side: BorderSide(color: errorColor),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(modalCtx);
                              await _viewModel.excluirCategoria(categoriaExistente);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Categoria "${categoriaExistente.nome}" apagada.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text(
                              'Apagar categoria',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () async {
                            final nome = nomeCtrl.text.trim();
                            if (nome.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Digite um nome para a categoria.'),
                                ),
                              );
                              return;
                            }
                            if (isEdicao) {
                              await _viewModel.renomearCategoria(
                                categoriaExistente,
                                novoNome: nome,
                                novoIconeKey: iconeEscolhido,
                              );
                            } else {
                              await _viewModel.adicionarCategoria(
                                nome: nome,
                                iconeKey: iconeEscolhido,
                              );
                            }
                            if (!mounted || !modalCtx.mounted) return;
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdicao
                                      ? 'Categoria atualizada para "$nome"!'
                                      : 'Categoria "$nome" adicionada!',
                                ),
                                backgroundColor: primaryColor,
                              ),
                            );
                          },
                          icon: Icon(isEdicao ? Icons.check : Icons.add, size: 18),
                          label: Text(isEdicao ? 'Salvar nome' : 'Criar categoria'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _abrirModalPublicacao({PostagemComunidadeModel? postExistente}) {
    final compTheme = ComunidadeTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: compTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => _ModalEditorPublicacao(
        viewModel: _viewModel,
        postExistente: postExistente,
        onGerenciarCategoria: (cat) => _abrirModalCategoria(categoriaExistente: cat),
        onSalvar: (dados) async {
          final isEdicao = postExistente != null;
          await _viewModel.salvarPublicacao(dados, postExistente: postExistente);
          if (!mounted || !modalContext.mounted) return;
          Navigator.pop(modalContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdicao
                    ? 'Alterações salvas na publicação!'
                    : 'Publicado no mural da Comunidade!',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final isNutri = _viewModel.isNutri;
        final postagens = _viewModel.postagensFiltradas;
        final categorias = _viewModel.categorias;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Comunidade',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              const AppleThemeToggle(size: 28),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar mural',
                onPressed: _viewModel.carregarPostagens,
              ),
              if (isNutri)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: BrandColors.white,
                        size: 20,
                      ),
                    ),
                    tooltip: 'Publicar receita ou dica',
                    onPressed: () => _abrirModalPublicacao(),
                  ),
                ),
            ],
          ),
          drawer: const AppDrawer(paginaAtual: 'comunidade'),
          floatingActionButton: isNutri
              ? FloatingActionButton.extended(
                  backgroundColor: primaryColor,
                  foregroundColor: BrandColors.white,
                  onPressed: () => _abrirModalPublicacao(),
                  icon: const Icon(Icons.post_add),
                  label: const Text(
                    'Nova Postagem',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          body: _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _viewModel.carregarPostagens,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCadernoEditorialBanner(context),
                              const SizedBox(height: AppSpacing.md),

                              // Barra de pesquisa
                              TextField(
                                controller: _buscaController,
                                onChanged: _viewModel.atualizarBusca,
                                decoration: InputDecoration(
                                  hintText:
                                      'Buscar receita, prato ou ingrediente (ex: Bolo de laranja)...',
                                  hintStyle: TextStyle(
                                    color: AppColors.getTextoSecundario(context),
                                    fontSize: 13.5,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppColors.getTextoSecundario(context),
                                  ),
                                  suffixIcon: _viewModel.buscaTexto.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _buscaController.clear();
                                            _viewModel.limparBusca();
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),

                              // Barra de Abas de Categorias Dinâmicas + Botão "+ Nova categoria" para Nutri
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Aba "Todos"
                                    Padding(
                                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                                      child: _buildFiltroChip(
                                        context,
                                        label: 'Todos',
                                        icone: Icons.grid_view_rounded,
                                        ativo: _viewModel.filtroSlug == 'todos',
                                        onTap: () => _viewModel.selecionarFiltroPorSlug('todos'),
                                      ),
                                    ),

                                    // Categorias dinâmicas (ao clicar seleciona; se Nutri clicar novamente ou no ícone de lápis, edita/apaga)
                                    ...categorias.map((cat) {
                                      final ativo = _viewModel.filtroSlug == cat.slug;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                                        child: _buildFiltroChip(
                                          context,
                                          label: cat.nome,
                                          icone: cat.icone,
                                          ativo: ativo,
                                          mostrarBotaoEditar: isNutri,
                                          onTap: () {
                                            if (isNutri && ativo) {
                                              _abrirModalCategoria(categoriaExistente: cat);
                                            } else {
                                              _viewModel.selecionarFiltroPorSlug(cat.slug);
                                            }
                                          },
                                          onEditarTap: isNutri
                                              ? () => _abrirModalCategoria(categoriaExistente: cat)
                                              : null,
                                        ),
                                      );
                                    }),

                                    // Aba "Salvos"
                                    Padding(
                                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                                      child: _buildFiltroChip(
                                        context,
                                        label: 'Salvos (${_viewModel.totalSalvos})',
                                        icone: Icons.bookmark_outline,
                                        ativo: _viewModel.filtroSlug == 'salvos',
                                        onTap: () => _viewModel.selecionarFiltroPorSlug('salvos'),
                                      ),
                                    ),

                                    // Botão "+ Nova Categoria" exclusivo para o perfil da Nutricionista
                                    if (isNutri)
                                      _buildBotaoAdicionarCategoria(context),
                                  ],
                                ),
                              ),
                              if (isNutri)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 2),
                                  child: Text(
                                    'Dica: toque no ícone de lápis de qualquer categoria para editar o nome ou apagá-la.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.getTextoSecundario(context),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ),
                        ),
                      ),

                      if (postagens.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEstadoVazio(context, isNutri: isNutri),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.xs,
                            AppSpacing.md,
                            AppSpacing.xxl * 2,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final post = postagens[index];
                                final nomeCategoriaExibicao = _viewModel.nomeCategoriaPorSlug(
                                  post.categoriaSlug,
                                  fallback: post.categoriaLabel,
                                );
                                return _PostagemEditorialCard(
                                  post: post,
                                  categoriaNomeExibicao: nomeCategoriaExibicao,
                                  isNutri: isNutri,
                                  expandido: _viewModel.isTextoExpandido(post.id),
                                  onAlternarExpansao: () =>
                                      _viewModel.alternarExpansaoTexto(post.id),
                                  onVisualizarImagem: () => _visualizarImagemAmpliada(post),
                                  onAbrirLink: () {
                                    if (post.linkExterno != null) {
                                      _abrirLinkConteudoCompleto(post.linkExterno!);
                                    }
                                  },
                                  onCurtir: () => _viewModel.alternarCurtida(post.id),
                                  onSalvar: () async {
                                    final salvoAgora = await _viewModel.alternarSalvar(post.id);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          salvoAgora
                                              ? 'Receita salva nos seus favoritos!'
                                              : 'Publicação removida dos itens salvos.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  onEditar: () => _abrirModalPublicacao(postExistente: post),
                                  onExcluir: () => _confirmarExclusao(post),
                                );
                              },
                              childCount: postagens.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCadernoEditorialBanner(BuildContext context) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: compTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: compTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor,
                backgroundImage: const AssetImage('assets/images/logo_nutri.jpg'),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caderno de Receitas & Nutrição',
                      style: GoogleFonts.fraunces(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pratos para preparar em casa, receitas testadas e orientações da ${_viewModel.nomeNutri}.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.getTextoSecundario(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Row(
            children: [
              _buildMiniMetrica(
                context,
                valor: '${_viewModel.totalPostagens}',
                label: 'Publicações',
                icone: Icons.auto_awesome_mosaic_outlined,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildMiniMetrica(
                context,
                valor: '${_viewModel.totalReceitasEPratos}',
                label: 'Receitas & Pratos',
                icone: Icons.restaurant_menu_outlined,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildMiniMetrica(
                context,
                valor: '${_viewModel.totalSalvos}',
                label: 'Salvos',
                icone: Icons.bookmark_added_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetrica(
    BuildContext context, {
    required String valor,
    required String label,
    required IconData icone,
  }) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: compTheme.highlightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: compTheme.highlightBorder),
        ),
        child: Row(
          children: [
            Icon(icone, size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valor,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.getTextoSecundario(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(
    BuildContext context, {
    required String label,
    required IconData icone,
    required bool ativo,
    required VoidCallback onTap,
    bool mostrarBotaoEditar = false,
    VoidCallback? onEditarTap,
  }) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      onLongPress: onEditarTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(
          left: 14,
          right: mostrarBotaoEditar ? 8 : 14,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: ativo ? primaryColor : compTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ativo ? primaryColor : compTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 15,
              color: ativo ? BrandColors.white : AppColors.getTextoSecundario(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w600,
                color: ativo ? BrandColors.white : AppColors.getTextoPrincipal(context),
              ),
            ),
            if (mostrarBotaoEditar && onEditarTap != null) ...[
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onEditarTap,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 13.5,
                    color: ativo
                        ? BrandColors.white.withValues(alpha: 0.9)
                        : AppColors.getTextoSecundario(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAdicionarCategoria(BuildContext context) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _abrirModalCategoria(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: compTheme.highlightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: compTheme.highlightBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 15, color: primaryColor),
            const SizedBox(width: 5),
            Text(
              'Nova categoria',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVazio(BuildContext context, {required bool isNutri}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: AppColors.getTextoSecundario(context),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Text(
              'Nenhuma receita ou dica encontrada neste filtro.',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextoPrincipal(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNutri
                  ? 'Toque em "Nova Postagem" para compartilhar uma receita com foto do prato e link do Instagram.'
                  : 'Selecione outra categoria acima ou limpe a busca para ver todas as receitas da nutricionista.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextoSecundario(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card editorial de cada postagem da Comunidade (`frontend-design` + `design-system`).
class _PostagemEditorialCard extends StatelessWidget {
  final PostagemComunidadeModel post;
  final String categoriaNomeExibicao;
  final bool isNutri;
  final bool expandido;
  final VoidCallback onAlternarExpansao;
  final VoidCallback onVisualizarImagem;
  final VoidCallback onAbrirLink;
  final VoidCallback onCurtir;
  final VoidCallback onSalvar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _PostagemEditorialCard({
    required this.post,
    required this.categoriaNomeExibicao,
    required this.isNutri,
    required this.expandido,
    required this.onAlternarExpansao,
    required this.onVisualizarImagem,
    required this.onAbrirLink,
    required this.onCurtir,
    required this.onSalvar,
    required this.onEditar,
    required this.onExcluir,
  });

  String _formatarDataRelativa(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return 'Recentemente';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;
    final textoLongo = post.texto.length > 230;
    final temFoto = post.fotoUrl != null && post.fotoUrl!.trim().isNotEmpty;
    final temLink = post.linkExterno != null && post.linkExterno!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: compTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: compTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho da autora + Categoria + Data + Menu da Nutri
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              14,
              AppSpacing.sm + AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor,
                  backgroundImage: const AssetImage('assets/images/logo_nutri.jpg'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.autorNome,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.getTextoPrincipal(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: compTheme.highlightSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: compTheme.highlightBorder),
                            ),
                            child: Text(
                              categoriaNomeExibicao,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: compTheme.categoryTagText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatarDataRelativa(post.dataCriacao),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.getTextoSecundario(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNutri)
                  PopupMenuButton<String>(
                    tooltip: 'Gerenciar publicação',
                    onSelected: (acao) {
                      if (acao == 'editar') {
                        onEditar();
                      } else if (acao == 'excluir') {
                        onExcluir();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text('Editar publicação'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'excluir',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: errorColor),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Excluir publicação',
                              style: TextStyle(color: errorColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 2. Título editorial do prato/receita (ex: "Bolo de laranja") + tags nutricionais
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 2, AppSpacing.md, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.titulo,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.25,
                    color: AppColors.getTextoPrincipal(context),
                  ),
                ),
                if ((post.tempoPreparo != null && post.tempoPreparo!.isNotEmpty) ||
                    post.caloriasPorcao != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 6,
                    children: [
                      if (post.tempoPreparo != null && post.tempoPreparo!.isNotEmpty)
                        _buildMetaTag(
                          context,
                          icone: Icons.schedule_outlined,
                          texto: post.tempoPreparo!,
                        ),
                      if (post.caloriasPorcao != null)
                        _buildMetaTag(
                          context,
                          icone: Icons.local_fire_department_outlined,
                          texto: '${post.caloriasPorcao} kcal / porção',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 3. Foto do prato logo abaixo do título (aplicando enquadramento e centralização manual)
          if (temFoto)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: onVisualizarImagem,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _ImagemPratoComunidade(
                    fotoUrl: post.fotoUrl!,
                    titulo: post.titulo,
                    enquadramento: post.enquadramentoFoto,
                    altura: 230,
                  ),
                ),
              ),
            ),

          // 4. Texto abaixo da foto (receita, modo de preparo, dica ou reflexão)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.md, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (!expandido && textoLongo)
                      ? '${post.texto.substring(0, 230).trim()}...'
                      : post.texto,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: AppColors.getTextoPrincipal(context),
                  ),
                ),
                if (textoLongo)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InkWell(
                      onTap: onAlternarExpansao,
                      child: Text(
                        expandido ? 'Mostrar menos' : 'Ler receita completa',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: compTheme.categoryTagText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 5. Link ao final para o conteúdo completo (geralmente Instagram)
          if (temLink)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onAbrirLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: post.isInstagramLink
                          ? [
                              BrandColors.plum600.withValues(alpha: 0.12),
                              compTheme.socialAccent.withValues(alpha: 0.14),
                              BrandColors.citrus500.withValues(alpha: 0.12),
                            ]
                          : [
                              compTheme.highlightSurface,
                              compTheme.highlightSurface,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: post.isInstagramLink
                          ? compTheme.socialAccent.withValues(alpha: 0.4)
                          : compTheme.highlightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: post.isInstagramLink ? compTheme.socialAccent : primaryColor,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Icon(
                          post.isInstagramLink ? Icons.camera_alt_outlined : Icons.open_in_new,
                          color: BrandColors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.isInstagramLink
                                  ? 'Ver conteúdo completo no Instagram'
                                  : 'Acessar conteúdo completo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.getTextoPrincipal(context),
                              ),
                            ),
                            Text(
                              post.linkExterno!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.getTextoSecundario(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 17,
                        color: post.isInstagramLink ? compTheme.socialAccent : primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // 6. Barra de interações (Curtir e Salvar Receita)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: onCurtir,
                        icon: Icon(
                          post.curtidoPorMim ? Icons.favorite : Icons.favorite_border,
                          color: post.curtidoPorMim
                              ? compTheme.likeActive
                              : AppColors.getTextoSecundario(context),
                          size: 20,
                        ),
                        label: Text(
                          '${post.totalCurtidas} ${post.totalCurtidas == 1 ? 'curtida' : 'curtidas'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: post.curtidoPorMim
                                ? compTheme.likeActive
                                : AppColors.getTextoSecundario(context),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onSalvar,
                        icon: Icon(
                          post.salvoPorMim ? Icons.bookmark : Icons.bookmark_border,
                          color: post.salvoPorMim
                              ? primaryColor
                              : AppColors.getTextoSecundario(context),
                          size: 20,
                        ),
                        label: Text(
                          post.salvoPorMim ? 'Salvo' : 'Salvar receita',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: post.salvoPorMim
                                ? primaryColor
                                : AppColors.getTextoSecundario(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (temLink)
                  IconButton(
                    tooltip: 'Copiar link da publicação',
                    icon: Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppColors.getTextoSecundario(context),
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: post.linkExterno!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link da publicação copiado!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTag(
    BuildContext context, {
    required IconData icone,
    required String texto,
  }) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: compTheme.highlightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: primaryColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextoSecundario(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal isolado para criação e edição de publicação pela Nutricionista,
/// incluindo ajuste/centralização manual de foto (estilo WhatsApp) e gerenciamento de categorias.
class _ModalEditorPublicacao extends StatefulWidget {
  final ComunidadeViewModel viewModel;
  final PostagemComunidadeModel? postExistente;
  final void Function(CategoriaComunidadeModel? categoria) onGerenciarCategoria;
  final Future<void> Function(DadosPublicacaoComunidade dados) onSalvar;

  const _ModalEditorPublicacao({
    required this.viewModel,
    this.postExistente,
    required this.onGerenciarCategoria,
    required this.onSalvar,
  });

  @override
  State<_ModalEditorPublicacao> createState() => _ModalEditorPublicacaoState();
}

class _ModalEditorPublicacaoState extends State<_ModalEditorPublicacao> {
  static const List<Map<String, String>> _sugestoesFotosPratos = [
    {
      'nome': 'Bolo de Laranja',
      'url':
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=900&q=80',
    },
    {
      'nome': 'Bowl Saudável',
      'url':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
    },
    {
      'nome': 'Panqueca de Aveia',
      'url':
          'https://images.unsplash.com/photo-1528207776546-365bb710ee93?auto=format&fit=crop&w=900&q=80',
    },
    {
      'nome': 'Frutas & Fibras',
      'url':
          'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=900&q=80',
    },
  ];

  late final TextEditingController _tituloCtrl;
  late final TextEditingController _textoCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _tempoCtrl;
  late final TextEditingController _caloriasCtrl;
  late final TextEditingController _urlFotoCtrl;

  late String _categoriaSlugSelecionada;
  String? _imagemDispositivoDataUrl;
  late EnquadramentoFotoModel _enquadramentoFoto;
  bool _selecionandoArquivo = false;

  bool get _isEdicao => widget.postExistente != null;

  @override
  void initState() {
    super.initState();
    final p = widget.postExistente;
    _tituloCtrl = TextEditingController(text: p?.titulo ?? '');
    _textoCtrl = TextEditingController(text: p?.texto ?? '');
    _linkCtrl = TextEditingController(text: p?.linkExterno ?? 'https://www.instagram.com/');
    _tempoCtrl = TextEditingController(text: p?.tempoPreparo ?? '');
    _caloriasCtrl = TextEditingController(text: p?.caloriasPorcao?.toString() ?? '');

    final fotoInicial = p?.fotoUrl ?? '';
    final isDataUriInicial = fotoInicial.startsWith('data:image/');
    _urlFotoCtrl = TextEditingController(text: isDataUriInicial ? '' : fotoInicial);
    _imagemDispositivoDataUrl = isDataUriInicial ? fotoInicial : null;
    _enquadramentoFoto = p?.enquadramentoFoto ?? EnquadramentoFotoModel.padrao;

    final cats = widget.viewModel.categorias;
    _categoriaSlugSelecionada =
        p?.categoriaSlug ?? (cats.isNotEmpty ? cats.first.slug : 'receita');
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _textoCtrl.dispose();
    _linkCtrl.dispose();
    _tempoCtrl.dispose();
    _caloriasCtrl.dispose();
    _urlFotoCtrl.dispose();
    super.dispose();
  }

  String get _fotoPreviewAtual {
    if (_imagemDispositivoDataUrl != null && _imagemDispositivoDataUrl!.isNotEmpty) {
      return _imagemDispositivoDataUrl!;
    }
    return _urlFotoCtrl.text.trim();
  }

  /// Abre o diálogo interativo de ajuste e centralização manual de imagem (estilo WhatsApp).
  Future<void> _abrirAjusteManualDaFoto() async {
    final foto = _fotoPreviewAtual;
    if (foto.isEmpty) return;

    final novoEnquadramento = await showDialog<EnquadramentoFotoModel>(
      context: context,
      builder: (ctx) => _DialogAjusteFotoWhatsApp(
        fotoUrl: foto,
        titulo: _tituloCtrl.text.isEmpty ? 'Ajustar foto do prato' : _tituloCtrl.text,
        enquadramentoInicial: _enquadramentoFoto,
      ),
    );

    if (novoEnquadramento != null && mounted) {
      setState(() {
        _enquadramentoFoto = novoEnquadramento;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final categorias = widget.viewModel.categorias;
        if (categorias.isNotEmpty &&
            !categorias.any((c) => c.slug == _categoriaSlugSelecionada)) {
          _categoriaSlugSelecionada = categorias.first.slug;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: compTheme.highlightSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isEdicao ? Icons.edit_note : Icons.post_add,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEdicao ? 'Editar Publicação' : 'Nova Publicação na Comunidade',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextoPrincipal(context),
                                  ),
                                ),
                                Text(
                                  'Compartilhe receitas, fotos de pratos e o link do Instagram',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.getTextoSecundario(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Seleção e gerenciamento de Categorias
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Categoria da publicação',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => widget.onGerenciarCategoria(null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Nova categoria',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: categorias.map((cat) {
                    final selecionado = _categoriaSlugSelecionada == cat.slug;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (selecionado) {
                          widget.onGerenciarCategoria(cat);
                        } else {
                          setState(() => _categoriaSlugSelecionada = cat.slug);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: selecionado ? primaryColor : compTheme.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selecionado ? primaryColor : compTheme.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icone,
                              size: 15,
                              color: selecionado
                                  ? BrandColors.white
                                  : AppColors.getTextoSecundario(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.nome,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selecionado
                                    ? BrandColors.white
                                    : AppColors.getTextoPrincipal(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => widget.onGerenciarCategoria(cat),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 13,
                                color: selecionado
                                    ? BrandColors.white.withValues(alpha: 0.9)
                                    : AppColors.getTextoSecundario(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título do prato ou publicação (ex: Bolo de laranja)',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 14),

                // Upload do dispositivo + URL da foto + Ajuste manual (estilo WhatsApp)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: compTheme.highlightSurface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: compTheme.highlightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 18, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Foto do Prato',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.getTextoPrincipal(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.getTextoPrincipal(context),
                                side: BorderSide(color: compTheme.highlightBorder),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _selecionandoArquivo
                                  ? null
                                  : () async {
                                      setState(() => _selecionandoArquivo = true);
                                      final dataUrl =
                                          await ComunidadePlatform.selecionarImagemDoDispositivo();
                                      if (!mounted) return;
                                      setState(() {
                                        _selecionandoArquivo = false;
                                        if (dataUrl != null && dataUrl.isNotEmpty) {
                                          _imagemDispositivoDataUrl = dataUrl;
                                          _enquadramentoFoto = EnquadramentoFotoModel.padrao;
                                          _urlFotoCtrl.clear();
                                        }
                                      });
                                      if (dataUrl != null && dataUrl.isNotEmpty && mounted) {
                                        await _abrirAjusteManualDaFoto();
                                      }
                                    },
                              icon: _selecionandoArquivo
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file_outlined, size: 18),
                              label: Text(
                                _imagemDispositivoDataUrl != null
                                    ? 'Trocar foto do dispositivo'
                                    : 'Escolher foto do dispositivo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          if (_fotoPreviewAtual.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              tooltip: 'Remover foto',
                              onPressed: () {
                                setState(() {
                                  _imagemDispositivoDataUrl = null;
                                  _enquadramentoFoto = EnquadramentoFotoModel.padrao;
                                  _urlFotoCtrl.clear();
                                });
                              },
                              icon: Icon(Icons.delete_outline, color: errorColor),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _urlFotoCtrl,
                        onChanged: (_) {
                          setState(() {
                            if (_urlFotoCtrl.text.trim().isNotEmpty) {
                              _imagemDispositivoDataUrl = null;
                              _enquadramentoFoto = EnquadramentoFotoModel.padrao;
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Ou cole a URL da foto do prato',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _sugestoesFotosPratos.map((sug) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                avatar: const Icon(Icons.image_outlined, size: 15),
                                label: Text(
                                  sug['nome']!,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _imagemDispositivoDataUrl = null;
                                    _enquadramentoFoto = EnquadramentoFotoModel.padrao;
                                    _urlFotoCtrl.text = sug['url']!;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_fotoPreviewAtual.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap: _abrirAjusteManualDaFoto,
                                child: _ImagemPratoComunidade(
                                  fotoUrl: _fotoPreviewAtual,
                                  titulo: _tituloCtrl.text.isEmpty
                                      ? 'Prévia do prato'
                                      : _tituloCtrl.text,
                                  enquadramento: _enquadramentoFoto,
                                  altura: 175,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BrandColors.black.withValues(alpha: 0.72),
                                  foregroundColor: BrandColors.white,
                                  minimumSize: const Size(120, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: _abrirAjusteManualDaFoto,
                                icon: const Icon(Icons.crop_rotate_rounded, size: 16),
                                label: const Text(
                                  'Ajustar / Centralizar foto',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tempoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tempo (ex: 35 min)',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _caloriasCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kcal/porção (opcional)',
                          prefixIcon: Icon(Icons.local_fire_department_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _textoCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Texto abaixo da foto (receita, ingredientes, dica...)',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 72),
                      child: Icon(Icons.notes_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _linkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link para o conteúdo completo (ex: Instagram)',
                    prefixIcon: Icon(Icons.open_in_new),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final titulo = _tituloCtrl.text.trim();
                      final texto = _textoCtrl.text.trim();
                      final link = _linkCtrl.text.trim();
                      final fotoFinal = _fotoPreviewAtual.isNotEmpty ? _fotoPreviewAtual : null;

                      if (titulo.isEmpty || texto.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preencha o título e o texto da publicação.'),
                          ),
                        );
                        return;
                      }

                      final nomeCat = widget.viewModel.nomeCategoriaPorSlug(
                        _categoriaSlugSelecionada,
                      );

                      final dados = DadosPublicacaoComunidade(
                        idExistente: widget.postExistente?.id,
                        titulo: titulo,
                        categoriaSlug: _categoriaSlugSelecionada,
                        categoriaNome: nomeCat,
                        texto: texto,
                        fotoUrl: fotoFinal,
                        enquadramentoFoto: _enquadramentoFoto,
                        linkExterno: (link.isEmpty || link == 'https://www.instagram.com/')
                            ? null
                            : link,
                        tempoPreparo:
                            _tempoCtrl.text.trim().isEmpty ? null : _tempoCtrl.text.trim(),
                        caloriasPorcao: int.tryParse(_caloriasCtrl.text.trim()),
                      );

                      widget.onSalvar(dados);
                    },
                    icon: Icon(_isEdicao ? Icons.check : Icons.send_outlined),
                    label: Text(_isEdicao ? 'Salvar Alterações' : 'Publicar na Comunidade'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Diálogo interativo de enquadramento, zoom e centralização manual da foto (estilo WhatsApp).
/// Permite arrastar com o dedo ou mouse para centralizar o prato e ajustar o nível de zoom.
class _DialogAjusteFotoWhatsApp extends StatefulWidget {
  final String fotoUrl;
  final String titulo;
  final EnquadramentoFotoModel enquadramentoInicial;

  const _DialogAjusteFotoWhatsApp({
    required this.fotoUrl,
    required this.titulo,
    required this.enquadramentoInicial,
  });

  @override
  State<_DialogAjusteFotoWhatsApp> createState() => _DialogAjusteFotoWhatsAppState();
}

class _DialogAjusteFotoWhatsAppState extends State<_DialogAjusteFotoWhatsApp> {
  late double _escala;
  late double _posX;
  late double _posY;
  double _escalaBasePinch = 1.0;

  @override
  void initState() {
    super.initState();
    _escala = widget.enquadramentoInicial.escala;
    _posX = widget.enquadramentoInicial.posicaoX;
    _posY = widget.enquadramentoInicial.posicaoY;
  }

  EnquadramentoFotoModel get _enquadramentoAtual => EnquadramentoFotoModel(
        escala: _escala,
        posicaoX: _posX,
        posicaoY: _posY,
      );

  void _centralizarPadrao() {
    setState(() {
      _escala = 1.0;
      _posX = 0.0;
      _posY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: compTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.crop_free_rounded, color: primaryColor, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ajustar e Centralizar Foto',
                            style: GoogleFonts.fraunces(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextoPrincipal(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _centralizarPadrao,
                    icon: const Icon(Icons.filter_center_focus, size: 16),
                    label: const Text('Centralizar'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Arraste a imagem com o dedo ou mouse para posicionar o prato e ajuste o zoom.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.getTextoSecundario(context),
                ),
              ),
              const SizedBox(height: 14),

              // Visor interativo estilo WhatsApp com máscara e grade 3x3
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onScaleStart: (_) {
                    _escalaBasePinch = _escala;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      // Arrasto manual para centralizar (X e Y de -1.0 a 1.0)
                      _posX = (_posX - details.focalPointDelta.dx / 120).clamp(-1.0, 1.0);
                      _posY = (_posY - details.focalPointDelta.dy / 120).clamp(-1.0, 1.0);
                      if (details.scale != 1.0) {
                        _escala = (_escalaBasePinch * details.scale).clamp(1.0, 3.0);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      _ImagemPratoComunidade(
                        fotoUrl: widget.fotoUrl,
                        titulo: widget.titulo,
                        enquadramento: _enquadramentoAtual,
                        altura: 250,
                      ),
                      // Grade guia de enquadramento (regra dos terços)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GradeEnquadramentoPainter(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: BrandColors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_with_rounded, color: BrandColors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Arraste para mover',
                                style: TextStyle(
                                  color: BrandColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Controle deslizante de Zoom (1.0x a 3.0x)
              Row(
                children: [
                  Icon(
                    Icons.zoom_out_rounded,
                    size: 20,
                    color: AppColors.getTextoSecundario(context),
                  ),
                  Expanded(
                    child: Slider(
                      value: _escala,
                      min: 1.0,
                      max: 3.0,
                      activeColor: primaryColor,
                      label: '${_escala.toStringAsFixed(1)}x',
                      onChanged: (val) => setState(() => _escala = val),
                    ),
                  ),
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 20,
                    color: AppColors.getTextoSecundario(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_escala.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextoPrincipal(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () => Navigator.pop(context, _enquadramentoAtual),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar ajuste'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desenha a grade 3x3 de enquadramento sobre o visor de ajuste de foto.
class _GradeEnquadramentoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.white.withValues(alpha: 0.32)
      ..strokeWidth = 1.0;

    final w3 = size.width / 3;
    final h3 = size.height / 3;

    canvas.drawLine(Offset(w3, 0), Offset(w3, size.height), paint);
    canvas.drawLine(Offset(w3 * 2, 0), Offset(w3 * 2, size.height), paint);
    canvas.drawLine(Offset(0, h3), Offset(size.width, h3), paint);
    canvas.drawLine(Offset(0, h3 * 2), Offset(size.width, h3 * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget dedicado para renderizar fotos de pratos (Data URL Base64, Asset ou Network)
/// aplicando o enquadramento manual (`EnquadramentoFotoModel`) escolhido pela Nutricionista.
class _ImagemPratoComunidade extends StatelessWidget {
  final String fotoUrl;
  final String titulo;
  final EnquadramentoFotoModel enquadramento;
  final double altura;

  const _ImagemPratoComunidade({
    required this.fotoUrl,
    required this.titulo,
    this.enquadramento = EnquadramentoFotoModel.padrao,
    this.altura = 220,
  });

  @override
  Widget build(BuildContext context) {
    Widget imagemBase;

    if (fotoUrl.startsWith('data:image/')) {
      try {
        final commaIdx = fotoUrl.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(fotoUrl.substring(commaIdx + 1));
          imagemBase = Image.memory(
            bytes,
            width: double.infinity,
            height: altura,
            fit: BoxFit.cover,
            alignment: enquadramento.alignment,
            errorBuilder: (ctx, _, __) => _buildFallbackPrato(context),
          );
        } else {
          imagemBase = _buildFallbackPrato(context);
        }
      } catch (_) {
        imagemBase = _buildFallbackPrato(context);
      }
    } else if (fotoUrl.startsWith('assets/')) {
      imagemBase = Image.asset(
        fotoUrl,
        width: double.infinity,
        height: altura,
        fit: BoxFit.cover,
        alignment: enquadramento.alignment,
        errorBuilder: (ctx, _, __) => _buildFallbackPrato(context),
      );
    } else {
      imagemBase = Image.network(
        fotoUrl,
        width: double.infinity,
        height: altura,
        fit: BoxFit.cover,
        alignment: enquadramento.alignment,
        errorBuilder: (ctx, _, __) => _buildFallbackPrato(context),
      );
    }

    if (!enquadramento.foiAjustado) {
      return SizedBox(
        width: double.infinity,
        height: altura,
        child: imagemBase,
      );
    }

    // Aplica o deslocamento manual X/Y e a escala de zoom dentro do quadro recortado
    return SizedBox(
      width: double.infinity,
      height: altura,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(
            -enquadramento.posicaoX * 45 * enquadramento.escala,
            -enquadramento.posicaoY * 35 * enquadramento.escala,
          ),
          child: Transform.scale(
            scale: enquadramento.escala,
            alignment: enquadramento.alignment,
            child: imagemBase,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackPrato(BuildContext context) {
    final compTheme = ComunidadeTheme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isBolo = titulo.toLowerCase().contains('bolo') ||
        titulo.toLowerCase().contains('laranja');

    return Container(
      width: double.infinity,
      height: altura,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBolo
              ? [compTheme.citrusStart, compTheme.citrusEnd]
              : [primaryColor, BrandColors.green700],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBolo ? Icons.cake_outlined : Icons.restaurant_menu_rounded,
            size: 48,
            color: BrandColors.white.withValues(alpha: 0.92),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fraunces(
                color: BrandColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
