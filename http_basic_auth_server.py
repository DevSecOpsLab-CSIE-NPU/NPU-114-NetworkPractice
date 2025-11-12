#!/usr/bin/env python3
"""
HTTP Basic Authentication Server 範例
使用 Flask 框架實作基本的 HTTP Basic Auth
"""

from flask import Flask, request, jsonify, Response, render_template_string
from functools import wraps
import base64
import random
import os
import socket

app = Flask(__name__)

# 學號變數 - 從環境變數讀取，如果沒有則使用預設值
STU_ID = os.environ.get('STU_ID', 'CSIE-NPU')

# 從 assets/password.txt 讀取密碼並根據學號隨機選擇
def get_password_from_file():
    """根據學號從 password.txt 中選擇一個密碼"""
    password_file = os.path.join('assets', 'password.txt')
    
    try:
        with open(password_file, 'r', encoding='utf-8') as f:
            passwords = [line.strip() for line in f if line.strip()]
        
        # 使用學號作為隨機種子，確保每次執行選擇相同的密碼
        random.seed(hash(STU_ID))
        selected_password = random.choice(passwords).lower()  # 轉換為小寫
        
        print(f"學號: {STU_ID}")
        # 密碼已隱藏，讓學生自行猜測
        
        return selected_password
    except FileNotFoundError:
        print(f"警告: 找不到 {password_file}，使用預設密碼")
        return 'admin123'

# 模擬用戶資料庫（實際應用中應使用真實資料庫和雜湊密碼）
ADMIN_PASSWORD = get_password_from_file()
USERS = {
    STU_ID: ADMIN_PASSWORD
}

# 取得主機 IP
def get_host_ip():
    """取得主機 IP 位址"""
    try:
        # 建立一個 UDP socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # 不需要真的連線，只是用來取得本機 IP
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

# HTML 模板
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>114 電腦網路實習 - 期中考</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 600px;
            width: 100%;
            padding: 40px;
            animation: fadeIn 0.5s ease-in;
        }
        
        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        h1 {
            color: #667eea;
            text-align: center;
            margin-bottom: 10px;
            font-size: 28px;
            font-weight: 700;
        }
        
        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
            font-size: 14px;
        }
        
        .success-badge {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 30px;
            font-size: 18px;
            font-weight: 600;
        }
        
        .info-section {
            margin-bottom: 20px;
        }
        
        .info-item {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px 20px;
            margin-bottom: 15px;
            border-radius: 5px;
            transition: transform 0.2s ease;
        }
        
        .info-item:hover {
            transform: translateX(5px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        
        .info-label {
            color: #667eea;
            font-weight: 600;
            font-size: 14px;
            margin-bottom: 5px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .info-value {
            color: #333;
            font-size: 18px;
            font-weight: 500;
            font-family: 'Courier New', monospace;
        }
        
        .timestamp {
            text-align: center;
            color: #999;
            font-size: 12px;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
        
        .icon {
            margin-right: 8px;
        }
        
        @media (max-width: 600px) {
            .container {
                padding: 30px 20px;
            }
            
            h1 {
                font-size: 24px;
            }
            
            .info-value {
                font-size: 16px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎓 114 電腦網路實習 - 期中考</h1>
        <div class="subtitle">HTTP Basic Authentication 實作</div>
        
        <div class="success-badge">
            ✅ 認證成功！歡迎，{{ username }}
        </div>
        
        <div class="info-section">
            <div class="info-item">
                <div class="info-label">🎫 學號 (Student ID)</div>
                <div class="info-value">{{ student_id }}</div>
            </div>
            
            <div class="info-item">
                <div class="info-label">️ 主機 IP (Host IP)</div>
                <div class="info-value">{{ host_ip }}</div>
            </div>
            
            <div class="info-item">
                <div class="info-label">🌐 請求來源 IP (Request IP)</div>
                <div class="info-value">{{ request_ip }}</div>
            </div>
        </div>
        
        <div class="timestamp">
            認證時間：{{ timestamp }}
        </div>
    </div>
</body>
</html>
"""


def check_auth(username, password):
    """驗證用戶名和密碼"""
    return username in USERS and USERS[username] == password


def authenticate():
    """發送 401 回應，要求進行基本認證"""
    return Response(
        'Could not verify your access level for that URL.\n'
        'You have to login with proper credentials', 401,
        {'WWW-Authenticate': 'Basic realm="Login Required"'}
    )


def requires_auth(f):
    """裝飾器：要求進行基本認證"""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)
    return decorated


@app.route('/')
@requires_auth
def home():
    """受保護的根路由，需要認證"""
    from datetime import datetime
    
    username = request.authorization.username
    
    # 取得請求來源 IP
    if request.headers.get('X-Forwarded-For'):
        request_ip = request.headers.get('X-Forwarded-For').split(',')[0]
    else:
        request_ip = request.remote_addr
    
    # 取得主機 IP
    host_ip = get_host_ip()
    
    # 取得當前時間
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    # 渲染 HTML 模板
    return render_template_string(
        HTML_TEMPLATE,
        username=username,
        student_id=STU_ID,
        host_ip=host_ip,
        request_ip=request_ip,
        timestamp=timestamp
    )


if __name__ == '__main__':
    print("=" * 50)
    print("HTTP Basic Auth Server 已啟動")
    print("=" * 50)
    print(f"\n學號: {STU_ID}")
    print("\n密碼已隱藏 - 請學生自行猜測密碼")
    print("\n可訪問的端點：")
    print("  http://localhost:3128/          - 受保護頁面（需要認證）")
    print("\n使用方式：")
    print(f"  curl -u {STU_ID}:<密碼> http://localhost:3128/")
    print("=" * 50)
    print()
    
    app.run(debug=True, host='0.0.0.0', port=3128)
