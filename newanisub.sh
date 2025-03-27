#!/bin/bash

# Cấu hình màu sắc
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)
BOLD=$(tput bold)

# Cấu hình thư mục
CONFIG_DIR="$HOME/.config/animeanisub"
CACHE_DIR="$CONFIG_DIR/cache"
DOWNLOAD_DIR="$HOME/anime"
CONFIG_FILE="$CONFIG_DIR/config"
DEPENDENCIES_FILE="$CONFIG_DIR/dependencies_installed"

# Khởi tạo thư mục và file cấu hình
init_config() {
    mkdir -p "$CONFIG_DIR" "$CACHE_DIR" "$DOWNLOAD_DIR"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<- EOM
# Anime Player Pro Configuration
DEFAULT_SOURCE="ophim"
QUALITY="best"
THEME="dark"
MAX_CACHE_AGE=24 # hours
EOM
    fi
    
    source "$CONFIG_FILE"
}

# Kiểm tra và cài đặt phụ thuộc
check_dependencies() {
    local missing=()
    local required=("mpv" "yt-dlp" "ffmpeg" "pup" "jq" "fzf" "curl")
    
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "${RED}${BOLD}Các công cụ sau chưa được cài đặt:${RESET} ${missing[*]}"
        
        # Kiểm tra xem đã từng cài đặt chưa
        if [[ -f "$DEPENDENCIES_FILE" ]]; then
            echo "${YELLOW}Bạn đã từ chối cài đặt trước đó. Tiếp tục mà không cài đặt.${RESET}"
            return
        fi
        
        read -p "${BOLD}Bạn có muốn cài đặt các phụ thuộc này không? (y/n): ${RESET}" choice
        
        case $choice in
            y|Y)
                install_dependencies "${missing[@]}"
                touch "$DEPENDENCIES_FILE"
                ;;
            *)
                echo "${YELLOW}Tiếp tục mà không cài đặt các phụ thuộc. Một số tính năng có thể không hoạt động.${RESET}"
                return
                ;;
        esac
    fi
}

# Cài đặt các phụ thuộc
install_dependencies() {
    local missing=("$@")
    local package_manager=""
    
    # Xác định trình quản lý gói
    if command -v apt &> /dev/null; then
        package_manager="apt"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v dnf &> /dev/null; then
        package_manager="dnf"
    elif command -v pacman &> /dev/null; then
        package_manager="pacman"
    elif command -v brew &> /dev/null; then
        package_manager="brew"
    else
        echo "${RED}Không thể xác định trình quản lý gói!${RESET}"
        return 1
    fi
    
    echo "${YELLOW}Đang cài đặt các phụ thuộc...${RESET}"
    
    for cmd in "${missing[@]}"; do
        case $cmd in
            "mpv")
                sudo $package_manager install -y mpv
                ;;
            "yt-dlp")
                sudo $package_manager install -y yt-dlp || {
                    sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
                    sudo chmod a+rx /usr/local/bin/yt-dlp
                }
                ;;
            "ffmpeg")
                sudo $package_manager install -y ffmpeg
                ;;
            "pup")
                # Thử cài đặt từ trình quản lý gói trước
                if ! sudo $package_manager install -y pup 2>/dev/null; then
                    echo "${YELLOW}Cài đặt pup từ Go...${RESET}"
                    if command -v go &>/dev/null; then
                        go install github.com/ericchiang/pup@latest
                        sudo mv "$HOME/go/bin/pup" /usr/local/bin/
                    else
                        echo "${RED}Không thể cài đặt pup do thiếu Go.${RESET}"
                    fi
                fi
                ;;
            "jq")
                sudo $package_manager install -y jq
                ;;
            "fzf")
                sudo $package_manager install -y fzf
                ;;
            "curl")
                sudo $package_manager install -y curl
                ;;
            *)
                echo "${RED}Không biết cách cài đặt: $cmd${RESET}"
                ;;
        esac
    done
    
    echo "${GREEN}Đã cài đặt xong các phụ thuộc!${RESET}"
    sleep 2
}

# Cache API responses
cache_api() {
    local key="$1"
    local cmd="$2"
    local cache_file="$CACHE_DIR/${key}.cache"
    local cache_age=$((MAX_CACHE_AGE * 60))
    
    if [[ -f "$cache_file" && $(find "$cache_file" -mmin +$cache_age 2>/dev/null) ]]; then
        rm -f "$cache_file"
    fi
    
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
    else
        eval "$cmd" | tee "$cache_file"
    fi
}

# Tìm kiếm anime
search_anime() {
    local keyword="$1"
    local source="$2"
    
    case "$source" in
        "ophim")
            local search_url="https://ophim17.cc/tim-kiem?keyword=${keyword}"
            cache_api "search_${keyword}_ophim" "curl -s '$search_url'"
            ;;
        "anidata")
            local csv_url="https://raw.githubusercontent.com/toilamsao/anidata/main/data.csv"
            cache_api "anidata_csv" "curl -s '$csv_url' | sed 's/\"//g'"
            ;;
        *)
            echo "${RED}Nguồn không được hỗ trợ: $source${RESET}" >&2
            return 1
            ;;
    esac
}

# Hiển thị menu chính
show_main_menu() {
    while true; do
        clear
        echo "${BOLD}${CYAN}ANIME PLAYER PRO${RESET}"
        echo "${GREEN}1. Xem Anime${RESET}"
        echo "${GREEN}2. Đọc Manga${RESET}"
        echo "${GREEN}3. Cài đặt${RESET}"
        echo "${RED}4. Thoát${RESET}"
        
        read -p "${BOLD}Chọn chức năng [1-4]: ${RESET}" choice
        
        case $choice in
            1) play_anime_menu ;;
            2) read_manga ;;
            3) settings_menu ;;
            4) exit 0 ;;
            *) echo "${RED}Lựa chọn không hợp lệ!${RESET}"; sleep 1 ;;
        esac
    done
}

# Menu phát anime
play_anime_menu() {
    while true; do
        clear
        echo "${BOLD}${CYAN}XEM ANIME${RESET}"
        echo "${GREEN}1. Tìm kiếm Anime${RESET}"
        echo "${GREEN}2. Xem từ URL${RESET}"
        echo "${GREEN}3. Lịch sử xem${RESET}"
        echo "${YELLOW}4. Quay lại${RESET}"
        
        read -p "${BOLD}Chọn chức năng [1-4]: ${RESET}" choice
        
        case $choice in
            1) search_and_play ;;
            2) play_from_url ;;
            3) show_history ;;
            4) return ;;
            *) echo "${RED}Lựa chọn không hợp lệ!${RESET}"; sleep 1 ;;
        esac
    done
}

# Tìm kiếm và phát anime
search_and_play() {
    read -p "${BOLD}Nhập tên anime: ${RESET}" query
    
    if [[ -z "$query" ]]; then
        echo "${RED}Tên anime không được để trống!${RESET}"
        sleep 1
        return
    fi
    
    local source_options=("ophim" "anidata")
    local source
    source=$(printf "%s\n" "${source_options[@]}" | fzf --prompt="Chọn nguồn: ")
    
    if [[ -z "$source" ]]; then
        return
    fi
    
    echo "${YELLOW}Đang tìm kiếm...${RESET}"
    
    case "$source" in
        "ophim")
            local results=$(search_anime "$query" "ophim")
            local anime_list=$(echo "$results" | pup '.ml-4 > a attr{href}' | awk '{print "https://ophim17.cc" $0}')
            
            if [[ -z "$anime_list" ]]; then
                echo "${RED}Không tìm thấy anime nào!${RESET}"
                sleep 1
                return
            fi
            
            local selected=$(echo "$anime_list" | fzf --prompt="Chọn anime: " --preview="echo 'Đang tải thông tin...'; curl -s {} | pup 'h1, .description text{}'")
            
            if [[ -n "$selected" ]]; then
                play_anime "$selected" "ophim"
            fi
            ;;
        "anidata")
            local csv_data=$(search_anime "$query" "anidata")
            local anime_list=$(echo "$csv_data" | awk -F',' 'NR>1 {print $1}' | sort -u)
            
            if [[ -z "$anime_list" ]]; then
                echo "${RED}Không tìm thấy anime nào!${RESET}"
                sleep 1
                return
            fi
            
            local selected_anime=$(echo "$anime_list" | fzf --prompt="Chọn anime: ")
            
            if [[ -n "$selected_anime" ]]; then
                local episodes=$(echo "$csv_data" | awk -F',' -v anime="$selected_anime" '$1 == anime {print $2 " | " $3}')
                local selected_episode=$(echo "$episodes" | fzf --prompt="Chọn tập: ")
                
                if [[ -n "$selected_episode" ]]; then
                    local url=$(echo "$selected_episode" | awk -F' | ' '{print $3}')
                    mpv "$url"
                fi
            fi
            ;;
    esac
}

# Phát anime từ URL
play_from_url() {
    read -p "${BOLD}Nhập URL anime: ${RESET}" url
    
    if [[ -z "$url" ]]; then
        echo "${RED}URL không được để trống!${RESET}"
        sleep 1
        return
    fi
    
    if [[ "$url" == *"ophim"* ]]; then
        play_anime "$url" "ophim"
    else
        echo "${YELLOW}Đang phát trực tiếp...${RESET}"
        mpv "$url"
    fi
}

# Phát anime với các tập
play_anime() {
    local url="$1"
    local source="$2"
    
    case "$source" in
        "ophim")
            local html_content=$(curl -s "$url")
            local title=$(echo "$html_content" | pup 'h1 text{}' | tr -d '\n')
            local episodes=$(echo "$html_content" | pup 'script json{}' | jq -r '.[].text | @text' | grep -oE '"(http|https)://[^"]*index.m3u8"' | sed 's/"//g' | awk '{print NR "|" $0}')
            
            if [[ -z "$episodes" ]]; then
                echo "${RED}Không tìm thấy tập phim nào!${RESET}"
                sleep 1
                return
            fi
            
            local selected=$(echo "$episodes" | fzf --prompt="Chọn tập: " --preview="echo 'Tập '{} | awk -F'|' '{print \$1}'")
            
            if [[ -n "$selected" ]]; then
                local ep_num=$(echo "$selected" | awk -F'|' '{print $1}')
                local ep_url=$(echo "$selected" | awk -F'|' '{print $2}')
                
                while true; do
                    echo "${CYAN}Đang phát: ${BOLD}$title - Tập $ep_num${RESET}"
                    mpv "$ep_url"
                    
                    local options=("Tập tiếp" "Tập trước" "Chọn tập khác" "Quay lại")
                    local choice=$(printf "%s\n" "${options[@]}" | fzf --prompt="Chọn hành động: ")
                    
                    case "$choice" in
                        "Tập tiếp")
                            ep_num=$((ep_num + 1))
                            ep_url=$(echo "$episodes" | awk -F'|' -v num="$ep_num" '$1 == num {print $2}')
                            if [[ -z "$ep_url" ]]; then
                                echo "${RED}Không có tập tiếp theo!${RESET}"
                                ep_num=$((ep_num - 1))
                                ep_url=$(echo "$episodes" | awk -F'|' -v num="$ep_num" '$1 == num {print $2}')
                            fi
                            ;;
                        "Tập trước")
                            ep_num=$((ep_num - 1))
                            if [[ $ep_num -lt 1 ]]; then
                                echo "${RED}Không có tập trước đó!${RESET}"
                                ep_num=1
                            fi
                            ep_url=$(echo "$episodes" | awk -F'|' -v num="$ep_num" '$1 == num {print $2}')
                            ;;
                        "Chọn tập khác")
                            selected=$(echo "$episodes" | fzf --prompt="Chọn tập: " --preview="echo 'Tập '{} | awk -F'|' '{print \$1}'")
                            if [[ -n "$selected" ]]; then
                                ep_num=$(echo "$selected" | awk -F'|' '{print $1}')
                                ep_url=$(echo "$selected" | awk -F'|' '{print $2}')
                            fi
                            ;;
                        "Quay lại") return ;;
                        *) return ;;
                    esac
                done
            fi
            ;;
    esac
}

# Đọc manga
read_manga() {
    echo "${YELLOW}Đang khởi động trình đọc manga...${RESET}"
    manga-tui lang --set 'vi'
}

# Menu cài đặt
settings_menu() {
    while true; do
        clear
        echo "${BOLD}${CYAN}CÀI ĐẶT${RESET}"
        echo "${GREEN}1. Thay đổi nguồn mặc định${RESET}"
        echo "${GREEN}2. Thay đổi chất lượng video${RESET}"
        echo "${GREEN}3. Thay đổi theme${RESET}"
        echo "${GREEN}4. Xóa cache${RESET}"
        echo "${YELLOW}5. Quay lại${RESET}"
        
        read -p "${BOLD}Chọn chức năng [1-5]: ${RESET}" choice
        
        case $choice in
            1) change_default_source ;;
            2) change_quality ;;
            3) change_theme ;;
            4) clear_cache ;;
            5) return ;;
            *) echo "${RED}Lựa chọn không hợp lệ!${RESET}"; sleep 1 ;;
        esac
    done
}

# Thay đổi nguồn mặc định
change_default_source() {
    local sources=("ophim" "anidata")
    local new_source=$(printf "%s\n" "${sources[@]}" | fzf --prompt="Chọn nguồn mặc định: ")
    
    if [[ -n "$new_source" ]]; then
        sed -i "s/^DEFAULT_SOURCE=.*/DEFAULT_SOURCE=\"$new_source\"/" "$CONFIG_FILE"
        echo "${GREEN}Đã thay đổi nguồn mặc định thành: $new_source${RESET}"
        sleep 1
    fi
}

# Thay đổi chất lượng video
change_quality() {
    local qualities=("best" "1080p" "720p" "480p" "360p")
    local new_quality=$(printf "%s\n" "${qualities[@]}" | fzf --prompt="Chọn chất lượng video: ")
    
    if [[ -n "$new_quality" ]]; then
        sed -i "s/^QUALITY=.*/QUALITY=\"$new_quality\"/" "$CONFIG_FILE"
        echo "${GREEN}Đã thay đổi chất lượng video thành: $new_quality${RESET}"
        sleep 1
    fi
}

# Thay đổi theme
change_theme() {
    local themes=("dark" "light" "blue" "green")
    local new_theme=$(printf "%s\n" "${themes[@]}" | fzf --prompt="Chọn theme: ")
    
    if [[ -n "$new_theme" ]]; then
        sed -i "s/^THEME=.*/THEME=\"$new_theme\"/" "$CONFIG_FILE"
        echo "${GREEN}Đã thay đổi theme thành: $new_theme${RESET}"
        sleep 1
    fi
}

# Xóa cache
clear_cache() {
    rm -f "$CACHE_DIR"/*
    echo "${GREEN}Đã xóa tất cả cache!${RESET}"
    sleep 1
}

# Hiển thị lịch sử xem
show_history() {
    echo "${YELLOW}Tính năng này đang được phát triển...${RESET}"
    sleep 1
}

# Hàm chính
main() {
    init_config
    check_dependencies
    show_main_menu
}

# Chạy chương trình
main