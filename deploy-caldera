#!/bin/bash
set -euo pipefail

echo "[+] Starting CALDERA installation..."

if [[ $EUID -ne 0 ]]; then
  echo "[!] Please run this script as root or with sudo."
  exit 1
fi

CALDERA_DIR="/root/caldera"
CALDERA_IMAGE="caldera:latest"
UPDATED_IMAGE="caldera_update:latest"
TEMP_CONTAINER="caldera_mir"
FINAL_CONTAINER="caldera_new"

echo "[+] Installing prerequisites..."
apt update
apt upgrade -y
apt-get install -y python3-pip apt-transport-https ca-certificates curl gnupg lsb-release git

echo "[+] Installing Docker..."
mkdir -p /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
EOF

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "[+] Removing any previous CALDERA clone..."
rm -rf "$CALDERA_DIR"

echo "[+] Cloning CALDERA recursively..."
git clone https://github.com/mitre/caldera.git --recursive "$CALDERA_DIR"
cd "$CALDERA_DIR"
git submodule update --init --recursive

echo "[+] Building CALDERA Docker image..."
docker build . --build-arg WIN_BUILD=true -t "$CALDERA_IMAGE"

echo "[+] Removing old containers..."
docker rm -f "$TEMP_CONTAINER" 2>/dev/null || true
docker rm -f "$FINAL_CONTAINER" 2>/dev/null || true

echo "[+] Starting temporary container..."
docker run -d --name "$TEMP_CONTAINER" -p 8888:8888 "$CALDERA_IMAGE"

sleep 15

echo "[+] Configuring pip..."
docker exec "$TEMP_CONTAINER" python3 -m pip config set global.break-system-packages true

echo "[+] Installing plugin dependencies..."
docker exec "$TEMP_CONTAINER" pip3 install -r /usr/src/app/plugins/debrief/requirements.txt
docker exec "$TEMP_CONTAINER" pip3 install -r /usr/src/app/plugins/emu/requirements.txt
docker exec "$TEMP_CONTAINER" pip3 install -r /usr/src/app/plugins/human/requirements.txt
docker exec "$TEMP_CONTAINER" pip3 install -r /usr/src/app/plugins/stockpile/requirements.txt

echo "[+] Installing docker Python module..."
docker exec "$TEMP_CONTAINER" python3 -m pip install docker

echo "[+] Forcing plugin entries via sed..."
docker exec "$TEMP_CONTAINER" sed -i '36i - emu' /usr/src/app/conf/local.yml
docker exec "$TEMP_CONTAINER" sed -i '37i - gameboard' /usr/src/app/conf/local.yml
docker exec "$TEMP_CONTAINER" sed -i '39i - human' /usr/src/app/conf/local.yml

echo "[+] Updating passwords..."
docker exec "$TEMP_CONTAINER" sed -i '/^  red:/,/^  [a-z]/ s/^    red:.*/    red: MyRedPassword123!/' /usr/src/app/conf/local.yml
docker exec "$TEMP_CONTAINER" sed -i '/^  blue:/,/^  [a-z]/ s/^    blue:.*/    blue: MyBluePassword123!/' /usr/src/app/conf/local.yml

echo "[+] Updating API keys..."
docker exec "$TEMP_CONTAINER" sed -i '/api_key_blue:/c\api_key_blue: BlueKey4Me123!' /usr/src/app/conf/local.yml
docker exec "$TEMP_CONTAINER" sed -i '/api_key_red:/c\api_key_red: RedKey4Me123!' /usr/src/app/conf/local.yml

echo "[+] Creating updated image..."
docker commit "$TEMP_CONTAINER" "$UPDATED_IMAGE"

echo "[+] Stopping temp container..."
docker stop "$TEMP_CONTAINER"

echo "[+] Starting final container with verbose logging..."
docker run -d --name "$FINAL_CONTAINER" -p 8888:8888 "$UPDATED_IMAGE" --log DEBUG

echo "[+] Configuring pip in final container..."
docker exec "$FINAL_CONTAINER" python3 -m pip config set global.break-system-packages true

echo "[+] Installing docker module in final container..."
docker exec "$FINAL_CONTAINER" python3 -m pip install docker

echo "[+] Restarting CALDERA..."
docker restart "$FINAL_CONTAINER"
sleep 20

echo "[+] Validating Python modules..."

docker exec "$FINAL_CONTAINER" python3 - <<'EOF'
import sys

errors = []

for mod in ("docker", "yaml"):
    try:
        __import__(mod)
    except Exception as e:
        errors.append(f"{mod}: {e}")

if errors:
    print("[!] Module validation failed")
    for err in errors:
        print(" -", err)
    sys.exit(1)

print("[+] Python module validation successful")
EOF

echo "[+] Checking logs for CURRENT builder errors..."

RECENT_LOGS=$(docker logs --since 60s "$FINAL_CONTAINER" 2>&1 || true)

if echo "$RECENT_LOGS" | grep -qi "Error importing plugin=builder"; then
  echo "[!] ERROR: Builder plugin still failing"
  exit 1
fi

echo "[+] Builder plugin validation passed"

echo "[+] Checking CALDERA availability..."

for i in {1..12}; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888 || true)
  if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "302" ]]; then
    echo "[+] CALDERA responding (HTTP $HTTP_CODE)"
    break
  fi
  sleep 5
done

echo "[+] Final container status:"
docker ps --filter "name=$FINAL_CONTAINER"

echo "[+] CALDERA installation complete!"
echo "[+] URL: http://localhost:8888"
echo "[+] Username: red"
echo "[+] Password: MyRedPassword123!"

