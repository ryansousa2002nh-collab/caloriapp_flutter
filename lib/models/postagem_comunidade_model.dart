import 'package:flutter/material.dart';

/// Enum tipado de ícones para categorias da Comunidade (evita Primitive Obsession).
enum IconeCategoriaComunidade {
  receita(key: 'receita', label: 'Bolo / Receita', icone: Icons.cake_outlined),
  prato(key: 'prato', label: 'Prato / Refeição', icone: Icons.restaurant_menu_outlined),
  dica(key: 'dica', label: 'Dica / Ideia', icone: Icons.lightbulb_outline),
  texto(key: 'texto', label: 'Texto / Artigo', icone: Icons.article_outlined),
  lanche(key: 'lanche', label: 'Lanche / Café', icone: Icons.free_breakfast_outlined),
  fit(key: 'fit', label: 'Saúde / Fit', icone: Icons.eco_outlined);

  final String key;
  final String label;
  final IconData icone;

  const IconeCategoriaComunidade({
    required this.key,
    required this.label,
    required this.icone,
  });

  static IconData iconePorKey(String? rawKey) {
    switch ((rawKey ?? '').trim().toLowerCase()) {
      case 'receita':
        return Icons.cake_outlined;
      case 'prato':
        return Icons.restaurant_menu_outlined;
      case 'dica':
        return Icons.lightbulb_outline;
      case 'texto':
        return Icons.article_outlined;
      case 'lanche':
        return Icons.bakery_dining_outlined;
      case 'bebida':
        return Icons.local_cafe_outlined;
      case 'suplemento':
        return Icons.bolt_outlined;
      default:
        return Icons.label_outline;
    }
  }
}

/// Domain Model imutável para uma Categoria da Comunidade.
/// Permite que a Nutricionista adicione novas categorias, edite o nome ou apague categorias existentes.
@immutable
class CategoriaComunidadeModel {
  final String id;
  final String slug;
  final String nome;
  final String iconeKey;

  const CategoriaComunidadeModel({
    required this.id,
    required this.slug,
    required this.nome,
    this.iconeKey = 'receita',
  });

  IconData get icone => IconeCategoriaComunidade.iconePorKey(iconeKey);

  CategoriaComunidadeModel copyWith({
    String? id,
    String? slug,
    String? nome,
    String? iconeKey,
  }) {
    return CategoriaComunidadeModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nome: nome ?? this.nome,
      iconeKey: iconeKey ?? this.iconeKey,
    );
  }

  factory CategoriaComunidadeModel.fromJson(Map<String, dynamic> json) {
    final nome = (json['nome'] ?? 'Categoria').toString();
    final slugBruto = (json['slug'] ?? nome).toString();
    return CategoriaComunidadeModel(
      id: (json['id'] ?? slugBruto).toString(),
      slug: gerarSlug(slugBruto),
      nome: nome,
      iconeKey: (json['icone'] ?? json['icone_key'] ?? 'receita').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'nome': nome,
      'icone': iconeKey,
    };
  }

  static String gerarSlug(String texto) {
    final normalizado = texto
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalizado.isEmpty ? 'categoria_${DateTime.now().millisecondsSinceEpoch}' : normalizado;
  }

  static const List<CategoriaComunidadeModel> padroesIniciais = [
    CategoriaComunidadeModel(
      id: 'cat_receita',
      slug: 'receita',
      nome: 'Receitas',
      iconeKey: 'receita',
    ),
    CategoriaComunidadeModel(
      id: 'cat_prato',
      slug: 'prato',
      nome: 'Pratos',
      iconeKey: 'prato',
    ),
    CategoriaComunidadeModel(
      id: 'cat_dica',
      slug: 'dica',
      nome: 'Dicas',
      iconeKey: 'dica',
    ),
    CategoriaComunidadeModel(
      id: 'cat_texto',
      slug: 'texto',
      nome: 'Textos',
      iconeKey: 'texto',
    ),
  ];
}

/// Value Object imutável que representa o ajuste e centralização manual da foto
/// (estilo foto de perfil do WhatsApp: zoom + deslocamento horizontal e vertical).
@immutable
class EnquadramentoFotoModel {
  final double escala; // 1.0 a 3.0
  final double posicaoX; // -1.0 (esquerda) a 1.0 (direita), 0.0 = centro
  final double posicaoY; // -1.0 (topo) a 1.0 (base), 0.0 = centro

  const EnquadramentoFotoModel({
    this.escala = 1.0,
    this.posicaoX = 0.0,
    this.posicaoY = 0.0,
  });

  static const padrao = EnquadramentoFotoModel();

  bool get foiAjustado =>
      (escala - 1.0).abs() > 0.01 || posicaoX.abs() > 0.01 || posicaoY.abs() > 0.01;

  Alignment get alignment => Alignment(
        posicaoX.clamp(-1.0, 1.0),
        posicaoY.clamp(-1.0, 1.0),
      );

  EnquadramentoFotoModel copyWith({
    double? escala,
    double? posicaoX,
    double? posicaoY,
  }) {
    return EnquadramentoFotoModel(
      escala: (escala ?? this.escala).clamp(1.0, 3.0),
      posicaoX: (posicaoX ?? this.posicaoX).clamp(-1.0, 1.0),
      posicaoY: (posicaoY ?? this.posicaoY).clamp(-1.0, 1.0),
    );
  }
}

/// Enum mantido para compatibilidade semântica com as categorias base.
enum CategoriaPostagem {
  receita(
    slug: 'receita',
    label: 'Receita',
    pluralLabel: 'Receitas',
    icone: Icons.cake_outlined,
  ),
  prato(
    slug: 'prato',
    label: 'Prato',
    pluralLabel: 'Pratos',
    icone: Icons.restaurant_menu_outlined,
  ),
  dica(
    slug: 'dica',
    label: 'Dica da Nutri',
    pluralLabel: 'Dicas',
    icone: Icons.lightbulb_outline,
  ),
  texto(
    slug: 'texto',
    label: 'Texto & Reflexão',
    pluralLabel: 'Textos',
    icone: Icons.article_outlined,
  );

  final String slug;
  final String label;
  final String pluralLabel;
  final IconData icone;

  const CategoriaPostagem({
    required this.slug,
    required this.label,
    required this.pluralLabel,
    required this.icone,
  });

  static CategoriaPostagem fromSlug(String? raw) {
    final clean = (raw ?? '').trim().toLowerCase();
    for (final item in CategoriaPostagem.values) {
      if (item.slug == clean) return item;
    }
    return CategoriaPostagem.receita;
  }
}

/// Enum para filtros rápidos padrão.
enum FiltroComunidade {
  todos(slug: 'todos', label: 'Todos', icone: Icons.grid_view_rounded),
  receitas(
    slug: 'receita',
    label: 'Receitas',
    icone: Icons.cake_outlined,
    categoriaAssociada: CategoriaPostagem.receita,
  ),
  pratos(
    slug: 'prato',
    label: 'Pratos',
    icone: Icons.restaurant_menu_outlined,
    categoriaAssociada: CategoriaPostagem.prato,
  ),
  dicas(
    slug: 'dica',
    label: 'Dicas',
    icone: Icons.lightbulb_outline,
    categoriaAssociada: CategoriaPostagem.dica,
  ),
  textos(
    slug: 'texto',
    label: 'Textos',
    icone: Icons.article_outlined,
    categoriaAssociada: CategoriaPostagem.texto,
  ),
  salvos(slug: 'salvos', label: 'Salvos', icone: Icons.bookmark_outline);

  final String slug;
  final String label;
  final IconData icone;
  final CategoriaPostagem? categoriaAssociada;

  const FiltroComunidade({
    required this.slug,
    required this.label,
    required this.icone,
    this.categoriaAssociada,
  });
}

/// Value Object que agrupa os dados do formulário de criação/edição (evita Data Clumps).
@immutable
class DadosPublicacaoComunidade {
  final String? idExistente;
  final String titulo;
  final String categoriaSlug;
  final String categoriaNome;
  final String texto;
  final String? fotoUrl;
  final EnquadramentoFotoModel enquadramentoFoto;
  final String? linkExterno;
  final String? tempoPreparo;
  final int? caloriasPorcao;

  DadosPublicacaoComunidade({
    this.idExistente,
    required this.titulo,
    CategoriaPostagem? categoria,
    String? categoriaSlug,
    String? categoriaNome,
    required this.texto,
    this.fotoUrl,
    this.enquadramentoFoto = EnquadramentoFotoModel.padrao,
    this.linkExterno,
    this.tempoPreparo,
    this.caloriasPorcao,
  })  : categoriaSlug = categoriaSlug ?? (categoria != null ? categoria.slug : 'receita'),
        categoriaNome = categoriaNome ?? (categoria != null ? categoria.label : 'Receitas');
}

/// Domain Model imutável para uma publicação da Comunidade (flutter-apply-architecture-best-practices).
@immutable
class PostagemComunidadeModel {
  final String id;
  final String titulo;
  final String categoriaSlug;
  final String? categoriaNomeCustom;
  final String texto;
  final String? fotoUrl;
  final EnquadramentoFotoModel enquadramentoFoto;
  final String? linkExterno;
  final String? tempoPreparo;
  final int? caloriasPorcao;
  final String autorNome;
  final String dataCriacao;
  final int totalCurtidas;
  final bool curtidoPorMim;
  final bool salvoPorMim;

  PostagemComunidadeModel({
    required this.id,
    required this.titulo,
    CategoriaPostagem? categoriaType,
    String? categoriaSlug,
    this.categoriaNomeCustom,
    required this.texto,
    this.fotoUrl,
    this.enquadramentoFoto = EnquadramentoFotoModel.padrao,
    this.linkExterno,
    this.tempoPreparo,
    this.caloriasPorcao,
    this.autorNome = 'Dra. Juliana Braz',
    required this.dataCriacao,
    this.totalCurtidas = 0,
    this.curtidoPorMim = false,
    this.salvoPorMim = false,
  }) : categoriaSlug =
            categoriaSlug ?? (categoriaType != null ? categoriaType.slug : 'receita');

  CategoriaPostagem get categoriaType => CategoriaPostagem.fromSlug(categoriaSlug);
  String get categoria => categoriaSlug;

  String get categoriaLabel {
    if (categoriaNomeCustom != null && categoriaNomeCustom!.trim().isNotEmpty) {
      return categoriaNomeCustom!.trim();
    }
    return categoriaType.label;
  }

  bool get isReceitaOuPrato =>
      categoriaSlug == 'receita' || categoriaSlug == 'prato';

  bool get isInstagramLink {
    if (linkExterno == null || linkExterno!.trim().isEmpty) return false;
    final lower = linkExterno!.toLowerCase();
    return lower.contains('instagram.com') || lower.contains('instagr.am');
  }

  PostagemComunidadeModel copyWith({
    String? id,
    String? titulo,
    CategoriaPostagem? categoriaType,
    String? categoriaSlug,
    String? categoriaNomeCustom,
    String? texto,
    String? fotoUrl,
    EnquadramentoFotoModel? enquadramentoFoto,
    String? linkExterno,
    String? tempoPreparo,
    int? caloriasPorcao,
    String? autorNome,
    String? dataCriacao,
    int? totalCurtidas,
    bool? curtidoPorMim,
    bool? salvoPorMim,
  }) {
    return PostagemComunidadeModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      categoriaSlug: categoriaSlug ?? (categoriaType?.slug ?? this.categoriaSlug),
      categoriaNomeCustom: categoriaNomeCustom ?? this.categoriaNomeCustom,
      texto: texto ?? this.texto,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      enquadramentoFoto: enquadramentoFoto ?? this.enquadramentoFoto,
      linkExterno: linkExterno ?? this.linkExterno,
      tempoPreparo: tempoPreparo ?? this.tempoPreparo,
      caloriasPorcao: caloriasPorcao ?? this.caloriasPorcao,
      autorNome: autorNome ?? this.autorNome,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      totalCurtidas: totalCurtidas ?? this.totalCurtidas,
      curtidoPorMim: curtidoPorMim ?? this.curtidoPorMim,
      salvoPorMim: salvoPorMim ?? this.salvoPorMim,
    );
  }

  factory PostagemComunidadeModel.fromJson(Map<String, dynamic> json) {
    final slug = (json['categoria'] ?? 'receita').toString().toLowerCase();
    return PostagemComunidadeModel(
      id: (json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      categoriaSlug: slug,
      categoriaNomeCustom: json['categoria_nome']?.toString(),
      texto: (json['texto'] ?? '').toString(),
      fotoUrl: json['foto_url']?.toString(),
      enquadramentoFoto: EnquadramentoFotoModel(
        escala: double.tryParse((json['foto_escala'] ?? 1.0).toString()) ?? 1.0,
        posicaoX: double.tryParse((json['foto_posicao_x'] ?? 0.0).toString()) ?? 0.0,
        posicaoY: double.tryParse((json['foto_posicao_y'] ?? 0.0).toString()) ?? 0.0,
      ),
      linkExterno: json['link_externo']?.toString(),
      tempoPreparo: json['tempo_preparo']?.toString(),
      caloriasPorcao: json['calorias_porcao'] != null
          ? int.tryParse(json['calorias_porcao'].toString())
          : null,
      autorNome: (json['autor_nome'] ?? 'Dra. Juliana Braz').toString(),
      dataCriacao: (json['data_criacao'] ?? DateTime.now().toIso8601String()).toString(),
      totalCurtidas: int.tryParse((json['total_curtidas'] ?? 0).toString()) ?? 0,
      curtidoPorMim: json['curtido_por_mim'] == true,
      salvoPorMim: json['salvo_por_mim'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'categoria': categoriaSlug,
      'categoria_nome': categoriaNomeCustom,
      'texto': texto,
      'foto_url': fotoUrl,
      'foto_escala': enquadramentoFoto.escala,
      'foto_posicao_x': enquadramentoFoto.posicaoX,
      'foto_posicao_y': enquadramentoFoto.posicaoY,
      'link_externo': linkExterno,
      'tempo_preparo': tempoPreparo,
      'calorias_porcao': caloriasPorcao,
      'autor_nome': autorNome,
      'data_criacao': dataCriacao,
      'total_curtidas': totalCurtidas,
      'curtido_por_mim': curtidoPorMim,
      'salvo_por_mim': salvoPorMim,
    };
  }
}
