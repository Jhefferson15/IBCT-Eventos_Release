# IBCT Eventos

Aplicativo de gerenciamento de eventos desenvolvido para a Igreja Batista Central de Taguatinga (IBCT). O sistema oferece uma solução completa para controle de participantes, vendas em pontos de venda (PDV), check-in via QR Code e análise de dados.

## Trailer e Demonstração

<!-- Adicione o link para o vídeo do trailer ou demonstração aqui -->
[Assista ao Trailer do Projeto](link-para-o-video)

## Capturas de Tela

<p align="center">
  <img src="assets/screenshots/dashboard.png" width="30%" alt="Dashboard" />
  <img src="assets/screenshots/editor.png" width="30%" alt="Editor de Participantes" />
  <img src="assets/screenshots/store.png" width="30%" alt="Loja PDV" />
</p>

## Funcionalidades

### Gestão de Eventos
- Criação e edição de eventos.
- Arquivamento de eventos passados.
- Dashboard administrativo com busca e filtros.

### Controle de Participantes
- Importação de participantes via arquivo (CSV/Excel) e Google Forms.
- Editor avançado de dados em grade.
- Exportação de dados e geração de QR Codes para check-in.

### Loja e Ponto de Venda (PDV)
- Gestão de produtos e estoque por evento.
- Processamento de vendas e histórico de transações.
- Scanner de QR Code para identificação rápida de participantes durante a compra.

### Monitoramento e Feedback
- Coleta de feedbacks e pesquisas de satisfação.
- Analytics detalhado do evento.
- Monitoramento de erros via Firebase Crashlytics.

## Arquitetura

O projeto segue os princípios da **Clean Architecture**, dividindo-se em camadas para garantir manutenibilidade e testabilidade:

- **Domain**: Contém as entidades de negócio, interfaces de repositórios e casos de uso (Use Cases).
- **Data**: Implementações de repositórios, tratamento de fontes de dados externas (Firebase/Firestore) e DTOs.
- **Presentation**: Interface do usuário (Widgets) e gerenciamento de estado utilizando **Riverpod**.

O roteamento é gerenciado pelo **GoRouter**, proporcionando uma navegação declarativa e robusta.

## Stack Tecnológica

- **Framework**: Flutter
- **Gerenciamento de Estado**: Flutter Riverpod
- **Banco de Dados e Autenticação**: Firebase (Auth, Firestore)
- **Roteamento**: GoRouter
- **Estilização**: Google Fonts (Outfit)
- **Monitoramento**: Firebase Crashlytics

## Como Iniciar

### Pré-requisitos
- Flutter SDK (versão estável mais recente)
- Configuração do Firebase (Firebase Core SDK)

### Instalação
1. Clone o repositório:
   ```bash
   git clone [url-do-repositorio]
   ```
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute o aplicativo:
   ```bash
   flutter run
   ```

## Desenvolvimento e Testes

O projeto conta com um sistema de testes estruturado seguindo os mesmos padrões de arquitetura. Para mais detalhes, consulte o [README de Testes](test/README.md).

