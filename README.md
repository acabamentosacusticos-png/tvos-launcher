# TV Launcher (estilo tvOS) para Google TV

Um ecrã inicial leve, com aspeto inspirado no tvOS/iOS, para a tua Google TV, mais scripts para o instalar e otimizar por Wi-Fi.

**O que é e o que não é:** isto **não** substitui o sistema operativo da TV (isso não é possível, o firmware só aceita software assinado pelo fabricante). É uma app de ecrã inicial que passa a ser a interface que vês, mais um conjunto de ajustes que deixam a TV mais fluida, tudo reversível.

## O que o launcher faz

- Grelha de apps em 2 linhas, ícones arredondados, zoom e contorno branco no item em foco.
- Relógio e data, fundo em gradiente (sem imagens nem blur, para gastar o mínimo de memória).
- Atualiza sozinho quando instalas ou removes apps.
- **Manter OK premido** numa app abre a página dela (para desinstalar ou limpar cache).
- O botão Voltar não fecha o launcher; Home volta ao início.

## O que os scripts fazem

| Script | Função |
|---|---|
| `instalar` | Liga à TV por Wi-Fi, instala o APK e define-o como ecrã inicial. |
| `otimizar` | Animações mais rápidas (0.5x por defeito), limpa cache, desativa as apps da `lista-debloat.txt`, compila as apps para arrancarem mais depressa. |
| `restaurar` | Repõe tudo como estava e, se quiseres, remove o launcher. |

Há versões `.sh` (Mac/Linux) e `.bat` (Windows).

## Passo 1: obter o APK

O APK tem de ser compilado uma vez. Escolhe uma opção:

**A) Android Studio (mais simples em Windows/Mac)**
1. Instala o [Android Studio](https://developer.android.com/studio).
2. `File → Open` e escolhe esta pasta (`tvos-launcher`). Espera que sincronize.
3. `Build → Build Bundle(s) / APK(s) → Build APK(s)`.
4. O ficheiro fica em `app/build/outputs/apk/release/app-release.apk` (se só aparecer o de debug, usa `Build Variants` e escolhe `release`).

**B) GitHub (sem instalar nada)**
1. Cria uma conta e um repositório novo em github.com e carrega todos os ficheiros desta pasta (incluindo `.github`).
2. Separador `Actions` → `Compilar APK` → `Run workflow`.
3. Quando terminar, descarrega o artefacto `tv-launcher-apk` (zip com o `app-release.apk`).

Copia o `app-release.apk` para a pasta `scripts`.

## Passo 2: preparar a TV

1. `Definições → Sistema → Acerca de` e carrega várias vezes em **Compilação do SO** até aparecer "Já és programador".
2. `Definições → Sistema → Opções de programador` e ativa a **Depuração USB** e a **Depuração por rede / sem fios**.
3. Descobre o IP da TV em `Definições → Rede e Internet` (clica na tua rede Wi-Fi).
4. Se a tua TV usar depuração sem fios do Android 11+, aparece "Emparelhar com código". Corre `adb pair IP:PORTA_EMPARELHAMENTO`, escreve o código e usa depois `IP:PORTA` mostrado no ecrã principal da depuração sem fios em vez do IP simples.

No PC, instala o [platform-tools](https://developer.android.com/tools/releases/platform-tools) (contém o `adb`) e põe-no no PATH.

## Passo 3: instalar

Na pasta `scripts`, com o PC e a TV na mesma rede:

```
# Windows
instalar.bat 192.168.1.50 app-release.apk

# Mac / Linux
./instalar.sh 192.168.1.50 app-release.apk
```

Na primeira ligação a TV pede para autorizares o PC. Aceita (marca "permitir sempre").

**Se o botão Home continuar a abrir o ecrã original da Google TV**, o sistema está a proteger o launcher dele. Repete com `--substituir-launcher`, que desativa o launcher original (reversível com `restaurar`):

```
instalar.bat 192.168.1.50 app-release.apk --substituir-launcher
```

## Passo 4: otimizar

```
otimizar.bat 192.168.1.50          # animações a 0.5x
otimizar.bat 192.168.1.50 0        # animações desligadas (a TV parece mais rápida)
otimizar.bat 192.168.1.50 --listar # ver as apps instaladas
```

Para desativar apps que não usas, escreve o nome do pacote em `lista-debloat.txt` (vem vazio, por isso nada é desativado sem tu escolheres) e corre o script outra vez. Se não tiveres a certeza do que podes desativar, envia-me a lista e digo-te o que é seguro.

## Voltar atrás

```
restaurar.bat 192.168.1.50                       # repõe animações e reativa o launcher original
restaurar.bat 192.168.1.50 --remover-launcher    # e remove o TV Launcher
```

Se algum dia a TV ficar sem ecrã inicial, liga-te por ADB e corre `adb shell pm enable --user 0 com.google.android.apps.tv.launcherx`, ou faz um reset de fábrica.

## Expectativas realistas

- O ganho vem de menos animações, cache limpa, apps pré-compiladas e um ecrã inicial muito mais leve do que o original. Numa TV com pouca RAM/CPU notas diferença, mas o hardware continua a ser o limite.
- O launcher não mostra recomendações nem "continuar a ver" do Google; é só uma grelha de apps.
- Para uma experiência mesmo fluida e parecida com iOS, uma Apple TV 4K ligada ao HDMI continua a ser a melhor opção.
