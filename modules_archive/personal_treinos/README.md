# Módulo de Personal Trainer & Treinos (Arquivado Temporariamente)

Este módulo foi retirado da versão atual do aplicativo para manter o foco 100% na parte da Nutricionista (Dra. Juliana) e seus pacientes, conforme alinhamento com a nutricionista.

## Conteúdo Arquivado:
- `criar_treino_page.dart`: Tela do personal para prescrever treinos e exercícios para o aluno.
- `pacientes_treino_page.dart`: Lista de alunos sob a tutela do personal.
- `treinos_page.dart`: Tela do paciente/aluno para visualizar treinos prescritos e marcar como concluído.
- `treino_model.dart`: Modelo de dados para `TreinoModel` e `ItemTreinoModel`.

## Como reativar em uma atualização futura:
1. Mover `treino_model.dart` para `lib/models/`.
2. Mover as 3 páginas (`criar_treino_page.dart`, `pacientes_treino_page.dart`, `treinos_page.dart`) de volta para `lib/pages/`.
3. Reativar o item no `AppDrawer` (`lib/widgets/app_drawer.dart`).
4. Reativar a opção no login e o fluxo do usuário personal em `login_page.dart`.
