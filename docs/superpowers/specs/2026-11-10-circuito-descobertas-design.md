# Circuito de Descobertas — Design

Data: 2026-11-10
Status: aprovado em conversa

## Objetivo

Sistema para o Amazon Hacking: a organização cadastra estandes e lança uma missão
surpresa; visitantes recebem a missão no app, fazem check-in lendo QR code no estande;
a organização acompanha os totais no painel. Tudo sobre Firebase (plano Spark).

## Divisão de trabalho

- **Nós (este repositório):** todo o código do painel web e do app Flutter, `firestore.rules`,
  template de Remote Config, chamadas de Analytics, assinatura do APK e
  `docs/GUIA_FIREBASE.md` com os passos externos.
- **Restante da equipe:** criar/configurar o projeto Firebase, credenciais
  (`flutterfire configure`, config web), criar admin, publicar Remote Config,
  App Distribution, gravação do vídeo.
- **Git:** fica a cargo do usuário. Nenhuma operação git é feita aqui.

Credenciais do Firebase ficam como *placeholders*; o código precisa compilar e os
testes de unidade precisam passar sem um projeto Firebase real.

## Estrutura

```
/web/                         painel React + Vite + TypeScript
/mobile/                      app Flutter (Android)
/firestore.rules              regras de acesso
/firestore.indexes.json       (vazio; nenhuma consulta exige índice composto)
/firebase.json                firestore rules + hosting de web/dist
/remoteconfig.template.json   parâmetros de referência
/docs/GUIA_FIREBASE.md        passo a passo externo + roteiro do vídeo
```

## Modelo de dados (Cloud Firestore)

| Caminho | Campos |
|---|---|
| `estandes/{id}` | `nome` (string), `descricao` (string), `localizacao` (string), `ativo` (bool), `atualizadoEm` (timestamp) |
| `checkins/{visitanteId}_{estandeId}` | `visitanteId` (string), `estandeId` (string), `criadoEm` (timestamp do servidor) |
| `admins/{uid}` | `email` (string) — criado manualmente no console |

O ID composto do check-in garante uma visita por estande por visitante.

## Formato do QR code

Conteúdo: `circuito://estande/<estandeId>`. Qualquer outro conteúdo é "QR inválido".
O parser é uma função pura compartilhada em conceito (implementada em TS e em Dart).

## Regras de acesso

- `isAdmin()` = autenticado e existe `admins/{request.auth.uid}`.
- `estandes`:
  - `get`: qualquer usuário autenticado (permite ao app distinguir "inativo" de "inexistente").
  - `list`: admin; ou autenticado com `resource.data.ativo == true` (o app consulta com `where('ativo', '==', true)`).
  - `create`, `update`, `delete`: somente admin, com validação de tipos dos campos.
- `checkins`:
  - `create`: autenticado, `visitanteId == request.auth.uid`, ID do doc == `uid + '_' + estandeId`,
    só as chaves `visitanteId`, `estandeId`, `criadoEm`, `criadoEm == request.time`,
    e o estande referenciado existe e está ativo.
  - `get`: admin; ou ID do doc começa com `request.auth.uid + '_'` (funciona também para doc
    inexistente, necessário para a verificação "já registrado" dentro da transação).
  - `list`: admin; ou dono (`resource.data.visitanteId == request.auth.uid`).
  - `update`, `delete`: negado.
- `admins/{uid}`: leitura apenas pelo próprio uid; escrita negada (feita via console).

## Painel web (React + Vite + TS)

Dependências: `firebase`, `react-router-dom`, `qrcode.react`; testes com `vitest`.
Config via `.env` (`VITE_FIREBASE_*`), com `.env.example`.

- **Login** (`/login`): e-mail e senha. Após login, verifica `admins/{uid}`; se não existir,
  mostra "Usuário sem permissão de administrador" e oferece sair.
- **Estandes** (`/`): tabela com nome, localização, ativo e total de check-ins.
  Totais = listener `onSnapshot` em `checkins`, agrupados por `estandeId` no cliente
  (função pura `contarCheckinsPorEstande`). Ações: novo, editar, ativar/desativar,
  "Ver QR" (abre `/qr/:id` em nova aba). Botão "Criar estandes de exemplo" (3 fictícios),
  visível quando não há estandes.
- **Formulário**: nome, descrição breve, localização, ativo; validação de campos obrigatórios.
- **QR** (`/qr/:id`): página limpa com nome, localização, QR grande e botão Imprimir
  (`window.print()`, CSS de impressão esconde o botão).

## App Flutter

Pacotes: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_remote_config`,
`firebase_analytics`, `mobile_scanner`. Estado com `ChangeNotifier` + `StreamBuilder`.

Camadas:
- `lib/domain/` (puro, testável): `Estande`, `parseQr`, `estandesDaMissao`,
  `CheckinResultado` (sucesso, qrInvalido, naoEncontrado, inativo, jaRegistrado, erro),
  `CheckinService` (orquestra validação usando a interface `CheckinRepository`).
- `lib/data/`: `FirestoreCheckinRepository`, `EstandeRepository` (stream dos ativos),
  `MissaoConfig` (Remote Config), `AnalyticsService`, `AuthService` (anônimo).
- `lib/ui/`: `HomeScreen`, `MissaoScreen`, `ScannerScreen`.

Comportamento:
- Inicialização: `Firebase.initializeApp` → `signInAnonymously` se não houver usuário →
  Remote Config com padrões locais → abre Home.
- **Home**: lista em tempo real dos estandes ativos (nome, descrição, localização).
  Missão ligada → banner com `missao_titulo` e botão "Ver missão"; estandes destacados
  e ativos ganham selo "Missão". Missão desligada → sem banner e sem selos; lista e
  check-in continuam. FAB "Ler QR code".
- **Missão**: lista os estandes destacados ativos. Ao abrir, registra `missao_aberta`
  (param `qtd_estandes`).
- **Scanner**: `mobile_scanner`; no primeiro código lido, pausa e chama `CheckinService`:
  1. `parseQr` falhou → "QR inválido"
  2. estande não existe → "Estande não encontrado"
  3. `ativo == false` → "Estande inativo"
  4. check-in já existe → "Visita já registrada"
  5. transação grava o check-in → "Check-in confirmado!" + evento `checkin_concluido`
     (param `estande_id`)
  Diálogo de resultado permite ler outro QR ou voltar.
- **Remote Config**: `missao_ativa` (bool, padrão `false`), `missao_estandes`
  (string, IDs separados por vírgula, padrão `""`), `missao_titulo`
  (string, padrão `"Missão surpresa!"`). `fetchAndActivate` na inicialização e
  `onConfigUpdated.listen` → `activate()` → notifica a UI. Destaque efetivo =
  IDs da missão ∩ estandes ativos (`estandesDaMissao`).
- **Assinatura**: `android/key.properties` + keystore em `android/app/upload-keystore.jks`
  (ambos ignorados pelo `.gitignore`); `build.gradle(.kts)` usa a config de release quando
  `key.properties` existe. `applicationId`: `br.edu.circuito.descobertas`.
- Permissão de câmera no `AndroidManifest.xml`.

## Tratamento de erros

- Web: erros do Firebase exibidos em mensagem amigável (login inválido, sem permissão, falha de rede).
- App: falhas de rede/permissão no check-in → `CheckinResultado.erro` com mensagem;
  Remote Config indisponível → usa padrões (missão desligada).

## Testes e verificação

- Dart (`flutter test`): `parseQr`, `estandesDaMissao`, `CheckinService` com repositório falso
  cobrindo os 5 resultados, parse de `missao_estandes`.
- Web (`vitest`): `parseQr`/`qrPayload`, `contarCheckinsPorEstande`.
- Builds: `flutter analyze`, `flutter build apk --release`, `npm run build`, `npm test`.
- Regras: sem emulador (Java 8 local); o guia descreve teste no simulador de regras do console.

## Fora de escopo

Cloud Functions, custom claims, publicação na Play Store, iOS, ranking/gamificação extra.
