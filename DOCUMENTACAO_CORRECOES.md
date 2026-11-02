# Documentação Técnica das Correções e Padrões de Código — CaloriApp Flutter

Este documento registra as correções realizadas para zerar todos os alertas do `flutter analyze`, os padrões adotados e a estrutura dos modelos nutricionais.

---

## 1. Resumo Executivo

| Item | Status Anterior | Status Atual | Arquivo Principal |
| :--- | :--- | :--- | :--- |
| **Dependência `package:web`** | Ausente em `dependencies` | Adicionada (`^1.1.2`) | [pubspec.yaml](pubspec.yaml) |
| **Sintaxe de Wildcard** | `__` (redundante no Dart 3.7+) | `_` padronizado | [analise_nutricional_page.dart](lib/pages/analise_nutricional_page.dart), [comunidade_page.dart](lib/pages/comunidade_page.dart) |
| **Segurança em Async Gaps** | `!mounted` checava State pai | `!modalContext.mounted` checa modal | [configuracoes_page.dart](lib/pages/configuracoes_page.dart) |
| **Atribuição Nula** | Bloco `if (paciente == null)` | Operador `??` | [dados_service.dart](lib/services/dados_service.dart) |
| **Modelos Nutricionais** | Testado e verificado | 100% aderente | [dieta_model.dart](lib/models/dieta_model.dart), [alimento_model.dart](lib/models/alimento_model.dart) |

**Resultado final do `flutter analyze`:**
```
Analyzing caloriapp_flutter...
No issues found! (ran in 7.5s)
```

---

## 2. Padrões Adotados

### 2.1. Descarte de Parâmetros em Callbacks
No Dart moderno, utilize `_` para todos os parâmetros não utilizados:
```dart
// Correto:
separatorBuilder: (_, _) => const SizedBox(width: 6);
errorBuilder: (_, _, _) => _buildFallbackPrato(context);
```

### 2.2. Uso Seguro de `BuildContext` Assíncrono
Quando fechar diálogos ou bottom sheets com um context próprio (`modalContext`) após operações com `await`:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('chave', valor);

// Valide sempre o context do modal antes de fechá-lo:
if (!modalContext.mounted) return;
Navigator.pop(modalContext);

// E valide o State da página antes de usar setState ou ScaffoldMessenger:
if (!mounted) return;
setState(() {});
ScaffoldMessenger.of(context).showSnackBar(...);
```

### 2.3. Null-Coalescing
Prefira `??` ou `??=` ao invés de estruturas `if` manuais:
```dart
final paciente = getPacientePorId(pacienteId) ?? getPacienteAtivo();
```

---

## 3. Validação dos Modelos Nutricionais

- **[ItemRefeicaoModel](lib/models/dieta_model.dart):** Converte JSON com interoperabilidade entre a API (`alimento_nome`, `quantidade_gramas`) e armazenamento local (`nome`, `gramas`). Realiza o cálculo dos macronutrientes (proteínas, carboidratos, gorduras, fibras) proporcionalmente à massa informada.
- **[RefeicaoModel](lib/models/dieta_model.dart):** Totaliza calorias e macronutrientes de cada item da refeição.
- **[ComposicaoNutricionalDieta](lib/models/dieta_model.dart):** Calcula a distribuição energética no VET (% de calorias de cada macro), o índice por quilograma de massa corporal (g/kg) e o ranking de densidade nutricional por ingrediente.

