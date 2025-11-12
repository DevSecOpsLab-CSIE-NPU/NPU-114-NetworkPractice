#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定變數
IMAGE_NAME="http-basic-auth-server"
CONTAINER_NAME="http-auth-server"
COMPRESSED_FILE="./assets/http-basic-auth-server.tar.bz2"
EXPORT_FILE="http-basic-auth-server.tar"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker 映像載入與執行腳本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 檢查壓縮檔案是否存在
if [ ! -f "$COMPRESSED_FILE" ]; then
    echo -e "${RED}錯誤: 找不到壓縮檔案 ${COMPRESSED_FILE}${NC}"
    echo "請先執行 ./build_and_export.sh 建立映像檔案"
    exit 1
fi

# 檢查 pbzip2 是否已安裝
if ! command -v pbzip2 &> /dev/null; then
    echo -e "${RED}錯誤: pbzip2 未安裝${NC}"
    echo -e "${YELLOW}請安裝 pbzip2:${NC}"
    echo "  macOS: brew install pbzip2"
    echo "  Ubuntu/Debian: sudo apt-get install pbzip2"
    exit 1
fi

# 步驟 1: 解壓縮
echo -e "${YELLOW}[1/4] 解壓縮映像檔案...${NC}"
if pbzip2 -d -k -f "$COMPRESSED_FILE"; then
    echo -e "${GREEN}  ✓ 解壓縮成功${NC}"
    # pbzip2 會將檔案解壓到同目錄，移動到當前目錄
    mv "./assets/${EXPORT_FILE}" "./${EXPORT_FILE}"
else
    echo -e "${RED}  ✗ 解壓縮失敗${NC}"
    exit 1
fi

# 步驟 2: 載入 Docker 映像
echo -e "${YELLOW}[2/4] 載入 Docker 映像...${NC}"
if docker load -i "$EXPORT_FILE"; then
    echo -e "${GREEN}  ✓ 映像載入成功${NC}"
    # 清理解壓後的 tar 檔案
    rm "$EXPORT_FILE"
else
    echo -e "${RED}  ✗ 映像載入失敗${NC}"
    exit 1
fi

# 步驟 3: 停止並移除舊容器
echo -e "${YELLOW}[3/4] 清理舊容器...${NC}"
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    echo -e "${GREEN}  ✓ 舊容器已清理${NC}"
fi

# 步驟 4: 啟動新容器
echo -e "${YELLOW}[4/4] 啟動容器...${NC}"
if docker run -d -p 3128:3128 --name "$CONTAINER_NAME" "$IMAGE_NAME"; then
    echo -e "${GREEN}  ✓ 容器啟動成功${NC}"
    sleep 2
    
    # 顯示容器資訊
    echo ""
    echo -e "${BLUE}容器資訊:${NC}"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo -e "${BLUE}容器日誌:${NC}"
    docker logs "$CONTAINER_NAME" 2>&1 | head -n 15
else
    echo -e "${RED}  ✗ 容器啟動失敗${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 容器已成功啟動！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}訪問服務:${NC}"
echo "  URL: http://localhost:3128/"
echo ""
echo -e "${BLUE}常用指令:${NC}"
echo "  查看日誌: docker logs -f ${CONTAINER_NAME}"
echo "  停止容器: docker stop ${CONTAINER_NAME}"
echo "  啟動容器: docker start ${CONTAINER_NAME}"
echo "  移除容器: docker rm -f ${CONTAINER_NAME}"
echo ""
