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
