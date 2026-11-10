# Circuito de Descobertas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Painel web (React) e app Flutter sobre Firebase para estandes, check-ins por QR e missão surpresa via Remote Config.

**Architecture:** Monorepo com `/web` (React + Vite + TS) e `/mobile` (Flutter Android), ambos falando direto com Firestore/Auth. Lógica pura (parse de QR, contagem, missão, orquestração do check-in) separada da camada Firebase para ser testável sem credenciais.

**Tech Stack:** React 18 + Vite + TypeScript + vitest, firebase JS SDK, react-router-dom, qrcode.react; Flutter 3.44 / Dart 3.12, firebase_core, firebase_auth, cloud_firestore, firebase_remote_config, firebase_analytics, mobile_scanner.

**Spec:** `docs/superpowers/specs/2026-11-10-circuito-descobertas-design.md`

## Global Constraints

- Nenhuma operação git (o usuário faz). Não há passos de commit neste plano.
- Plano Firebase Spark: sem Cloud Functions, sem custom claims.
- Credenciais são placeholders; `npm run build`, `npm test`, `flutter analyze`, `flutter test`, `flutter build apk --release` devem passar sem projeto real.
- Formato do QR: `circuito://estande/<estandeId>`.
- Coleções: `estandes`, `checkins` (ID `<visitanteId>_<estandeId>`), `admins`.
- Remote Config: `missao_ativa` (bool, padrão `false`), `missao_estandes` (string CSV, padrão `""`), `missao_titulo` (string, padrão `"Missão surpresa!"`).
- Eventos Analytics: `missao_aberta` (param `qtd_estandes`), `checkin_concluido` (param `estande_id`).
- `applicationId`: `br.edu.circuito.descobertas`. Textos de UI em português.

## Review Focus

- QR com espaços/quebra de linha nas pontas → deve ser aceito (trim antes do parse); ID vazio ou com `/` → inválido. Teste em Task 2 e Task 6.
- `missao_estandes` com espaços e entradas vazias (`" a, b,,"`) → `["a","b"]`. Teste em Task 6.
- Missão destacando estande inativo ou inexistente → não aparece na missão nem com selo. Teste em Task 6.
- Scanner detectando o mesmo QR várias vezes seguidas → apenas um check-in processado (flag `_processando`). Verificado em Task 8.
- Falha de rede/permissão ao gravar → resultado `erro` com mensagem, sem travar. Teste em Task 6.

---

### Task 1: Arquivos Firebase da raiz

**Files:**
- Create: `firestore.rules`, `firestore.indexes.json`, `firebase.json`, `remoteconfig.template.json`

- [ ] **Step 1:** `firestore.rules` exatamente conforme a seção "Regras de acesso" da spec (funções `signedIn()`, `isAdmin()`, `estandeValido()` com tipos: `nome`/`descricao`/`localizacao` string, `ativo` bool).
- [ ] **Step 2:** `firebase.json` com `firestore.rules`, `firestore.indexes`, e `hosting.public = "web/dist"` com rewrite `** → /index.html`. `firestore.indexes.json` = `{"indexes":[],"fieldOverrides":[]}`.
- [ ] **Step 3:** `remoteconfig.template.json` no formato do template REST do Remote Config com os 3 parâmetros e seus padrões.
- [ ] **Step 4:** Validar JSON: `node -e "for (const f of ['firebase.json','firestore.indexes.json','remoteconfig.template.json']) JSON.parse(require('fs').readFileSync(f,'utf8'))"` → sem saída.

### Task 2: Web — scaffold e domínio puro

**Files:**
- Create: `web/` (Vite react-ts), `web/src/domain/qr.ts`, `web/src/domain/contagem.ts`, `web/src/domain/*.test.ts`, `web/.env.example`

**Interfaces:**
- Produces: `qrPayload(estandeId: string): string`; `parseQr(raw: string): string | null`; `contarCheckinsPorEstande(checkins: {estandeId: string}[]): Record<string, number>`; tipo `Estande { id: string; nome: string; descricao: string; localizacao: string; ativo: boolean }` em `web/src/domain/estande.ts`.

- [ ] **Step 1:** `npm create vite@latest web -- --template react-ts`, instalar `firebase react-router-dom qrcode.react` e dev `vitest`; script `"test": "vitest run"`.
- [ ] **Step 2: Testes**
```ts
expect(qrPayload('abc')).toBe('circuito://estande/abc');
expect(parseQr('circuito://estande/abc')).toBe('abc');
expect(parseQr('  circuito://estande/abc\n')).toBe('abc');
expect(parseQr('circuito://estande/')).toBeNull();
expect(parseQr('circuito://estande/a/b')).toBeNull();
expect(parseQr('https://x.com')).toBeNull();
expect(contarCheckinsPorEstande([{estandeId:'a'},{estandeId:'a'},{estandeId:'b'}])).toEqual({a:2,b:1});
expect(contarCheckinsPorEstande([])).toEqual({});
```
- [ ] **Step 3:** `npm test` → FAIL (módulos inexistentes). Implementar. `npm test` → PASS.

### Task 3: Web — Firebase, autenticação e gate de admin

**Files:**
- Create: `web/src/firebase.ts`, `web/src/auth/AuthContext.tsx`, `web/src/pages/LoginPage.tsx`, `web/src/App.tsx` (rotas), `web/src/index.css`

**Interfaces:**
- Produces: `auth`, `db` exportados de `firebase.ts` (config de `import.meta.env.VITE_FIREBASE_*`); `useAuth(): { user: User | null; isAdmin: boolean; loading: boolean; logout(): Promise<void> }`; rotas `/login`, `/` (protegida), `/qr/:id` (protegida).

- [ ] **Step 1:** `firebase.ts` inicializa app com env; `.env.example` lista `VITE_FIREBASE_API_KEY, AUTH_DOMAIN, PROJECT_ID, STORAGE_BUCKET, MESSAGING_SENDER_ID, APP_ID`.
- [ ] **Step 2:** `AuthContext` ouve `onAuthStateChanged`, lê `admins/{uid}` com `getDoc` → `isAdmin`.
- [ ] **Step 3:** `LoginPage` com `signInWithEmailAndPassword`; mensagens: credenciais inválidas, sem permissão ("Usuário sem permissão de administrador") + botão Sair.
- [ ] **Step 4:** `npm run build` → sucesso.

### Task 4: Web — estandes, totais e QR

**Files:**
- Create: `web/src/data/estandes.ts`, `web/src/pages/EstandesPage.tsx`, `web/src/components/EstandeForm.tsx`, `web/src/pages/QrPage.tsx`

**Interfaces:**
- Consumes: `db`, `Estande`, `contarCheckinsPorEstande`, `qrPayload`.
- Produces (`data/estandes.ts`): `ouvirEstandes(cb: (e: Estande[]) => void): Unsubscribe` (ordenado por nome); `ouvirTotais(cb: (t: Record<string, number>) => void): Unsubscribe`; `salvarEstande(dados: Omit<Estande,'id'>, id?: string): Promise<void>` (seta `atualizadoEm: serverTimestamp()`); `obterEstande(id): Promise<Estande | null>`; `criarEstandesExemplo(): Promise<void>` (3 fictícios, ex.: "Robô Guia" / "Corredor A", "App de Libras" / "Corredor C", "Horta Inteligente" / "Corredor E").

- [ ] **Step 1:** Implementar `data/estandes.ts`.
- [ ] **Step 2:** `EstandesPage`: tabela (nome, localização, ativo, check-ins), botões Novo, Editar, Ativar/Desativar, Ver QR (`<a href="/qr/:id" target="_blank">`), Sair; "Criar estandes de exemplo" quando vazio.
- [ ] **Step 3:** `EstandeForm`: campos obrigatórios (trim), checkbox ativo, Salvar/Cancelar.
- [ ] **Step 4:** `QrPage`: `QRCodeSVG` tamanho 320 com `qrPayload(id)`, nome, localização, ID, botão Imprimir; `@media print` esconde botão.
- [ ] **Step 5:** `npm run build` e `npm test` → sucesso.

### Task 5: Flutter — scaffold, dependências e Android

**Files:**
- Create: `mobile/` (`flutter create --org br.edu.circuito --project-name descobertas --platforms android mobile`), `mobile/lib/firebase_options.dart` (placeholder), `mobile/android/key.properties`, `mobile/android/app/upload-keystore.jks`
- Modify: `mobile/android/app/build.gradle.kts`, `mobile/android/app/src/main/AndroidManifest.xml`, `mobile/.gitignore`, `mobile/pubspec.yaml`

- [ ] **Step 1:** Criar projeto; `flutter pub add firebase_core firebase_auth cloud_firestore firebase_remote_config firebase_analytics mobile_scanner`.
- [ ] **Step 2:** `firebase_options.dart` placeholder com classe `DefaultFirebaseOptions.currentPlatform` (valores `SUBSTITUIR`) e comentário mandando rodar `flutterfire configure`.
- [ ] **Step 3:** Manifest: permissão `CAMERA`, label "Circuito de Descobertas". Gradle: `applicationId = "br.edu.circuito.descobertas"`, `minSdk` ≥ 23, signingConfig `release` lido de `key.properties` quando existir (fallback debug).
- [ ] **Step 4:** Gerar keystore com `keytool` (alias `upload`, validade 10000 dias); `key.properties`; adicionar `key.properties` e `*.jks` ao `.gitignore`.

### Task 6: Flutter — domínio puro e testes

**Files:**
- Create: `mobile/lib/domain/estande.dart`, `qr.dart`, `missao.dart`, `checkin.dart`; `mobile/test/domain/*_test.dart`

**Interfaces:**
- Produces:
  - `class Estande { final String id, nome, descricao, localizacao; final bool ativo; factory Estande.fromMap(String id, Map<String, dynamic> m); }` (campos ausentes → `''`/`false`)
  - `String? parseQr(String raw)` (mesmas regras do web)
  - `List<String> parseMissaoEstandes(String csv)`
  - `List<Estande> estandesDaMissao(List<Estande> ativos, List<String> ids)` (preserva ordem de `ativos`, só `ativo == true`)
  - `enum CheckinStatus { sucesso, qrInvalido, naoEncontrado, inativo, jaRegistrado, erro }`; `class CheckinResultado { final CheckinStatus status; final Estande? estande; final String? mensagemErro; String get mensagem; }`
  - `abstract class CheckinRepository { Future<Estande?> buscarEstande(String id); Future<bool> registrar(String visitanteId, String estandeId); }` (`registrar` retorna `false` se já existia)
  - `class CheckinService { CheckinService(CheckinRepository repo); Future<CheckinResultado> processar(String raw, String visitanteId); }`
- Mensagens: sucesso "Check-in confirmado!", qrInvalido "QR code inválido", naoEncontrado "Estande não encontrado", inativo "Este estande está inativo", jaRegistrado "Você já registrou visita neste estande", erro "Não foi possível registrar: <detalhe>".

- [ ] **Step 1: Testes**
```dart
expect(parseQr('circuito://estande/abc'), 'abc');
expect(parseQr(' circuito://estande/abc\n'), 'abc');
expect(parseQr('circuito://estande/'), isNull);
expect(parseQr('circuito://estande/a/b'), isNull);
expect(parseMissaoEstandes(' a, b,,'), ['a', 'b']);
expect(parseMissaoEstandes(''), isEmpty);
// ativos = [A(ativo), B(ativo)], ids = ['B','X','C-inativo'] -> [B]
// CheckinService com FakeRepo: qrInvalido (não chama repo), naoEncontrado, inativo,
// jaRegistrado (registrar->false), sucesso (registrar->true, estande preenchido),
// erro (registrar lança Exception('offline') -> status erro, mensagem contém 'offline')
```
- [ ] **Step 2:** `flutter test` → FAIL. Implementar. `flutter test` → PASS.

### Task 7: Flutter — camada Firebase

**Files:**
- Create: `mobile/lib/data/auth_service.dart`, `estande_repository.dart`, `firestore_checkin_repository.dart`, `missao_config.dart`, `analytics_service.dart`

**Interfaces:**
- Consumes: domínio da Task 6.
- Produces:
  - `AuthService.garantirLogin(): Future<String>` (uid; `signInAnonymously` se necessário)
  - `EstandeRepository.ouvirAtivos(): Stream<List<Estande>>` (`where('ativo', isEqualTo: true)`, ordenado por nome no cliente)
  - `FirestoreCheckinRepository implements CheckinRepository` (`registrar` via `runTransaction`: `get` do doc `<uid>_<estandeId>`; existe → `false`; senão `set` com `visitanteId`, `estandeId`, `criadoEm: FieldValue.serverTimestamp()` → `true`)
  - `class MissaoConfig extends ChangeNotifier { Future<void> iniciar(); bool get ativa; List<String> get estandeIds; String get titulo; }` (padrões locais, `minimumFetchInterval` 1 min, `fetchTimeout` 10 s, `fetchAndActivate` com try/catch, `onConfigUpdated.listen → activate → notifyListeners`)
  - `AnalyticsService.missaoAberta(int qtd)`, `AnalyticsService.checkinConcluido(String estandeId)`
- [ ] **Step 1:** Implementar. `flutter analyze` → sem issues.

### Task 8: Flutter — telas e main

**Files:**
- Create: `mobile/lib/ui/home_screen.dart`, `missao_screen.dart`, `scanner_screen.dart`, `estande_tile.dart`
- Modify: `mobile/lib/main.dart`, `mobile/test/widget_test.dart` (remover contador padrão)

- [ ] **Step 1:** `main`: `WidgetsFlutterBinding`, `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`, `garantirLogin`, `MissaoConfig.iniciar`; tela de erro amigável se a inicialização falhar.
- [ ] **Step 2:** `HomeScreen`: `StreamBuilder` dos ativos + `ListenableBuilder(MissaoConfig)`; banner com título e "Ver missão" só se `ativa`; selo "Missão" nos `estandesDaMissao`; FAB "Ler QR code"; estado vazio.
- [ ] **Step 3:** `MissaoScreen` recebe a lista da missão; `initState` chama `missaoAberta(qtd)`; reage se a missão for desligada (mostra "Missão encerrada").
- [ ] **Step 4:** `ScannerScreen`: `MobileScanner(onDetect)`; flag `_processando` ignora detecções enquanto processa/diálogo aberto; chama `CheckinService.processar`; em sucesso `checkinConcluido(id)`; diálogo com ícone por status + "Ler outro" / "Voltar".
- [ ] **Step 5:** `flutter analyze` e `flutter test` → sem issues/PASS. `flutter build apk --release` → `app-release.apk` gerado (assinado com a keystore).

### Task 9: Documentação

**Files:**
- Create: `docs/GUIA_FIREBASE.md`, `README.md`

- [ ] **Step 1:** Guia: criar projeto Spark com Analytics; ativar Auth (e-mail/senha + anônimo); criar Firestore + publicar `firestore.rules` (console ou `firebase deploy --only firestore:rules`); criar usuário admin + doc `admins/{uid}`; registrar app web e preencher `web/.env`; `dart pub global activate flutterfire_cli` + `flutterfire configure` em `mobile/`; obter SHA-1/SHA-256 da keystore; build e upload no App Distribution + convidar testador; publicar Remote Config; GA4 Tempo real (e DebugView `adb shell setprop debug.firebase.analytics.app br.edu.circuito.descobertas`); simulador de regras; roteiro do vídeo em 4 partes com divisão entre integrantes.
- [ ] **Step 2:** README com estrutura, como rodar web (`npm install`, `npm run dev`) e app (`flutter run`), e link para o guia.
