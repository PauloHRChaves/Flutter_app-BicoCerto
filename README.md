
-----

# Bico Certo - Aplicativo Flutter (Mobile/Web)

Este projeto implementa o lado do cliente (Front-end) para o aplicativo Bico Certo, com foco em um fluxo de autenticação completo e seguro, gerenciamento de estado e integração com a API Wallet.

## 1\. Configuração e Instalações

Para rodar este projeto, você precisa ter o Flutter e o Android Studio instalados.

### 1.1. Dependências do Projeto

Os seguintes pacotes foram instalados e configurados para as funcionalidades de rede, armazenamento e deep linking:

| Pacote | Função | Comando de Instalação |
| :--- | :--- | :--- |
| **`http`** | Comunicação com a API REST (GET, POST). | `flutter pub add http` |
| **`flutter_secure_storage`** | Armazenamento seguro do `access_token` e outros dados sensíveis. | `flutter pub add flutter_secure_storage` |
| **`app_links`** | Gerenciamento de Deep Links (substituto moderno do `uni_links`). | `flutter pub add app_links` |
| **`device_info_plus`** | Obter informações do dispositivo (usado no login/cadastro). | `flutter pub add device_info_plus` |

### 1.2. Notas Críticas de Build (Android)

  * **Compilação:** Se o projeto falhar ao compilar em Android (`cannot find symbol class Registrar`), execute `flutter clean` e `flutter pub get`.
  * **Deep Linking:** As configurações nativas foram feitas em `AndroidManifest.xml` para a rota `/reset-password` funcionar.
  * **Execução Local:** Ao rodar no **Emulador Android**, o `baseUrl` na sua classe `AuthService` deve ser **`http://10.0.2.2:8000`**. Para Windows/Web, use `http://127.0.0.1:8000`.

## 2\. Arquitetura e Organização do Código

O projeto segue um padrão modular com o seguinte esquema de pastas:

```
lib/
├── pages/
│   ├── auth/         # Login, Cadastro, AuthWrapper (estrutura visual)
│   ├── home/         # Página principal (HomePage)
│   └── profile/      # Perfil, WalletPage, CreateWalletPage
├── services/         # Lógica de API (AuthService) e Storage
├── widgets/          # Componentes reutilizáveis (CategoryCard, AuthGuard)
└── main.dart         # Ponto de entrada e rotas globais.
```

## 3\. Funcionalidades Implementadas

### 3.1. Autenticação Completa

| Feature | Descrição |
| :--- | :--- |
| **Login / Cadastro** | Requisições `POST /auth/login` e `POST /auth/register` funcionando com validação local de senha (8 caracteres, símbolos, maiúsculas/minúsculas). |
| **Token Handling** | Após o login, o `access_token` é salvo imediatamente usando `flutter_secure_storage`. Todas as requisições protegidas usam `Authorization: Bearer <token>`. |
| **Logout Seguro** | O `logout()` chama o endpoint da API (`/auth/logout`) para invalidar o token no servidor **antes** de removê-lo do armazenamento local. |
| **Deep Linking (Password Reset)** | O fluxo de redefinição de senha (`/auth/password/forgot` e `/auth/password/reset`) está configurado, permitindo que o usuário insira o código e o token (temporariamente manual para simplificação de teste). |

### 3.2. Gerenciamento de Estado e Segurança

  * **AuthGuard (lib/widgets/auth\_guard.dart):** Proteção de segurança implementada. Qualquer página importante (como o Perfil) é envolvida por este guarda, que verifica o token antes de exibir o conteúdo e redireciona para o login se o token estiver ausente.
  * **HomePage:** Exibe botões condicionais de **Login** (se deslogado) ou **Logout** (se logado) na AppBar, usando rotas nomeadas.

### 3.3. Funcionalidade Wallet

A seção de carteira (`WalletPage` e `SetProfile`) implementa a lógica condicional e o display de dados:

| Feature | Endpoint | Lógica Implementada |
| :--- | :--- | :--- |
| **Checagem de Status** | `GET /wallet/my-wallet` | Ao clicar no ícone Wallet, o app verifica a flag **`has_wallet`** retornada pela API. |
| **Navegação Condicional**| N/A | Redireciona para `WalletPage` (se existir) **OU** `CreateWalletPage` (se não existir). |
| **Criação de Carteira**| `POST /wallet/create` | Implementação do formulário para enviar a senha de criação. |
| **Exibição de Saldo** | `GET /wallet/balance` | Busca o `balance_eth` e o `address` da API. |
| **UI Dinâmica** | N/A | Exibe o saldo formatado como **BRL** e o endereço encurtado (`0x511E2...45131`) com funcionalidade de **copiar para a área de transferência**. |

## 4\. Próximos Passos (Desenvolvimento)

A próxima etapa lógica para a sua equipe é:

1.  **Carregar Dados do Usuário:** Usar um `FutureBuilder` no `SetProfile` para buscar os dados completos do usuário após o login e substituir os placeholders ("Name", "Profissão") por dados reais.
2.  **Finalizar Fluxo de Pedidos:** Implementar a navegação e a UI para a seção de `Pedidos` (ícone de índice 1 no `BottomNavBar`).
