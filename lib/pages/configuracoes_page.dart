import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/biometria_service.dart';
import '../services/dados_service.dart';
import '../services/lembretes_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/apple_theme_toggle.dart';
import 'chat_nutri_page.dart';
import 'login_page.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final DadosService _dadosService = DadosService();

  bool _notificacoesDieta = true;
  bool _notificacoesAgua = false;
  bool _biometriaAtiva = false;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeNutriSalvo = prefs.getString('config_nutri_nome');
    final emailNutriSalvo = prefs.getString('config_nutri_email');
    if (nomeNutriSalvo != null && emailNutriSalvo != null) {
      _dadosService.atualizarPerfilNutri(nome: nomeNutriSalvo, email: emailNutriSalvo);
    }

    if (!mounted) return;
    setState(() {
      _notificacoesDieta = prefs.getBool('config_notif_dieta') ?? true;
      _notificacoesAgua = prefs.getBool('config_notif_agua') ?? false;
      _biometriaAtiva = prefs.getBool('config_biometria') ?? false;
    });
  }

  Future<void> _alternarNotificacaoDieta(bool valor) async {
    setState(() => _notificacoesDieta = valor);
    await LembretesService.setLembretesAtivos(valor);
    if (valor) {
      await LembretesService.agendarLembretesDieta(_dadosService.getPacienteAtivo().planoAlimentar);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          valor
              ? 'Lembretes ativados! O app notificará você nos horários fixados pela Nutri.'
              : 'Lembretes de refeições desativados.',
        ),
        backgroundColor: valor ? AppColors.verde : Colors.grey,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _alternarNotificacaoAgua(bool valor) async {
    setState(() => _notificacoesAgua = valor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('config_notif_agua', valor);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          valor
              ? 'Lembrete de hidratação (de hora em hora) ativado!'
              : 'Lembrete de água desativado.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _abrirModalEditarPerfil() {
    final isNutri = _dadosService.isNutri;
    final paciente = _dadosService.getPacienteAtivo();

    final nomeCtrl = TextEditingController(
      text: isNutri ? _dadosService.nomeNutri : paciente.nome,
    );
    final emailCtrl = TextEditingController(
      text: isNutri ? _dadosService.emailNutri : (paciente.email ?? 'paciente@teste.com'),
    );
    final usuarioCtrl = TextEditingController(
      text: isNutri ? 'nutri' : paciente.usuario,
    );
    final fotoCtrl = TextEditingController(
      text: isNutri ? '' : (paciente.fotoUrl ?? ''),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: usuarioCtrl,
                  enabled: !isNutri,
                  decoration: const InputDecoration(
                    labelText: 'Nome de Usuário',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                if (!isNutri) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: fotoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da Foto de Perfil (Opcional)',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final novoNome = nomeCtrl.text.trim();
                      final novoEmail = emailCtrl.text.trim();
                      final novoUsuario = usuarioCtrl.text.trim();

                      if (novoNome.isEmpty || novoEmail.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preencha nome e e-mail.')),
                        );
                        return;
                      }

                      if (isNutri) {
                        final res = await ApiService.atualizarMeuPerfil(nome: novoNome, email: novoEmail);
                        if (res['sucesso'] == true) {
                          _dadosService.atualizarPerfilNutri(nome: novoNome, email: novoEmail);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('config_nutri_nome', novoNome);
                          await prefs.setString('config_nutri_email', novoEmail);
                        } else {
                          if (!modalContext.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['mensagem'] ?? 'Erro ao salvar perfil no servidor.'),
                              backgroundColor: AppColors.vermelho,
                            ),
                          );
                          return;
                        }
                      } else {
                        await _dadosService.atualizarDadosPerfilPaciente(
                          paciente.id,
                          nome: novoNome,
                          email: novoEmail,
                          usuario: novoUsuario.isNotEmpty ? novoUsuario : paciente.usuario,
                          fotoUrl: fotoCtrl.text.trim(),
                        );
                      }

                      if (!modalContext.mounted) return;
                      Navigator.pop(modalContext);
                      if (!mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perfil atualizado com sucesso!'),
                          backgroundColor: AppColors.verde,
                        ),
                      );
                    },
                    child: const Text('Salvar Alterações'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirModalSeguranca() {
    final senhaAtualCtrl = TextEditingController();
    final novaSenhaCtrl = TextEditingController();
    final confirmarSenhaCtrl = TextEditingController();
    bool ocultarSenhas = true;
    bool alterandoSenha = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Segurança da Conta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextoPrincipal(context),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fingerprint, color: AppColors.verde),
                      title: Text(
                        'Acesso com Biometria',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextoPrincipal(context),
                        ),
                      ),
                      subtitle: Text(
                        'Solicitar impressão digital ou FaceID ao abrir o app',
                        style: TextStyle(fontSize: 12, color: AppColors.getTextoSecundario(context)),
                      ),
                      value: _biometriaAtiva,
                      activeTrackColor: AppColors.verde,
                      onChanged: (val) async {
                        if (val) {
                          final podeUsar = await BiometriaService.podeUsarBiometria();
                          if (!podeUsar) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Biometria não configurada ou não suportada neste dispositivo.'),
                                backgroundColor: AppColors.vermelho,
                              ),
                            );
                            return;
                          }

                          final autenticou = await BiometriaService.autenticar(
                            motivo: 'Confirme sua biometria para ativar o acesso rápido',
                          );

                          if (!autenticou) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Autenticação biométrica cancelada ou não reconhecida.'),
                                backgroundColor: AppColors.vermelho,
                              ),
                            );
                            return;
                          }
                        }

                        if (!modalContext.mounted) return;
                        setModalState(() => _biometriaAtiva = val);
                        if (!mounted) return;
                        setState(() => _biometriaAtiva = val);
                        await BiometriaService.setBiometriaAtiva(val);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Acesso biométrico ativado com sucesso!'
                                  : 'Acesso biométrico desativado.',
                            ),
                            backgroundColor: val ? AppColors.verde : Colors.grey,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    Text(
                      'Alterar Senha',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: senhaAtualCtrl,
                      obscureText: ocultarSenhas,
                      decoration: const InputDecoration(
                        labelText: 'Senha Atual',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: novaSenhaCtrl,
                      obscureText: ocultarSenhas,
                      decoration: InputDecoration(
                        labelText: 'Nova Senha',
                        prefixIcon: const Icon(Icons.key_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(ocultarSenhas ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => ocultarSenhas = !ocultarSenhas),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmarSenhaCtrl,
                      obscureText: ocultarSenhas,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Nova Senha',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: alterandoSenha
                            ? null
                            : () async {
                                if (senhaAtualCtrl.text.isEmpty || novaSenhaCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Preencha a senha atual e a nova senha.')),
                                  );
                                  return;
                                }
                                if (novaSenhaCtrl.text.length < 4) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('A nova senha deve ter pelo menos 4 caracteres.')),
                                  );
                                  return;
                                }
                                if (novaSenhaCtrl.text != confirmarSenhaCtrl.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('A confirmação da senha não confere.'),
                                      backgroundColor: AppColors.vermelho,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => alterandoSenha = true);
                                final res = await ApiService.alterarSenha(
                                  senhaAtual: senhaAtualCtrl.text,
                                  novaSenha: novaSenhaCtrl.text,
                                );
                                setModalState(() => alterandoSenha = false);

                                if (res['sucesso'] == true) {
                                  if (!modalContext.mounted) return;
                                  Navigator.pop(modalContext);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['mensagem'] ?? 'Senha alterada com sucesso!'),
                                      backgroundColor: AppColors.verde,
                                    ),
                                  );
                                } else {
                                  if (!modalContext.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['mensagem'] ?? 'Erro ao alterar a senha.'),
                                      backgroundColor: AppColors.vermelho,
                                    ),
                                  );
                                }
                              },
                        child: alterandoSenha
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Atualizar Senha'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _abrirModalAjudaSuporte() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ajuda e Suporte',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextoPrincipal(context),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const ExpansionTile(
                  leading: Icon(Icons.calculate_outlined, color: AppColors.verde),
                  title: Text('Como funcionam as Calorias Restantes?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Sua nutricionista define a sua Meta Diária (ex: 2000 kcal). Sempre que você registra um alimento consumido ou marca uma refeição prescrita como consumida, esse valor calórico é subtraído automaticamente das suas calorias restantes do dia.',
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  leading: Icon(Icons.restaurant_menu_outlined, color: AppColors.verde),
                  title: Text('Como registrar minhas refeições?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Na tela de Refeições, você pode clicar no botão "Consumir" diretamente em uma refeição do seu Plano Prescrito ou ir até a aba "Registro Diário" e tocar em "Adicionar Consumo" para escolher alimentos e quantidades personalizadas.',
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  leading: Icon(Icons.support_agent_outlined, color: AppColors.verde),
                  title: Text('Contato da Clínica — Dra. Juliana Braz'),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'E-mail: atendimento@nutrijulianabraz.com.br\nHorário de atendimento: Segunda a Sexta, das 08h às 18h.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatNutriPage(
                            paciente: _dadosService.getPacienteAtivo(),
                            isNutri: _dadosService.isNutri,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Falar com a Nutri no Chat'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirModalTermosUso() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Termos de Uso e Privacidade'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Finalidade do Aplicativo\n'
            'O aplicativo Nutri+ Juliana Braz é destinado ao acompanhamento nutricional personalizado, prescrição de planos alimentares e monitoramento diário de metas calóricas e antropométricas.\n\n'
            '2. Privacidade e Proteção de Dados (LGPD)\n'
            'Seus dados pessoais, medidas corporais e registros alimentares são confidenciais e utilizados exclusivamente pela sua nutricionista para avaliação clínica.\n\n'
            '3. Responsabilidade Clínica\n'
            'As metas calóricas e planos alimentares são individualizados e somente podem ser alterados pela profissional nutricionista responsável.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Concordo e Fechar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusaoConta() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.vermelho, size: 40),
        title: const Text('Excluir minha conta'),
        content: const Text(
          'Tem certeza que deseja encerrar e excluir sua conta deste dispositivo? Você precisará fazer um novo login ou cadastro para acessar novamente.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.vermelho),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ChatService().limpar();
              await ApiService.logout();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sua conta foi desconectada e removida com sucesso.'),
                  backgroundColor: AppColors.vermelho,
                ),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Sim, excluir conta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNutri = _dadosService.isNutri;
    final nomeAtual = isNutri ? _dadosService.nomeNutri : _dadosService.getPacienteAtivo().nome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          AppleThemeToggle(size: 28),
          SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(paginaAtual: 'configuracoes'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Geral'),
            _buildSettingsContainer([
              _buildListTile(
                icone: Icons.person_outline,
                titulo: 'Editar Perfil ($nomeAtual)',
                subtitulo: 'Atualize seus dados pessoais, e-mail e foto',
                onTap: _abrirModalEditarPerfil,
              ),
              _buildDivider(),
              _buildListTile(
                icone: Icons.lock_outline,
                titulo: 'Segurança',
                subtitulo: _biometriaAtiva
                    ? 'Biometria ativa • Alterar senha de acesso'
                    : 'Mude sua senha ou habilite biometria',
                onTap: _abrirModalSeguranca,
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Notificações'),
            _buildSettingsContainer([
              _buildSwitchTile(
                icone: Icons.restaurant_outlined,
                titulo: 'Lembretes de Dieta',
                subtitulo: 'Seja avisado sobre suas próximas refeições',
                valor: _notificacoesDieta,
                onChanged: _alternarNotificacaoDieta,
              ),
              _buildDivider(),
              _buildSwitchTile(
                icone: Icons.water_drop_outlined,
                titulo: 'Lembrete de Água',
                subtitulo: 'Avise-me para beber água de hora em hora',
                valor: _notificacoesAgua,
                onChanged: _alternarNotificacaoAgua,
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Sobre o App'),
            _buildSettingsContainer([
              _buildListTile(
                icone: Icons.help_outline,
                titulo: 'Ajuda e Suporte',
                subtitulo: 'Dúvidas frequentes e contato com a clínica',
                onTap: _abrirModalAjudaSuporte,
              ),
              _buildDivider(),
              _buildListTile(
                icone: Icons.info_outline,
                titulo: 'Termos de Uso',
                subtitulo: 'Política de privacidade e diretrizes clínicas',
                onTap: _abrirModalTermosUso,
              ),
              _buildDivider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Versão do Aplicativo', style: TextStyle(color: AppColors.getTextoPrincipal(context))),
                    Text('1.0.5', style: TextStyle(color: AppColors.getTextoSecundario(context), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 40),
            Center(
              child: TextButton.icon(
                onPressed: _confirmarExclusaoConta,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text('Excluir minha conta', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.getTextoPrincipal(context),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Material(
      color: AppColors.getCard(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.getBorda(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icone,
    required String titulo,
    String? subtitulo,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icone, color: AppColors.verde),
      title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextoPrincipal(context))),
      subtitle: subtitulo != null
          ? Text(subtitulo, style: TextStyle(fontSize: 12, color: AppColors.getTextoSecundario(context)))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Icon(icone, color: AppColors.verde),
      title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.getTextoPrincipal(context))),
      subtitle: Text(subtitulo, style: TextStyle(fontSize: 12, color: AppColors.getTextoSecundario(context))),
      value: valor,
      activeTrackColor: AppColors.verde,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.getBorda(context));
  }
}
