#!/usr/bin/env bash
# build_tf_and_tftext_220_sigbuild.sh
# Buduje TensorFlow v2.20.0 (GPU) + TensorFlow-Text v2.20.0 w kontenerze SIG Build.
# Wymagania: Docker + NVIDIA Container Toolkit (działa `docker --gpus all`).
# Użycie:
#   TF_CUDA_COMPUTE_CAPABILITIES=8.9 ./build_tf_and_tftext_220_sigbuild.sh
#   (dla 3080/3090 użyj 8.6; dla innych kart dopasuj CC)

set -euo pipefail

# ======= KONFIG =======
IMG="${IMG:-tensorflow/build:2.20-python3.11}"   # obraz SIG Build (zmień na :python3.12 aby mieć cp312)
PKG_DIR="${PKG_DIR:-/tmp/pkg}"                   # gdzie lądują .whl na hoście
CACHE_DIR="${CACHE_DIR:-/tmp/bazelcache}"        # cache Bazela
DIST_DIR="${DIST_DIR:-/tmp/tf_distdir}"          # distdir dla prefetchów (np. LLVM)
TF_TAG="${TF_TAG:-v2.20.0}"
TFTEXT_TAG="${TFTEXT_TAG:-v2.20.0}"
CC="${TF_CUDA_COMPUTE_CAPABILITIES:-8.9}"        # Compute Capability (np. 8.6 / 8.9)
CONTAINER="${CONTAINER:-tfbuild}"

# hermetyczne CC do reguł (np. 8.9 -> sm_89,compute_89)
CC_NUM="${CC/./}"                                # "8.9" -> "89"
HERMETIC_CC="sm_${CC_NUM},compute_${CC_NUM}"

echo "[i] IMG=$IMG | TF=$TF_TAG | TF-Text=$TFTEXT_TAG | CC=$CC ($HERMETIC_CC)"
mkdir -p "$PKG_DIR" "$CACHE_DIR" "$DIST_DIR"

# ======= sanity: docker & GPU =======
command -v docker >/dev/null || { echo "[ERR] Brak Dockera."; exit 1; }
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker pull "$IMG" >/dev/null

# ======= start kontenera w tle =======
docker run -d --gpus all --name "$CONTAINER" \
  -w /tf -e TF_PYTHON_VERSION=3.11 \
  -v "$PKG_DIR":/tf/pkg \
  -v "$CACHE_DIR":/tf/cache \
  -v "$DIST_DIR":/tf/distfiles \
  "$IMG" bash -lc "sleep infinity" >/dev/null

# GPU dostępny?
docker exec "$CONTAINER" nvidia-smi >/dev/null || { echo "[ERR] Brak GPU w kontenerze (sprawdź NVIDIA Container Toolkit)."; exit 1; }

# ======= prefetch problematycznych paczek (LLVM) do distdir =======
docker exec "$CONTAINER" bash -lc '
  set -e
  mkdir -p /tf/distfiles /tf/cache/repo
  URL="https://storage.googleapis.com/mirror.tensorflow.org/github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz"
  echo "[i] Prefetch LLVM -> /tf/distfiles"
  curl -L --retry 10 --retry-connrefused --retry-delay 3 -C - -o /tf/distfiles/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz "$URL"
'

# ======= build TensorFlow (GPU) =======
docker exec "$CONTAINER" bash -lc "
  set -e
  rm -rf /tf/tensorflow
  git clone --branch $TF_TAG --depth 1 https://github.com/tensorflow/tensorflow.git /tf/tensorflow
  cd /tf/tensorflow
  echo '[i] Bazel build TF :wheel ...'
bazel --bazelrc=/usertools/gpu.bazelrc \
  build --config=sigbuild_local_cache \
  --config=cuda_wheel \
  --repo_env=USE_PYWRAP_RULES=1 \
  --repo_env=WHEEL_NAME=tensorflow \
  --repo_env=TF_CUDA_COMPUTE_CAPABILITIES=$CC \
  --repo_env=HERMETIC_CUDA_COMPUTE_CAPABILITIES="$HERMETIC_CC" \
  --distdir=/tf/distfiles \
  --repository_cache=/tf/cache/repo \
  //tensorflow/tools/pip_package:wheel

  cp bazel-bin/tensorflow/tools/pip_package/wheel_house/tensorflow-*.whl /tf/pkg/
  ls -lh /tf/pkg/tensorflow-*.whl
"

# ======= build TensorFlow-Text =======
docker exec "$CONTAINER" bash -lc "
  set -e
  python3 -m pip -q install -U pip
  python3 -m pip -q install /tf/pkg/tensorflow-*.whl
  rm -rf /tf/text
  git clone --branch $TFTEXT_TAG --depth 1 https://github.com/tensorflow/text.git /tf/text
  cd /tf/text
  echo '[i] Build TF-Text ...'
  ./oss_scripts/run_build.sh
  cp pip_pkg/tensorflow_text-*.whl /tf/pkg/
  ls -lh /tf/pkg/tensorflow_text-*.whl
"

echo
echo "[OK] Koła gotowe w: $PKG_DIR"
ls -lh "$PKG_DIR"/*whl || true
echo
echo "[TIP] Instalacja w Twoim env (Python musi pasować do ABI koła, np. cp311 → Py3.11):"
echo "  conda activate magenta_rt"
echo "  pip uninstall -y tensorflow tensorflow-text || true"
echo "  pip install $PKG_DIR/tensorflow-*.whl $PKG_DIR/tensorflow_text-*.whl"
