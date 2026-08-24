#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_CONFIG="$ROOT_DIR/mediamtx/mediamtx.runtime.yml"

CAMERA_NAME="${1:-}"
RTSP_URL="${2:-}"

if [[ -z "$CAMERA_NAME" || -z "$RTSP_URL" ]]; then
    echo
    echo "🔥 Casa da Lareira"
    echo
    echo "Uso:"
    echo "  $0 <nome-camera> '<url-rtsp>'"
    echo
    echo "Exemplo:"
    echo "  $0 portao 'rtsp://admin:senha@192.168.0.100:554/stream'"
    echo
    exit 1
fi

# Nome seguro para usar como path
CAMERA_NAME="$(printf '%s' "$CAMERA_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | tr ' ' '-' \
    | sed 's/[^a-z0-9_-]//g')"

if [[ -z "$CAMERA_NAME" ]]; then
    echo "❌ Nome da câmera inválido."
    exit 1
fi

if [[ "$RTSP_URL" != rtsp://* && "$RTSP_URL" != rtsps://* ]]; then
    echo "❌ A URL precisa começar com rtsp:// ou rtsps://"
    exit 1
fi

cat > "$RUNTIME_CONFIG" <<EOF2
logLevel: info

rtsp: true
rtspAddress: :8554

hls: true
hlsAddress: :8888

webrtc: true
webrtcAddress: :8889

paths:
  ${CAMERA_NAME}:
    source: "${RTSP_URL}"
    sourceOnDemand: true
EOF2

echo
echo "🔥 CASA DA LAREIRA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "✅ Câmera registrada"
echo
echo "📷 Nome: ${CAMERA_NAME}"
echo
echo "📄 Configuração:"
echo "   ${RUNTIME_CONFIG}"
echo
echo "Links após iniciar o MediaMTX:"
echo
echo "RTSP:"
echo "  rtsp://IP_DO_SERVIDOR:8554/${CAMERA_NAME}"
echo
echo "HLS:"
echo "  http://IP_DO_SERVIDOR:8888/${CAMERA_NAME}/index.m3u8"
echo
echo "WebRTC:"
echo "  http://IP_DO_SERVIDOR:8889/${CAMERA_NAME}"
echo
echo "Para iniciar:"
echo "  ./bin/mediamtx ./mediamtx/mediamtx.runtime.yml"
echo
