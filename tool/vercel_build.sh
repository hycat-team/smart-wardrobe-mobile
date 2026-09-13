#!/usr/bin/env bash
# Build Flutter web on Vercel (called from vercel.json -> buildCommand).
# - .env is gitignored, so create a minimal one for the asset bundle.
# - API URLs are injected via --dart-define from Vercel env vars
#   (see lib/core/constants/app_constants.dart priority order).
set -e

echo "APP_ENV=production" > .env

if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b 3.47.2 https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=API_BASE_URL_ANDROID="$API_BASE_URL_ANDROID" \
  --dart-define=CLOUDINARY_CLOUD_NAME="$CLOUDINARY_CLOUD_NAME"
