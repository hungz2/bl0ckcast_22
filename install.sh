#!/bin/bash

# Script cài đặt tự động Blockcast Multi-Node Manager
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}   Blockcast Multi-Node Manager Installer${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

print_step() {
    echo -e "${YELLOW}[STEP] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

check_os() {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "Script này chỉ hỗ trợ Linux!"
        exit 1
    fi
    
    if ! command -v apt &> /dev/null && ! command -v yum &> /dev/null; then
        print_error "Script này yêu cầu apt (Ubuntu/Debian) hoặc yum (CentOS/RHEL)!"
        exit 1
    fi
}

install_docker() {
    print_step "Cài đặt Docker..."
    
    if command -v docker &> /dev/null; then
        print_success "Docker đã được cài đặt!"
        return 0
    fi
    
    # Cài đặt Docker
    curl -fsSL https://get.docker.com | sh
    
    # Thêm user vào group docker
    sudo usermod -aG docker $USER
    
    # Khởi động Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    
    print_success "Docker đã được cài đặt!"
}

install_docker_compose() {
    print_step "Cài đặt Docker Compose..."
    
    if docker compose version &> /dev/null; then
        print_success "Docker Compose plugin đã được cài đặt!"
        return 0
    fi
    
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose standalone đã được cài đặt!"
        return 0
    fi
    
    # Cài đặt Docker Compose plugin
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y docker-compose-plugin
    elif command -v yum &> /dev/null; then
        sudo yum install -y docker-compose-plugin
    fi
    
    print_success "Docker Compose đã được cài đặt!"
}

install_dependencies() {
    print_step "Cài đặt dependencies..."
    
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y curl wget jq git
    elif command -v yum &> /dev/null; then
        sudo yum install -y curl wget jq git
    fi
    
    print_success "Dependencies đã được cài đặt!"
}

setup_blockcast_manager() {
    print_step "Thiết lập Blockcast Multi-Node Manager..."
    
    # Tạo thư mục làm việc
    INSTALL_DIR="$HOME/blockcast-multi-node"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Thiết lập quyền thực thi
    chmod +x blockcast-multi-node-manager.sh
    
    # Chạy setup
    ./blockcast-multi-node-manager.sh setup
    
    print_success "Blockcast Multi-Node Manager đã được thiết lập!"
}

show_final_instructions() {
    print_header
    echo -e "${GREEN}🎉 Cài đặt thành công!${NC}"
    echo ""
    echo -e "${YELLOW}Đường dẫn cài đặt: ${BLUE}$HOME/blockcast-multi-node${NC}"
    echo ""
    echo -e "${YELLOW}Các bước tiếp theo:${NC}"
    echo -e "1. ${GREEN}cd ~/blockcast-multi-node${NC}"
    echo -e "2. ${GREEN}./blockcast-multi-node-manager.sh add-node${NC}  - Thêm node đầu tiên"
    echo -e "3. ${GREEN}./blockcast-multi-node-manager.sh start${NC}     - Khởi động tất cả node"
    echo -e "4. ${GREEN}./blockcast-multi-node-manager.sh init <node>${NC} - Generate keys"
    echo -e "5. ${GREEN}./blockcast-multi-node-manager.sh status${NC}    - Kiểm tra trạng thái"
    echo ""
    echo -e "${YELLOW}Để xem tất cả lệnh có sẵn:${NC}"
    echo -e "${GREEN}./blockcast-multi-node-manager.sh help${NC}"
    echo ""
    echo -e "${YELLOW}Lưu ý quan trọng:${NC}"
    echo -e "- Mỗi node cần port riêng (8080, 8081, 8082...)"
    echo -e "- Backup Hardware ID và Challenge Key của mỗi node"
    echo -e "- Đăng ký node trên https://app.blockcast.network/"
    echo -e "- Node cần online 6h để test connectivity"
    echo -e "- Node cần online 24h để bắt đầu kiếm reward"
    echo ""
    echo -e "${RED}⚠️ QUAN TRỌNG: Logout/login lại để Docker group có hiệu lực${NC}"
    echo -e "${YELLOW}Hoặc chạy: newgrp docker${NC}"
}

# Main execution
main() {
    print_header
    
    check_os
    install_dependencies
    install_docker
    install_docker_compose
    setup_blockcast_manager
    show_final_instructions
    
    echo ""
    echo -e "${GREEN}Cài đặt hoàn tất! Happy mining! 🚀${NC}"
}

# Chạy main function
main "$@" 