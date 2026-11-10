# Guia da parte Firebase — Circuito de Descobertas

O código do painel web (`web/`) e do app Flutter (`mobile/`) já está pronto.
Este guia cobre o que precisa ser feito **no console do Firebase** e nas máquinas
da equipe para tudo funcionar. Siga na ordem. Tudo funciona no **plano Spark
(gratuito, sem cartão)**.

> Use apenas dados fictícios em toda a demonstração.

---

## 1. Criar o projeto

1. Acesse <https://console.firebase.google.com> → **Adicionar projeto**.
2. Nome sugerido: `circuito-descobertas`.
3. **Ative o Google Analytics** quando perguntado (é necessário para o GA4)
   e escolha/crie uma conta do Analytics.
4. Confirme que o plano é **Spark** (canto inferior esquerdo do console).

## 2. Authentication

1. **Criação → Authentication → Vamos começar**.
2. Aba **Método de login**, ative:
   - **E-mail/senha** (organização)
   - **Anônimo** (visitantes)
3. Aba **Usuários → Adicionar usuário**: crie o administrador, por exemplo
   `admin@circuito.dev` com uma senha de teste.
4. **Copie o UID** desse usuário (coluna "UID do usuário"), que será usado no passo 3.

## 3. Cloud Firestore e regras

1. **Criação → Firestore Database → Criar banco de dados**. Escolha a localização
   `southamerica-east1` (São Paulo) e inicie em **modo de produção**.
2. Aba **Regras**: apague o conteúdo e cole **todo** o arquivo
   [`firestore.rules`](../firestore.rules) da raiz do projeto → **Publicar**.
3. Aba **Dados → Iniciar coleção**:
   - ID da coleção: `admins`
   - ID do documento: **o UID copiado no passo 2.4**
   - Campo: `email` (string) = e-mail do admin
4. As coleções `estandes` e `checkins` são criadas automaticamente pelo painel e pelo app.

> Alternativa via CLI (opcional): `npm i -g firebase-tools`, `firebase login`,
> `firebase use --add` e `firebase deploy --only firestore:rules` na raiz do projeto.

### Testar as regras (opcional, recomendado)

Na aba **Regras → Playground de regras**:

| Simulação | Autenticado | Resultado esperado |
|---|---|---|
| `get` em `/estandes/qualquer` | sim (qualquer UID) | Permitido |
| `create` em `/estandes/x` com UID que **não** está em `admins` | sim | **Negado** |
| `create` em `/estandes/x` com o UID do admin e campos `nome`, `descricao`, `localizacao`, `ativo` | sim | Permitido |
| `create` em `/checkins/OUTRO_estande1` com `visitanteId` diferente do UID | sim | **Negado** |
| `update` em `/checkins/...` | sim | **Negado** |

## 4. Painel web

1. **Configurações do projeto (engrenagem) → Seus apps → `</>` (Web)**.
   Apelido: `painel`. Não precisa marcar Hosting agora.
2. Copie os valores do objeto `firebaseConfig`.
3. Em `web/`, copie `.env.example` para `.env` e preencha:
   ```env
   VITE_FIREBASE_API_KEY=...
   VITE_FIREBASE_AUTH_DOMAIN=...
   VITE_FIREBASE_PROJECT_ID=...
   VITE_FIREBASE_STORAGE_BUCKET=...
   VITE_FIREBASE_MESSAGING_SENDER_ID=...
   VITE_FIREBASE_APP_ID=...
   ```
4. Rode:
   ```bash
   cd web
   npm install
   npm run dev
   ```
5. Abra <http://localhost:5173>, entre com o admin e clique em
   **Criar estandes de exemplo** (gera 3 estandes fictícios).

> Hospedagem gratuita (opcional): `npm run build` e, na raiz, `firebase deploy --only hosting`.
> Adicione o domínio `*.web.app` em **Authentication → Configurações → Domínios autorizados** se necessário.

## 5. App Flutter: conectar ao Firebase

Pré-requisitos: Flutter instalado, Firebase CLI (`npm i -g firebase-tools`) e `firebase login`.

```bash
dart pub global activate flutterfire_cli
cd mobile
flutterfire configure --project=<ID-DO-PROJETO> --platforms=android --android-package-name=br.edu.circuito.descobertas
```

Isso **substitui** `mobile/lib/firebase_options.dart`, cria
`mobile/android/app/google-services.json` e ajusta o Gradle. O app passa a abrir
normalmente (antes disso ele mostra "Firebase ainda não configurado").

## 6. Assinatura do APK

O APK release é assinado com a keystore de upload que **já foi gerada**:

- `mobile/android/app/upload-keystore.jks`
- `mobile/android/key.properties` (senha e alias)

Esses dois arquivos **não vão para o git** (estão no `.gitignore`). Quem gerar o
APK precisa deles. Compartilhe por um canal privado e não perca: atualizações do
app instalado precisam da mesma assinatura.

Impressões digitais (podem ser cadastradas em **Configurações do projeto →
Seus apps → Android → Adicionar impressão digital**; não são obrigatórias para
Firestore, Auth, Remote Config ou Analytics):

```bash
keytool -list -v -keystore mobile/android/app/upload-keystore.jks -alias upload
```

Gerar o APK:

```bash
cd mobile
flutter build apk --release
# saída: mobile/build/app/outputs/flutter-apk/app-release.apk
```

## 7. App Distribution (1,0 ponto)

1. **Lançamento e monitoramento → App Distribution → Começar** (app Android).
2. Aba **Testadores e grupos**: crie o grupo `testadores` e adicione o e-mail do testador.
3. Aba **Versões**: arraste o `app-release.apk` → selecione o grupo → **Distribuir**.
4. No celular Android do testador:
   - abra o e-mail de convite → **Aceitar convite**;
   - instale o app **Firebase App Tester**, se solicitado, ou baixe direto pelo link;
   - **baixe e instale** a versão (permita "instalar apps desconhecidos");
   - abra o **Circuito de Descobertas**.

## 8. Remote Config: missão surpresa (1,0 ponto)

1. **Executar → Remote Config → Criar configuração**.
2. Crie os parâmetros (veja também [`remoteconfig.template.json`](../remoteconfig.template.json)):

   | Parâmetro | Tipo | Valor padrão |
   |---|---|---|
   | `missao_ativa` | Booleano | `false` |
   | `missao_estandes` | String | IDs dos estandes destacados separados por vírgula |
   | `missao_titulo` | String | `Missão surpresa!` |

   O ID de cada estande aparece no painel web, abaixo do nome ("ID: …").
3. **Publicar alterações**.
4. Para **ligar** a missão: mude `missao_ativa` para `true` → **Publicar**.
   O app aberto mostra o banner e os destaques em alguns segundos, **sem reinstalar**,
   graças ao Remote Config em tempo real.
5. Para **desligar**: volte `missao_ativa` para `false` → **Publicar**.
   O banner e os destaques somem, e a lista e o check-in continuam funcionando.

> Se a mudança demorar, deixe o app em primeiro plano e com internet; a
> atualização em tempo real chega pelo listener `onConfigUpdated`.

## 9. Google Analytics / GA4 (1,0 ponto)

Eventos registrados pelo app:

| Evento | Quando | Parâmetro |
|---|---|---|
| `missao_aberta` | ao abrir a tela da missão | `qtd_estandes` |
| `checkin_concluido` | após check-in gravado com sucesso | `estande_id` |

Para conferir:

1. **Analytics → Dashboard → Ver mais no Google Analytics** (abre o GA4).
2. **Relatórios → Tempo real**.
3. No cartão **"Contagem de eventos por nome do evento"**, procure
   `missao_aberta` e `checkin_concluido`.
4. Clique em `checkin_concluido` → parâmetro `estande_id` → confira o ID do estande.

> O Tempo real pode atrasar alguns minutos. Se precisar, pause a gravação e retome
> quando os eventos aparecerem.
>
> **Para o parâmetro `estande_id` aparecer bem nos relatórios**, registre-o como
> dimensão personalizada: GA4 → **Administrador → Definições personalizadas →
> Criar dimensão personalizada** (escopo Evento, parâmetro `estande_id`).
>
> **DebugView** (opcional, para ver os eventos na hora durante testes):
> `adb shell setprop debug.firebase.analytics.app br.edu.circuito.descobertas`.
> Para desligar: `adb shell setprop debug.firebase.analytics.app .none.`

## 10. Roteiro do vídeo

Cada integrante deve **aparecer ou narrar uma parte identificável**. Sugestão de divisão:

| Parte | Quem | O que mostrar |
|---|---|---|
| 1. App Distribution | Integrante 1 | Apresentação da equipe; console do App Distribution com a versão; e-mail/App Tester no celular; instalação e abertura do app |
| 2. Painel → app | Integrante 2 | Login no painel; cadastrar um estande novo; ver o estande aparecer no app; abrir "Ver QR" e mostrar o QR (pode imprimir ou abrir em outra tela) |
| 3. Missão + check-in | Integrante 3 | Publicar `missao_ativa = true` no Remote Config; banner aparece no app; abrir a missão; ler o QR → "Check-in confirmado!"; total atualizado no painel; publicar `missao_ativa = false`; banner some |
| 4. Analytics | Integrante 1 | GA4 → Relatórios → Tempo real → `missao_aberta` e `checkin_concluido` → abrir `checkin_concluido` e mostrar `estande_id` |

Extras que valorizam a demonstração da validação:
- ler o mesmo QR de novo → "Você já registrou visita neste estande";
- desativar um estande no painel e ler o QR dele → "Este estande está inativo";
- ler um QR qualquer (ex.: de um site) → "QR code inválido".

Lembrete: **cada integrante envia o mesmo vídeo individualmente no Classroom**.
