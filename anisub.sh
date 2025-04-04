#!/bin/bash

###############################################################################
# ANISUB REMAKE BY CHERRY | KIDTOMBOY
# Phiên bản: 2.0.0
# Tác giả: 
#   - Original: @NiyakiPham 
#   - Remake & Enhance: @Kidtomboy
# Ngày cập nhật: 04-04-2025
#
# Tính năng chính:
# - Phát anime từ nhiều nguồn (Ophim17, AniData, YouTube)
# - Tải xuống tập phim với nhiều tùy chọn
# - Công cụ video mạnh mẽ (cắt/ghép/xem trước)
# - Lịch sử xem chi tiết
# - Danh sách yêu thích thông minh
# - Hệ thống cache và cấu hình linh hoạt
# - Hỗ trợ đa nền tảng (Linux, Windows, macOS, Android/Termux)
# - Giao diện terminal đẹp với nhiều theme
###############################################################################

# ============================ CẤU HÌNH HỆ THỐNG ============================
VERSION="2.0.0"
AUTHORS=("Kidtomboy (Remake & Enhance)" "NiyakiPham (Original)")
DONATION_LINK="https://github.com/kidtomboy"

# ============================ BIỂU TƯỢNG UNICODE ============================
SYM_SEARCH="🔍" 
SYM_HIST="🕒"  
SYM_FAV="⭐"   
SYM_TOOLS="🛠️"  
SYM_SETTINGS="⚙️" 
SYM_UPDATE="🔄" 
SYM_INFO="ℹ️"  
SYM_EXIT="🚪"  
SYM_DOWNLOAD="💾" 
SYM_PLAY="▶️"   
SYM_CUT="✂️"   
SYM_MERGE="➕" 
SYM_DELETE="🗑️" 
SYM_PROMPT="#️⃣"
SYM_NEXT="⏭" 
SYM_PREV="⏮" 
SYM_SELECT="🔢"
SYM_FOLDER="📁"
SYM_WARNING="⚠️"
SYM_ERROR="❌"
SYM_SUCCESS="✅"

# Unicode box-drawing characters
BOX_HORIZ="─"
BOX_VERT="│"
BOX_CORNER_TL="┌"
BOX_CORNER_TR="┐"
BOX_CORNER_BL="└"
BOX_CORNER_BR="┘"
BOX_T="┬"
BOX_B="┴"
BOX_L="├"
BOX_R="┤"
BOX_CROSS="┼"

# Phát hiện hệ điều hành
detect_os() {
    case "$(uname -s)" in
        Linux*)     
            OS="Linux"
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                OS_DISTRO="$ID"
            elif [[ -f /etc/debian_version ]]; then
                OS_DISTRO="debian"
            elif [[ -f /etc/arch-release ]]; then
                OS_DISTRO="arch"
            elif [[ -f /etc/gentoo-release ]]; then
                OS_DISTRO="gentoo"
            else
                OS_DISTRO="unknown"
            fi
            ;;
        Darwin*)    
            OS="macOS"
            OS_DISTRO="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*) 
            OS="Windows"
            OS_DISTRO="windows"
            ;;
        *)          
            OS="Unknown"
            OS_DISTRO="unknown"
    esac

    # Kiểm tra Termux trên Android
    if [[ "$OS" == "Linux" ]] && [[ -d "/data/data/com.termux/files" ]]; then
        OS="Android/Termux"
        OS_DISTRO="termux"
    fi
}

detect_os

# ============================ CẤU HÌNH THƯ MỤC ============================
init_dirs() {
    log "SYSTEM" "Đang khởi tạo thư mục..."
    case "$OS" in
        "Linux"|"macOS")
            CONFIG_DIR="$HOME/.config/anisub_pro"
            DOWNLOAD_DIR="$HOME/Downloads/anisub_downloads"
            ;;
        "Windows")
            CONFIG_DIR="$APPDATA/anisub_pro"
            DOWNLOAD_DIR="$USERPROFILE/Downloads/anisub_downloads"
            ;;
        "Android/Termux")
            CONFIG_DIR="$HOME/.config/anisub_pro"
            DOWNLOAD_DIR="/sdcard/Download/anisub_downloads"
            ;;
        *)
            CONFIG_DIR="$HOME/.anisub_pro"
            DOWNLOAD_DIR="$HOME/anisub_downloads"
            ;;
    esac

    # Tạo các thư mục cần thiết
    mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR" "$CONFIG_DIR/cache" "$CONFIG_DIR/logs" \
             "$CONFIG_DIR/backups"

    # File cấu hình
    CONFIG_FILE="$CONFIG_DIR/config.cfg"
    LOG_FILE="$CONFIG_DIR/logs/anisub_$(date +%Y%m%d).log"
    HISTORY_FILE="$CONFIG_DIR/history.json"
    FAVORITES_FILE="$CONFIG_DIR/favorites.json"
    CACHE_DIR="$CONFIG_DIR/cache"
    BACKUP_DIR="$CONFIG_DIR/backups"

    # Tạo file cấu hình mặc định nếu chưa có
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "CONFIG" "Tạo file cấu hình mới"
    cat > "$CONFIG_FILE" <<- EOM
# CẤU HÌNH MẶC ĐỊNH ANISUB PRO
	DEFAULT_PLAYER="mpv"
	DEFAULT_QUALITY="720p"
	DEFAULT_SOURCE="ophim17"
	THEME="dark"
	NOTIFICATIONS="true"
	MAX_CACHE_AGE=86400
	UPDATE_URL="https://raw.githubusercontent.com/kidtomboy/Anisub/main/anisub.sh"
	AUTO_BACKUP=true
	AUTO_CLEANUP=true
	PLAYER_ARGS="--no-terminal --force-window --quiet"
	SKIP_DEPENDENCY_CHECK=false
	LOG_LEVEL="info" 
	LOG_TO_FILE=true  
	SKIP_OPTIONAL_PKGS=false
	TERMINAL_NOTIFY=true
EOM
    fi

    # Load cấu hình
    source "$CONFIG_FILE"
    log "CONFIG" "Đã tải cấu hình từ $CONFIG_FILE"
    
    # Sao lưu tự động nếu được bật
    if [[ "$AUTO_BACKUP" == "true" ]]; then
        local backup_file="$BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S).cfg"
        cp "$CONFIG_FILE" "$backup_file"
        log "BACKUP" "Đã sao lưu cấu hình tại $backup_file"
        # Giữ tối đa 5 bản sao lưu
        ls -t "$BACKUP_DIR"/config_backup_*.cfg | tail -n +6 | xargs rm -f --
    fi
    
    # Dọn dẹp cache tự động nếu được bật
    if [[ "$AUTO_CLEANUP" == "true" ]]; then
        log "CLEANUP" "Đang dọn dẹp cache cũ..."
        find "$CACHE_DIR" -type f -mtime +7 -exec rm -f {} \;
    fi
}

# ============================ CẤU HÌNH MÀU SẮC & GIAO DIỆN ============================
init_ui() {
    log "UI" "Đang khởi tạo giao diện..."
    # Màu sắc theo theme
    case "$THEME" in
        "dark")
            PRIMARY='\033[0;35m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[40m'
            ;;
        "light")
            PRIMARY='\033[0;34m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;35m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;30m'
            BG='\033[47m'
            ;;
        "blue")
            PRIMARY='\033[0;34m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[44m'
            ;;
        "green")
            PRIMARY='\033[0;32m'
            SECONDARY='\033[1;32m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;34m'
            TEXT='\033[0;37m'
            BG='\033[42m'
            ;;
        "red")
            PRIMARY='\033[0;31m'
            SECONDARY='\033[1;31m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;34m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[41m'
            ;;
        *)
            PRIMARY='\033[0;35m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[40m'
            ;;
    esac
    
    NC='\033[0m' # No Color
}

# ============================ HÀM HIỂN THỊ GIAO DIỆN ============================
draw_box() {
    local width=$1
    local title=$2
    local color=$3
    local content=$4
    
    echo -ne "${color}${BOX_CORNER_TL}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_CORNER_TR}${NC}\n"
    
    if [[ -n "$title" ]]; then
        local title_len=${#title}
        local left_pad=$(( (width - title_len - 2) / 2 ))
        local right_pad=$(( width - title_len - 2 - left_pad ))
        
        echo -ne "${color}${BOX_VERT}${NC}"
        for ((i=0; i<left_pad; i++)); do echo -ne " "; done
        echo -ne "${ACCENT}${title}${NC}"
        for ((i=0; i<right_pad; i++)); do echo -ne " "; done
        echo -ne "${color}${BOX_VERT}${NC}\n"
        
        echo -ne "${color}${BOX_L}"
        for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
        echo -ne "${BOX_R}${NC}\n"
    fi
    
    while IFS= read -r line; do
        echo -ne "${color}${BOX_VERT}${NC} ${TEXT}${line}"
        for ((i=${#line}; i<width-3; i++)); do echo -ne " "; done
        echo -ne "${color}${BOX_VERT}${NC}\n"
    done <<< "$content"
    
    echo -ne "${color}${BOX_CORNER_BL}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_CORNER_BR}${NC}\n"
}

show_header() {
    clear
    local width=60
    local title=" ANISUB v$VERSION "
    
    echo -ne "${PRIMARY}${BOX_CORNER_TL}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_CORNER_TR}${NC}\n"
    
    echo -ne "${PRIMARY}${BOX_VERT}${NC}"
    for ((i=0; i<(width-${#title}-2)/2; i++)); do echo -ne " "; done
    echo -ne "${ACCENT}${title}${NC}"
    for ((i=0; i<(width-${#title}-2)/2; i++)); do echo -ne " "; done
    echo -ne "${PRIMARY}${BOX_VERT}${NC}\n"
    
    echo -ne "${PRIMARY}${BOX_L}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_R}${NC}\n"
}

show_menu() {
    local options=("$@")
    local width=60
    local content=""
    
    for i in "${!options[@]}"; do
        if [[ $((i%2)) -eq 0 ]]; then
            # Menu item
            content+="${PRIMARY}${options[i]}${NC}\n"
        else
            # Description
            content+="  ${TEXT}${options[i]}${NC}\n"
        fi
    done
    
    draw_box $width "" "$PRIMARY" "$content"
}

# ============================ GHI LOG (NHẬT KÝ) ============================
log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_type="${1^^}"  # Chuyển thành chữ hoa
    local message="$2"
    local user_input="$3"
    
    # Xác định mức độ log
    local log_level_num=0
    case "$LOG_LEVEL" in
        "debug") log_level_num=0 ;;
        "info") log_level_num=1 ;;
        "warn") log_level_num=2 ;;
        "error") log_level_num=3 ;;
        *) log_level_num=1 ;;
    esac
    
    # Xác định mức độ log hiện tại
    local current_level_num=0
    case "$log_type" in
        "DEBUG") current_level_num=0 ;;
        "INFO") current_level_num=1 ;;
        "WARN") current_level_num=2 ;;
        "ERROR") current_level_num=3 ;;
        *) current_level_num=1 ;;
    esac
    
    # Chỉ ghi log nếu mức độ hiện tại >= mức độ cấu hình
    if [[ $current_level_num -lt $log_level_num ]]; then
        return
    fi
    
    # Tạo thông điệp log
    local log_entry="[$timestamp] [$log_type] $message"
    [[ -n "$user_input" ]] && log_entry+=" | Input: $user_input"
    
    # Hiển thị log ra console nếu ở chế độ debug
    if [[ "$DEBUG_MODE" == "true" || "$log_type" == "ERROR" || "$log_type" == "WARN" ]]; then
        case "$log_type" in
            "ERROR") echo -e "${WARNING}$log_entry${NC}" >&2 ;;
            "WARN") echo -e "${ACCENT}$log_entry${NC}" >&2 ;;
            *) echo -e "${SECONDARY}$log_entry${NC}" >&2 ;;
        esac
    fi
    
    # Ghi vào file log nếu được bật
    if [[ "$LOG_TO_FILE" == "true" ]]; then
        echo "$log_entry" >> "$CONFIG_DIR/anisub.log"
    fi
    
    # Giới hạn kích thước file log (tối đa 1MB)
    if [[ -f "$CONFIG_DIR/anisub.log" ]]; then
        local log_size=$(stat -c %s "$CONFIG_DIR/anisub.log" 2>/dev/null || stat -f %z "$CONFIG_DIR/anisub.log")
        if [[ $log_size -gt 1048576 ]]; then  # 1MB
            tail -n 500 "$CONFIG_DIR/anisub.log" > "$CONFIG_DIR/anisub.log.tmp"
            mv "$CONFIG_DIR/anisub.log.tmp" "$CONFIG_DIR/anisub.log"
        fi
    fi
}

# ============================ HIỂN THỊ CÁC THÔNG BÁO ============================
notify() {
    local message="$1"
    local icon="${2:-$SYM_INFO}"
    
    if [[ "$TERMINAL_NOTIFY" == "true" ]]; then
        echo -e "${INFO}[${icon}]${NC} $message"
    fi
    
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        case "$OS" in
            "Linux")
                notify-send -i "video-display" "Anisub" "$icon $message" 2>/dev/null
                ;;
            "macOS")
                osascript -e "display notification \"$message\" with title \"Anisub\" subtitle \"$icon\"" 2>/dev/null
                ;;
            "Windows")
                # TODO: Implement Windows notification
                ;;
            "Android/Termux")
                termux-notification -t "Anisub" -c "$icon $message" 2>/dev/null
                ;;
        esac
    fi
    log "INFO" "$message"
}

warn() {
    local message="$1"
    echo -e "${WARNING}[${SYM_WARNING}]${NC} $message" >&2
    log "WARN" "$message"
}

error() {
    local message="$1"
    echo -e "${WARNING}[${SYM_ERROR}]${NC} $message" >&2
    log "ERROR" "$message"
}

# ============================ KIỂM TRA VÀ TỰ ĐỘNG CÀI ĐẶT CÁC GÓI ============================
check_dependencies() {
    log "SYSTEM" "Kiểm tra phụ thuộc..."
    
    # Bỏ qua nếu có flag --version hoặc SKIP_DEPENDENCY_CHECK=true
    if [[ "$1" == "--version" || "$SKIP_DEPENDENCY_CHECK" == "true" ]]; then
        log "SYSTEM" "Bỏ qua kiểm tra phụ thuộc"
        return 0
    fi

    local -A pkg_manager=(
        ["apt"]="sudo apt-get install -y"
        ["pacman"]="sudo pacman -S --noconfirm"
        ["dnf"]="sudo dnf install -y"
        ["yum"]="sudo yum install -y"
        ["zypper"]="sudo zypper install -y"
        ["brew"]="brew install"
        ["termux"]="pkg install -y"
    )

    # Xác định trình quản lý gói
    local manager
    if [[ "$OS_DISTRO" == "termux" ]]; then
        manager="termux"
    else
        for m in "${!pkg_manager[@]}"; do
            if command -v "$m" &>/dev/null; then
                manager="$m"
                break
            fi
        done
    fi

    if [[ -z "$manager" ]]; then
        error "Không thể xác định trình quản lý gói!"
        log "ERROR" "Không thể xác định trình quản lý gói"
        return 1
    fi

    # Các gói bắt buộc theo hệ điều hành
    local -A required_pkgs
    if [[ "$OS_DISTRO" == "termux" ]]; then
        required_pkgs=(
            ["curl"]="curl"
            ["pup"]="pup"
            ["jq"]="jq"
            ["fzf"]="fzf"
            ["mpv"]="mpv-x"
        )
    else
        required_pkgs=(
            ["curl"]="curl"
            ["pup"]="pup"
            ["jq"]="jq"
            ["fzf"]="fzf"
            ["mpv"]="mpv"
        )
    fi

    # Các gói tùy chọn theo hệ điều hành
    local -A optional_pkgs
    if [[ "$OS_DISTRO" == "termux" ]]; then
        optional_pkgs=(
            ["yt-dlp"]="yt-dlp"
            ["ffmpeg"]="ffmpeg"
            ["termux-api"]="termux-api"
        )
    else
        optional_pkgs=(
            ["yt-dlp"]="yt-dlp"
            ["ffmpeg"]="ffmpeg"
            ["notify-send"]="libnotify-bin"
        )
    fi

    local missing=()
    local optional_missing=()

    # Kiểm tra gói bắt buộc
    for cmd in "${!required_pkgs[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("${required_pkgs[$cmd]}")
            log "DEPENDENCY" "Thiếu gói bắt buộc: $cmd"
        fi
    done

    # Kiểm tra gói tùy chọn (chỉ nếu SKIP_OPTIONAL_PKGS=false)
    if [[ "$SKIP_OPTIONAL_PKGS" != "true" ]]; then
        for cmd in "${!optional_pkgs[@]}"; do
            if ! command -v "$cmd" &>/dev/null; then
                optional_missing+=("${optional_pkgs[$cmd]}")
                log "DEPENDENCY" "Thiếu gói tùy chọn: $cmd"
            fi
        done
    else
        log "SYSTEM" "Bỏ qua kiểm tra gói tùy chọn do SKIP_OPTIONAL_PKGS=true"
    fi

    # Cài đặt các gói bắt buộc
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "${SYM_WARNING} Đang cài đặt các gói bắt buộc: ${missing[*]}"
        log "SYSTEM" "Cài đặt gói bắt buộc: ${missing[*]}"
        
        if ! ${pkg_manager[$manager]} "${missing[@]}"; then
            error "${SYM_ERROR} Không thể cài đặt các gói bắt buộc!"
            log "ERROR" "Không thể cài đặt gói bắt buộc: ${missing[*]}"
            exit 1
        fi
        log "SYSTEM" "Đã cài đặt gói bắt buộc: ${missing[*]}"
    fi

    # Cài đặt các gói tùy chọn (chỉ nếu SKIP_OPTIONAL_PKGS=false)
    if [[ "$SKIP_OPTIONAL_PKGS" != "true" && ${#optional_missing[@]} -gt 0 ]]; then
        warn "${SYM_WARNING} Các gói tùy chọn chưa có: ${optional_missing[*]}"
        log "SYSTEM" "Gói tùy chọn chưa có: ${optional_missing[*]}"
        
        read -p "Bạn có muốn cài đặt chúng không? (y/N) " -n 1 -r
        echo
        log "USER" "Lựa chọn cài đặt gói tùy chọn" "$REPLY"
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! ${pkg_manager[$manager]} "${optional_missing[@]}"; then
                warn "${SYM_WARNING} Có lỗi khi cài gói tùy chọn"
                log "ERROR" "Có lỗi khi cài gói tùy chọn: ${optional_missing[*]}"
            else
                log "SYSTEM" "Đã cài đặt gói tùy chọn: ${optional_missing[*]}"
            fi
        fi
    fi

    # Kiểm tra lại sau khi cài đặt
    for cmd in "${!required_pkgs[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error "${SYM_ERROR} Không thể cài đặt $cmd, script không thể chạy!"
            log "ERROR" "Không thể cài đặt $cmd, script không thể chạy"
            exit 1
        fi
    done
    
    log "SYSTEM" "Kiểm tra phụ thuộc hoàn tất"
}

# ============================ HÀM LẤY DANH SÁCH ANIME/PHIM TỪ OPHIM17 ============================
search_anime_ophim17() {
    local keyword="$1"
    log "SEARCH" "Tìm kiếm trên OPhim17 với từ khóa: $keyword"
    
    # Kiểm tra độ dài từ khóa
    if [[ ${#keyword} -lt 3 ]]; then
        error "Từ khóa tìm kiếm phải có ít nhất 3 ký tự"
        log "ERROR" "Từ khóa quá ngắn: $keyword"
        return 1
    fi

    local cache_file="$CACHE_DIR/ophim17_search_${keyword}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $keyword"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm: $keyword..."
    local search_url="https://ophim17.cc/tim-kiem?keyword=${keyword}"
    local anime_list
    
    # Sử dụng timeout cho curl để tránh treo lâu
    if ! anime_list=$(timeout 20 curl -s "$search_url" | pup '.ml-4 > a attr{href}' 2>/dev/null); then
        error "Không thể tải dữ liệu tìm kiếm"
        log "ERROR" "Không thể tải dữ liệu tìm kiếm từ OPhim17"
        return 1
    fi
    
    # Xử lý kết quả tìm kiếm
    if [[ -z "$anime_list" ]]; then
        warn "Không tìm thấy anime nào với từ khóa '$keyword'"
        log "SEARCH" "Không tìm thấy kết quả cho: $keyword"
        return 1
    fi

    # Tạo danh sách anime với thông tin đầy đủ
    local processed_list=$(echo "$anime_list" | awk '{print "https://ophim17.cc" $0}' | \
        while IFS= read -r link; do
            local title=$(timeout 20 curl -s "$link" | pup 'h1 text{}' | tr -d '\n' 2>/dev/null)
            if [[ -z "$title" ]]; then
                title="Không có tiêu đề"
                log "WARN" "Không lấy được tiêu đề cho URL: $link"
            fi
            printf '%s\n' "$link@@@$title"
        done | \
        awk -F '@@@' '{print NR ". " $2 " (" $1 ")"}' 2>/dev/null)
    
    # Kiểm tra kết quả xử lý
    if [[ -z "$processed_list" ]]; then
        error "Không thể xử lý kết quả tìm kiếm"
        log "ERROR" "Không thể xử lý kết quả tìm kiếm từ OPhim17"
        return 1
    fi
    
    # Lưu vào cache
    echo "$processed_list" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm vào cache: $cache_file"
    echo "$processed_list"
}

# ============================ HÀM LẤY DANH SÁCH TẬP TỪ OPHIM17 ============================
get_episode_list_ophim17() {
    local url="$1"
    log "STREAM" "Lấy danh sách tập từ URL: $url"
    
    local cache_file="$CACHE_DIR/ophim17_episodes_$(echo "$url" | md5sum | cut -d' ' -f1).cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng danh sách tập từ cache"
            cat "$cache_file"
            return
        fi
    fi
    
    local html_content=$(curl -s "$url")
    if [[ -z "$html_content" ]]; then
        error "Không thể tải nội dung từ URL: $url"
        log "ERROR" "Không thể tải nội dung từ URL: $url"
        return 1
    fi
    
    local episode_data=$(echo "$html_content" | pup 'script json{}' | \
        jq -r '.[].text | @text' | \
        grep -oE '"(http|https)://[^"]*index.m3u8"' | \
        sed 's/"//g')
    
    if [[ -z "$episode_data" ]]; then
        error "Không tìm thấy danh sách tập phim cho URL: $url"
        log "ERROR" "Không tìm thấy danh sách tập phim cho URL: $url"
        return 1
    fi
    
    local i=1
    while IFS= read -r link; do
        printf "%s|%s\n" "$i" "$link"
        i=$((i + 1))
    done <<< "$episode_data" > "$cache_file"
    
    log "CACHE" "Lưu danh sách tập vào cache: $cache_file"
    cat "$cache_file"
}

# ============================ LẤY TIÊU ĐỀ TẬP PHIM ============================
get_episode_title() {
    local episode_url="$1"
    local episode_number="$2"
    log "STREAM" "Lấy tiêu đề tập phim #$episode_number từ URL: $episode_url"
    
    local cache_file="$CACHE_DIR/ophim17_title_$(echo "$episode_url" | md5sum | cut -d' ' -f1)_$episode_number.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return
    fi
    
    local episode_title=$(curl -s "$episode_url" | pup ".ep-name text{}" | sed -n "${episode_number}p")
    
    if [[ -z "$episode_title" ]]; then
        episode_title="Episode $episode_number"
        log "WARN" "Không lấy được tiêu đề tập phim, sử dụng mặc định"
    fi
    
    echo "$episode_title" > "$cache_file"
    log "CACHE" "Lưu tiêu đề tập phim vào cache: $cache_file"
    echo "$episode_title"
}

# ============================ HÀM LẤY DANH SÁCH ANIME/PHIM TỪ ANIDATA (@NiyakiPham QUẢN LÝ) ============================
get_anime_list_anidata() {
    log "SEARCH" "Lấy danh sách anime từ AniData"
    local cache_file="$CACHE_DIR/anidata_list.cache"
    local csv_url="https://raw.githubusercontent.com/toilamsao/anidata/refs/heads/main/data.csv"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng danh sách anime từ cache"
            cat "$cache_file"
            return
        fi
    fi
    
    local csv_content=$(curl -s "$csv_url" | sed 's/"//g')
    local anime_names=$(echo "$csv_content" | sed '1d' | cut -d',' -f1 | sort -u)
    
    # Lưu vào cache
    echo "$anime_names" > "$cache_file"
    log "CACHE" "Lưu danh sách anime vào cache: $cache_file"
    echo "$anime_names"
}

# ============================ HÀM LẤY DANH SÁCH TẬP TỪ ANIDATA (@NiyakiPham QUẢN LÝ) ============================
get_episode_list_anidata() {
    local anime_name="$1"
    log "STREAM" "Lấy danh sách tập từ AniData cho: $anime_name"
    
    local cache_file="$CACHE_DIR/anidata_episodes_$(echo "$anime_name" | md5sum | cut -d' ' -f1).cache"
    local csv_url="https://raw.githubusercontent.com/toilamsao/anidata/refs/heads/main/data.csv"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng danh sách tập từ cache"
            cat "$cache_file"
            return
        fi
    fi
    
    local csv_content=$(curl -s "$csv_url" | sed 's/"//g')
    local episodes=$(echo "$csv_content" | awk -F',' -v anime="$anime_name" '$1 == anime {print $2 " | " $3}')
    
    # Lưu vào cache
    echo "$episodes" > "$cache_file"
    log "CACHE" "Lưu danh sách tập vào cache: $cache_file"
    echo "$episodes"
}

# ============================ HÀM LƯU VÀO NHẬT KÝ ============================
add_to_history() {
    local anime="$1"
    local episode="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    log "HISTORY" "Thêm vào lịch sử: $anime - $episode"
    
    # Sử dụng JSON cho lịch sử
    local history_entry="{\"timestamp\":\"$timestamp\",\"anime\":\"$anime\",\"episode\":\"$episode\"}"
    
    # Giới hạn lịch sử 50 mục
    if [[ ! -f "$HISTORY_FILE" ]]; then
        echo "[$history_entry]" > "$HISTORY_FILE"
    else
        local temp_file=$(mktemp)
        jq --argjson entry "$history_entry" 'limit(50; [$entry] + .)' "$HISTORY_FILE" > "$temp_file"
        mv "$temp_file" "$HISTORY_FILE"
    fi
}

# ============================ Hàm cấu hình logging ============================
configure_logging() {
    while true; do
        show_header
        
        local current_log_level="${LOG_LEVEL^^}"
        local log_status=$([[ "$LOG_TO_FILE" == "true" ]] && echo "BẬT" || echo "TẮT")
        local notify_status=$([[ "$TERMINAL_NOTIFY" == "true" ]] && echo "BẬT" || echo "TẮT")
        
        local options=(
            "${SYM_SETTINGS} 1. Mức độ log hiện tại: $current_log_level" "Chọn mức độ ghi log (debug/info/warn/error)"
            "${SYM_SETTINGS} 2. Ghi log ra file: $log_status" "Bật/tắt ghi log ra file anisub.log"
            "${SYM_SETTINGS} 3. Thông báo trên terminal: $notify_status" "Bật/tắt thông báo trên terminal"
            "${SYM_FOLDER} 4. Xem log file" "Hiển thị nội dung file log"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu cài đặt"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn cấu hình log" "$choice"
        
        case $choice in
            1)
                local levels=("debug" "info" "warn" "error")
                local selected=$(printf "%s\n" "${levels[@]}" | fzf --prompt="Chọn mức độ log: ")
                
                if [[ -n "$selected" ]]; then
                    sed -i "s/^LOG_LEVEL=.*/LOG_LEVEL=\"$selected\"/" "$CONFIG_FILE"
                    LOG_LEVEL="$selected"
                    notify "${SYM_SUCCESS} Đã thay đổi mức độ log thành: $selected"
                    log "SETTINGS" "Thay đổi mức độ log thành: $selected"
                fi
                ;;
            2)
                if [[ "$LOG_TO_FILE" == "true" ]]; then
                    sed -i "s/^LOG_TO_FILE=.*/LOG_TO_FILE=false/" "$CONFIG_FILE"
                    LOG_TO_FILE="false"
                    notify "${SYM_SUCCESS} Đã tắt ghi log ra file"
                    log "SETTINGS" "Tắt ghi log ra file"
                else
                    sed -i "s/^LOG_TO_FILE=.*/LOG_TO_FILE=true/" "$CONFIG_FILE"
                    LOG_TO_FILE="true"
                    notify "${SYM_SUCCESS} Đã bật ghi log ra file"
                    log "SETTINGS" "Bật ghi log ra file"
                fi
                ;;
            3)
                if [[ "$TERMINAL_NOTIFY" == "true" ]]; then
                    sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=false/" "$CONFIG_FILE"
                    TERMINAL_NOTIFY="false"
                    notify "${SYM_SUCCESS} Đã tắt thông báo trên terminal"
                    log "SETTINGS" "Tắt thông báo trên terminal"
                else
                    sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=true/" "$CONFIG_FILE"
                    TERMINAL_NOTIFY="true"
                    notify "${SYM_SUCCESS} Đã bật thông báo trên terminal"
                    log "SETTINGS" "Bật thông báo trên terminal"
                fi
                ;;
            4)
                if [[ -f "$CONFIG_DIR/anisub.log" ]]; then
                    less "$CONFIG_DIR/anisub.log"
                else
                    warn "${SYM_WARNING} Không tìm thấy file log"
                    log "WARN" "Không tìm thấy file log để xem"
                fi
                ;;
            0)
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# Hàm bật/tắt gói tùy chọn
toggle_optional_packages() {
    if [[ "$SKIP_OPTIONAL_PKGS" == "true" ]]; then
        sed -i "s/^SKIP_OPTIONAL_PKGS=.*/SKIP_OPTIONAL_PKGS=false/" "$CONFIG_FILE"
        SKIP_OPTIONAL_PKGS="false"
        notify "${SYM_SUCCESS} Đã bật cài đặt gói tùy chọn"
        log "SETTINGS" "Bật cài đặt gói tùy chọn"
    else
        sed -i "s/^SKIP_OPTIONAL_PKGS=.*/SKIP_OPTIONAL_PKGS=true/" "$CONFIG_FILE"
        SKIP_OPTIONAL_PKGS="true"
        notify "${SYM_SUCCESS} Đã tắt cài đặt gói tùy chọn"
        log "SETTINGS" "Tắt cài đặt gói tùy chọn"
    fi
}

# ============================ HÀM HIỂN THỊ LỊCH SỬ ĐÃ XEM ============================
show_history() {
    log "HISTORY" "Hiển thị lịch sử xem"
    if [[ ! -s "$HISTORY_FILE" ]]; then
        echo "Không có lịch sử xem."
        return
    fi
    
    local history_list=$(jq -r '.[] | "\(.timestamp) | \(.anime) | \(.episode)"' "$HISTORY_FILE" | \
        awk '{print NR ". " $0}')
    echo "$history_list"
}

# ============================ HÀM THÊM VÀO DANH SÁCH YÊU THÍCH ============================
add_to_favorites() {
    local anime="$1"
    log "FAVORITE" "Thêm vào yêu thích: $anime"
    
    # Sử dụng JSON cho danh sách yêu thích
    if [[ ! -f "$FAVORITES_FILE" ]]; then
        echo "[\"$anime\"]" > "$FAVORITES_FILE"
    else
        if jq -e --arg anime "$anime" 'index($anime) != null' "$FAVORITES_FILE" >/dev/null; then
            warn "Anime đã có trong danh sách yêu thích"
            log "WARN" "Anime đã có trong yêu thích: $anime"
            return
        fi
        
        local temp_file=$(mktemp)
        jq --arg anime "$anime" '. + [$anime]' "$FAVORITES_FILE" > "$temp_file"
        mv "$temp_file" "$FAVORITES_FILE"
    fi
    
    notify "${SYM_FAV} Đã thêm '$anime' vào danh sách yêu thích"
}

# ============================ HÀM XÓA KHỎI DANH SÁCH YÊU THÍCH ============================
remove_from_favorites() {
    local anime="$1"
    log "FAVORITE" "Xóa khỏi yêu thích: $anime"
    
    if [[ ! -f "$FAVORITES_FILE" ]]; then
        warn "Danh sách yêu thích trống"
        log "WARN" "Danh sách yêu thích trống"
        return
    fi
    
    if ! jq -e --arg anime "$anime" 'index($anime) != null' "$FAVORITES_FILE" >/dev/null; then
        warn "Anime không có trong danh sách yêu thích"
        log "WARN" "Anime không có trong yêu thích: $anime"
        return
    fi
    
    local temp_file=$(mktemp)
    jq --arg anime "$anime" 'del(.[index($anime)])' "$FAVORITES_FILE" > "$temp_file"
    mv "$temp_file" "$FAVORITES_FILE"
    
    notify "${SYM_FAV} Đã xóa '$anime' khỏi danh sách yêu thích"
}

# ============================ HÀM XEM DANH SÁCH YÊU THÍCH ============================
show_favorites() {
    log "FAVORITE" "Hiển thị danh sách yêu thích"
    if [[ ! -s "$FAVORITES_FILE" ]]; then
        echo "Không có anime nào trong danh sách yêu thích."
        return
    fi
    
    local favorites_list=$(jq -r '.[]' "$FAVORITES_FILE" | awk '{print NR ". " $0}')
    echo "$favorites_list"
}

# ============================ PHÁT VIDEO BẰNG TRÌNH PHÁT ============================
play_video() {
    local url="$1"
    local title="$2"
    log "PLAYER" "Phát video: $title (URL: $url)"
    
    notify "${SYM_PLAY} Đang phát: $title"
    
    case "$DEFAULT_PLAYER" in
        "mpv")
            mpv $PLAYER_ARGS --title="Anisub - $title" "$url"
            ;;
        "vlc")
            vlc --qt-notification=0 "$url" &>/dev/null
            ;;
        "ffplay")
            ffplay -nodisp -window_title "Anisub - $title" -autoexit "$url"
            ;;
        *)
            mpv $PLAYER_ARGS --title="Anisub - $title" "$url"
            ;;
    esac
    
    if [[ $? -ne 0 ]]; then
        error "${SYM_ERROR} Có lỗi khi phát video"
        log "ERROR" "Lỗi khi phát video: $title (URL: $url)"
        return 1
    fi
}

# ============================ HÀM TẢI VIDEO VỀ THIẾT BỊ ============================
download_video() {
    local url="$1"
    local title="$2"
    local output_dir="$3"
    local anime_name="$4"
    log "DOWNLOAD" "Bắt đầu tải video: $title (URL: $url)"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "${SYM_ERROR} yt-dlp không được cài đặt. Không thể tải video."
        log "ERROR" "yt-dlp không được cài đặt"
        return 1
    fi
    
    mkdir -p "$output_dir"
    notify "${SYM_DOWNLOAD} Đang tải: $title"
    
    yt-dlp -o "$output_dir/$title.%(ext)s" \
        --no-progress \
        --console-title \
        --merge-output-format mp4 \
        "$url"
    
    if [[ $? -eq 0 ]]; then
        notify "${SYM_SUCCESS} Đã tải xong: $title"
        log "DOWNLOAD" "Tải thành công: $title"
        
        # Thêm menu sau khi tải xong
        while true; do
            clear
            show_header
            
            local options=(
                "${SYM_PLAY} 1. Phát video vừa tải" "Phát video đã tải xuống"
                "${SYM_PLAY} 2. Quay lại phát tập hiện tại" "Tiếp tục xem tập hiện tại"
                "${SYM_FOLDER} 3. Mở thư mục chứa video" "Mở thư mục chứa file đã tải"
                "${SYM_EXIT} 0. Quay lại menu trước" "Quay lại menu trước đó"
            )
            
            show_menu "${options[@]}"
            
            read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
            log "USER" "Lựa chọn sau khi tải" "$choice"
            
            case $choice in
                1)
                    local video_file=$(find "$output_dir" -name "$title*.mp4" | head -n 1)
                    if [[ -f "$video_file" ]]; then
                        play_video "$video_file" "$title (Đã tải)"
                        log "PLAY" "Phát video đã tải: $title"
                    else
                        error "${SYM_ERROR} Không tìm thấy file video đã tải"
                        log "ERROR" "Không tìm thấy file video: $title"
                    fi
                    ;;
                2)
                    # Quay lại phát tập hiện tại
                    log "NAVIGATE" "Quay lại phát tập hiện tại"
                    return 2
                    ;;
                3)
                    log "SYSTEM" "Mở thư mục chứa video"
                    case "$OS" in
                        "Linux"|"Android/Termux")
                            xdg-open "$output_dir" || open "$output_dir"
                            ;;
                        "macOS")
                            open "$output_dir"
                            ;;
                        "Windows")
                            explorer "$(cygpath -w "$output_dir")"
                            ;;
                        *)
                            echo "Thư mục chứa video: $output_dir"
                            ;;
                    esac
                    ;;
                0)
                    log "NAVIGATE" "Quay lại menu trước"
                    return
                    ;;
                *)
                    warn "${SYM_WARNING} Lựa chọn không hợp lệ"
                    log "WARN" "Lựa chọn không hợp lệ: $choice"
                    ;;
            esac
        done
    else
        error "${SYM_ERROR} Tải video thất bại"
        log "ERROR" "Tải video thất bại: $title (URL: $url)"
        return 1
    fi
}

# ============================ CẮT VIDEO BẰNG FFMPEG ============================
cut_video() {
    local url="$1"
    local title="$2"
    local output_dir="$DOWNLOAD_DIR/cut"
    log "TOOLS" "Bắt đầu cắt video: $title (URL: $url)"
    
    if ! command -v yt-dlp &> /dev/null || ! command -v ffmpeg &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt yt-dlp và ffmpeg để sử dụng tính năng này"
        log "ERROR" "Thiếu yt-dlp hoặc ffmpeg"
        return 1
    fi
    
    mkdir -p "$output_dir"
    
    local cut_option=$(echo -e "Cắt 1 lần\nCắt nhiều lần" | fzf --prompt="Chọn chế độ cắt: ")
    log "USER" "Chọn chế độ cắt" "$cut_option"
    
    case "$cut_option" in
        "Cắt 1 lần")
            read -r -p "Nhập thời gian bắt đầu (định dạng HH:MM:SS hoặc MM:SS): " start_time
            read -r -p "Nhập thời gian kết thúc (định dạng HH:MM:SS hoặc MM:SS): " end_time
            log "USER" "Nhập thời gian cắt" "Start: $start_time, End: $end_time"
            
            local output_file="$output_dir/${title}_cut_$(date +%s).mp4"
            
            notify "${SYM_CUT} Đang cắt video từ $start_time đến $end_time..."
            yt-dlp --download-sections "*${start_time}-${end_time}" \
                -o "$output_file" \
                --no-progress \
                --console-title \
                "$url"
            
            if [[ $? -eq 0 ]]; then
                notify "${SYM_SUCCESS} Đã cắt và lưu video tại: $output_file"
                log "TOOLS" "Cắt video thành công: $output_file"
            else
                error "${SYM_ERROR} Cắt video thất bại"
                log "ERROR" "Cắt video thất bại: $title"
            fi
            ;;
        "Cắt nhiều lần")
            read -r -p "Nhập số lượng phân đoạn muốn cắt: " num_segments
            log "USER" "Số lượng phân đoạn cắt" "$num_segments"
            
            for ((i=1; i<=num_segments; i++)); do
                echo "Phân đoạn $i:"
                read -r -p "Nhập thời gian bắt đầu (định dạng HH:MM:SS hoặc MM:SS): " start_time
                read -r -p "Nhập thời gian kết thúc (định dạng HH:MM:SS hoặc MM:SS): " end_time
                log "USER" "Phân đoạn $i thời gian" "Start: $start_time, End: $end_time"
                
                local output_file="$output_dir/${title}_cut_${i}_$(date +%s).mp4"
                
                notify "${SYM_CUT} Đang cắt video từ $start_time đến $end_time..."
                yt-dlp --download-sections "*${start_time}-${end_time}" \
                    -o "$output_file" \
                    --no-progress \
                    --console-title \
                    "$url"
                
                if [[ $? -eq 0 ]]; then
                    notify "${SYM_SUCCESS} Đã cắt và lưu phân đoạn $i tại: $output_file"
                    log "TOOLS" "Cắt phân đoạn $i thành công: $output_file"
                else
                    error "${SYM_ERROR} Cắt phân đoạn $i thất bại"
                    log "ERROR" "Cắt phân đoạn $i thất bại: $title"
                fi
            done
            ;;
        *)
            warn "${SYM_WARNING} Lựa chọn không hợp lệ"
            log "WARN" "Lựa chọn chế độ cắt không hợp lệ"
            ;;
    esac
}

# ============================ GHÉP VIDEO LẠI VỚI NHAU ============================
merge_videos() {
    local output_dir="$DOWNLOAD_DIR/merged"
    mkdir -p "$output_dir"
    log "TOOLS" "Bắt đầu ghép video"
    
    local merge_option=$(echo -e "Ghép 1 lần\nGhép nhiều lần" | fzf --prompt="Chọn chế độ ghép: ")
    log "USER" "Chọn chế độ ghép" "$merge_option"
    
    case "$merge_option" in
        "Ghép 1 lần")
            read -r -p "Nhập số lượng video muốn ghép: " num_videos
            log "USER" "Số lượng video ghép" "$num_videos"
            local video_files=()
            
            for ((i=1; i<=num_videos; i++)); do
                local selected=$(find "$DOWNLOAD_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" \) | fzf --prompt="Chọn video $i: ")
                if [[ -z "$selected" ]]; then
                    warn "${SYM_WARNING} Không có video nào được chọn"
                    log "WARN" "Không chọn video $i"
                    return 1
                fi
                video_files+=("$selected")
                log "USER" "Chọn video $i" "$selected"
            done
            
            local output_file="$output_dir/merged_$(date +%s).mp4"
            
            notify "${SYM_MERGE} Đang ghép ${#video_files[@]} video..."
            ffmpeg -f concat -safe 0 -i <(for f in "${video_files[@]}"; do echo "file '$f'"; done) \
                -c copy \
                "$output_file" \
                -y
            
            if [[ $? -eq 0 ]]; then
                notify "${SYM_SUCCESS} Đã ghép và lưu video tại: $output_file"
                log "TOOLS" "Ghép video thành công: $output_file"
            else
                error "${SYM_ERROR} Ghép video thất bại"
                log "ERROR" "Ghép video thất bại"
            fi
            ;;
        "Ghép nhiều lần")
            read -r -p "Nhập số lượng vòng lặp ghép: " num_loops
            log "USER" "Số vòng lặp ghép" "$num_loops"
            
            for ((loop=1; loop<=num_loops; loop++)); do
                echo "Vòng lặp ghép thứ $loop:"
                read -r -p "Nhập số lượng video muốn ghép: " num_videos
                log "USER" "Vòng lặp $loop, số video" "$num_videos"
                local video_files=()
                
                for ((i=1; i<=num_videos; i++)); do
                    local selected=$(find "$DOWNLOAD_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" \) | fzf --prompt="Chọn video $i: ")
                    if [[ -z "$selected" ]]; then
                        warn "${SYM_WARNING} Không có video nào được chọn"
                        log "WARN" "Không chọn video $i trong vòng $loop"
                        continue 2
                    fi
                    video_files+=("$selected")
                    log "USER" "Chọn video $i vòng $loop" "$selected"
                done
                
                local output_file="$output_dir/merged_loop${loop}_$(date +%s).mp4"
                
                notify "${SYM_MERGE} Đang ghép ${#video_files[@]} video..."
                ffmpeg -f concat -safe 0 -i <(for f in "${video_files[@]}"; do echo "file '$f'"; done) \
                    -c copy \
                    "$output_file" \
                    -y
                
                if [[ $? -eq 0 ]]; then
                    notify "${SYM_SUCCESS} Đã ghép và lưu video tại: $output_file"
                    log "TOOLS" "Ghép video vòng $loop thành công: $output_file"
                else
                    error "${SYM_ERROR} Ghép video thất bại"
                    log "ERROR" "Ghép video vòng $loop thất bại"
                fi
            done
            ;;
        *)
            warn "${SYM_WARNING} Lựa chọn không hợp lệ"
            log "WARN" "Lựa chọn chế độ ghép không hợp lệ"
            ;;
    esac
}

# ============================ TÌM KIẾM TRÊN YOUTUBE ============================
search_youtube() {
    local query="$1"
    log "SEARCH" "Tìm kiếm trên YouTube: $query"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt yt-dlp để sử dụng tính năng này"
        log "ERROR" "Thiếu yt-dlp"
        return 1
    fi
    
    local cache_file="$CACHE_DIR/youtube_search_${query}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $query"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm trên YouTube: $query..."
    
    # Sử dụng yt-dlp để tìm kiếm và lấy thông tin chi tiết
    local search_results=$(yt-dlp --flat-playlist --print "%(title)s@@@%(id)s@@@%(duration)s@@@%(view_count)s@@@%(uploader)s" "ytsearch10:$query" 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy kết quả nào trên YouTube"
        log "ERROR" "Không tìm thấy kết quả YouTube cho: $query"
        return 1
    fi
    
    # Xử lý kết quả
    local processed_results=$(echo "$search_results" | awk -F'@@@' '{
        split($3, time, ":");
        if (length(time) == 3) { duration = time[1]"h "time[2]"m "time[3]"s" }
        else if (length(time) == 2) { duration = time[1]"m "time[2]"s" }
        else { duration = time[1]"s" }
        
        views = $4;
        if (views >= 1000000) { views = sprintf("%.1fM", views/1000000) }
        else if (views >= 1000) { views = sprintf("%.1fK", views/1000) }
        
        printf "%s | %s | %s | %s views | Kênh: %s\n", NR, $1, duration, views, $5
    }')
    
    # Lưu vào cache
    echo "$processed_results" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm YouTube vào cache: $cache_file"
    echo "$processed_results"
}

# ============================ PHÁT VIDEO TỪ YOUTUBE ============================
play_from_youtube() {
    local query="$1"
    log "STREAM" "Phát video từ YouTube: $query"
    
    local search_results=$(search_youtube "$query")
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy video phù hợp"
        log "ERROR" "Không có kết quả tìm kiếm YouTube"
        return 1
    fi
    
    local selected_video=$(echo "$search_results" | fzf --prompt="Chọn video: " --preview "echo {} | cut -d'|' -f2-")
    log "USER" "Chọn video YouTube" "$selected_video"
    
    if [[ -z "$selected_video" ]]; then
        warn "${SYM_WARNING} Không có video nào được chọn"
        log "WARN" "Không chọn video YouTube"
        return
    fi
    
    local video_title=$(echo "$selected_video" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
    local video_id=$(yt-dlp --get-id "ytsearch1:$video_title" 2>/dev/null)
    local video_url="https://youtu.be/$video_id"
    
    add_to_history "YouTube" "$video_title"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát video" "Phát video đã chọn"
            "${SYM_NEXT} 2. Phát video liên quan" "Phát video liên quan tiếp theo"
            "${SYM_DOWNLOAD} 3. Tải video xuống" "Tải video về thiết bị"
            "${SYM_FAV} 4. Thêm vào yêu thích" "Thêm video vào danh sách yêu thích"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi xem YouTube" "$choice"
        
        case $choice in
            1)
                play_video "$video_url" "YouTube: $video_title"
                ;;
            2)
                # Phát video liên quan
                local next_url=$(yt-dlp --flat-playlist --get-url "https://www.youtube.com/watch?v=$video_id" 2>/dev/null | head -n 1)
                if [[ -n "$next_url" ]]; then
                    video_url="$next_url"
                    video_title=$(yt-dlp --get-title "$next_url" 2>/dev/null)
                    add_to_history "YouTube" "$video_title"
                    play_video "$video_url" "YouTube: $video_title"
                else
                    warn "${SYM_WARNING} Không tìm thấy video liên quan"
                    log "WARN" "Không tìm thấy video liên quan"
                fi
                ;;
            3)
                download_video "$video_url" "$video_title" "$DOWNLOAD_DIR/YouTube" "YouTube"
                if [[ $? -eq 2 ]]; then
                    play_video "$video_url" "YouTube: $video_title"
                fi
                ;;
            4)
                add_to_favorites "YouTube: $video_title"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CHÍNH CỦA ANISUB ============================
main_menu() {
    while true; do
        show_header
        
        local options=(
            "${SYM_SEARCH} 1. Tìm kiếm và phát anime" "Tìm kiếm và xem anime từ nhiều nguồn"
            "${SYM_HIST} 2. Lịch sử xem" "Xem lịch sử các tập đã xem"
            "${SYM_FAV} 3. Danh sách yêu thích" "Quản lý danh sách anime yêu thích"
            "${SYM_TOOLS} 4. Công cụ video" "Cắt, ghép và chỉnh sửa video"
            "${SYM_SETTINGS} 5. Cài đặt" "Thay đổi cấu hình hệ thống"
            "${SYM_UPDATE} 6. Kiểm tra cập nhật" "Kiểm tra và cập nhật phiên bản mới"
            "${SYM_INFO} 7. Thông tin tác giả" "Thông tin về nhà phát triển"
            "${SYM_EXIT} 0. Thoát" "Thoát chương trình"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu chính" "$choice"
        
        case $choice in
            1) 
                log "MENU" "Vào menu Tìm kiếm và phát anime"
                search_and_play_menu 
                ;;
            2) 
                log "MENU" "Vào menu Lịch sử xem"
                history_menu 
                ;;
            3) 
                log "MENU" "Vào menu Danh sách yêu thích"
                favorites_menu 
                ;;
            4) 
                log "MENU" "Vào menu Công cụ video"
                video_tools_menu 
                ;;
            5) 
                log "MENU" "Vào menu Cài đặt"
                settings_menu 
                ;;
            6) 
                log "MENU" "Vào menu Kiểm tra cập nhật"
                check_for_updates 
                ;;
            7) 
                log "MENU" "Vào menu Thông tin tác giả"
                show_authors 
                ;;
            0) 
                log "SYSTEM" "Kết thúc chương trình"
                echo "Đã thoát Anisub..."
                exit 0 
                ;;
            *) 
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU TÌM KIẾM VÀ PHÁT VIDEO ============================
search_and_play_menu() {
    while true; do
        show_header
        
        local options=(
            "${SYM_SEARCH} 1. Tìm kiếm từ OPhim17" "Tìm kiếm anime từ nguồn OPhim17"
            "${SYM_SEARCH} 2. Tìm kiếm từ KKPhim" "Tìm kiếm anime từ nguồn KKPhim"
            "${SYM_SEARCH} 3. Tìm kiếm từ AniData" "Tìm kiếm anime từ nguồn AniData"
            "${SYM_SEARCH} 4. Tìm kiếm từ YouTube" "Tìm kiếm anime/AMV từ YouTube"
            "${SYM_PLAY} 5. Nhập URL trực tiếp" "Phát trực tiếp từ URL (OPhim17/KKPhim/AniData/YouTube)"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu tìm kiếm" "$choice"
        
        case $choice in
            1) search_ophim17 ;;
            2) search_kkphim ;;
            3) search_anidata ;;
            4) 
                read -p "Nhập từ khóa tìm kiếm trên YouTube: " query
                log "USER" "Tìm kiếm YouTube" "$query"
                play_from_youtube "$query" 
                ;;
            5) play_from_url ;;
            0) 
                log "NAVIGATE" "Quay lại menu chính"
                return 
                ;;
            *) 
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# Thêm hàm search_kkphim
search_kkphim() {
    read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập từ khóa tìm kiếm: " keyword
    log "USER" "Tìm kiếm KKPhim" "$keyword"
    
    if [[ -z "$keyword" ]]; then
        warn "${SYM_WARNING} Từ khóa không được để trống"
        log "WARN" "Từ khóa tìm kiếm trống"
        return
    fi
    
    local anime_list=$(search_anime_kkphim "$keyword")
    
    if [[ -z "$anime_list" ]]; then
        warn "${SYM_WARNING} Không tìm thấy anime nào với từ khóa '$keyword'"
        log "SEARCH" "Không tìm thấy kết quả cho: $keyword"
        return
    fi
    
    local selected_anime=$(echo "$anime_list" | fzf --prompt="Chọn anime: " --preview "echo {} | sed 's/.*(//;s/)//' | xargs -I{} curl -s {} | pup 'p.description text{}'")
    log "USER" "Chọn anime" "$selected_anime"
    
    if [[ -z "$selected_anime" ]]; then
        warn "${SYM_WARNING} Không có anime nào được chọn"
        log "WARN" "Không chọn anime"
        return
    fi
    
    local anime_url=$(echo "$selected_anime" | sed 's/.*(\(.*\))/\1/')
    local anime_name=$(echo "$selected_anime" | sed 's/^[^(]*(\([^)]*\)) \+//;s/ ([^ ]*)$//')
    
    play_anime_kkphim "$anime_url" "$anime_name"
}

# ============================ TÌM KIẾM TỪ OPHIM17 ============================
search_ophim17() {
    read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập từ khóa tìm kiếm: " keyword
    log "USER" "Tìm kiếm OPhim17" "$keyword"
    
    if [[ -z "$keyword" ]]; then
        warn "${SYM_WARNING} Từ khóa không được để trống"
        log "WARN" "Từ khóa tìm kiếm trống"
        return
    fi
    
    local anime_list=$(search_anime_ophim17 "$keyword")
    
    if [[ -z "$anime_list" ]]; then
        warn "${SYM_WARNING} Không tìm thấy anime nào với từ khóa '$keyword'"
        log "SEARCH" "Không tìm thấy kết quả cho: $keyword"
        return
    fi
    
    local selected_anime=$(echo "$anime_list" | fzf --prompt="Chọn anime: " --preview "echo {} | sed 's/.*(//;s/)//' | xargs -I{} curl -s {} | pup 'p.description text{}'")
    log "USER" "Chọn anime" "$selected_anime"
    
    if [[ -z "$selected_anime" ]]; then
        warn "${SYM_WARNING} Không có anime nào được chọn"
        log "WARN" "Không chọn anime"
        return
    fi
    
    local anime_url=$(echo "$selected_anime" | sed 's/.*(\(.*\))/\1/')
    local anime_name=$(echo "$selected_anime" | sed 's/^[^(]*(\([^)]*\)) \+//;s/ ([^ ]*)$//')
    
    play_anime_ophim17 "$anime_url" "$anime_name"
}

# ============================ PHÁT VIDEO ĐÓ TỪ OPHIM17 ============================
play_anime_ophim17() {
    local anime_url="$1"
    local anime_name="$2"
    log "STREAM" "Phát anime từ OPhim17: $anime_name (URL: $anime_url)"
    
    local episode_list=$(get_episode_list_ophim17 "$anime_url")
    if [[ -z "$episode_list" ]]; then
        error "${SYM_ERROR} Không thể lấy danh sách tập phim"
        log "ERROR" "Không lấy được danh sách tập phim"
        return
    fi
    
    local selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: " --preview "echo {} | cut -d'|' -f2")
    log "USER" "Chọn tập phim" "$selected_episode"
    
    if [[ -z "$selected_episode" ]]; then
        warn "${SYM_WARNING} Không có tập nào được chọn"
        log "WARN" "Không chọn tập phim"
        return
    fi
    
    local episode_number=$(echo "$selected_episode" | cut -d'|' -f1)
    local episode_url=$(echo "$selected_episode" | cut -d'|' -f2)
    local episode_title=$(get_episode_title "$anime_url" "$episode_number")
    
    add_to_history "$anime_name" "$episode_title"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát tập này" "Phát tập hiện tại"
            "${SYM_NEXT} 2. Phát tập tiếp theo" "Chuyển đến tập tiếp theo"
            "${SYM_PREV} 3. Phát tập trước đó" "Quay lại tập trước đó"
            "${SYM_SELECT} 4. Chọn tập khác" "Chọn tập phim khác"
            "${SYM_DOWNLOAD} 5. Tải tập này xuống" "Tải tập phim về thiết bị"
            "${SYM_FAV} 6. Thêm vào yêu thích" "Thêm anime vào danh sách yêu thích"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi xem phim" "$choice"
        
        case $choice in
            1)
                play_video "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            2)
                next_episode_number=$((episode_number + 1))
                local next_episode=$(echo "$episode_list" | grep "^$next_episode_number|")
                
                if [[ -z "$next_episode" ]]; then
                    warn "${SYM_WARNING} Không có tập tiếp theo"
                    log "WARN" "Không có tập tiếp theo"
                    continue
                fi
                
                episode_number=$next_episode_number
                episode_url=$(echo "$next_episode" | cut -d'|' -f2)
                episode_title=$(get_episode_title "$anime_url" "$episode_number")
                add_to_history "$anime_name" "$episode_title"
                play_video "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            3)
                previous_episode_number=$((episode_number - 1))
                local previous_episode=$(echo "$episode_list" | grep "^$previous_episode_number|")
                
                if [[ -z "$previous_episode" || $previous_episode_number -lt 1 ]]; then
                    warn "${SYM_WARNING} Không có tập trước đó"
                    log "WARN" "Không có tập trước đó"
                    continue
                fi
                
                episode_number=$previous_episode_number
                episode_url=$(echo "$previous_episode" | cut -d'|' -f2)
                episode_title=$(get_episode_title "$anime_url" "$episode_number")
                add_to_history "$anime_name" "$episode_title"
                play_video "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            4)
                selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: " --preview "echo {} | cut -d'|' -f2")
                log "USER" "Chọn tập phim khác" "$selected_episode"
                
                if [[ -z "$selected_episode" ]]; then
                    warn "${SYM_WARNING} Không có tập nào được chọn"
                    log "WARN" "Không chọn tập phim"
                    continue
                fi
                
                episode_number=$(echo "$selected_episode" | cut -d'|' -f1)
                episode_url=$(echo "$selected_episode" | cut -d'|' -f2)
                episode_title=$(get_episode_title "$anime_url" "$episode_number")
                add_to_history "$anime_name" "$episode_title"
                play_video "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            5)
                download_video "$episode_url" "$anime_name - Tập $episode_number: $episode_title" "$DOWNLOAD_DIR/$anime_name" "$anime_name"
                if [[ $? -eq 2 ]]; then
                    # Nếu người dùng chọn quay lại phát tập hiện tại
                    play_video "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                fi
                ;;
            6)
                add_to_favorites "$anime_name"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HÀM LẤY DANH SÁCH ANIME/PHIM TỪ KKPHIM ============================
search_anime_kkphim() {
    local keyword="$1"
    log "SEARCH" "Tìm kiếm trên KKPhim với từ khóa: $keyword"
    
    if [[ ${#keyword} -lt 3 ]]; then
        error "Từ khóa tìm kiếm phải có ít nhất 3 ký tự"
        log "ERROR" "Từ khóa quá ngắn: $keyword"
        return 1
    fi

    local cache_file="$CACHE_DIR/kkphim_search_${keyword}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $keyword"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm: $keyword..."
    local search_url="https://kkphim.com/tim-kiem?keyword=${keyword}"
    local anime_list
    
    if ! anime_list=$(timeout 20 curl -s "$search_url" | pup '.ml-4 > a attr{href}' 2>/dev/null); then
        error "Không thể tải dữ liệu tìm kiếm"
        log "ERROR" "Không thể tải dữ liệu tìm kiếm từ KKPhim"
        return 1
    fi
    
    if [[ -z "$anime_list" ]]; then
        warn "Không tìm thấy anime nào với từ khóa '$keyword'"
        log "SEARCH" "Không tìm thấy kết quả cho: $keyword"
        return 1
    fi

    # Xử lý kết quả tìm kiếm
    local processed_list=$(echo "$anime_list" | awk '{print "https://kkphim.com" $0}' | \
        while IFS= read -r link; do
            local title=$(timeout 20 curl -s "$link" | pup 'h1 text{}' | tr -d '\n' 2>/dev/null)
            if [[ -z "$title" ]]; then
                title="Không có tiêu đề"
                log "WARN" "Không lấy được tiêu đề cho URL: $link"
            fi
            printf '%s\n' "$link@@@$title"
        done | \
        awk -F '@@@' '{print NR ". " $2 " (" $1 ")"}' 2>/dev/null)
    
    if [[ -z "$processed_list" ]]; then
        error "Không thể xử lý kết quả tìm kiếm"
        log "ERROR" "Không thể xử lý kết quả tìm kiếm từ KKPhim"
        return 1
    fi
    
    # Lưu vào cache
    echo "$processed_list" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm vào cache: $cache_file"
    echo "$processed_list"
}

# ============================ HÀM LẤY DANH SÁCH TẬP TỪ KKPHIM ============================
get_episode_list_kkphim() {
    local url="$1"
    log "STREAM" "Lấy danh sách tập từ URL: $url"
    
    local cache_file="$CACHE_DIR/kkphim_episodes_$(echo "$url" | md5sum | cut -d' ' -f1).cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng danh sách tập từ cache"
            cat "$cache_file"
            return
        fi
    fi
    
    local html_content=$(curl -s "$url")
    if [[ -z "$html_content" ]]; then
        error "Không thể tải nội dung từ URL: $url"
        log "ERROR" "Không thể tải nội dung từ URL: $url"
        return 1
    fi
    
    local episode_data=$(echo "$html_content" | pup 'script json{}' | \
        jq -r '.[].text | @text' | \
        grep -oE '"(http|https)://[^"]*index.m3u8"' | \
        sed 's/"//g')
    
    if [[ -z "$episode_data" ]]; then
        error "Không tìm thấy danh sách tập phim cho URL: $url"
        log "ERROR" "Không tìm thấy danh sách tập phim cho URL: $url"
        return 1
    fi
    
    local i=1
    while IFS= read -r link; do
        printf "%s|%s\n" "$i" "$link"
        i=$((i + 1))
    done <<< "$episode_data" > "$cache_file"
    
    log "CACHE" "Lưu danh sách tập vào cache: $cache_file"
    cat "$cache_file"
}

# ============================ PHÁT ANIME TỪ KKPHIM ============================
play_anime_kkphim() {
    local anime_url="$1"
    local anime_name="$2"
    log "STREAM" "Phát anime từ KKPhim: $anime_name (URL: $anime_url)"
    
    local episode_list=$(get_episode_list_kkphim "$anime_url")
    if [[ -z "$episode_list" ]]; then
        error "${SYM_ERROR} Không thể lấy danh sách tập phim"
        log "ERROR" "Không lấy được danh sách tập phim"
        return
    fi
    
    local selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: ")
    log "USER" "Chọn tập phim" "$selected_episode"
    
    if [[ -z "$selected_episode" ]]; then
        warn "${SYM_WARNING} Không có tập nào được chọn"
        log "WARN" "Không chọn tập phim"
        return
    fi
    
    local episode_number=$(echo "$selected_episode" | cut -d'|' -f1)
    local episode_url=$(echo "$selected_episode" | cut -d'|' -f2)
    local episode_title="Tập $episode_number"
    
    add_to_history "$anime_name" "$episode_title"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát tập này" "Phát tập hiện tại"
            "${SYM_NEXT} 2. Phát tập tiếp theo" "Chuyển đến tập tiếp theo"
            "${SYM_PREV} 3. Phát tập trước đó" "Quay lại tập trước đó"
            "${SYM_SELECT} 4. Chọn tập khác" "Chọn tập phim khác"
            "${SYM_DOWNLOAD} 5. Tải tập này xuống" "Tải tập phim về thiết bị"
            "${SYM_FAV} 6. Thêm vào yêu thích" "Thêm anime vào danh sách yêu thích"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi xem phim" "$choice"
        
        case $choice in
            1)
                play_video "$episode_url" "$anime_name - Tập $episode_number"
                ;;
            2)
                next_episode_number=$((episode_number + 1))
                local next_episode=$(echo "$episode_list" | grep "^$next_episode_number|")
                
                if [[ -z "$next_episode" ]]; then
                    warn "${SYM_WARNING} Không có tập tiếp theo"
                    log "WARN" "Không có tập tiếp theo"
                    continue
                fi
                
                episode_number=$next_episode_number
                episode_url=$(echo "$next_episode" | cut -d'|' -f2)
                episode_title="Tập $episode_number"
                add_to_history "$anime_name" "$episode_title"
                play_video "$episode_url" "$anime_name - Tập $episode_number"
                ;;
            3)
                previous_episode_number=$((episode_number - 1))
                local previous_episode=$(echo "$episode_list" | grep "^$previous_episode_number|")
                
                if [[ -z "$previous_episode" || $previous_episode_number -lt 1 ]]; then
                    warn "${SYM_WARNING} Không có tập trước đó"
                    log "WARN" "Không có tập trước đó"
                    continue
                fi
                
                episode_number=$previous_episode_number
                episode_url=$(echo "$previous_episode" | cut -d'|' -f2)
                episode_title="Tập $episode_number"
                add_to_history "$anime_name" "$episode_title"
                play_video "$episode_url" "$anime_name - Tập $episode_number"
                ;;
            4)
                selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: ")
                log "USER" "Chọn tập phim khác" "$selected_episode"
                
                if [[ -z "$selected_episode" ]]; then
                    warn "${SYM_WARNING} Không có tập nào được chọn"
                    log "WARN" "Không chọn tập phim"
                    continue
                fi
                
                episode_number=$(echo "$selected_episode" | cut -d'|' -f1)
                episode_url=$(echo "$selected_episode" | cut -d'|' -f2)
                episode_title="Tập $episode_number"
                add_to_history "$anime_name" "$episode_title"
                play_video "$episode_url" "$anime_name - Tập $episode_number"
                ;;
            5)
                download_video "$episode_url" "$anime_name - Tập $episode_number" "$DOWNLOAD_DIR/$anime_name" "$anime_name"
                if [[ $? -eq 2 ]]; then
                    play_video "$episode_url" "$anime_name - Tập $episode_number"
                fi
                ;;
            6)
                add_to_favorites "$anime_name"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ TÌM KIẾM TỪ ANIDATA (@NiyakiPham QUẢN LÝ) ============================
search_anidata() {
    log "SEARCH" "Tìm kiếm từ AniData"
    local anime_list=$(get_anime_list_anidata)
    
    if [[ -z "$anime_list" ]]; then
        error "${SYM_ERROR} Không thể lấy danh sách anime từ AniData"
        log "ERROR" "Không lấy được danh sách từ AniData"
        return
    fi
    
    local selected_anime=$(echo "$anime_list" | fzf --prompt="Chọn anime: ")
    log "USER" "Chọn anime từ AniData" "$selected_anime"
    
    if [[ -z "$selected_anime" ]]; then
        warn "${SYM_WARNING} Không có anime nào được chọn"
        log "WARN" "Không chọn anime từ AniData"
        return
    fi
    
    play_anime_anidata "$selected_anime"
}

# ============================ PHÁT VIDEO ĐÓ TỪ ANIDATA (@NiyakiPham QUẢN LÝ) ============================
play_anime_anidata() {
    local anime_name="$1"
    log "STREAM" "Phát anime từ AniData: $anime_name"
    
    local episode_list=$(get_episode_list_anidata "$anime_name")
    if [[ -z "$episode_list" ]]; then
        error "${SYM_ERROR} Không thể lấy danh sách tập phim"
        log "ERROR" "Không lấy được danh sách tập từ AniData"
        return
    fi
    
    local selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: ")
    log "USER" "Chọn tập phim từ AniData" "$selected_episode"
    
    if [[ -z "$selected_episode" ]]; then
        warn "${SYM_WARNING} Không có tập nào được chọn"
        log "WARN" "Không chọn tập phim từ AniData"
        return
    fi
    
    local episode_title=$(echo "$selected_episode" | awk -F' | ' '{print $1}')
    local episode_url=$(echo "$selected_episode" | awk -F' | ' '{print $3}')
    
    add_to_history "$anime_name" "$episode_title"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát tập này" "Phát tập hiện tại"
            "${SYM_DOWNLOAD} 2. Tải tập này xuống" "Tải tập phim về thiết bị"
            "${SYM_FAV} 3. Thêm vào yêu thích" "Thêm anime vào danh sách yêu thích"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi xem phim từ AniData" "$choice"
        
        case $choice in
            1)
                play_video "$episode_url" "$anime_name - $episode_title"
                ;;
            2)
                download_video "$episode_url" "$anime_name - $episode_title" "$DOWNLOAD_DIR/$anime_name" "$anime_name"
                if [[ $? -eq 2 ]]; then
                    play_video "$episode_url" "$anime_name - $episode_title"
                fi
                ;;
            3)
                add_to_favorites "$anime_name"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ PHÁT VIDEO TỪ URL TRỰC TIẾP ============================
play_from_url() {
    read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập URL anime (OPhim17/KKPhim/AniData hoặc YouTube): " url
    log "USER" "Nhập URL trực tiếp" "$url"
    
    if [[ -z "$url" ]]; then
        warn "${SYM_WARNING} URL không được để trống"
        log "WARN" "URL trống"
        return
    fi
    
    if [[ "$url" == *"ophim17.cc"* ]]; then
        local anime_name=$(curl -s "$url" | pup 'h1 text{}' | tr -d '\n')
        play_anime_ophim17 "$url" "$anime_name"
    elif [[ "$url" == *"kkphim.com"* ]]; then
        local anime_name=$(curl -s "$url" | pup 'h1 text{}' | tr -d '\n')
        play_anime_kkphim "$url" "$anime_name"
    elif [[ "$url" == *"youtube.com"* || "$url" == *"youtu.be"* ]]; then
        local video_title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "YouTube Video")
        add_to_history "YouTube" "$video_title"
        
        while true; do
            show_header
            
            local options=(
                "${SYM_PLAY} 1. Phát video" "Phát video từ URL"
                "${SYM_DOWNLOAD} 2. Tải video xuống" "Tải video về thiết bị"
                "${SYM_FAV} 3. Thêm vào yêu thích" "Thêm video vào danh sách yêu thích"
                "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
            )
            
            show_menu "${options[@]}"
            
            read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
            log "USER" "Lựa chọn khi xem YouTube từ URL" "$choice"
            
            case $choice in
                1)
                    play_video "$url" "YouTube: $video_title"
                    ;;
                2)
                    download_video "$url" "$video_title" "$DOWNLOAD_DIR/YouTube" "YouTube"
                    if [[ $? -eq 2 ]]; then
                        play_video "$url" "YouTube: $video_title"
                    fi
                    ;;
                3)
                    add_to_favorites "YouTube: $video_title"
                    ;;
                0)
                    log "NAVIGATE" "Quay lại menu tìm kiếm"
                    return
                    ;;
                *)
                    warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                    log "WARN" "Lựa chọn không hợp lệ: $choice"
                    ;;
            esac
        done
    elif [[ "$url" == *"raw.githubusercontent.com/toilamsao/anidata"* ]]; then
        warn "${SYM_WARNING} Vui lòng sử dụng tùy chọn tìm kiếm AniData thay vì nhập URL trực tiếp"
        log "WARN" "Nhập URL AniData trực tiếp"
    else
        warn "${SYM_WARNING} URL không được hỗ trợ. Chỉ hỗ trợ OPhim17, KKPhim, AniData và YouTube."
        log "WARN" "URL không được hỗ trợ: $url"
    fi
}

# ============================ HIỂN THỊ MENU LỊCH SỬ XEM ============================
history_menu() {
    while true; do
        show_header
        
        local history_list=$(show_history)
        local content=""
        
        if [[ -z "$history_list" ]]; then
            content="Không có lịch sử xem."
        else
            content="$history_list"
        fi
        
        draw_box 60 "LỊCH SỬ XEM" "$SECONDARY" "$content"
        
        local options=(
            "${SYM_SEARCH} 1. Xem toàn bộ lịch sử" "Hiển thị toàn bộ lịch sử xem"
            "${SYM_DELETE} 2. Xóa lịch sử" "Xóa toàn bộ lịch sử xem"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu lịch sử" "$choice"
        
        case $choice in
            1)
                clear
                draw_box 80 "TOÀN BỘ LỊCH SỬ" "$SECONDARY" "$history_list"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                log "HISTORY" "Xem toàn bộ lịch sử"
                ;;
            2)
                > "$HISTORY_FILE"
                notify "${SYM_SUCCESS} Đã xóa toàn bộ lịch sử"
                log "HISTORY" "Xóa toàn bộ lịch sử"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu chính"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU YÊU THÍCH ============================
favorites_menu() {
    while true; do
        show_header
        
        local favorites_list=$(show_favorites)
        local content=""
        
        if [[ -z "$favorites_list" ]]; then
            content="Không có anime nào trong danh sách yêu thích."
        else
            content="$favorites_list"
        fi
        
        draw_box 60 "DANH SÁCH YÊU THÍCH" "$SECONDARY" "$content"
        
        local options=(
            "${SYM_SEARCH} 1. Xem toàn bộ yêu thích" "Hiển thị toàn bộ danh sách yêu thích"
            "${SYM_PLAY} 2. Phát anime từ yêu thích" "Chọn và phát anime từ danh sách yêu thích"
            "${SYM_DELETE} 3. Xóa anime khỏi yêu thích" "Xóa anime khỏi danh sách yêu thích"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu yêu thích" "$choice"
        
        case $choice in
            1)
                clear
                draw_box 80 "TOÀN BỘ YÊU THÍCH" "$SECONDARY" "$favorites_list"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                log "FAVORITE" "Xem toàn bộ yêu thích"
                ;;
            2)
                if [[ -z "$favorites_list" ]]; then
                    warn "${SYM_WARNING} Không có anime nào trong danh sách yêu thích"
                    log "WARN" "Danh sách yêu thích trống"
                    continue
                fi
                
                local selected_anime=$(echo "$favorites_list" | fzf --prompt="Chọn anime từ yêu thích: " | sed 's/^[0-9]*\. //')
                log "USER" "Chọn anime từ yêu thích" "$selected_anime"
                
                if [[ -z "$selected_anime" ]]; then
                    warn "${SYM_WARNING} Không có anime nào được chọn"
                    log "WARN" "Không chọn anime từ yêu thích"
                    continue
                fi
                
                # Kiểm tra xem anime có trong AniData không
                local anime_list=$(get_anime_list_anidata)
                if echo "$anime_list" | grep -q "^$selected_anime$"; then
                    play_anime_anidata "$selected_anime"
                else
                    # Nếu không có trên AniData, thử tìm trên OPhim17
                    local anime_name_encoded=$(echo "$selected_anime" | sed 's/ /+/g')
                    local anime_list=$(search_anime_ophim17 "$anime_name_encoded")
                    
                    if [[ -n "$anime_list" ]]; then
                        local selected_anime=$(echo "$anime_list" | head -n 1)
                        local anime_url=$(echo "$selected_anime" | sed 's/.*(\(.*\))/\1/')
                        local anime_name=$(echo "$selected_anime" | sed 's/^[^(]*(\([^)]*\)) \+//;s/ ([^ ]*)$//')
                        play_anime_ophim17 "$anime_url" "$anime_name"
                    else
                        warn "${SYM_WARNING} Không tìm thấy anime '$selected_anime' trên OPhim17"
                        log "WARN" "Không tìm thấy anime trên OPhim17: $selected_anime"
                    fi
                fi
                ;;
            3)
                if [[ -z "$favorites_list" ]]; then
                    warn "${SYM_WARNING} Không có anime nào trong danh sách yêu thích"
                    log "WARN" "Danh sách yêu thích trống"
                    continue
                fi
                
                local selected_anime=$(echo "$favorites_list" | fzf --prompt="Chọn anime để xóa: " | sed 's/^[0-9]*\. //')
                log "USER" "Chọn anime để xóa" "$selected_anime"
                
                if [[ -z "$selected_anime" ]]; then
                    warn "${SYM_WARNING} Không có anime nào được chọn"
                    log "WARN" "Không chọn anime để xóa"
                    continue
                fi
                
                remove_from_favorites "$selected_anime"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu chính"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CÔNG CỤ VIDEO ============================
video_tools_menu() {
    while true; do
        show_header
        
        local options=(
            "${SYM_CUT} 1. Cắt video" "Cắt video từ URL hoặc file đã tải"
            "${SYM_MERGE} 2. Ghép video" "Ghép nhiều video thành một"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu công cụ video" "$choice"
        
        case $choice in
            1) cut_video_menu ;;
            2) merge_videos ;;
            0) 
                log "NAVIGATE" "Quay lại menu chính"
                return 
                ;;
            *) 
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CẮT VIDEO ============================
cut_video_menu() {
    while true; do
        show_header
        
        local options=(
            "${SYM_CUT} 1. Cắt video từ URL" "Cắt video trực tiếp từ URL"
            "${SYM_CUT} 2. Cắt video từ file đã tải" "Cắt video đã tải về thiết bị"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu công cụ video"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu cắt video" "$choice"
        
        case $choice in
            1)
                read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập URL video: " url
                log "USER" "Nhập URL video để cắt" "$url"
                
                if [[ -z "$url" ]]; then
                    warn "${SYM_WARNING} URL không được để trống"
                    log "WARN" "URL video trống"
                    continue
                fi
                
                read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập tiêu đề video: " title
                if [[ -z "$title" ]]; then
                    title="Video_$(date +%s)"
                    log "USER" "Sử dụng tiêu đề mặc định" "$title"
                else
                    log "USER" "Nhập tiêu đề video" "$title"
                fi
                
                cut_video "$url" "$title"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                local video_file=$(find "$DOWNLOAD_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" \) | fzf --prompt="Chọn video: ")
                log "USER" "Chọn video để cắt" "$video_file"
                
                if [[ -z "$video_file" ]]; then
                    warn "${SYM_WARNING} Không có video nào được chọn"
                    log "WARN" "Không chọn video"
                    continue
                fi
                
                local title=$(basename "$video_file" | sed 's/\.[^.]*$//')
                cut_video "$video_file" "$title"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            0)
                log "NAVIGATE" "Quay lại menu công cụ video"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CÀI ĐẶT ============================
settings_menu() {
    while true; do
        show_header
        
        local current_log_level="${LOG_LEVEL^^}"
        local log_status=$([[ "$LOG_TO_FILE" == "true" ]] && echo "BẬT" || echo "TẮT")
        local notify_status=$([[ "$TERMINAL_NOTIFY" == "true" ]] && echo "BẬT" || echo "TẮT")
        local optional_pkgs_status=$([[ "$SKIP_OPTIONAL_PKGS" == "true" ]] && echo "TẮT" || echo "BẬT")
        local dependency_check_status=$([[ "$SKIP_DEPENDENCY_CHECK" == "true" ]] && echo "TẮT" || echo "BẮT")
        
        local options=(
            "${SYM_FOLDER} 1. Thay đổi thư mục tải xuống" "Thay đổi nơi lưu video tải về"
            "${SYM_PLAY} 2. Thay đổi trình phát mặc định" "Chọn trình phát video (mpv/vlc/ffplay)"
            "${SYM_SETTINGS} 3. Thay đổi chất lượng mặc định" "Chọn chất lượng video (360p/480p/720p/1080p)"
            "${SYM_SETTINGS} 4. Thay đổi chủ đề" "Thay đổi giao diện màu sắc"
            "${SYM_SETTINGS} 5. Bật/tắt thông báo" "Bật hoặc tắt thông báo hệ thống"
            "${SYM_SETTINGS} 6. Bật/tắt thông báo terminal" "Bật hoặc tắt thông báo trên terminal"
            "${SYM_SETTINGS} 7. Xóa cache" "Xóa toàn bộ dữ liệu cache"
            "${SYM_SETTINGS} 8. Sao lưu cấu hình" "Sao lưu cấu hình hiện tại"
            "${SYM_SETTINGS} 9. Khôi phục cấu hình" "Khôi phục từ bản sao lưu"
            "${SYM_SETTINGS} 10. Bật/tắt kiểm tra phụ thuộc: $dependency_check_status" "Bật hoặc tắt kiểm tra gói khi khởi động"
            "${SYM_SETTINGS} 11. Cấu hình log" "Thay đổi cấu hình ghi log"
            "${SYM_SETTINGS} 12. Bật/tắt gói tùy chọn: $optional_pkgs_status" "Bật hoặc tắt cài đặt gói tùy chọn"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu cài đặt" "$choice"
        
        case $choice in
            1) change_download_dir ;;
            2) change_default_player ;;
            3) change_default_quality ;;
            4) change_theme ;;
            5) toggle_notifications ;;
            6) toggle_terminal_notify ;;
            7) clear_cache ;;
            8) backup_config ;;
            9) restore_config ;;
            10) toggle_dependency_check ;;
            11) configure_logging ;;
            12) toggle_optional_packages ;;
            0) 
                log "NAVIGATE" "Quay lại menu chính"
                return 
                ;;
            *) 
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ THAY ĐỔI THƯ MỤC TẢI XUỐNG ============================
change_download_dir() {
    read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập đường dẫn thư mục tải xuống mới: " new_dir
    log "USER" "Nhập thư mục tải xuống mới" "$new_dir"
    
    if [[ -z "$new_dir" ]]; then
        warn "${SYM_WARNING} Đường dẫn không được để trống"
        log "WARN" "Thư mục tải xuống trống"
        return
    fi
    
    mkdir -p "$new_dir"
    if [[ ! -d "$new_dir" ]]; then
        error "${SYM_ERROR} Không thể tạo thư mục $new_dir"
        log "ERROR" "Không thể tạo thư mục: $new_dir"
        return
    fi
    
    sed -i "s|^DOWNLOAD_DIR=.*|DOWNLOAD_DIR=\"$new_dir\"|" "$CONFIG_FILE"
    DOWNLOAD_DIR="$new_dir"
    notify "${SYM_SUCCESS} Đã thay đổi thư mục tải xuống thành: $new_dir"
    log "SETTINGS" "Thay đổi thư mục tải xuống thành: $new_dir"
}

# ============================ THAY ĐỔI TRÌNH PHÁT MẶC ĐỊNH ============================
change_default_player() {
    local players=("mpv" "vlc" "ffplay")
    local selected=$(printf "%s\n" "${players[@]}" | fzf --prompt="Chọn trình phát mặc định: ")
    log "USER" "Chọn trình phát mặc định" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có trình phát nào được chọn"
        log "WARN" "Không chọn trình phát"
        return
    fi
    
    sed -i "s/^DEFAULT_PLAYER=.*/DEFAULT_PLAYER=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_PLAYER="$selected"
    notify "${SYM_SUCCESS} Đã thay đổi trình phát mặc định thành: $selected"
    log "SETTINGS" "Thay đổi trình phát mặc định thành: $selected"
}

# ============================ THAY ĐỔI CHẤT LƯỢNG MẶC ĐỊNH ============================
change_default_quality() {
    local qualities=("360p" "480p" "720p" "1080p")
    local selected=$(printf "%s\n" "${qualities[@]}" | fzf --prompt="Chọn chất lượng mặc định: ")
    log "USER" "Chọn chất lượng mặc định" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có chất lượng nào được chọn"
        log "WARN" "Không chọn chất lượng"
        return
    fi
    
    sed -i "s/^DEFAULT_QUALITY=.*/DEFAULT_QUALITY=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_QUALITY="$selected"
    notify "${SYM_SUCCESS} Đã thay đổi chất lượng mặc định thành: $selected"
    log "SETTINGS" "Thay đổi chất lượng mặc định thành: $selected"
}

# ============================ THAY ĐỔI CHỦ ĐỀ ============================
change_theme() {
    local themes=("dark" "light" "blue" "green" "red")
    local selected=$(printf "%s\n" "${themes[@]}" | fzf --prompt="Chọn chủ đề: ")
    log "USER" "Chọn chủ đề" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có chủ đề nào được chọn"
        log "WARN" "Không chọn chủ đề"
        return
    fi
    
    sed -i "s/^THEME=.*/THEME=\"$selected\"/" "$CONFIG_FILE"
    THEME="$selected"
    init_ui
    notify "${SYM_SUCCESS} Đã thay đổi chủ đề thành: $selected"
    log "SETTINGS" "Thay đổi chủ đề thành: $selected"
}

# ============================ BẬT/TẮT THÔNG BÁO ============================
toggle_notifications() {
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=false/" "$CONFIG_FILE"
        NOTIFICATIONS="false"
        notify "${SYM_SUCCESS} Đã tắt thông báo"
        log "SETTINGS" "Tắt thông báo"
    else
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=true/" "$CONFIG_FILE"
        NOTIFICATIONS="true"
        notify "${SYM_SUCCESS} Đã bật thông báo"
        log "SETTINGS" "Bật thông báo"
    fi
}

# ============================ BẬT/TẮT THÔNG BÁO TERMINAL ============================
toggle_terminal_notify() {
    if [[ "$TERMINAL_NOTIFY" == "true" ]]; then
        sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=false/" "$CONFIG_FILE"
        TERMINAL_NOTIFY="false"
        notify "${SYM_SUCCESS} Đã tắt thông báo terminal"
        log "SETTINGS" "Tắt thông báo terminal"
    else
        sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=true/" "$CONFIG_FILE"
        TERMINAL_NOTIFY="true"
        notify "${SYM_SUCCESS} Đã bật thông báo terminal"
        log "SETTINGS" "Bật thông báo terminal"
    fi
}

# ============================ BẬT/TẮT KIỂM TRA PHỤ THUỘC ============================
toggle_dependency_check() {
    if [[ "$SKIP_DEPENDENCY_CHECK" == "true" ]]; then
        sed -i "s/^SKIP_DEPENDENCY_CHECK=.*/SKIP_DEPENDENCY_CHECK=false/" "$CONFIG_FILE"
        SKIP_DEPENDENCY_CHECK="false"
        notify "${SYM_SUCCESS} Đã bật kiểm tra phụ thuộc"
        log "SETTINGS" "Bật kiểm tra phụ thuộc"
    else
        sed -i "s/^SKIP_DEPENDENCY_CHECK=.*/SKIP_DEPENDENCY_CHECK=true/" "$CONFIG_FILE"
        SKIP_DEPENDENCY_CHECK="true"
        notify "${SYM_SUCCESS} Đã tắt kiểm tra phụ thuộc"
        log "SETTINGS" "Tắt kiểm tra phụ thuộc"
    fi
}

# ============================ XÓA CACHE ============================
clear_cache() {
    rm -rf "$CACHE_DIR"/*
    notify "${SYM_SUCCESS} Đã xóa toàn bộ cache"
    log "SETTINGS" "Xóa toàn bộ cache"
}

# ============================ SAO LƯU CẤU HÌNH ============================
backup_config() {
    local backup_file="$BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S).cfg"
    cp "$CONFIG_FILE" "$backup_file"
    notify "${SYM_SUCCESS} Đã sao lưu cấu hình tại: $backup_file"
    log "SETTINGS" "Sao lưu cấu hình tại: $backup_file"
}

# ============================ KHÔI PHỤC CẤU HÌNH ============================
restore_config() {
    local backup_files=($(ls -t "$BACKUP_DIR"/config_backup_*.cfg 2>/dev/null))
    
    if [[ ${#backup_files[@]} -eq 0 ]]; then
        warn "${SYM_WARNING} Không có bản sao lưu nào được tìm thấy"
        log "WARN" "Không tìm thấy bản sao lưu"
        return
    fi
    
    local selected=$(printf "%s\n" "${backup_files[@]}" | fzf --prompt="Chọn bản sao lưu: ")
    log "USER" "Chọn bản sao lưu" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có bản sao lưu nào được chọn"
        log "WARN" "Không chọn bản sao lưu"
        return
    fi
    
    cp "$selected" "$CONFIG_FILE"
    source "$CONFIG_FILE"
    notify "${SYM_SUCCESS} Đã khôi phục cấu hình từ: $selected"
    log "SETTINGS" "Khôi phục cấu hình từ: $selected"
}

# ============================ XỬ LÝ CLI ARGUMENTS ============================
process_cli_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--update)
                log "SYSTEM" "Cập nhật script từ CLI"
                update_script
                exit 0
                ;;
            -v|--version)
                log "SYSTEM" "Hiển thị phiên bản từ CLI"
                echo "Anisub version $VERSION"
                exit 0
                ;;
            -h|--help)
                log "SYSTEM" "Hiển thị trợ giúp từ CLI"
                show_help
                exit 0
                ;;
            --play)
                if [[ -z "$2" ]]; then
                    error "${SYM_ERROR} Thiếu tên anime cần phát"
                    log "ERROR" "Thiếu tên anime từ CLI"
                    exit 1
                fi
                DIRECT_PLAY="$2"
                log "SYSTEM" "Phát trực tiếp từ CLI: $DIRECT_PLAY"
                shift
                ;;
            --search)
                if [[ -z "$2" ]]; then
                    error "${SYM_ERROR} Thiếu từ khóa tìm kiếm"
                    log "ERROR" "Thiếu từ khóa tìm kiếm từ CLI"
                    exit 1
                fi
                DIRECT_SEARCH="$2"
                log "SYSTEM" "Tìm kiếm trực tiếp từ CLI: $DIRECT_SEARCH"
                shift
                ;;
            --download)
                if [[ -z "$2" ]]; then
                    error "${SYM_ERROR} Thiếu URL video cần tải"
                    log "ERROR" "Thiếu URL tải từ CLI"
                    exit 1
                fi
                DIRECT_DOWNLOAD="$2"
                log "SYSTEM" "Tải trực tiếp từ CLI: $DIRECT_DOWNLOAD"
                shift
                ;;
            *)
                error "${SYM_ERROR} Argument không hợp lệ: $1"
                log "ERROR" "Argument không hợp lệ từ CLI: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# ============================ HIỂN THỊ TRỢ GIÚP ============================
show_help() {
    draw_box 80 "TRỢ GIÚP ANISUB" "$PRIMARY" "\
${ACCENT}Usage:${NC} $0 [OPTION]

${ACCENT}Options:${NC}
  -u, --update        Cập nhật script lên phiên bản mới nhất
  -v, --version       Hiển thị phiên bản hiện tại
  -h, --help          Hiển thị thông tin trợ giúp này
  --play \"TÊN\"       Phát trực tiếp anime không qua menu
  --search \"TỪ KHÓA\"  Tìm kiếm nhanh anime
  --download \"URL\"    Tải video từ URL

${ACCENT}Ví dụ:${NC}
  $0 --play \"One Piece\"
  $0 --search \"Attack on Titan\"
  $0 --download \"https://ophim17.cc/phim/one-piece\"

${ACCENT}Tác giả:${NC} ${AUTHORS[*]}
${ACCENT}Donate:${NC} $DONATION_LINK"
    exit 0
}

# ============================ KIỂM TRA BẢN CẬP NHẬT ============================
check_for_updates() {
    log "SYSTEM" "Kiểm tra bản cập nhật"
    notify "${SYM_UPDATE} Đang kiểm tra bản cập nhật..."
    
    # Thêm kiểm tra kết nối Internet trước
    if ! curl -Is https://github.com >/dev/null 2>&1; then
        error "${SYM_ERROR} Không thể kết nối đến GitHub. Vui lòng kiểm tra kết nối Internet."
        log "ERROR" "Không có kết nối Internet để kiểm tra cập nhật"
        return 1
    fi

    # Sử dụng URL raw chính xác 
    local latest_content=$(curl -s "https://raw.githubusercontent.com/kidtomboy/Anisub/main/anisub.sh")
    if [[ -z "$latest_content" ]]; then
        error "${SYM_ERROR} Không thể tải nội dung từ GitHub"
        log "ERROR" "Không thể tải nội dung từ GitHub"
        return 1
    fi

    local latest_version=$(echo "$latest_content" | grep -m1 "VERSION=" | cut -d'"' -f2)
    
    if [[ -z "$latest_version" ]]; then
        error "${SYM_ERROR} Không thể xác định phiên bản mới nhất"
        log "ERROR" "Không thể xác định phiên bản mới nhất"
        return 1
    fi

    if [[ "$latest_version" != "$VERSION" ]]; then
        warn "${SYM_WARNING} Đã có bản cập nhật mới!"
        log "UPDATE" "Phát hiện phiên bản mới: $latest_version (Hiện tại: $VERSION)"
        draw_box 60 "CẬP NHẬT MỚI" "$WARNING" "\
${ACCENT}Bản hiện tại:${NC} $VERSION
${ACCENT}Bản mới nhất:${NC} $latest_version

${TEXT}Bạn có muốn cập nhật không?${NC}"
        
        read -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập lựa chọn (y/N): " -n 1 -r
        echo
        log "USER" "Lựa chọn cập nhật" "$REPLY"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_script
        else
            notify "${SYM_INFO} Bạn đã chọn không cập nhật. Có thể có lỗi tiềm ẩn khi sử dụng bản cũ."
            log "UPDATE" "Người dùng từ chối cập nhật"
        fi
    else
        notify "${SYM_SUCCESS} Bạn đang sử dụng phiên bản mới nhất ($VERSION)"
        log "UPDATE" "Đang sử dụng phiên bản mới nhất: $VERSION"
    fi
}

# ============================ CẬP NHẬT SCRIPT ============================
update_script() {
    log "SYSTEM" "Bắt đầu cập nhật script"
    notify "${SYM_UPDATE} Đang cập nhật script..."
    local tmp_file="/tmp/anisub_update.sh"
    
    if curl -s "https://raw.githubusercontent.com/kidtomboy/Anisub/main/anisub.sh" -o "$tmp_file"; then
        # Kiểm tra xem file tải về có hợp lệ không
        if grep -q "ANISUB PRO MAX" "$tmp_file"; then
            chmod +x "$tmp_file"
            mv "$tmp_file" "$0"
            notify "${SYM_SUCCESS} Cập nhật thành công! Vui lòng chạy lại script."
            log "UPDATE" "Cập nhật thành công"
            exit 0
        else
            rm -f "$tmp_file"
            error "${SYM_ERROR} File tải về không hợp lệ"
            log "ERROR" "File cập nhật không hợp lệ"
            return 1
        fi
    else
        error "${SYM_ERROR} Không thể tải bản cập nhật. Vui lòng thử lại sau."
        log "ERROR" "Không thể tải bản cập nhật"
        return 1
    fi
}

# ============================ HIỂN THỊ THÔNG TIN TÁC GIẢ ============================
show_authors() {
    log "SYSTEM" "Hiển thị thông tin tác giả"
    clear
    draw_box 60 "THÔNG TIN TÁC GIẢ" "$PRIMARY" "\
${ACCENT}Tác giả:${NC} ${AUTHORS[*]}

${ACCENT}Donate:${NC} $DONATION_LINK

${ACCENT}Github:${NC} https://github.com/kidtomboy

${TEXT}Cảm ơn bạn đã sử dụng Anisub!${NC}"
    
    read -n 1 -s -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhấn bất kỳ phím nào để tiếp tục..."
}

# ============================ HÀM CHÍNH ============================
main() {
    # Bắt lỗi và thoát
    trap 'handle_interrupt SIGINT' SIGINT
    trap 'handle_interrupt SIGTSTP' SIGTSTP
    trap 'log "SYSTEM" "Chương trình bị dừng đột ngột"; exit 1' SIGTERM
    
    init_dirs
    init_ui
    check_dependencies "$1"
    
    # Xử lý CLI arguments nếu có
    if [[ $# -gt 0 ]]; then
        process_cli_arguments "$@"
    fi
    
        # Xử lý các lệnh trực tiếp
    if [[ -n "$DIRECT_PLAY" ]]; then
        log "SYSTEM" "Phát trực tiếp: $DIRECT_PLAY"
        
        # Thử tìm trên AniData trước
        local anime_list=$(get_anime_list_anidata)
        if echo "$anime_list" | grep -q "^$DIRECT_PLAY$"; then
            play_anime_anidata "$DIRECT_PLAY"
            exit 0
        fi
        
        # Nếu không có trên AniData, thử tìm trên OPhim17 hoặc KKPhim
        local anime_name_encoded=$(echo "$DIRECT_PLAY" | sed 's/ /+/g')
        
        # Thử tìm trên OPhim17 trước
        local anime_list=$(search_anime_ophim17 "$anime_name_encoded")
        
        if [[ -n "$anime_list" ]]; then
            local selected_anime=$(echo "$anime_list" | head -n 1)
            local anime_url=$(echo "$selected_anime" | sed 's/.*(\(.*\))/\1/')
            local anime_name=$(echo "$selected_anime" | sed 's/^[^(]*(\([^)]*\)) \+//;s/ ([^ ]*)$//')
            play_anime_ophim17 "$anime_url" "$anime_name"
            exit 0
        else
            # Nếu không có trên OPhim17, thử tìm trên KKPhim
            local anime_list=$(search_anime_kkphim "$anime_name_encoded")
            
            if [[ -n "$anime_list" ]]; then
                local selected_anime=$(echo "$anime_list" | head -n 1)
                local anime_url=$(echo "$selected_anime" | sed 's/.*(\(.*\))/\1/')
                local anime_name=$(echo "$selected_anime" | sed 's/^[^(]*(\([^)]*\)) \+//;s/ ([^ ]*)$//')
                play_anime_kkphim "$anime_url" "$anime_name"
                exit 0
            else
                error "${SYM_ERROR} Không tìm thấy anime '$DIRECT_PLAY'"
                log "ERROR" "Không tìm thấy anime để phát trực tiếp: $DIRECT_PLAY"
                exit 1
            fi
        fi
    fi
    
    
    # Hiển thị thông báo khởi động
    show_header
    
    local content="\
${SYM_SUCCESS} Đang khởi động Anisub Pro Max...
${SYM_SUCCESS} Hệ điều hành: $OS ($OS_DISTRO)
${SYM_SUCCESS} Thư mục cấu hình: $CONFIG_DIR
${SYM_SUCCESS} Thư mục tải xuống: $DOWNLOAD_DIR"
    
    draw_box 60 "THÔNG TIN HỆ THỐNG" "$INFO" "$content"
    sleep 2
    
    # Kiểm tra kết nối Internet
    if ! curl -Is https://google.com | grep -q "HTTP/2"; then
        error "${SYM_ERROR} Không có kết nối Internet. Vui lòng kiểm tra kết nối của bạn."
        log "ERROR" "Không có kết nối Internet"
        exit 1
    fi
    
    # Chạy menu chính
    main_menu
}

# ============================ XỬ LÝ KHI NGƯỜI DÙNG NHẤN CTRL+C HOẶC CTRL+Z ============================
handle_interrupt() {
    case $1 in
        SIGINT)
            echo
            warn "${SYM_WARNING} Bạn có chắc muốn thoát? (y/N) "
            read -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "SYSTEM" "Người dùng chọn thoát khi nhấn Ctrl+C"
                echo
                exit 0
            else
                log "SYSTEM" "Người dùng chọn tiếp tục sau khi nhấn Ctrl+C"
                echo
                main_menu
            fi
            ;;
        SIGTSTP)
            echo
            log "SYSTEM" "Phát hiện dừng đột ngột (Ctrl+Z)"
            exit 0
            ;;
    esac
}

# Chạy chương trình
main "$@"

# Kết thúc
exit 0
