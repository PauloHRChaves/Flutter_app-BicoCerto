# Pagina Profile:
### Primeiramente observar na bottomNavigationBar da home_page.dart o seguinte:
```
else if (index == 3) {
    Navigator.pushNamedAndRemoveUntil(context,
        AppRoutes.profileteste,
        (route) => route.isFirst,
    );
}
```

### AppRoutes.**profileteste** -> pagina de teste apenas UI<br>AppRoutes.**profilePage** -> pagina de uso com logica aplicada
<hr>

### Precisa receber as informações.
```
final double totalEarnings = 1850.00;
final double percentageChange = 12.0;
final String nome = '1234_1234_1234_1234_1234_1234_1234_1';
final String id = '123456789';
final String cidade = 'Salvador';
final String estado = 'BA';
final String description =
    '123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_';

final int jobdone = 0;
final double estrelas = 2;
```

### Redirecionar para a pagina de create wallet

- profile.dart - linha: 30
```
else {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Carteira não encontrada. Por favor, crie uma.')),
        );
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateWalletPage()), // pagina de Criação da Wallet
        );
    }
}`
```
<br>

# Pagina Wallet
### Fazer uma pagina apenas para UI

Error ao criar wallet e buscar wallet corrigidos.

Wallet_page: mudaças no _timer, basicamente trocando **late Timer _timer;**, que estava causando error, por **Timer? _timer;**
<pre>
Error de autenticação ou conexão:   LateInitializationError:Field'_time@53303382' has not been initialized
</pre>


Auth_service antigo:
```
    Future<Map<String, dynamic>> getWalletDetails() async {
    try {
      final responseData = await _secureGet('wallet/my-wallet');
      
      // CASO A: API envia o status de "não tem carteira"
      if (responseData.containsKey('has_wallet')) {
        return responseData; 
      }
      
      // CASO B: API envia os detalhes da carteira (Carteira existe).
      // Cria um novo Map, injetando o status 'has_wallet: true'
      final Map<String, dynamic> walletData = responseData['data'] as Map<String, dynamic>? ?? {};
      
      // Retorna os dados da carteira juntamente com o status de sucesso.
      return {
        'has_wallet': true,
        ...walletData, // Adiciona o resto dos dados da carteira
      };

    } catch (e) {
      rethrow; 
    }
  }
```