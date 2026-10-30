import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caloriapp_flutter/data/repositories/comunidade_repository.dart';
import 'package:caloriapp_flutter/models/postagem_comunidade_model.dart';
import 'package:caloriapp_flutter/pages/comunidade_page.dart';
import 'package:caloriapp_flutter/services/dados_service.dart';
import 'package:caloriapp_flutter/theme/app_theme.dart';
import 'package:caloriapp_flutter/ui/features/comunidade/view_models/comunidade_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ComunidadeViewModel gerencia categorias dinâmicas e enquadramento de foto', () async {
    final dados = DadosService();
    dados.setTipoUsuarioLogado('NUTRI');
    final repository = ComunidadeRepository(dadosService: dados);
    final viewModel = ComunidadeViewModel(repository: repository);

    await viewModel.carregarPostagens();
    expect(viewModel.totalPostagens, greaterThanOrEqualTo(4));

    // Adiciona nova categoria
    final novaCat = await viewModel.adicionarCategoria(
      nome: 'Lanches Fit',
      iconeKey: 'lanche',
    );
    expect(viewModel.categorias.any((c) => c.nome == 'Lanches Fit'), isTrue);

    // Renomeia a categoria criada
    final catRenomeada = await viewModel.renomearCategoria(
      novaCat,
      novoNome: 'Lanches Proteicos',
    );
    expect(viewModel.categorias.any((c) => c.nome == 'Lanches Proteicos'), isTrue);

    // Publica receita na nova categoria com ajuste manual de foto (zoom + centralização)
    await viewModel.salvarPublicacao(
      DadosPublicacaoComunidade(
        titulo: 'Bolo de laranja caseiro',
        categoriaSlug: catRenomeada.slug,
        categoriaNome: catRenomeada.nome,
        texto: 'Receita deliciosa e rica em fibras.',
        enquadramentoFoto: const EnquadramentoFotoModel(
          escala: 1.4,
          posicaoX: 0.2,
          posicaoY: -0.1,
        ),
        linkExterno: 'https://www.instagram.com/p/bolo_laranja/',
      ),
    );

    final criado = viewModel.todasPostagens.firstWhere(
      (p) => p.titulo == 'Bolo de laranja caseiro',
    );
    expect(criado.enquadramentoFoto.escala, closeTo(1.4, 0.01));
    expect(criado.enquadramentoFoto.posicaoX, closeTo(0.2, 0.01));

    // Exclui a categoria
    await viewModel.excluirCategoria(catRenomeada);
    expect(viewModel.categorias.any((c) => c.slug == catRenomeada.slug), isFalse);
  });

  testWidgets('ComunidadePage exibe Bolo de laranja, botão Nova categoria e link do Instagram',
      (WidgetTester tester) async {
    final dados = DadosService();
    dados.setTipoUsuarioLogado('NUTRI');
    await dados.carregarPostagensComunidade();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ComunidadePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comunidade'), findsOneWidget);
    expect(find.textContaining('Bolo de laranja'), findsOneWidget);
    expect(find.text('Ver conteúdo completo no Instagram'), findsWidgets);
    expect(find.text('Nova categoria'), findsOneWidget);
  });
}
