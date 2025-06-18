# 🚀 Hướng dẫn nhanh Blockcast Multi-Node

## 📥 Cài đặt trong 3 bước

### Bước 1: Cài đặt Docker

```bash
# Cài đặt Docker và Docker Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
sudo apt install docker-compose-plugin
```

### Bước 2: Tải script

```bash
# Tạo thư mục và tải script
mkdir blockcast-multi-node
cd blockcast-multi-node
wget https://raw.githubusercontent.com/your-repo/blockcast-multi-node-manager.sh
chmod +x blockcast-multi-node-manager.sh
```

### Bước 3: Thiết lập và thêm node

```bash
# Thiết lập ban đầu
./blockcast-multi-node-manager.sh setup

# Thêm node đầu tiên
./blockcast-multi-node-manager.sh add-node
```

## ⚡ Sử dụng cơ bản

### 1. Thêm BEACON node

```bash
./blockcast-multi-node-manager.sh add-node
```

**Thông tin cần nhập:**
```
Tên node: beacon1
Watchtower port: 8080 (mặc định)
Proxy: http://proxy1-ip:port (hoặc để trống)
Mô tả node: Main BEACON node
```

### 2. Khởi động node

```bash
./blockcast-multi-node-manager.sh start beacon1
```

### 3. Generate keys

```bash
./blockcast-multi-node-manager.sh init beacon1
```

**Lưu lại thông tin sau:**
- Hardware ID
- Challenge Key  
- Registration URL

### 4. Đăng ký node

1. **Truy cập Registration URL** từ step 3
2. **Hoặc truy cập https://app.blockcast.network/register**
3. **Nhập Hardware ID và Challenge Key**
4. **Enable location access** trên browser

### 5. Kiểm tra trạng thái

```bash
./blockcast-multi-node-manager.sh status
```

## 🔧 Thêm nhiều node

### Node thứ 2:

```bash
./blockcast-multi-node-manager.sh add-node
```

```
Tên node: beacon2
Watchtower port: 8081
Proxy: http://proxy2-ip:port (proxy khác)
Mô tả node: Backup BEACON node
```

### Node thứ 3:

```bash
./blockcast-multi-node-manager.sh add-node
```

```
Tên node: beacon3
Watchtower port: 8082
Proxy: http://proxy3-ip:port (proxy khác)
Mô tả node: Test BEACON node
```

## 📊 Quản lý node

```bash
# Xem tất cả node
./blockcast-multi-node-manager.sh list

# Khởi động node cụ thể
./blockcast-multi-node-manager.sh start beacon2

# Dừng node cụ thể
./blockcast-multi-node-manager.sh stop beacon2

# Khởi động lại node
./blockcast-multi-node-manager.sh restart beacon2

# Xem logs
./blockcast-multi-node-manager.sh logs beacon2

# Generate keys cho node khác
./blockcast-multi-node-manager.sh init beacon2

# Xóa node
./blockcast-multi-node-manager.sh remove beacon2

# Test proxy của node
./blockcast-multi-node-manager.sh test-proxy beacon1

# Xem thống kê proxy
./blockcast-multi-node-manager.sh proxy-stats
```

## 💡 Tips quan trọng

### Port management:

- **Node 1**: Port 8080
- **Node 2**: Port 8081
- **Node 3**: Port 8082
- **Node 4**: Port 8083
- **Node 5**: Port 8084

### Khuyến nghị số lượng node:

- **VPS 4GB RAM**: 1-2 node
- **VPS 8GB RAM**: 2-3 node
- **VPS 16GB RAM**: 4-5 node

### Workflow chuẩn:

1. `add-node` → Thêm cấu hình node
2. `start` → Khởi động containers
3. `init` → Generate keys
4. **Đăng ký trên web portal**
5. `status` → Kiểm tra health

## 🔍 Troubleshooting nhanh

### Node không khởi động:

```bash
# Xem logs chi tiết
./blockcast-multi-node-manager.sh logs beacon1

# Khởi động lại
./blockcast-multi-node-manager.sh restart beacon1
```

### Port bị conflict:

```bash
# Kiểm tra port
netstat -tulpn | grep :8080

# Dùng port khác khi add-node
```

### Docker lỗi:

```bash
# Kiểm tra Docker running
sudo systemctl status docker

# Khởi động Docker
sudo systemctl start docker
```

## 🚨 Backup quan trọng

### Backup keys:

```bash
# Tạo backup
./blockcast-multi-node-manager.sh backup

# Backup được lưu tại backups/
```

### Lưu thông tin manual:

Cho mỗi node, lưu lại:
```
Node Name: beacon1
Hardware ID: c6ff0e6f-bc4d-4151-47c3-07df0e3cf53f
Challenge Key: MCowBQYDK2VwAyEAXP49l4pBK1V5qy7vbRJYv3etRdEr7ycsQAvrgS+hQY0=
Port: 8080
Proxy: http://proxy1-ip:port
Status: Registered
```

## 📋 Checklist hoàn chỉnh

### ✅ Setup:
- [ ] Docker đã cài đặt
- [ ] Script có quyền execute
- [ ] Chạy `setup` thành công

### ✅ Node 1:
- [ ] `add-node` beacon1
- [ ] `start` beacon1  
- [ ] `init` beacon1
- [ ] Đăng ký trên web portal
- [ ] Status = Healthy trên portal

### ✅ Node 2:
- [ ] `add-node` beacon2 (port khác)
- [ ] `start` beacon2
- [ ] `init` beacon2  
- [ ] Đăng ký trên web portal
- [ ] Status = Healthy trên portal

### ✅ Backup:
- [ ] Chạy `backup`
- [ ] Lưu Hardware ID + Challenge Key
- [ ] Test `status` command
- [ ] Test proxy: `test-proxy beacon1`

## 🌐 Links quan trọng

- **Web Portal**: https://app.blockcast.network/
- **Register**: https://app.blockcast.network/register
- **Manage Nodes**: https://app.blockcast.network/manage-nodes
- **Documentation**: https://docs.blockcast.network/

---

**🎉 Chúc bạn thành công với Blockcast BEACON nodes!** 