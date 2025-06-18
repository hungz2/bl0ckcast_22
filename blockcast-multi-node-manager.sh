#!/bin/bash

# Blockcast Multi-Node Manager Script
# Chạy nhiều Blockcast BEACON node trên 1 VPS

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cấu hình cơ bản
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODES_DIR="$SCRIPT_DIR/blockcast-nodes"
CONFIG_FILE="$SCRIPT_DIR/nodes-config.json"
DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/Blockcast/beacon-docker-compose/main/docker-compose.yml"

# Hiển thị header
print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}   Blockcast Multi-Node Manager${NC}"
    echo -e "${BLUE}=====================================${NC}"
}

# Hiển thị trợ giúp
show_help() {
    echo -e "${YELLOW}Cách sử dụng:${NC}"
    echo "  $0 setup                    - Thiết lập ban đầu"
    echo "  $0 add-node                 - Thêm node mới"
    echo "  $0 start [node-name]        - Khởi động node (hoặc tất cả)"
    echo "  $0 stop [node-name]         - Dừng node (hoặc tất cả)"
    echo "  $0 restart [node-name]      - Khởi động lại node"
    echo "  $0 status                   - Kiểm tra trạng thái tất cả node"
    echo "  $0 logs [node-name]         - Xem logs của node"
    echo "  $0 init [node-name]         - Generate keys cho node"
    echo "  $0 remove [node-name]       - Xóa node"
    echo "  $0 list                     - Liệt kê tất cả node"
    echo "  $0 backup                   - Backup cấu hình và keys"
    echo "  $0 test-proxy [proxy-url]   - Test proxy connection"
    echo "  $0 test-node-ip [node-name] - Kiểm tra IP của node"
    echo "  $0 proxy-stats              - Thống kê sử dụng proxy"
    echo "  $0 fix-compose [node-name]  - Sửa lỗi docker-compose.yml"
    echo ""
}

# Kiểm tra dependencies
check_dependencies() {
    echo -e "${YELLOW}Kiểm tra dependencies...${NC}"
    
    # Kiểm tra Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker chưa được cài đặt!${NC}"
        echo -e "${YELLOW}Cài đặt Docker:${NC}"
        echo "curl -fsSL https://get.docker.com | sh"
        echo "sudo usermod -aG docker \$USER"
        echo "newgrp docker"
        return 1
    fi
    
    # Kiểm tra Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}Docker Compose chưa được cài đặt!${NC}"
        echo -e "${YELLOW}Cài đặt Docker Compose:${NC}"
        echo "sudo apt install docker-compose-plugin"
        return 1
    fi
    
    # Kiểm tra jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}jq chưa được cài đặt. Đang cài đặt...${NC}"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt update && sudo apt install -y jq
        else
            echo "Vui lòng cài đặt jq thủ công"
            return 1
        fi
    fi
    
    # Kiểm tra curl
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}curl chưa được cài đặt. Đang cài đặt...${NC}"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt install -y curl
        else
            echo "Vui lòng cài đặt curl thủ công"
            return 1
        fi
    fi
    
    echo -e "${GREEN}Dependencies đã sẵn sàng!${NC}"
}

# Thiết lập ban đầu
setup_initial() {
    print_header
    echo -e "${YELLOW}Thiết lập ban đầu Blockcast Multi-Node Manager...${NC}"
    
    check_dependencies
    
    # Tạo thư mục
    mkdir -p "$NODES_DIR"
    
    # Tạo config file nếu chưa có
    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{"nodes": {}}' > "$CONFIG_FILE"
    fi
    
    echo -e "${GREEN}Thiết lập hoàn tất!${NC}"
    echo -e "${YELLOW}Bước tiếp theo: ./blockcast-multi-node-manager.sh add-node${NC}"
}

# Thêm node mới
add_node() {
    print_header
    echo -e "${YELLOW}Thêm Blockcast BEACON node mới...${NC}"
    
    # Nhập thông tin node
    read -p "Tên node: " node_name
    
    if [ -z "$node_name" ]; then
        echo -e "${RED}Tên node không được để trống!${NC}"
        return 1
    fi
    
    # Kiểm tra node đã tồn tại
    if jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' đã tồn tại!${NC}"
        return 1
    fi
    
    read -p "Watchtower port (mặc định 8080): " watchtower_port
    read -p "Proxy (http://ip:port hoặc để trống): " proxy
    read -p "Mô tả node (tùy chọn): " description
    
    watchtower_port=${watchtower_port:-8080}
    
    # Kiểm tra port có bị trùng không
    if jq -e ".nodes | to_entries[] | select(.value.watchtower_port == \"$watchtower_port\")" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Port $watchtower_port đã được sử dụng bởi node khác!${NC}"
        return 1
    fi
    
    # Kiểm tra proxy có bị trùng không (nếu có proxy)
    if [ -n "$proxy" ]; then
        if jq -e ".nodes | to_entries[] | select(.value.proxy == \"$proxy\" and .value.proxy != \"\")" "$CONFIG_FILE" &> /dev/null; then
            echo -e "${YELLOW}Cảnh báo: Proxy $proxy đã được sử dụng bởi node khác!${NC}"
            read -p "Bạn có muốn tiếp tục? (yes/no): " confirm_proxy
            if [ "$confirm_proxy" != "yes" ]; then
                echo -e "${YELLOW}Hủy bỏ thêm node.${NC}"
                return 0
            fi
        fi
        
        # Auto-fix proxy format
        if [[ ! "$proxy" =~ ^https?:// ]] && [[ ! "$proxy" =~ ^socks5?:// ]]; then
            echo -e "${YELLOW}Auto-fixing proxy format...${NC}"
            
            # Nếu proxy có dạng ip:port:user:pass, chuyển thành http://user:pass@ip:port
            if [[ "$proxy" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+:.+:.+ ]]; then
                IFS=':' read -r proxy_ip proxy_port proxy_user proxy_pass <<< "$proxy"
                proxy="http://${proxy_user}:${proxy_pass}@${proxy_ip}:${proxy_port}"
                echo -e "${GREEN}✅ Đã chuyển đổi thành: $proxy${NC}"
            # Nếu proxy chỉ có ip:port, thêm http://
            elif [[ "$proxy" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
                proxy="http://$proxy"
                echo -e "${GREEN}✅ Đã thêm protocol: $proxy${NC}"
            else
                echo -e "${YELLOW}Cảnh báo: Proxy format có thể không đúng. Định dạng khuyến nghị: http://ip:port${NC}"
            fi
        fi
    fi
    
    # Tạo thư mục node
    node_dir="$NODES_DIR/$node_name"
    mkdir -p "$node_dir"
    
    # Tạo docker-compose.yml cho node
    echo -e "${YELLOW}Tạo docker-compose.yml...${NC}"
    create_node_compose "$node_name" "$watchtower_port" "$proxy"
    
    # Lưu config
    jq ".nodes.\"$node_name\" = {
        \"watchtower_port\": \"$watchtower_port\",
        \"proxy\": \"$proxy\",
        \"description\": \"$description\",
        \"directory\": \"$node_dir\",
        \"created_at\": \"$(date -Iseconds)\"
    }" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    
    echo -e "${GREEN}Node '$node_name' đã được thêm thành công!${NC}"
    echo -e "${YELLOW}Bước tiếp theo:${NC}"
    echo -e "1. ./blockcast-multi-node-manager.sh start $node_name"
    echo -e "2. ./blockcast-multi-node-manager.sh init $node_name"
    echo -e "3. Đăng ký node trên https://app.blockcast.network/"
    
    if [ -n "$proxy" ]; then
        echo -e "${GREEN}✅ Node sử dụng proxy: $proxy${NC}"
        echo -e "${YELLOW}💡 Test proxy: curl --proxy $proxy https://google.com${NC}"
    fi
}

# Thêm proxy environment variables cho compose file
add_proxy_to_compose() {
    local compose_file="$1"
    local proxy="$2"
    
    # Thêm proxy environment cho x-service template
    if grep -q "x-service:" "$compose_file"; then
        # Thêm environment vào x-service template
        if ! grep -A 20 "x-service:" "$compose_file" | grep -q "environment:"; then
            sed -i "/x-service:/,/^[[:space:]]*image:/ {
                /image:/a\\  environment:\\    - HTTP_PROXY=$proxy\\    - HTTPS_PROXY=$proxy\\    - NO_PROXY=localhost,127.0.0.1
            }" "$compose_file"
        fi
    fi
    
    # Thêm environment cho watchtower service
    if ! grep -A 10 "watchtower:" "$compose_file" | grep -q "HTTP_PROXY"; then
        sed -i "/watchtower:/,/^[[:space:]]*[a-zA-Z_]/ {
            /environment:/a\\      HTTP_PROXY: \"$proxy\"\\      HTTPS_PROXY: \"$proxy\"\\      NO_PROXY: \"localhost,127.0.0.1\"
        }" "$compose_file"
        
        # Nếu watchtower chưa có environment section
        if ! grep -A 10 "watchtower:" "$compose_file" | grep -q "environment:"; then
            sed -i "/watchtower:/,/^[[:space:]]*[a-zA-Z_]/ {
                /WATCHTOWER_LABEL_ENABLE:/a\\    environment:\\      HTTP_PROXY: \"$proxy\"\\      HTTPS_PROXY: \"$proxy\"\\      NO_PROXY: \"localhost,127.0.0.1\"
            }" "$compose_file"
        fi
    fi
}

# Tạo docker-compose.yml cho node cụ thể
create_node_compose() {
    local node_name="$1"
    local port="$2"
    local proxy="$3"
    
    local compose_dir="${NODES_DIR}/${node_name}"
    local compose_file="${compose_dir}/docker-compose.yml"
    
    # Tạo nội dung docker-compose.yml chỉ thay đổi proxy, port và container names
    cat > "$compose_file" << EOF
x-service: &service
  image: blockcast/cdn_gateway_go:\${IMAGE_VERSION:-stable}
  restart: unless-stopped
  network_mode: "service:blockcastd"
  volumes:
    - \${HOME}/.blockcast/certs:/var/opt/magma/certs
    - \${HOME}/.blockcast/snowflake:/etc/snowflake
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
EOF
    
    # Thêm proxy environment nếu có
    if [ -n "$proxy" ]; then
        cat >> "$compose_file" << EOF
  environment:
    - HTTP_PROXY=$proxy
    - HTTPS_PROXY=$proxy
    - NO_PROXY=localhost,127.0.0.1
    - http_proxy=$proxy
    - https_proxy=$proxy
    - no_proxy=localhost,127.0.0.1
EOF
    fi
    
    # Services section - chỉ thay đổi container names và port
    cat >> "$compose_file" << EOF

services:
  control_proxy:
    <<: *service
    container_name: ${node_name}-control_proxy
    command: /usr/bin/control_proxy

  blockcastd:
    <<: *service
    container_name: ${node_name}-blockcastd
    command: /usr/bin/blockcastd -logtostderr=true -v=0
    network_mode: bridge

  beacond:
    <<: *service
    container_name: ${node_name}-beacond
    command: /usr/bin/beacond -logtostderr=true -v=0

  watchtower:
    image: containrrr/watchtower
    container_name: ${node_name}-watchtower
    restart: unless-stopped
    environment:
      - WATCHTOWER_LABEL_ENABLE=true
EOF
    
    # Thêm proxy environment cho watchtower nếu có
    if [ -n "$proxy" ]; then
        cat >> "$compose_file" << EOF
      - HTTP_PROXY=$proxy
      - HTTPS_PROXY=$proxy
      - NO_PROXY=localhost,127.0.0.1
      - http_proxy=$proxy
      - https_proxy=$proxy
      - no_proxy=localhost,127.0.0.1
EOF
    fi
    
    # Kết thúc watchtower với volumes và ports
    cat >> "$compose_file" << EOF
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "${port}:8080"
EOF
}

# Modify docker-compose.yml để thay đổi port và proxy
modify_docker_compose() {
    local compose_file="$1"
    local new_port="$2"
    local node_name="$3"
    local proxy="$4"
    
    # Sử dụng create_node_compose để tạo file mới
    create_node_compose "$node_name" "$new_port" "$proxy"
}

# Khởi động node
start_node() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${YELLOW}Khởi động tất cả node...${NC}"
        jq -r '.nodes | keys[]' "$CONFIG_FILE" | while read -r name; do
            start_single_node "$name"
        done
    else
        start_single_node "$node_name"
    fi
}

# Khởi động một node
start_single_node() {
    local node_name="$1"
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    local node_dir=$(jq -r ".nodes.\"$node_name\".directory" "$CONFIG_FILE")
    
    if [ ! -f "$node_dir/docker-compose.yml" ]; then
        echo -e "${RED}Không tìm thấy docker-compose.yml cho node '$node_name'!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Khởi động node '$node_name'...${NC}"
    
    cd "$node_dir"
    
    # Sử dụng docker compose (phiên bản mới) hoặc docker-compose (phiên bản cũ)
    if docker compose version &> /dev/null; then
        docker compose up -d
    else
        docker-compose up -d
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Node '$node_name' đã khởi động thành công!${NC}"
        echo -e "${YELLOW}Kiểm tra trạng thái: docker compose ps${NC}"
    else
        echo -e "${RED}Lỗi khởi động node '$node_name'!${NC}"
    fi
}

# Dừng node
stop_node() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${YELLOW}Dừng tất cả node...${NC}"
        jq -r '.nodes | keys[]' "$CONFIG_FILE" | while read -r name; do
            stop_single_node "$name"
        done
    else
        stop_single_node "$node_name"
    fi
}

# Dừng một node
stop_single_node() {
    local node_name="$1"
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    local node_dir=$(jq -r ".nodes.\"$node_name\".directory" "$CONFIG_FILE")
    
    echo -e "${YELLOW}Dừng node '$node_name'...${NC}"
    
    cd "$node_dir"
    
    if docker compose version &> /dev/null; then
        docker compose down
    else
        docker-compose down
    fi
    
    echo -e "${GREEN}Node '$node_name' đã dừng!${NC}"
}

# Khởi động lại node
restart_node() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${YELLOW}Khởi động lại tất cả node...${NC}"
        stop_node
        sleep 3
        start_node
    else
        echo -e "${YELLOW}Khởi động lại node '$node_name'...${NC}"
        stop_single_node "$node_name"
        sleep 3
        start_single_node "$node_name"
    fi
}

# Generate keys cho node
init_node() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${RED}Vui lòng chỉ định tên node!${NC}"
        return 1
    fi
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    local node_dir=$(jq -r ".nodes.\"$node_name\".directory" "$CONFIG_FILE")
    
    echo -e "${YELLOW}Generate keys cho node '$node_name'...${NC}"
    echo -e "${YELLOW}Đảm bảo node đã được khởi động trước!${NC}"
    
    cd "$node_dir"
    
    if docker compose version &> /dev/null; then
        docker compose exec blockcastd blockcastd init
    else
        docker-compose exec blockcastd blockcastd init
    fi
    
    echo -e "${GREEN}Keys đã được generate!${NC}"
    echo -e "${YELLOW}Lưu ý quan trọng:${NC}"
    echo -e "1. Backup Hardware ID và Challenge Key"
    echo -e "2. Backup private key tại ~/.blockcast/certs/gw_challenge.key"
    echo -e "3. Sử dụng Registration URL để đăng ký node"
    echo -e "4. Hoặc truy cập https://app.blockcast.network/register"
}

# Kiểm tra trạng thái
check_status() {
    print_header
    echo -e "${YELLOW}Trạng thái các Blockcast BEACON node:${NC}"
    echo ""
    
    if [ ! -f "$CONFIG_FILE" ] || [ "$(jq '.nodes | length' "$CONFIG_FILE")" -eq 0 ]; then
        echo -e "${RED}Không có node nào được cấu hình!${NC}"
        return 0
    fi
    
    printf "%-15s %-10s %-15s %-15s %-20s\n" "NODE NAME" "STATUS" "PORT" "PROXY" "DESCRIPTION"
    echo "============================================================================="
    
    jq -r '.nodes | to_entries[] | "\(.key) \(.value.watchtower_port) \(.value.proxy) \(.value.description)"' "$CONFIG_FILE" | while read -r name port proxy description; do
        local node_dir=$(jq -r ".nodes.\"$name\".directory" "$CONFIG_FILE")
        
        cd "$node_dir" 2>/dev/null || continue
        
        # Kiểm tra container status
        local containers_running=0
        local total_containers=4  # watchtower, beacond, blockcastd, control_proxy
        
        # Sử dụng docker compose ps thông thường thay vì --format json
        if docker compose ps 2>/dev/null | grep -q "Up"; then
            containers_running=$(docker compose ps 2>/dev/null | grep -c "Up")
        elif docker-compose ps 2>/dev/null | grep -q "Up"; then
            containers_running=$(docker-compose ps 2>/dev/null | grep -c "Up")
        fi
        
        if [ "$containers_running" -eq "$total_containers" ]; then
            status="${GREEN}RUNNING${NC}"
        elif [ "$containers_running" -gt 0 ]; then
            status="${YELLOW}PARTIAL${NC}"
        else
            status="${RED}STOPPED${NC}"
        fi
        
        # Hiển thị proxy (rút gọn nếu quá dài)
        local proxy_display="$proxy"
        if [ -n "$proxy" ] && [ ${#proxy} -gt 15 ]; then
            proxy_display="${proxy:0:12}..."
        elif [ -z "$proxy" ]; then
            proxy_display="None"
        fi
        
        printf "%-15s %-10s %-15s %-15s %-20s\n" "$name" "$status" "$port" "$proxy_display" "$description"
    done
}

# Xem logs
view_logs() {
    local node_name="$1"
    local service="$2"
    
    if [ -z "$node_name" ]; then
        echo -e "${RED}Vui lòng chỉ định tên node!${NC}"
        echo -e "${YELLOW}Sử dụng: $0 logs <node-name> [service]${NC}"
        echo -e "${YELLOW}Services: blockcastd, beacond, control_proxy, watchtower${NC}"
        return 1
    fi
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    local node_dir=$(jq -r ".nodes.\"$node_name\".directory" "$CONFIG_FILE")
    
    cd "$node_dir"
    
    if [ -z "$service" ]; then
        echo -e "${YELLOW}Xem logs tất cả services của node '$node_name'${NC}"
        if docker compose version &> /dev/null; then
            docker compose logs -f
        else
            docker-compose logs -f
        fi
    else
        echo -e "${YELLOW}Xem logs service '$service' của node '$node_name'${NC}"
        if docker compose version &> /dev/null; then
            docker compose logs -f "$service"
        else
            docker-compose logs -f "$service"
        fi
    fi
}

# Xóa node
remove_node() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${RED}Vui lòng chỉ định tên node!${NC}"
        return 1
    fi
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}CẢNH BÁO: Bạn sắp xóa node '$node_name'${NC}"
    echo -e "${RED}Điều này sẽ xóa tất cả dữ liệu và cấu hình của node!${NC}"
    read -p "Bạn có chắc chắn? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Hủy bỏ xóa node.${NC}"
        return 0
    fi
    
    # Dừng node trước
    stop_single_node "$node_name"
    
    # Xóa containers và volumes
    local node_dir=$(jq -r ".nodes.\"$node_name\".directory" "$CONFIG_FILE")
    cd "$node_dir"
    
    if docker compose version &> /dev/null; then
        docker compose down -v --remove-orphans
    else
        docker-compose down -v --remove-orphans
    fi
    
    # Xóa thư mục
    if [ -d "$node_dir" ]; then
        rm -rf "$node_dir"
    fi
    
    # Xóa khỏi config
    jq "del(.nodes.\"$node_name\")" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    
    echo -e "${GREEN}Node '$node_name' đã được xóa hoàn toàn!${NC}"
}

# Liệt kê node
list_nodes() {
    print_header
    echo -e "${YELLOW}Danh sách các Blockcast BEACON node:${NC}"
    echo ""
    
    if [ ! -f "$CONFIG_FILE" ] || [ "$(jq '.nodes | length' "$CONFIG_FILE")" -eq 0 ]; then
        echo -e "${RED}Không có node nào được cấu hình!${NC}"
        return 0
    fi
    
    jq -r '.nodes | to_entries[] | "Node: \(.key)\n  Port: \(.value.watchtower_port)\n  Proxy: \(.value.proxy // "None")\n  Description: \(.value.description)\n  Created: \(.value.created_at)\n  Directory: \(.value.directory)\n"' "$CONFIG_FILE"
}

# Backup cấu hình
backup_config() {
    local backup_dir="$SCRIPT_DIR/backups"
    local backup_file="blockcast-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "$backup_dir"
    
    echo -e "${YELLOW}Tạo backup...${NC}"
    
    tar -czf "$backup_dir/$backup_file" \
        -C "$SCRIPT_DIR" \
        nodes-config.json \
        blockcast-nodes/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup thành công: $backup_dir/$backup_file${NC}"
        echo -e "${YELLOW}Backup bao gồm:${NC}"
        echo -e "- File cấu hình nodes"
        echo -e "- Docker compose files"
        echo -e "- Dữ liệu containers"
    else
        echo -e "${RED}Lỗi tạo backup!${NC}"
    fi
}

# Test proxy của node
test_proxy() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${RED}Vui lòng chỉ định tên node!${NC}"
        return 1
    fi
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    local proxy=$(jq -r ".nodes.\"$node_name\".proxy" "$CONFIG_FILE")
    
    if [ -z "$proxy" ] || [ "$proxy" = "null" ]; then
        echo -e "${YELLOW}Node '$node_name' không sử dụng proxy.${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Testing proxy $proxy cho node '$node_name'...${NC}"
    
    # Test basic connectivity
    if curl --proxy "$proxy" --connect-timeout 10 --max-time 30 -s https://google.com > /dev/null; then
        echo -e "${GREEN}✅ Proxy hoạt động tốt!${NC}"
        
        # Get IP thông qua proxy
        local proxy_ip=$(curl --proxy "$proxy" --connect-timeout 10 --max-time 30 -s https://ipinfo.io/ip 2>/dev/null)
        if [ -n "$proxy_ip" ]; then
            echo -e "${GREEN}🌐 IP thông qua proxy: $proxy_ip${NC}"
        fi
        
        # Get location thông qua proxy
        local location=$(curl --proxy "$proxy" --connect-timeout 10 --max-time 30 -s https://ipinfo.io/country 2>/dev/null)
        if [ -n "$location" ]; then
            echo -e "${GREEN}📍 Location: $location${NC}"
        fi
    else
        echo -e "${RED}❌ Proxy không hoạt động hoặc không thể kết nối!${NC}"
        echo -e "${YELLOW}Kiểm tra lại:${NC}"
        echo -e "- Format proxy: http://ip:port hoặc socks5://ip:port"
        echo -e "- Proxy server có hoạt động không"
        echo -e "- Firewall/network restrictions"
    fi
}

# Thống kê sử dụng proxy
proxy_stats() {
    print_header
    echo -e "${YELLOW}Thống kê sử dụng proxy:${NC}"
    echo ""
    
    if [ ! -f "$CONFIG_FILE" ] || [ "$(jq '.nodes | length' "$CONFIG_FILE")" -eq 0 ]; then
        echo -e "${RED}Không có node nào được cấu hình!${NC}"
        return 0
    fi
    
    local total_nodes=$(jq '.nodes | length' "$CONFIG_FILE")
    local nodes_with_proxy=$(jq '.nodes | to_entries[] | select(.value.proxy != null and .value.proxy != "")' "$CONFIG_FILE" | jq -s 'length')
    local nodes_without_proxy=$((total_nodes - nodes_with_proxy))
    
    echo -e "${BLUE}📊 Tổng quan:${NC}"
    echo -e "  Tổng số node: $total_nodes"
    echo -e "  Node có proxy: $nodes_with_proxy"
    echo -e "  Node không proxy: $nodes_without_proxy"
    echo ""
    
    if [ $nodes_with_proxy -gt 0 ]; then
        echo -e "${BLUE}🔗 Danh sách proxy đang sử dụng:${NC}"
        jq -r '.nodes | to_entries[] | select(.value.proxy != null and .value.proxy != "") | "  \(.key): \(.value.proxy)"' "$CONFIG_FILE"
        echo ""
        
        # Kiểm tra proxy trùng lặp
        local unique_proxies=$(jq -r '.nodes | to_entries[] | select(.value.proxy != null and .value.proxy != "") | .value.proxy' "$CONFIG_FILE" | sort | uniq | wc -l)
        local total_proxies=$nodes_with_proxy
        
        if [ $unique_proxies -lt $total_proxies ]; then
            echo -e "${YELLOW}⚠️  Cảnh báo: Có $(($total_proxies - $unique_proxies)) proxy bị trùng lặp!${NC}"
            echo -e "${YELLOW}Proxy trùng lặp:${NC}"
            jq -r '.nodes | to_entries[] | select(.value.proxy != null and .value.proxy != "") | .value.proxy' "$CONFIG_FILE" | sort | uniq -d | while read -r dup_proxy; do
                echo -e "  🔄 $dup_proxy được sử dụng bởi:"
                jq -r ".nodes | to_entries[] | select(.value.proxy == \"$dup_proxy\") | \"    - \(.key)\"" "$CONFIG_FILE"
            done
            echo ""
        else
            echo -e "${GREEN}✅ Tất cả proxy đều unique!${NC}"
            echo ""
        fi
    fi
    
    echo -e "${BLUE}💡 Khuyến nghị:${NC}"
    echo -e "  - Mỗi node nên sử dụng proxy riêng để tránh rate limit"
    echo -e "  - Test proxy định kỳ: ./blockcast-multi-node-manager.sh test-proxy <node>"
    echo -e "  - Sử dụng proxy ở các quốc gia khác nhau"
}

# Fix docker-compose.yml bị lỗi
fix_compose() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${RED}Vui lòng chỉ định tên node!${NC}"
        return 1
    fi
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    local node_dir=$(jq -r ".nodes.\"$node_name\".directory" "$CONFIG_FILE")
    local compose_file="$node_dir/docker-compose.yml"
    
    if [ ! -f "$compose_file" ]; then
        echo -e "${RED}Không tìm thấy docker-compose.yml cho node '$node_name'!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Đang sửa lỗi docker-compose.yml cho node '$node_name'...${NC}"
    
    # Backup file hiện tại
    cp "$compose_file" "$compose_file.backup"
    
    # Khôi phục từ file original nếu có
    if [ -f "$compose_file.original" ]; then
        echo -e "${YELLOW}Khôi phục từ file original...${NC}"
        cp "$compose_file.original" "$compose_file"
    else
        echo -e "${YELLOW}Tải lại docker-compose.yml từ GitHub...${NC}"
        if ! curl -fsSL "$DOCKER_COMPOSE_URL" -o "$compose_file"; then
            echo -e "${RED}Không thể tải docker-compose.yml!${NC}"
            # Khôi phục backup
            cp "$compose_file.backup" "$compose_file"
            return 1
        fi
    fi
    
    # Lấy thông tin node
    local watchtower_port=$(jq -r ".nodes.\"$node_name\".watchtower_port" "$CONFIG_FILE")
    local proxy=$(jq -r ".nodes.\"$node_name\".proxy" "$CONFIG_FILE")
    
    # Apply modifications lại
    modify_docker_compose "$compose_file" "$watchtower_port" "$node_name" "$proxy"
    
    echo -e "${GREEN}✅ Đã sửa lỗi docker-compose.yml thành công!${NC}"
    echo -e "${YELLOW}File backup được lưu tại: $compose_file.backup${NC}"
    
    # Test syntax
    cd "$node_dir"
    if docker compose config >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker-compose syntax hợp lệ!${NC}"
        echo -e "${YELLOW}Bạn có thể khởi động node: ./blockcast-multi-node-manager.sh start $node_name${NC}"
    else
        echo -e "${RED}❌ Vẫn còn lỗi syntax. Kiểm tra lại file docker-compose.yml${NC}"
    fi
}

# Test proxy connection
test_proxy() {
    local proxy="$1"
    
    if [ -z "$proxy" ]; then
        echo -e "${RED}Vui lòng cung cấp proxy để test!${NC}"
        echo -e "${YELLOW}Sử dụng: $0 test-proxy <proxy_url>${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Testing proxy: $proxy${NC}"
    
    # Test kết nối cơ bản
    if curl --proxy "$proxy" --connect-timeout 10 -s https://httpbin.org/ip > /dev/null; then
        echo -e "${GREEN}✅ Proxy kết nối thành công!${NC}"
        
        # Lấy IP qua proxy
        local proxy_ip=$(curl --proxy "$proxy" --connect-timeout 10 -s https://httpbin.org/ip | jq -r '.origin' 2>/dev/null)
        if [ -n "$proxy_ip" ] && [ "$proxy_ip" != "null" ]; then
            echo -e "${GREEN}🌐 IP qua proxy: $proxy_ip${NC}"
        fi
        
        # Lấy IP trực tiếp (không qua proxy)
        local direct_ip=$(curl --connect-timeout 10 -s https://httpbin.org/ip | jq -r '.origin' 2>/dev/null)
        if [ -n "$direct_ip" ] && [ "$direct_ip" != "null" ]; then
            echo -e "${BLUE}🏠 IP trực tiếp: $direct_ip${NC}"
        fi
        
        # So sánh
        if [ "$proxy_ip" != "$direct_ip" ]; then
            echo -e "${GREEN}✅ Proxy đang hoạt động - IP khác nhau${NC}"
        else
            echo -e "${YELLOW}⚠️  Cảnh báo: IP giống nhau, proxy có thể không hoạt động${NC}"
        fi
        
    else
        echo -e "${RED}❌ Proxy không thể kết nối!${NC}"
        return 1
    fi
}

# Test IP của node
test_node_ip() {
    local node_name="$1"
    
    if [ -z "$node_name" ]; then
        echo -e "${RED}Vui lòng chỉ định tên node!${NC}"
        return 1
    fi
    
    if ! jq -e ".nodes.\"$node_name\"" "$CONFIG_FILE" &> /dev/null; then
        echo -e "${RED}Node '$node_name' không tồn tại!${NC}"
        return 1
    fi
    
    local node_dir=$(jq -r ".nodes.\"$node_name\".directory" "$CONFIG_FILE")
    local proxy=$(jq -r ".nodes.\"$node_name\".proxy // empty" "$CONFIG_FILE")
    
    echo -e "${YELLOW}Kiểm tra IP của node '$node_name'...${NC}"
    
    if [ -n "$proxy" ]; then
        echo -e "${BLUE}Node được cấu hình proxy: $proxy${NC}"
    else
        echo -e "${BLUE}Node không sử dụng proxy${NC}"
    fi
    
    cd "$node_dir"
    
    # Kiểm tra container có đang chạy không
    if docker compose version &> /dev/null; then
        if ! docker compose ps | grep -q "Up"; then
            echo -e "${RED}Node chưa được khởi động!${NC}"
            return 1
        fi
        
        # Test IP từ trong container
        echo -e "${YELLOW}Testing IP từ container beacond...${NC}"
        local container_ip=$(docker compose exec -T beacond curl -s --connect-timeout 5 https://httpbin.org/ip 2>/dev/null | jq -r '.origin' 2>/dev/null)
        
        if [ -n "$container_ip" ] && [ "$container_ip" != "null" ]; then
            echo -e "${GREEN}🔍 IP từ container: $container_ip${NC}"
        else
            echo -e "${YELLOW}⚠️  Không thể lấy IP từ container${NC}"
        fi
        
        # So sánh với IP host
        local host_ip=$(curl -s --connect-timeout 5 https://httpbin.org/ip | jq -r '.origin' 2>/dev/null)
        if [ -n "$host_ip" ] && [ "$host_ip" != "null" ]; then
            echo -e "${BLUE}🏠 IP của host: $host_ip${NC}"
            
            if [ "$container_ip" != "$host_ip" ]; then
                echo -e "${GREEN}✅ Container đang sử dụng IP khác với host${NC}"
            else
                echo -e "${YELLOW}⚠️  Container đang sử dụng cùng IP với host${NC}"
            fi
        fi
        
        # Nếu có proxy, test xem proxy có hoạt động không
        if [ -n "$proxy" ]; then
            echo -e "${YELLOW}Testing proxy trực tiếp...${NC}"
            test_proxy "$proxy"
        fi
        
    else
        echo -e "${RED}Docker compose không có sẵn!${NC}"
        return 1
    fi
}

# Main function
main() {
    case "$1" in
        "setup")
            setup_initial
            ;;
        "add-node")
            add_node
            ;;
        "start")
            start_node "$2"
            ;;
        "stop")
            stop_node "$2"
            ;;
        "restart")
            restart_node "$2"
            ;;
        "status")
            check_status
            ;;
        "logs")
            view_logs "$2" "$3"
            ;;
        "init")
            init_node "$2"
            ;;
        "remove")
            remove_node "$2"
            ;;
        "list")
            list_nodes
            ;;
        "backup")
            backup_config
            ;;
        "test-proxy")
            test_proxy "$2"
            ;;
        "test-node-ip")
            test_node_ip "$2"
            ;;
        "proxy-stats")
            proxy_stats
            ;;
        "fix-compose")
            fix_compose "$2"
            ;;
        "help"|"--help"|"-h"|"")
            print_header
            show_help
            ;;
        *)
            echo -e "${RED}Lệnh không hợp lệ: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Chạy main function
main "$@"