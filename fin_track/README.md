# FinTrack

FinTrack é um aplicativo Flutter desenvolvido como Trabalho de Conclusão de Curso para registrar, organizar, buscar e proteger comprovantes financeiros. O app funciona com persistência local, processamento por OCR, classificação assistida por dados extraídos, busca textual e semântica, relatórios e backup opcional no Google Drive.

## Objetivo

O projeto resolve um problema prático: comprovantes ficam espalhados em galeria, aplicativos de banco, arquivos PDF e conversas. O FinTrack centraliza esses registros, extrai informações relevantes e oferece meios de consulta, categorização, auditoria e recuperação por backup.

## Funcionalidades

- Cadastro de comprovantes por câmera, seleção de arquivos e compartilhamento de imagens/PDFs a partir de outros apps.
- Processamento de OCR com Google ML Kit, leitura de códigos visuais e seleção da melhor variante processada.
- Extração de dados como estabelecimento, valor, data, tipo de comprovante, forma de pagamento, CNPJ e itens fiscais quando disponíveis.
- Enriquecimento fiscal por chave/QR code e consulta de CNPJ com cache local.
- Revisão e confirmação dos dados antes de salvar, inclusive em fluxo de importação em lote.
- Listagem com busca textual, filtros, ordenação, seleção múltipla, edição, exclusão, compartilhamento e exportação local.
- Busca semântica local com embeddings do modelo `distiluse-base-multilingual-cased-v2` em ONNX.
- Reindexação semântica em segundo plano quando necessário.
- Categorias personalizadas com descrição, cor, ícone, ordenação e proteção contra exclusão quando há comprovantes associados.
- Relatórios por categoria, tipo e período.
- Backup e restauração com Google Drive, histórico de backups e opção de backup automático.
- Criptografia de backup com AES-GCM 256 e chave derivada por PBKDF2-HMAC-SHA256.
- Bloqueio por autenticação local do dispositivo quando habilitado.
- Tela de configurações com preferências, armazenamento, backup, segurança e informações do app.
- Registro de diagnósticos para falhas controladas e suporte.

## Arquitetura

O app segue uma separação em camadas:

- `domain`: entidades, contratos, repositórios abstratos, serviços abstratos e exceções.
- `application`: casos de uso, regras de negócio, OCR parsing, enriquecimento, backup, políticas e serviços de aplicação.
- `infrastructure`: banco Drift/SQLite, Google Drive, ML Kit, embeddings ONNX, criptografia, segurança, imagem e integrações Android.
- `presentation`: telas, controllers e widgets Flutter.
- `bootstrap`: composição das dependências para execução local, testes e execução persistente.

Essa organização permite substituir integrações nativas por fakes nos testes, sem acoplar a regra de negócio à UI ou a plugins externos.

## Principais Tecnologias

- Flutter e Dart.
- Drift, SQLite e `sqlite_vector` para persistência e suporte a busca vetorial.
- Google ML Kit para OCR, scanner de documentos e leitura de códigos.
- ONNX Runtime para geração local de embeddings.
- Google Sign-In e Google Drive API para backup.
- `cryptography` para criptografia autenticada dos backups.
- Mockito e Flutter Test para testes unitários e de widget.

## Execução

Instale as dependências:

```bash
flutter pub get
```

Execute o app:

```bash
flutter run
```

Execute os testes:

```bash
flutter test
```

Execute análise estática:

```bash
flutter analyze
```

Execute os testes com cobertura:

```bash
flutter test --coverage
```

Gere código quando alterar arquivos dependentes de build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Gere os ícones do app:

```bash
dart run flutter_launcher_icons
```

## Build Android

Para gerar APK de release:

```bash
flutter build apk --release
```

O manifesto Android já inclui permissões e filtros necessários para câmera, biometria, internet, notificações e recebimento de imagens/PDFs por compartilhamento.

## Backup e Segurança

O backup é opcional. Quando configurado, os dados são empacotados, criptografados com senha definida pelo usuário e enviados ao Google Drive. A senha não deve ser perdida: sem ela, não é possível restaurar backups protegidos.

O bloqueio local usa a autenticação disponível no dispositivo, como biometria ou credenciais do sistema, conforme suporte da plataforma.

## Testes e Qualidade

O projeto possui cobertura ampla de serviços, repositórios, parsing OCR, backup, importação em lote, busca semântica, configurações e telas principais.

Comandos de validação recomendados antes de entrega:

```bash
flutter analyze
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Publicação por Tag

Quando a pipeline de release estiver configurada, crie e envie uma tag de versão:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Substitua `v1.0.0` pela versão desejada. O push comum continua acionando a pipeline principal configurada no repositório.
