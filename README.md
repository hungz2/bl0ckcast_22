# 🚀 Blockcast Multi-Node Manager

Script quản lý nhiều Blockcast BEACON node trên 1 VPS một cách dễ dàng và hiệu quả.

## ✨ Tính năng

- ✅ Chạy nhiều Blockcast BEACON node trên cùng 1 VPS
- ✅ Tự động tải và cấu hình Docker Compose
- ✅ Quản lý port riêng biệt cho từng node
- ✅ Theo dõi trạng thái real-time
- ✅ Xem logs của từng node riêng biệt
- ✅ Generate Hardware ID và Challenge Key
- ✅ Backup và restore cấu hình
- ✅ Hỗ trợ Docker Compose mới và cũ

## 📋 Yêu cầu hệ thống

- **OS**: Ubuntu 18.04+ hoặc Debian 9+
- **RAM**: Tối thiểu 4GB (khuyến nghị 8GB+ cho nhiều node)
- **CPU**: Tối thiểu 2 core (khuyến nghị 4+ core)
- **Disk**: 20GB+ trống
- **Docker**: Phiên bản mới nhất
- **Docker Compose**: Plugin hoặc standalone

## 🛠️ Cài đặt

### Bước 1: Cài đặt Docker (nếu chưa có)

```bash
# Cài đặt Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Cài đặt Docker Compose plugin
sudo apt update
sudo apt install docker-compose-plugin
```

### Bước 2: Tải Blockcast Multi-Node Manager

```bash
# Clone hoặc tải script
git clone <repo-url>
cd blockcast-multi-node

# Hoặc tải trực tiếp
wget https://raw.githubusercontent.com/your-repo/blockcast-multi-node-manager.sh
chmod +x blockcast-multi-node-manager.sh
```

### Bước 3: Thiết lập ban đầu

```bash
./blockcast-multi-node-manager.sh setup
```

## 📖 Cách sử dụng

### Thêm node đầu tiên

```bash
./blockcast-multi-node-manager.sh add-node
```

**Thông tin cần nhập:**
```
Tên node: beacon1
Watchtower port: 8080 (mặc định)
Mô tả node: Main BEACON node
```

### Khởi động node

```bash
# Khởi động node cụ thể
./blockcast-multi-node-manager.sh start beacon1

# Hoặc khởi động tất cả
./blockcast-multi-node-manager.sh start
```

### Generate keys cho node

```bash
./blockcast-multi-node-manager.sh init beacon1
```

**Output sẽ có dạng:**
```
Hardware ID:
------------
c6ff0e6f-bc4d-4151-47c3-07df0e3cf53f

Challenge Key:
--------------
MCowBQYDK2VwAyEAXP49l4pBK1V5qy7vbRJYv3etRdEr7ycsQAvrgS+hQY0=

Register URL:
-------------
https://app.blockcast.network/register?hwid=...&challenge-key=...
```

### Đăng ký node trên web portal

1. Copy Registration URL từ output
2. Dán vào browser và truy cập
3. Hoặc truy cập https://app.blockcast.network/register thủ công
4. Nhập Hardware ID và Challenge Key

## 🔧 Quản lý node

### Các lệnh cơ bản

```bash
# Kiểm tra trạng thái tất cả node
./blockcast-multi-node-manager.sh status

# Xem logs của node
./blockcast-multi-node-manager.sh logs beacon1

# Xem logs service cụ thể
./blockcast-multi-node-manager.sh logs beacon1 blockcastd

# Dừng node
./blockcast-multi-node-manager.sh stop beacon1

# Khởi động lại node
./blockcast-multi-node-manager.sh restart beacon1

# Liệt kê tất cả node
./blockcast-multi-node-manager.sh list

# Xóa node
./blockcast-multi-node-manager.sh remove beacon1
```

### Thêm nhiều node

```bash
# Node thứ 2
./blockcast-multi-node-manager.sh add-node
# Tên: beacon2, Port: 8081

# Node thứ 3  
./blockcast-multi-node-manager.sh add-node
# Tên: beacon3, Port: 8082
```

## 📊 Monitoring

### Kiểm tra trạng thái chi tiết

```bash
./blockcast-multi-node-manager.sh status
```

**Output:**
```
=====================================
   Blockcast Multi-Node Manager
=====================================
Trạng thái các Blockcast BEACON node:

NODE NAME       STATUS     WATCHTOWER      PORT       DESCRIPTION         
================================================================================
beacon1         RUNNING    8080           8080       Main BEACON node    
beacon2         RUNNING    8081           8081       Backup node         
beacon3         STOPPED    8082           8082       Test node           
```

### Xem logs real-time

```bash
# Tất cả services
./blockcast-multi-node-manager.sh logs beacon1

# Service cụ thể
./blockcast-multi-node-manager.sh logs beacon1 blockcastd
./blockcast-multi-node-manager.sh logs beacon1 beacond
./blockcast-multi-node-manager.sh logs beacon1 control_proxy
./blockcast-multi-node-manager.sh logs beacon1 watchtower
```

## 💾 Backup và Restore

### Tạo backup

```bash
./blockcast-multi-node-manager.sh backup
```

Backup sẽ được lưu tại `backups/blockcast-backup-YYYYMMDD-HHMMSS.tar.gz`

### Restore từ backup

```bash
# Giải nén backup
cd blockcast-multi-node
tar -xzvf backups/blockcast-backup-20231201-120000.tar.gz

# Khởi động lại các node
./blockcast-multi-node-manager.sh start
```

## 🔧 Cấu hình nâng cao

### Cấu trúc thư mục

```
blockcast-multi-node/
├── blockcast-multi-node-manager.sh    # Script chính
├── nodes-config.json                  # Cấu hình các node
├── blockcast-nodes/                   # Thư mục chứa các node
│   ├── beacon1/                       # Node 1
│   │   ├── docker-compose.yml         # Docker compose cho node 1
│   │   └── docker-compose.yml.original
│   ├── beacon2/                       # Node 2
│   │   ├── docker-compose.yml         # Docker compose cho node 2
│   │   └── docker-compose.yml.original
│   └── ...
└── backups/                           # Backup files
```

### File cấu hình nodes-config.json

```json
{
  "nodes": {
    "beacon1": {
      "watchtower_port": "8080",
      "description": "Main BEACON node",
      "directory": "/path/to/blockcast-nodes/beacon1",
      "created_at": "2023-12-01T12:00:00+07:00"
    },
    "beacon2": {
      "watchtower_port": "8081", 
      "description": "Backup node",
      "directory": "/path/to/blockcast-nodes/beacon2",
      "created_at": "2023-12-01T12:05:00+07:00"
    }
  }
}
```

## 🚨 Lưu ý quan trọng

### Bảo mật

1. **⚠️ Backup Challenge Key và Hardware ID** - Rất quan trọng!
2. **🔐 Backup private key** tại `~/.blockcast/certs/gw_challenge.key`
3. **📝 Ghi chú thông tin đăng ký** cho từng node
4. **🔒 Bảo vệ file backup** - chứa thông tin nhạy cảm

### Hiệu suất

- **Khuyến nghị số node theo RAM:**
  - VPS 4GB: 1-2 node
  - VPS 8GB: 2-3 node  
  - VPS 16GB: 4-5 node

- **Port range:** 8080-8090 cho watchtower của các node

### Network

- **Đảm bảo port không bị firewall block**
- **Kiểm tra port forwarding** nếu chạy behind NAT
- **Stable internet connection** để tránh disconnect

## 🔍 Troubleshooting

### Node không khởi động

```bash
# Kiểm tra logs chi tiết
./blockcast-multi-node-manager.sh logs beacon1

# Kiểm tra Docker
docker ps -a

# Khởi động lại
./blockcast-multi-node-manager.sh restart beacon1
```

### Port conflict

```bash
# Kiểm tra port đang sử dụng
netstat -tulpn | grep :8080

# Thay đổi port cho node
# Xóa và tạo lại node với port khác
```

### Docker compose command not found

```bash
# Cài đặt Docker Compose plugin
sudo apt install docker-compose-plugin

# Hoặc cài đặt standalone
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Container không healthy

```bash
# Kiểm tra chi tiết container
./blockcast-multi-node-manager.sh logs beacon1 blockcastd

# Kiểm tra network connectivity
docker network ls
docker network inspect <network-name>
```

## ❓ FAQ

### Q: Có thể chạy bao nhiêu node trên 1 VPS?
**A**: Phụ thuộc vào cấu hình VPS và bandwidth. Khuyến nghị:
- VPS 4GB RAM: 1-2 node
- VPS 8GB RAM: 2-3 node
- VPS 16GB RAM: 4-5 node

### Q: Hardware ID có giống nhau không khi chạy nhiều node?
**A**: Có thể giống nhau vì cùng hardware, nhưng Challenge Key sẽ khác nhau cho mỗi container.

### Q: Làm sao để check node có đang kiếm được reward không?
**A**: Truy cập https://app.blockcast.network/manage-nodes để xem uptime và reward.

### Q: Node cần chạy liên tục không?
**A**: Có, cần online tối thiểu 6 giờ để connectivity test và 24 giờ để bắt đầu kiếm reward.

### Q: Backup quan trọng nhất là gì?
**A**: Challenge Key và Hardware ID. Mất 2 thông tin này sẽ mất quyền sở hữu node.

## 🤝 Hỗ trợ

- **Official Website**: https://blockcast.network/
- **Web Portal**: https://app.blockcast.network/
- **Documentation**: https://docs.blockcast.network/
- **Discord**: https://discord.gg/blockcast (nếu có)

## 📄 License

MIT License - Xem file LICENSE để biết chi tiết.

---

**⚠️ Disclaimer**: Script này được phát triển để hỗ trợ việc quản lý nhiều Blockcast BEACON node. Luôn backup dữ liệu quan trọng và test trên môi trường development trước khi sử dụng production. 