# Módulo Financeiro (Arquivado Temporariamente)

Este módulo foi retirado da versão atual do aplicativo para simplificar o lançamento inicial, mantendo o foco no acompanhamento nutricional, prescrição de dietas e registro diário de refeições.

## Conteúdo Arquivado:
- `financeiro_page.dart`: Tela de visão geral mensal de recebimentos, saldo previsto e lista de pacientes pendentes/em débito.
- Indicadores de status financeiro (`Pago` / `Em débito`) que apareciam nos cards de pacientes (`pacientes_page.dart`), no topo da prescrição de dieta (`criar_dieta_page.dart`) e nos alertas de `configuracoes_page.dart`.

## Como reativar em uma atualização futura:
1. Mover `financeiro_page.dart` de volta para `lib/pages/financeiro_page.dart`.
2. Reativar o item **Financeiro** no `AppDrawer` (`lib/widgets/app_drawer.dart`).
3. Reativar os filtros e badges de status financeiro em `lib/pages/pacientes_page.dart` e `lib/pages/criar_dieta_page.dart`.
4. Reativar o switch de **Alertas Financeiros** em `lib/pages/configuracoes_page.dart`.

