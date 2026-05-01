#!/bin/bash
# WSL용 이미지 브릿지 런처
# config.json을 WSL 경로 버전으로 교체해서 실행

cd /home/dtsli/dtslib-localpc/telegram-bots

# WSL config를 사용하도록 심볼릭 링크 생성
ln -sf /home/dtsli/dtslib-localpc/telegram-bots/image_config_wsl.json /home/dtsli/dtslib-localpc/telegram-bots/config.json

echo '[IMAGE BRIDGE] Starting with WSL paths...'
exec python3 image_downloader.py
