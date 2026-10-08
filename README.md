# Relatório de revisão para publicação no GitHub

Data: 08/10/2026. Escopo: lib.zip enviado nesta conversa; os Dart avulsos não substituíram os arquivos do ZIP.

## Alterações feitas

- `lib/data/firebase_options.dart`: valores do projeto Firebase substituídos por `String.fromEnvironment`, com uma variável por campo e plataforma. Classes, plataformas e estrutura preservadas.
- `lib/Base/login_page.dart`: três emails da lista de acesso e o client ID Google macOS substituídos por `String.fromEnvironment`. Removido o email de duas mensagens de log e da mensagem de acesso não autorizado. A verificação de domínio e a lógica de login foram preservadas.
- Removidos somente metadados macOS (`__MACOSX` e `.DS_Store`), que podem carregar informações locais desnecessárias.

Os demais arquivos Dart foram mantidos byte a byte. Não alterei layout, cálculos, preços, operações Firestore, nomes da empresa nem endereço comercial.

## Como executar a cópia preparada

O ZIP é uma cópia para publicação. Sem configurar os valores removidos, Firebase e login Google não funcionarão normalmente.

Use `config_publicacao.example.json` como modelo, preencha uma cópia local chamada `config_publicacao.json` com os valores originais e rode, na raiz do projeto completo:

```bash
flutter run --dart-define-from-file=config_publicacao.json
```

Adicione `/config_publicacao.json` ao `.gitignore` da raiz antes de publicar. O modelo contém apenas nomes de variáveis e valores vazios. Não publique o arquivo preenchido. Alternativamente, configure seu próprio projeto usando FlutterFire e o client ID correspondente.

Os valores de `ALLOWED_EMAIL_1`, `ALLOWED_EMAIL_2` e `ALLOWED_EMAIL_3` mantêm a lista original quando fornecidos. O domínio empresarial original permanece no código e continua autorizando contas desse domínio, como antes.

## Resultado e limites

Não encontrei senhas literais, chaves privadas de conta de serviço, tokens de sessão literais ou registros reais de clientes nos arquivos examinados. Campos de senha e referências a tokens usados durante o login são código funcional e foram mantidos.

Configuração cliente Firebase e IDs OAuth não são, por si só, credenciais privadas. Foram retirados desta cópia para evitar publicar os identificadores do ambiente empresarial. A proteção dos dados depende das regras do Firebase; esconder a configuração não substitui autorização. Variáveis de compilação também ficam no aplicativo compilado e não são um cofre de segredos.

Referência oficial: https://firebase.google.com/docs/projects/api-keys

O ZIP contém somente a pasta lib; não inclui regras Firestore, pubspec.yaml, configurações Android/iOS, assets nem histórico Git. Não foi possível verificar as regras implantadas, restrições de API ou compilar o projeto completo. Portanto, este relatório não certifica a segurança do banco nem de todo o repositório. A checagem de emails no cliente não substitui regras no servidor.

## Validação realizada

Comparação dos bytes com o ZIP original: apenas os dois Dart listados acima mudaram. Verificação do ZIP final: os identificadores Firebase removidos, o client ID Google original e os três emails da lista não aparecem nos Dart. Arquivo ZIP reaberto e verificado. Nenhuma execução ou alteração do banco foi realizada.

Arquivos Dart preservados sem alteração: 28. Arquivos Dart alterados: 2. Entradas de metadados removidas: 45.
