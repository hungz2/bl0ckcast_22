# 📋 Blockcast Multi-Node Manager - Tổng quan dự án

## 🎯 Mục tiêu

Tạo công cụ quản lý nhiều Blockcast BEACON node trên cùng 1 VPS một cách dễ dàng, tương tự như Dria Multi-Node Manager nhưng được tối ưu cho Blockcast Network.

## 📁 Cấu trúc dự án

```
blockcast-multi-node/
├── blockcast-multi-node-manager.sh    # Script chính quản lý node
├── install.sh                         # Script cài đặt tự động
├── README.md                          # Hướng dẫn chi tiết
├── QUICK-START.md                     # Hướng dẫn nhanh
├── sample-docker-compose.yml          # File docker-compose mẫu
├── PROJECT-OVERVIEW.md               # File này
├── nodes-config.json                 # File cấu hình (tự tạo)
├── blockcast-nodes/                  # Thư mục chứa nodes (tự tạo)
│   ├── beacon1/
│   ├── beacon2/
│   └── ...
└── backups/                          # Thư mục backup (tự tạo)
```

## ⚙️ Tính năng chính

### 🔧 Quản lý Node
- ✅ **add-node**: Thêm node mới với port riêng biệt
- ✅ **start/stop/restart**: Quản lý trạng thái node
- ✅ **status**: Xem trạng thái tất cả node
- ✅ **logs**: Xem logs từng node/service
- ✅ **init**: Generate Hardware ID + Challenge Key
- ✅ **remove**: Xóa node hoàn toàn
- ✅ **list**: Liệt kê tất cả node

### 🛠️ Setup & Maintenance
- ✅ **setup**: Thiết lập ban đầu
- ✅ **backup**: Backup cấu hình + keys
- ✅ Tự động tải docker-compose.yml từ GitHub
- ✅ Tự động modify port để tránh conflict
- ✅ Hỗ trợ cả Docker Compose plugin và standalone

## 🔑 Khác biệt với Dria

| Tính năng | Dria | Blockcast |
|-----------|------|-----------|
| **Authentication** | Private key riêng | Hardware ID + Challenge Key |
| **API** | Gemini API key | Không cần API key |
| **Proxy** | Hỗ trợ proxy | Không cần proxy |
| **Port** | 4001+ | 8080+ (watchtower) |
| **Services** | 1 service | 4 services (watchtower, beacond, blockcastd, control_proxy) |
| **Registration** | Tự động | Thủ công trên web portal |

## 🚀 Workflow sử dụng

```bash
# 1. Cài đặt (chỉ chạy 1 lần)
./install.sh

# 2. Thêm node
./blockcast-multi-node-manager.sh add-node

# 3. Khởi động node
./blockcast-multi-node-manager.sh start beacon1

# 4. Generate keys
./blockcast-multi-node-manager.sh init beacon1

# 5. Đăng ký trên web portal
# Sử dụng Hardware ID + Challenge Key từ step 4

# 6. Kiểm tra trạng thái
./blockcast-multi-node-manager.sh status
```

## 🎨 Architecture

### Node Structure
```
beacon1/
├── docker-compose.yml          # Modified từ GitHub
├── docker-compose.yml.original # Backup original
└── volumes/                    # Docker volumes data
    ├── beacon_data/
    └── blockcast_data/
```

### Config Structure
```json
{
  "nodes": {
    "beacon1": {
      "watchtower_port": "8080",
      "description": "Main BEACON node",
      "directory": "/path/to/blockcast-nodes/beacon1",
      "created_at": "2023-12-01T12:00:00+07:00"
    }
  }
}
```

## 🔐 Security Notes

### Critical Backups
1. **Hardware ID**: Định danh thiết bị
2. **Challenge Key**: Public key để verify
3. **Private Key**: Lưu tại `~/.blockcast/certs/gw_challenge.key`
4. **Registration Info**: Hardware ID + Challenge Key pair

### Best Practices
- Backup keys định kỳ
- Không share private key
- Ghi chú thông tin đăng ký cho mỗi node
- Test backup/restore process

## 📊 Performance Guidelines

### Resource Requirements
- **1 node**: 1GB RAM, 1 CPU core
- **2 nodes**: 2GB RAM, 2 CPU cores
- **3 nodes**: 4GB RAM, 2 CPU cores
- **4+ nodes**: 8GB+ RAM, 4+ CPU cores

### Port Allocation
- Node 1: 8080
- Node 2: 8081
- Node 3: 8082
- Node 4: 8083
- Node 5: 8084

## 🔄 Maintenance Tasks

### Daily
- Check node status
- Monitor logs for errors
- Verify connectivity on web portal

### Weekly
- Create backup
- Check disk usage
- Update Docker images (auto via watchtower)

### Monthly
- Rotate logs
- Clean unused Docker images
- Review node performance

## 🐛 Troubleshooting

### Common Issues
1. **Port conflicts**: Use different ports
2. **Docker permissions**: Add user to docker group
3. **Container not starting**: Check logs and dependencies
4. **Key generation fails**: Ensure node is running first

### Debug Commands
```bash
# Check containers
docker ps -a

# Check logs
./blockcast-multi-node-manager.sh logs beacon1

# Check Docker network
docker network ls

# Check volumes
docker volume ls
```

## 🎯 Future Improvements

### Planned Features
- [ ] Auto-restart on failure
- [ ] Resource monitoring
- [ ] Web dashboard
- [ ] Telegram/Discord notifications
- [ ] Performance metrics
- [ ] Auto-scaling

### Nice to Have
- [ ] GUI interface
- [ ] Mobile app monitoring
- [ ] Cloud deployment templates
- [ ] Kubernetes support

## 📝 Development Notes

### Code Style
- Bash scripting với error handling
- Colored output cho UX
- JSON config với jq parsing
- Modular functions
- Comprehensive logging

### Testing
- Test trên Ubuntu 20.04+
- Test với nhiều node configurations
- Test backup/restore scenarios
- Test error handling

## 🤝 Contributing

Để contribute vào dự án:
1. Fork repo
2. Tạo feature branch
3. Test thoroughly
4. Submit pull request

## 📞 Support

- **Blockcast Official**: https://blockcast.network/
- **Documentation**: https://docs.blockcast.network/
- **Web Portal**: https://app.blockcast.network/

---

**Tạo bởi**: AI Assistant để hỗ trợ cộng đồng Blockcast  
**Phiên bản**: 1.0  
**Cập nhật**: 2024-12-14 