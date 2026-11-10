# Circuito de Descobertas

Painel web para a organização e app Flutter para visitantes do Amazon Hacking,
integrados ao Firebase (plano Spark): a organização cadastra estandes e lança uma
missão surpresa, e os visitantes fazem check-in lendo o QR code de cada estande.

| Pasta / arquivo | Conteúdo |
|---|---|
| [`web/`](web/) | Painel administrativo (React + Vite + TypeScript) |
| [`mobile/`](mobile/) | App do visitante (Flutter, Android) |
| [`firestore.rules`](firestore.rules) | Regras de acesso do Cloud Firestore |
| [`remoteconfig.template.json`](remoteconfig.template.json) | Parâmetros da missão (referência) |
| [`docs/GUIA_FIREBASE.md`](docs/GUIA_FIREBASE.md) | **Passo a passo no console do Firebase + roteiro do vídeo** |

## Serviços Firebase usados

- **Authentication**: e-mail/senha (admin) e anônimo (visitante)
- **Cloud Firestore**: coleções `estandes`, `checkins` (`<uid>_<estandeId>`) e `admins`
- **Remote Config**: `missao_ativa`, `missao_estandes`, `missao_titulo`, com atualização em tempo real
- **Google Analytics**: eventos `missao_aberta` e `checkin_concluido` (`estande_id`)
- **App Distribution**: APK release assinado

## Rodar

Antes de tudo, siga o [guia](docs/GUIA_FIREBASE.md) para criar o projeto Firebase
e preencher as credenciais. Sem elas, o painel e o app mostram uma tela pedindo a configuração.

**Painel web**

```bash
cd web
cp .env.example .env   # preencha com a config do app web
npm install
npm run dev            # http://localhost:5173
npm test               # testes de unidade
```

**App Flutter**

```bash
cd mobile
flutterfire configure  # gera lib/firebase_options.dart
flutter run            # celular Android conectado
flutter test
flutter build apk --release
```

## Como funciona

- **QR code**: o conteúdo é `circuito://estande/<id>`. O painel gera o QR na página `/qr/<id>`, que pode ser impressa.
- **Check-in**: o app valida o QR, confere se o estande existe e está ativo, e grava
  `checkins/<uid>_<estandeId>` numa transação. O ID composto impede visitas duplicadas,
  e as regras do Firestore também conferem isso no servidor.
- **Totais**: o painel escuta a coleção `checkins` em tempo real e soma por estande.
- **Missão**: com `missao_ativa = true`, o app mostra o banner e destaca os estandes de
  `missao_estandes` que estão ativos. Com `false`, tudo volta ao normal sem reinstalar.
