# Pagina Profile:
Primeiramente observar na bottomNavigationBar da home_page.dart o seguinte:
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