#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Casa da Lareira - registrar-laboratorio.sh
# Cria a documentação do laboratório RTSP/HLS,
# protege arquivos locais/sensíveis, versiona e publica no GitHub.
# ============================================================

PROJECT_DIR="${HOME}/casa-da-lareira"
DOCS_DIR="${PROJECT_DIR}/docs"
DOC_FILE="${DOCS_DIR}/LAB-TESTES-TERMUX.md"
DOC_INDEX="${DOCS_DIR}/README.md"

log()  { printf '\n🔥 %s\n' "$*"; }
ok()   { printf '✅ %s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*"; }
die()  { printf '❌ %s\n' "$*" >&2; exit 1; }

trap 'printf "\n❌ Erro na linha %s.\n" "$LINENO" >&2' ERR

# ------------------------------------------------------------
# 1. Validar projeto
# ------------------------------------------------------------

[ -d "$PROJECT_DIR" ] || die "Projeto não encontrado em: $PROJECT_DIR"
cd "$PROJECT_DIR"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "Essa pasta não é um repositório Git."

log "CASA DA LAREIRA - Registrando laboratório"

# ------------------------------------------------------------
# 2. Criar diretórios
# ------------------------------------------------------------

mkdir -p "$DOCS_DIR"

# ------------------------------------------------------------
# 3. Criar documentação principal
# ------------------------------------------------------------

cat > "$DOC_FILE" <<'EOF'
# Casa da Lareira — Laboratório RTSP/HLS no Termux

## Objetivo

Validar a arquitetura inicial do Casa da Lareira usando Android + Termux, sem depender de um DVR físico.

Pipeline validado:

```text
FFmpeg
  ↓
RTSP
  ↓
MediaMTX
  ↓
HLS
  ↓
hls.js
  ↓
Chrome
```

## Ambiente

- Android
- Termux
- ARM64 / aarch64
- FFmpeg 8.1.2
- MediaMTX v1.20.1

## 1. Câmera simulada

Foi criado um vídeo H.264 de teste:

```bash
ffmpeg \
  -f lavfi \
  -i testsrc=size=1280x720:rate=25 \
  -t 30 \
  -c:v libx264 \
  -pix_fmt yuv420p \
  camera1.mp4
```

Características:

```text
Codec: H.264
Resolução: 1280x720
FPS: 25
Áudio: não
```

## 2. Publicação RTSP

O vídeo foi publicado continuamente no MediaMTX:

```bash
ffmpeg \
  -re \
  -stream_loop -1 \
  -i camera1.mp4 \
  -c:v libx264 \
  -preset veryfast \
  -tune zerolatency \
  -pix_fmt yuv420p \
  -an \
  -f rtsp \
  -rtsp_transport tcp \
  rtsp://127.0.0.1:8554/camera1
```

RTSP:

```text
rtsp://127.0.0.1:8554/camera1
```

## 3. Validação do RTSP

```bash
ffprobe -v error \
  -show_entries stream=index,codec_name,codec_type,width,height,r_frame_rate \
  -of default=noprint_wrappers=1 \
  rtsp://127.0.0.1:8554/camera1
```

Resultado observado:

```text
index=0
codec_name=h264
codec_type=video
width=1280
height=720
```

## 4. MediaMTX

Inicialização:

```bash
./bin/mediamtx ./mediamtx/mediamtx.yml
```

Serviços:

```text
RTSP    :8554
RTMP    :1935
HLS     :8888
WebRTC  :8889
SRT     :8890
```

## 5. Validação HLS

URL HLS:

```text
http://127.0.0.1:8888/camera1/index.m3u8
```

Teste:

```bash
ffprobe -v error \
  -show_entries stream=index,codec_name,codec_type,width,height \
  http://127.0.0.1:8888/camera1/index.m3u8
```

Resultado:

```text
codec_name=h264
codec_type=video
width=1280
height=720
```

## 6. WebRTC no Android

Ao acessar:

```text
http://127.0.0.1:8889/camera1
```

foi observado:

```text
error getting local interfaces:
route ip+net:
netlinkrib: permission denied
```

No laboratório Android, o HLS foi adotado como saída principal.

## 7. Player HLS

Foi usado `hls.js` em um viewer HTML.

Servidor local:

```bash
python3 -m http.server 3000
```

Acesso:

```text
http://127.0.0.1:3000/viewer.html
```

Resultado: vídeo exibido corretamente no Chrome Android.

## 8. Pipeline comprovado

```text
camera1.mp4
  ↓
FFmpeg
  ↓ RTSP
MediaMTX
  ↓ HLS
hls.js
  ↓
Chrome
```

Status:

```text
FFmpeg      OK
H.264       OK
RTSP        OK
MediaMTX    OK
HLS         OK
ffprobe     OK
hls.js      OK
Chrome      OK
WebRTC      limitado no Android/Termux
```

## Arquitetura planejada

```text
Câmeras
  ↓
DVR
  ↓ RTSP
Casa da Lareira
  ↓
MediaMTX
  ├────────────→ Visualização
  ↓
Gravação
  ↓
NAS
  ↓
Detector de eventos
  ↓
IA
  ↓
Snapshot / clipe
  ↓
CDN
  ↓
WhatsApp / Telegram / Painel
```

## Próximos passos

1. Simular DVR com 8 canais.
2. Criar painel multi-câmera.
3. Criar gravação individual por canal.
4. Simular NAS.
5. Implementar retenção automática.
6. Detectar movimento.
7. Integrar IA.
8. Gerar snapshots e clipes.
9. Integrar CDN.
10. Integrar WhatsApp/Telegram.
11. Testar DVRs reais.
12. Criar instalador automático.
EOF

ok "Documento criado: $DOC_FILE"

# ------------------------------------------------------------
# 4. Criar índice da documentação
# ------------------------------------------------------------

cat > "$DOC_INDEX" <<'EOF'
# Documentação — Casa da Lareira

## Laboratório

- [Laboratório RTSP/HLS no Termux](./LAB-TESTES-TERMUX.md)

## Próximas etapas

- DVR simulado de 8 canais
- Painel multi-câmera
- Sistema de gravação
- NAS
- Detecção de movimento
- IA
- CDN
- WhatsApp / Telegram
- Integração com DVRs reais
EOF

ok "Índice criado: $DOC_INDEX"

# ------------------------------------------------------------
# 5. Garantir viewer.html
# ------------------------------------------------------------

if [ ! -f viewer.html ]; then
cat > viewer.html <<'EOF'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Casa da Lareira - Camera 1</title>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
  <style>
    html,body{margin:0;background:#000;height:100%}
    body{display:flex;align-items:center;justify-content:center}
    video{width:100%;max-width:1200px;background:#000}
  </style>
</head>
<body>
<video id="video" controls autoplay muted playsinline></video>
<script>
const video = document.getElementById('video');
const src = 'http://127.0.0.1:8888/camera1/index.m3u8';

if (Hls.isSupported()) {
  const hls = new Hls({ lowLatencyMode: true });
  hls.loadSource(src);
  hls.attachMedia(video);
  hls.on(Hls.Events.MANIFEST_PARSED, () => video.play().catch(() => {}));
} else if (video.canPlayType('application/vnd.apple.mpegurl')) {
  video.src = src;
}
</script>
</body>
</html>
EOF
  ok "viewer.html criado"
else
  ok "viewer.html já existe; mantendo arquivo atual"
fi

# ------------------------------------------------------------
# 6. Atualizar .gitignore com segurança
# ------------------------------------------------------------

touch .gitignore

IGNORE_ITEMS=(
  "bin/"
  ".env"
  "auto.key"
  "auto.crt"
  "mediamtx/mediamtx.runtime.yml"
  ".mediamtx.pid"
  "mediamtx.log"
  "camera1.mp4"
  "*.pid"
  "*.log"
)

for item in "${IGNORE_ITEMS[@]}"; do
  grep -qxF "$item" .gitignore || printf '%s\n' "$item" >> .gitignore
done

ok ".gitignore atualizado"

# ------------------------------------------------------------
# 7. Proteger contra credenciais reais
# ------------------------------------------------------------

if git grep -nE 'rtsp://[^[:space:]]+:[^[:space:]@]+@' -- \
  ':!docs/LAB-TESTES-TERMUX.md' \
  ':!viewer.html' \
  2>/dev/null | grep -v 'usuario:senha' >$HOME/.cdl-secrets.txt 2>/dev/null; then
  warn "Foram encontrados possíveis RTSPs com credenciais em arquivos rastreados:"
  cat $HOME/.cdl-secrets.txt
  rm -f $HOME/.cdl-secrets.txt
  die "Remova as credenciais reais antes de publicar."
fi
rm -f $HOME/.cdl-secrets.txt

# ------------------------------------------------------------
# 8. Permissões
# ------------------------------------------------------------

[ -f casa-da-lareira ] && chmod +x casa-da-lareira || true
[ -d scripts ] && chmod +x scripts/*.sh 2>/dev/null || true

# ------------------------------------------------------------
# 9. Adicionar arquivos seguros ao Git
# ------------------------------------------------------------

FILES=(
  ".gitignore"
  ".env.example"
  "casa-da-lareira"
  "viewer.html"
  "docs/README.md"
  "docs/LAB-TESTES-TERMUX.md"
  "mediamtx/mediamtx.yml"
  "mediamtx/mediamtx.default.yml"
  "mediamtx/mediamtx.template.yml"
  "scripts/registrar-camera.sh"
)

for file in "${FILES[@]}"; do
  if [ -e "$file" ]; then
    git add -- "$file"
  fi
done

log "Arquivos preparados"
git status --short

# ------------------------------------------------------------
# 10. Commit
# ------------------------------------------------------------

if git diff --cached --quiet; then
  warn "Não há alterações novas para commit."
else
  git commit -m "feat: documenta laboratorio RTSP HLS no Termux"
  ok "Commit criado"
fi

# ------------------------------------------------------------
# 11. Push
# ------------------------------------------------------------

BRANCH="$(git branch --show-current)"
[ -n "$BRANCH" ] || BRANCH="main"

log "Publicando no GitHub"
git push origin "$BRANCH"

ok "Push concluído"

printf '\n============================================\n'
printf '🔥 CASA DA LAREIRA\n'
printf '============================================\n'
printf '✅ Documentação criada\n'
printf '✅ Viewer preservado/criado\n'
printf '✅ Arquivos locais sensíveis ignorados\n'
printf '✅ Commit realizado quando necessário\n'
printf '✅ Repositório publicado\n\n'
printf 'Último commit:\n'
git log -1 --oneline
printf '\n'

