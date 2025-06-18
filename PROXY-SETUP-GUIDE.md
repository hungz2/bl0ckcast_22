# 🔗 Hướng dẫn thiết lập Proxy cho Blockcast Multi-Node

## 🎯 Tại sao cần dùng proxy riêng cho từng node?

- **🚫 Tránh rate limiting**: Blockcast có thể giới hạn số request từ cùng 1 IP
- **🌍 Phân tán địa lý**: Có thể cần IP từ các quốc gia khác nhau
- **🔒 Bảo mật**: Ẩn IP thật của VPS
- **⚡ Redundancy**: Nếu 1 proxy down, các node khác vẫn hoạt động

## 📝 Format proxy hỗ trợ

### HTTP/HTTPS Proxy
```bash
http://ip:port
http://username:password@ip:port
https://ip:port
https://username:password@ip:port
```

### SOCKS5 Proxy
```bash
socks5://ip:port
socks5://username:password@ip:port
```

## 🛠️ Thiết lập từng node với proxy riêng

### Node 1 - Proxy US
```bash
./blockcast-multi-node-manager.sh add-node
```
```
Tên node: beacon-us
Watchtower port: 8080
Proxy: http://us-proxy.example.com:8080
Mô tả node: US Proxy Node
```

### Node 2 - Proxy EU
```bash
./blockcast-multi-node-manager.sh add-node
```
```
Tên node: beacon-eu
Watchtower port: 8081
Proxy: http://eu-proxy.example.com:8080
Mô tả node: EU Proxy Node
```

### Node 3 - Proxy Asia
```bash
./blockcast-multi-node-manager.sh add-node
```
```
Tên node: beacon-asia
Watchtower port: 8082
Proxy: http://asia-proxy.example.com:8080
Mô tả node: Asia Proxy Node
```

### Node 4 - No Proxy (Direct)
```bash
./blockcast-multi-node-manager.sh add-node
```
```
Tên node: beacon-direct
Watchtower port: 8083
Proxy: (để trống)
Mô tả node: Direct Connection Node
```

## 🔍 Kiểm tra và test proxy

### Test proxy của node cụ thể
```bash
./blockcast-multi-node-manager.sh test-proxy beacon-us
```

**Output mẫu:**
```
Testing proxy http://us-proxy.example.com:8080 cho node 'beacon-us'...
✅ Proxy hoạt động tốt!
🌐 IP thông qua proxy: 192.168.1.100
📍 Location: US
```

### Xem thống kê tất cả proxy
```bash
./blockcast-multi-node-manager.sh proxy-stats
```

**Output mẫu:**
```
=====================================
   Blockcast Multi-Node Manager
=====================================
Thống kê sử dụng proxy:

📊 Tổng quan:
  Tổng số node: 4
  Node có proxy: 3
  Node không proxy: 1

🔗 Danh sách proxy đang sử dụng:
  beacon-us: http://us-proxy.example.com:8080
  beacon-eu: http://eu-proxy.example.com:8080
  beacon-asia: http://asia-proxy.example.com:8080

✅ Tất cả proxy đều unique!

💡 Khuyến nghị:
  - Mỗi node nên sử dụng proxy riêng để tránh rate limit
  - Test proxy định kỳ: ./blockcast-multi-node-manager.sh test-proxy <node>
  - Sử dụng proxy ở các quốc gia khác nhau
```

### Xem trạng thái có proxy info
```bash
./blockcast-multi-node-manager.sh status
```

**Output mẫu:**
```
NODE NAME       STATUS     WATCHTOWER      PORT       PROXY           DESCRIPTION         
==========================================================================================
beacon-us       RUNNING    8080           8080       us-proxy.ex...  US Proxy Node       
beacon-eu       RUNNING    8081           8081       eu-proxy.ex...  EU Proxy Node       
beacon-asia     RUNNING    8082           8082       asia-proxy....  Asia Proxy Node     
beacon-direct   RUNNING    8083           8083       None            Direct Connection   
```

## ⚠️ Xử lý proxy trùng lặp

Nếu có proxy trùng lặp, script sẽ cảnh báo:

```bash
./blockcast-multi-node-manager.sh add-node
```
```
Tên node: beacon-test
Watchtower port: 8084
Proxy: http://us-proxy.example.com:8080
```

**Kết quả:**
```
Cảnh báo: Proxy http://us-proxy.example.com:8080 đã được sử dụng bởi node khác!
Bạn có muốn tiếp tục? (yes/no):
```

## 🛡️ Best Practices

### 1. Sử dụng proxy chất lượng cao
- **Dedicated proxy** thay vì shared
- **High uptime** (99%+)
- **Fast response time** (<500ms)
- **Unlimited bandwidth**

### 2. Phân bổ địa lý hợp lý
```bash
Node 1: US West Coast
Node 2: US East Coast  
Node 3: Europe (UK/Germany)
Node 4: Asia (Singapore/Japan)
Node 5: Direct (no proxy)
```

### 3. Backup proxy plan
```bash
# Primary proxy
http://primary-proxy.com:8080

# Backup proxy (để sẵn khi primary fail)
http://backup-proxy.com:8080
```

### 4. Monitor proxy health
```bash
# Chạy định kỳ để test tất cả proxy
for node in beacon-us beacon-eu beacon-asia; do
    ./blockcast-multi-node-manager.sh test-proxy $node
done
```

## 🔧 Troubleshooting Proxy

### Proxy không kết nối được

**Symptoms:**
```
❌ Proxy không hoạt động hoặc không thể kết nối!
```

**Solutions:**
1. **Kiểm tra format proxy:**
   ```bash
   # Đúng
   http://192.168.1.100:8080
   
   # Sai
   192.168.1.100:8080  # thiếu protocol
   ```

2. **Test proxy thủ công:**
   ```bash
   curl --proxy http://proxy-ip:port https://google.com
   ```

3. **Kiểm tra firewall:**
   ```bash
   # Check outbound connections
   sudo ufw status
   ```

### Container không sử dụng proxy

**Symptoms:**
- Node hoạt động nhưng vẫn dùng IP gốc

**Solutions:**
1. **Kiểm tra docker-compose.yml:**
   ```bash
   cd blockcast-nodes/beacon-us
   cat docker-compose.yml | grep -A5 environment
   ```

2. **Restart node sau khi cấu hình proxy:**
   ```bash
   ./blockcast-multi-node-manager.sh restart beacon-us
   ```

3. **Kiểm tra logs:**
   ```bash
   ./blockcast-multi-node-manager.sh logs beacon-us
   ```

### Proxy chậm hoặc timeout

**Symptoms:**
- Node khởi động chậm
- Timeout errors trong logs

**Solutions:**
1. **Test proxy speed:**
   ```bash
   time curl --proxy http://proxy-ip:port https://google.com
   ```

2. **Thay đổi proxy timeout trong docker-compose:**
   ```yaml
   environment:
     - HTTP_PROXY=http://proxy-ip:port
     - HTTPS_PROXY=http://proxy-ip:port
     - NO_PROXY=localhost,127.0.0.1
     - PROXY_TIMEOUT=30
   ```

## 📊 Proxy Providers khuyến nghị

### Free Proxy (testing only)
⚠️ **Không khuyến nghị cho production**

### Paid Proxy Services
- **Bright Data** (formerly Luminati)
- **Oxylabs**
- **Smartproxy**
- **Proxy-Cheap**
- **IPRoyal**

### VPS + Proxy Setup
```bash
# Tự setup proxy trên VPS khác
# 1. Thuê VPS ở quốc gia khác
# 2. Cài đặt Squid proxy
sudo apt install squid
sudo nano /etc/squid/squid.conf

# 3. Cấu hình authentication (optional)
# 4. Restart squid
sudo systemctl restart squid
```

## 🎯 Kết luận

- ✅ **Mỗi node 1 proxy riêng** = Optimal performance
- ✅ **Test proxy trước khi dùng** = Tránh downtime  
- ✅ **Monitor proxy health** = Phát hiện sớm vấn đề
- ✅ **Backup plan** = Continuity khi có sự cố

---

**💡 Pro Tip**: Bắt đầu với 1-2 node có proxy để test, sau đó mở rộng dần dần. Đừng setup quá nhiều node cùng lúc! 