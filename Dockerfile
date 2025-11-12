# 使用 Python 3.11 作為基礎映像
FROM python:3.11-slim

# 設定工作目錄
WORKDIR /app

# 設定學號環境變數（可在 build 時覆蓋）
ARG STU_ID=CSIE-NPU
ENV STU_ID=${STU_ID}

# 複製 requirements.txt 並安裝依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用程式檔案
COPY http_basic_auth_server.py .
COPY assets/ ./assets/

# 暴露 port 3128
EXPOSE 3128

# 啟動伺服器
CMD ["python", "http_basic_auth_server.py"]
