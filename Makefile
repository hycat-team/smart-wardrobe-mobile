# ============================================================
#  Closy / Smart Wardrobe Mobile -- lenh tien ich (make)
# ============================================================
#  Yeu cau: GNU Make 4.3+ (da co san tren may), Flutter 3.47.2
#
#  `make help` de xem tat ca target. 3 lenh chinh:
#      make run      -- chay web tren Edge, port 8081
#      make dev      -- chay tren thiet bi that / emulator
#      make build    -- APK + AAB release roi verify
#
#  Moi bien deu override duoc tu command line:
#      make run WEB_PORT=9000
#      make apk DEV_API=http://10.0.2.2:8080/api/v1
# ============================================================
#
#  GHI CHU QUAN TRONG -- SHELL tren Windows
#  ------------------------------------------
#  make mac dinh gan SHELL = sh.exe. tren Windows `sh.exe` KHONG
#  co tren PATH, va make KHONG bao loi -- no im lang fallback
#  sang cmd.exe. Han qua moi recipe bi cmd pha:
#      echo "x"      -> in ra "x" (co dau nhay)
#      if [ -f f ]   -> loi
#  Ben duoi tu tim POSIX sh that cua Git va gan SHELL. Neu may
#  khong co Git for Windows, Makefile van chay duoc (recipe
#  duoc viet de an toan cho ca sh lan cmd).
#
#  `.RECIPEPREFIX = >` thay cho TAB: TAB trong Makefile hay bi
#  make bao "missing separator" khi editor lam mat khoang trang
#  hay khi copy-paste. Ky tu `>` dong duoc, doc ky hon.
# ============================================================

# Phai BO DUAU NHAY: duong dan Git chua `Program Files` (co khoang
# trang). Khong co dau nhay thi make tach sai argv va CreateProcess
# that bai -- recipe bao loi "process_begin: CreateProcess(NULL, ...)".
GIT_SH := $(wildcard C:/Program*/Git/usr/bin/sh.exe)
ifneq ($(GIT_SH),)
SHELL := "$(GIT_SH)"
endif

.RECIPEPREFIX = >
.DEFAULT_GOAL := help

# ------------------------------------------------------------
#  Cau hinh moi truong
#
#  KHONG sua file nay khi doi moi truong -- truyen qua command
#  line: make apk PROD_API=https://moi/api/v1
#  Gia tri mac dinh lay tu docs/Release_Play_Checklist.md muc 2.
# ------------------------------------------------------------

# Dev: BE local. BE chay trong Docker, nginx gateway map `8080:80`
# (deployments/docker-compose.yml:182) -> entry point la
# `http://localhost:8080`. KHONG phai 5000 (cong do khong co gi
# listen -> app bao "khong ket noi duoc backend").
# Android emulator: doi localhost thanh 10.0.2.2 (alias host cua
# may host) -- truyen qua command line khi can.
DEV_API  ?= http://localhost:8080/api/v1
DEV_CLD  ?= dzvwkngxu
DEV_GID  ?= 368645245473-u71cfbe461nl51us9dmlta6vfgcdun8a.apps.googleusercontent.com

# Prod: ghi thang vao bytecode luc compile -- khong doc .env
# (gop gotcha cua AGENTS.md muc 3).
PROD_API ?= https://api.closy.hycat.online/api/v1
PROD_CLD ?= dzvwkngxu
PROD_GID ?= 368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com

WEB_PORT ?= 8081
BROWSER  ?= edge
DEVICE   ?=

# API_BASE_URL_ANDROID duoc Android runtime doc TRUOC API_BASE_URL
# (xem lib/core/constants/app_constants.dart:_resolveBaseUrl).
DART_DEFINES_DEV  := --dart-define=API_BASE_URL=$(DEV_API) \
                      --dart-define=CLOUDINARY_CLOUD_NAME=$(DEV_CLD) \
                      --dart-define=GOOGLE_CLIENT_ID=$(DEV_GID)

DART_DEFINES_PROD := --dart-define=API_BASE_URL=$(PROD_API) \
                      --dart-define=API_BASE_URL_ANDROID=$(PROD_API) \
                      --dart-define=CLOUDINARY_CLOUD_NAME=$(PROD_CLD) \
                      --dart-define=GOOGLE_CLIENT_ID=$(PROD_GID) \
                      --dart-define=ENABLE_PAID_FEATURES=false

# --no-tree-shake-icons: tranh loi Windows Application Control chan
# font-subset.exe (Release_Play_Checklist.md muc 2).
BUILD_FLAGS := --release --no-tree-shake-icons

FLUTTER ?= flutter
PS      := powershell -ExecutionPolicy Bypass -File
APK_DIR := build/app/outputs/flutter-apk

# ============================================================
#  Target chinh
# ============================================================

## run: chay app tren trinh duyet (mac dinh Edge, WEB_PORT)
run:
> $(FLUTTER) run -d $(BROWSER) --web-port=$(WEB_PORT) $(DART_DEFINES_DEV)

## dev: chay app tren thiet bi that / emulator (DEVICE=android)
dev:
> $(FLUTTER) run $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES_DEV)

## run-webserver: chay web server KHONG mo trinh duyet (CI, remote)
run-webserver:
> $(FLUTTER) run -d web-server --web-port=$(WEB_PORT) --web-hostname=localhost $(DART_DEFINES_DEV)

## build: build release APK + AAB roi verify -- san sang cai
build: apk aab verify

## apk: build release APK universal
apk:
> $(FLUTTER) build apk $(BUILD_FLAGS) $(DART_DEFINES_PROD)

## apksplit: build 3 APK tach theo ABI (arm64 cho may that)
apksplit:
> $(FLUTTER) build apk $(BUILD_FLAGS) --split-per-abi $(DART_DEFINES_PROD)

## aab: build App Bundle de upload len Google Play
aab:
> $(FLUTTER) build appbundle $(BUILD_FLAGS) $(DART_DEFINES_PROD)

## verify: kiem tra APK/AAB (package, chu ky, config, secrets)
verify:
> $(PS) tool/verify_release.ps1

## apkdebug: build debug APK -- test Android khong can may that
apkdebug:
> $(FLUTTER) build apk --debug $(DART_DEFINES_DEV)

# ============================================================
#  Chat luong
# ============================================================

## analyze: flutter analyze -- phai 0 issues truoc khi ban giao
analyze:
> $(FLUTTER) analyze

## test: flutter test (3 integration test can BE that se fail)
test:
> $(FLUTTER) test

## check: analyze + test
check: analyze test

## logs: bat logcat Google Sign-In dechan loi 12500 khi dang nhap
logs:
> $(PS) tool/capture_google_login_log.ps1

# ============================================================
#  Bao tri
# ============================================================

## deps: flutter pub get
deps:
> $(FLUTTER) pub get

## clean: xoa thu muc build (bat buoc neu Gradle loi khi doi ABI)
clean:
> $(FLUTTER) clean

## distclean: clean + deps
distclean: clean deps

# ============================================================
#  help
#  Khong dung dau nhay hay ky tu chuyen huong trong echo:
#  cmd.exe fallback se lam sai. Chi dung ASCII.
# ============================================================

## help: liet ke tat ca target
help:
> @echo ============================================================
> @echo  Closy / Smart Wardrobe Mobile -- make targets
> @echo ============================================================
> @echo.
> @echo  Chay nhanh:
> @echo    make run        web tren Edge, port $(WEB_PORT), mo san trinh duyet
> @echo    make dev        chay tren thiet bi that hoac emulator
> @echo    make build      APK + AAB release + verify  [lenh phat hanh]
> @echo.
> @echo  Build:
> @echo    make apk        APK universal      : $(APK_DIR)/app-release.apk
> @echo    make apksplit   3 APK tach ABI      : arm64 cho may that
> @echo    make aab        App Bundle          : upload len Google Play
> @echo    make apkdebug   APK debug           : test Android khong can may
> @echo    make verify     kiem tra APK/AAB
> @echo.
> @echo  Chat luong:
> @echo    make analyze    flutter analyze
> @echo    make test       flutter test
> @echo    make check      analyze + test
> @echo    make logs       logcat Google Sign-In
> @echo.
> @echo  Bao tri:
> @echo    make deps / clean / distclean
> @echo.
> @echo  Bien -- override duoc tu command line:
> @echo    WEB_PORT=$(WEB_PORT)   BROWSER=$(BROWSER)   DEVICE=android
> @echo    DEV_API / DEV_CLD / DEV_GID / PROD_API / PROD_CLD / PROD_GID
> @echo.
> @echo  Vi du:
> @echo    make run WEB_PORT=9000 BROWSER=chrome
> @echo    make apk DEV_API=http://10.0.2.2:8080/api/v1
> @echo ============================================================
