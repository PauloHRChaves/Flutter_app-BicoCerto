<h1>Bico Certo</h1>
Frontend de Projeto - Desenvolvimento Mobile com Dart//Flutter
<br>
<p>O app consiste em um service hub para "pequenos" trabalhos informais servindo de ponte, e não apenas, para prestadores de serviços e clientes trazendo camadas de segurança e praticidade para quem o utilizar.</p>
<br>
<br>
<h3>Esqueleto do app:</h3>
<pre>
/assets                     - Para manter arquivos de mídia ou arquivos de dados organizados. (Declararpath no pubspec.yaml)
    /images/
    /fonts/
    /data/
/lib                        - Estrutura principal
    /models/                - Guardar as classes de dados
    /pages/                 - Telas do app
    /services/              - Lógica de negócio, como a comunicação com a API, funcionalidades do app.
    /widgets/               - Para widgets reutilizáveis
pubspec.yaml
</pre>
<br>
<br>
<h3> Arquivos:</h3>
<pre>
/lib
    /pages/
        login_page.dart                    - Pagina incial abrindo o app não sendo a primeira vez
        welcome_page.dart                  - Pagina incial abrindo o app pela primeira vez
    /services/
        local_storage_service.dart         - Funcionalidade de redirecionamento da pagina inicial
    main.dart                              - Ponto de partida
    route.dart                             - Navegação entre as telas (rotas)
pubspec.yaml                               - Adição de dependencias (shared_preferences;)
</pre>