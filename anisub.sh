#!/bin/bash

###############################################################################
# ANISUB PRO MAX xD
# Phiên bản: Không biết vì lười nghĩ ra
# Tác giả: Github: @NiyakiPham - Remake by @Kidtomboy 1337
# Ngày cập nhật: Lười lắm ghi cho có thôi ^^
#
# Tính năng chính:
# - Phát anime từ nhiều nguồn (Cụ thể là Ophim, Anidata)
# - Đọc manga trực tuyến (Chưa cập nhật)
# - Tải xuống tập phim về thiết bị
# - Cắt và ghép video ngay trên terminal
# - Lịch sử xem video
# - Thêm video vào danh sách yêu thích 
# - Hệ thống cấu hình và cache (Có thể chỉnh sửa)
# - Bật/tắt thông báo (Tùy chọn)
###############################################################################
# PHIỂN BẢN CỦA ANISUB VÀ THỜI GIAN CODE LẪN CHỈNH SỬA

# Phiên bản script 
VERSION="Unknown 1337"

# Liệt kê thời gian code và chỉnh sửa lại: 
# START: 23/3/2025 - 19:20
# 1
# 2
# 3
# 4
# 5
# 6 
# Ngày nào cũng code sao nhớ nổi T^T
# END: 28/3/2025 - 2:30

# ============================ CẤU HÌNH CỦA ANISUB ============================
CONFIG_DIR="$HOME/.config/anisub_cli"           # Có thể thay đổi tùy ý
CONFIG_FILE="$CONFIG_DIR/config.cfg"            # Có thể thay đổi tùy ý
DOWNLOAD_DIR="$HOME/Downloads/anime"            # Có thể thay đổi tùy ý
LOG_FILE="$CONFIG_DIR/anisub_cli.log"           # Có thể thay đổi tùy ý
CACHE_DIR="$CONFIG_DIR/cache"                   # Có thể thay đổi tùy ý
HISTORY_FILE="$CONFIG_DIR/history.txt"          # Có thể thay đổi tùy ý
FAVORITES_FILE="$CONFIG_DIR/favorites.txt"      # Có thể thay đổi tùy ý

# ============================ CẤU HÌNH MÀU SẮC ============================
RED='\033[0;31m'            # Có thể thay đổi tùy ý
GREEN='\033[0;32m'          # Có thể thay đổi tùy ý
YELLOW='\033[1;33m'         # Có thể thay đổi tùy ý
BLUE='\033[0;34m'           # Có thể thay đổi tùy ý
MAGENTA='\033[0;35m'        # Có thể thay đổi tùy ý
CYAN='\033[0;36m'           # Có thể thay đổi tùy ý
NC='\033[0m' # Không màu    # Có thể thay đổi tùy ý

# Source bên dưới không được chỉnh sửa nếu không nắm rõ về code!!! @Kidtomboy

# ============================ COOLDOWN THÔNG BÁO ============================
LAST_NOTIFICATION_TIME=0
NOTIFICATION_COOLDOWN=2 # 2 giây            # Tăng thời gian Cooldown nếu cần

# ============================ KHỞI TẠO THƯ MỤC VÀ FILE CẦN THIẾT ============================
init_dirs() {
    mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR" "$CACHE_DIR"
    touch "$LOG_FILE" "$HISTORY_FILE" "$FAVORITES_FILE"
    
    # Tạo file config nếu chưa có
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<- EOM

# ============================ CẤU HÌNH MẶC ĐỊNH CỦA ANISUB ============================
DEFAULT_PLAYER="mpv"
DEFAULT_QUALITY="720p"
DEFAULT_SOURCE="ophim"
MAX_CACHE_AGE=86400 # 1 ngày ( Tình bằng thời gian: giây)
THEME="dark"
NOTIFICATIONS=true
EOM
    fi
    
    # Load cấu hình
    source "$CONFIG_FILE"
}

# ============================ KIỂM TRA THÔNG BÁO ============================
can_notify() {
    local current_time=$(date +%s)
    if (( current_time - LAST_NOTIFICATION_TIME >= NOTIFICATION_COOLDOWN )); then
        LAST_NOTIFICATION_TIME=$current_time
        return 0
    fi
    return 1
}

# ============================ GHI LOG (NHẬT KÝ) ============================
log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# ============================ HIỂN THỊ CÁC THÔNG BÁO ============================
notify() {
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        if can_notify; then
            if command -v notify-send &> /dev/null; then
                notify-send "Anisub" "$1"
            fi
        fi
    fi
    echo -e "${GREEN}[INFO]${NC} $1"
    log "$1"
}

# Hiển thị cảnh báo (WARN)
warn() {
    if can_notify; then
        echo -e "${YELLOW}[WARN]${NC} $1" >&2
    fi
    log "[WARN] $1"
}

# Hiển thị lỗi (ERROR - WTF)
error() {
    if can_notify; then
        echo -e "${RED}[ERROR]${NC} $1" >&2
    fi
    log "[ERROR] $1"
}

# ============================ KIỂM TRA CÁC GÓI ============================
check_dependencies() {
    local missing=()
    
    # Các lệnh bắt buộc để cài gói
    for cmd in curl pup jq fzf mpv; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    # Các lệnh tùy chọn
    for cmd in yt-dlp ffmpeg notify-send manga-tui; do
        if ! command -v "$cmd" &> /dev/null; then
            warn "$cmd không được tìm thấy, một số tính năng có thể bị hạn chế"
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Thiếu các gói bắt buộc: ${missing[*]}"
        echo "Vui lòng cài đặt chúng trước khi sử dụng script này."
        exit 1
    fi
}

# ============================ HÀM LẤY DANH SÁCH ANIME/PHIM TỪ OPHIM ============================
search_anime_ophim() {
    local keyword="$1"
    local cache_file="$CACHE_DIR/ophim_search_${keyword}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi
    
    local anime_list
    anime_list=$(curl -s "https://ophim17.cc/tim-kiem?keyword=$keyword" | \
        pup '.ml-4 > a attr{href}' | \
        awk '{print "https://ophim17.cc" $0}' | \
        while IFS= read -r link; do
            local title=$(curl -s "$link" | pup 'h1 text{}' | tr -d '\n')
            printf '%s\n' "$link@@@$title"
        done | \
        awk -F '@@@' '{print NR ". " $2 " (" $1 ")"}')
    
    # Lưu vào cache
    if [[ -n "$anime_list" ]]; then
        echo "$anime_list" > "$cache_file"
    fi
    
    echo "$anime_list"
}

# ============================ HÀM LẤY DANH SÁCH TẬP TỪ OPHIM ============================
get_episode_list_ophim() {
    local url="$1"
    local cache_file="$CACHE_DIR/ophim_episodes_$(echo "$url" | md5sum | cut -d' ' -f1).cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi
    
    local html_content=$(curl -s "$url")
    if [[ -z "$html_content" ]]; then
        error "Không thể tải nội dung từ URL: $url"
        return 1
    fi
    
    local episode_data=$(echo "$html_content" | pup 'script json{}' | \
        jq -r '.[].text | @text' | \
        grep -oE '"(http|https)://[^"]*index.m3u8"' | \
        sed 's/"//g')
    
    if [[ -z "$episode_data" ]]; then
        error "Không tìm thấy danh sách tập phim cho URL: $url"
        return 1
    fi
    
    local i=1
    while IFS= read -r link; do
        printf "%s|%s\n" "$i" "$link"
        i=$((i + 1))
    done <<< "$episode_data" > "$cache_file"
    
    cat "$cache_file"
}

# ============================ LẤY TIÊU ĐÊ ============================
get_episode_title() {
    local episode_url="$1"
    local episode_number="$2"
    local cache_file="$CACHE_DIR/ophim_title_$(echo "$episode_url" | md5sum | cut -d' ' -f1)_$episode_number.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return
    fi
    
    local episode_title=$(curl -s "$episode_url" | pup ".ep-name text{}" | sed -n "${episode_number}p")
    
    if [[ -z "$episode_title" ]]; then
        episode_title="Episode $episode_number"
    fi
    
    echo "$episode_title" > "$cache_file"
    echo "$episode_title"
}

# ============================ HÀM LẤY DANH SÁCH ANIME/PHIM TỪ ANIDATA (@NiyakiPham QUẢN LÝ) ============================
get_anime_list_anidata() {
    local cache_file="$CACHE_DIR/anidata_list.cache"
    local csv_url="https://raw.githubusercontent.com/toilamsao/anidata/refs/heads/main/data.csv"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi
    
    local csv_content=$(curl -s "$csv_url" | sed 's/"//g')
    local anime_names=$(echo "$csv_content" | sed '1d' | cut -d',' -f1 | sort -u)
    
    # Lưu vào cache
    echo "$anime_names" > "$cache_file"
    echo "$anime_names"
}

# ============================ HÀM LẤY DANH SÁCH TẬP TỪ ANIDATA (@NiyakiPham QUẢN LÝ) ============================
get_episode_list_anidata() {
    local anime_name="$1"
    local cache_file="$CACHE_DIR/anidata_episodes_$(echo "$anime_name" | md5sum | cut -d' ' -f1).cache"
    local csv_url="https://raw.githubusercontent.com/toilamsao/anidata/refs/heads/main/data.csv"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi
    
    local csv_content=$(curl -s "$csv_url" | sed 's/"//g')
    local episodes=$(echo "$csv_content" | awk -F',' -v anime="$anime_name" '$1 == anime {print $2 " | " $3}')
    
    # Lưu vào cache
    echo "$episodes" > "$cache_file"
    echo "$episodes"
}

# ============================ HÀM LƯU VÀO NHẬT KÝ ============================
add_to_history() {
    local anime="$1"
    local episode="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Giới hạn lịch sử 50 mục / tránh spam quá nhiều
    local temp_file=$(mktemp)
    echo "$timestamp|$anime|$episode" > "$temp_file"
    cat "$HISTORY_FILE" | head -n 49 >> "$temp_file"
    mv "$temp_file" "$HISTORY_FILE"
}

# ============================ HÀM HIỂN THỊ LỊCH SỬ ĐÃ XEM ============================
show_history() {
    if [[ ! -s "$HISTORY_FILE" ]]; then
        echo "Không có lịch sử xem."
        return
    fi
    
    local history_list=$(cat "$HISTORY_FILE" | awk -F'|' '{print NR ". " $2 " - " $3 " (" $1 ")"}')
    echo "$history_list"
}

# ============================ HÀM THÊM VÀO DANH SÁCH ============================
add_to_favorites() {
    local anime="$1"
    
    if grep -q "^$anime$" "$FAVORITES_FILE"; then
        warn "Anime đã có trong danh sách yêu thích"
        return
    fi
    
    echo "$anime" >> "$FAVORITES_FILE"
    notify "Đã thêm '$anime' vào danh sách yêu thích"
}

# ============================ HÀM XÓA KHỎI DANH SÁCH YÊU THÍCH ============================
remove_from_favorites() {
    local anime="$1"
    
    if ! grep -q "^$anime$" "$FAVORITES_FILE"; then
        warn "Anime không có trong danh sách yêu thích"
        return
    fi
    
    local temp_file=$(mktemp)
    grep -v "^$anime$" "$FAVORITES_FILE" > "$temp_file"
    mv "$temp_file" "$FAVORITES_FILE"
    notify "Đã xóa '$anime' khỏi danh sách yêu thích"
}

# ============================ HÀM XEM DANH SÁCH YÊU THÍCH ============================
show_favorites() {
    if [[ ! -s "$FAVORITES_FILE" ]]; then
        echo "Không có anime nào trong danh sách yêu thích."
        return
    fi
    
    local favorites_list=$(cat "$FAVORITES_FILE" | awk '{print NR ". " $0}')
    echo "$favorites_list"
}

# ============================ PHÁT VIDEO BẰNG MPV ============================
play_with_mpv() {
    local url="$1"
    local title="$2"
    
    notify "Đang phát: $title"
    mpv "$url" \
        --force-media-title="$title" \
        --no-terminal \
        --profile=sw-fast \
        --audio-display=no \
        --no-keepaspect-window \
        --title="Anisub - $title"
}

# ============================ HÀM TẢI VIDEO VỀ THIẾT BỊ ============================
download_video() {
    local url="$1"
    local title="$2"
    local output_dir="$3"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "yt-dlp không được cài đặt. Không thể tải video."
        return 1
    fi
    
    mkdir -p "$output_dir"
    notify "Đang tải: $title"
    
    yt-dlp -o "$output_dir/$title.%(ext)s" \
        --no-progress \
        --console-title \
        --merge-output-format mp4 \
        "$url"
    
    if [[ $? -eq 0 ]]; then
        notify "Đã tải xong: $title"
    else
        error "Tải video thất bại"
    fi
}

# ============================ CẮT VIDEO BẰNG FFMPEG ============================
cut_video() {
    local url="$1"
    local title="$2"
    local output_dir="$DOWNLOAD_DIR/cut"
    
    if ! command -v yt-dlp &> /dev/null || ! command -v ffmpeg &> /dev/null; then
        error "Cần cài đặt yt-dlp và ffmpeg để sử dụng tính năng này"
        return 1
    fi
    
    mkdir -p "$output_dir"
    
    local cut_option=$(echo -e "Cắt 1 lần\nCắt nhiều lần" | fzf --prompt="Chọn chế độ cắt: ")
    
    case "$cut_option" in
        "Cắt 1 lần")
            read -r -p "Nhập thời gian bắt đầu (định dạng HH:MM:SS hoặc MM:SS): " start_time
            read -r -p "Nhập thời gian kết thúc (định dạng HH:MM:SS hoặc MM:SS): " end_time
            local output_file="$output_dir/${title}_cut_$(date +%s).mp4"
            
            notify "Đang cắt video từ $start_time đến $end_time..."
            yt-dlp --download-sections "*${start_time}-${end_time}" \
                -o "$output_file" \
                --no-progress \
                --console-title \
                "$url"
            
            if [[ $? -eq 0 ]]; then
                notify "Đã cắt và lưu video tại: $output_file"
            else
                error "Cắt video thất bại"
            fi
            ;;
        "Cắt nhiều lần")
            read -r -p "Nhập số lượng phân đoạn muốn cắt: " num_segments
            
            for ((i=1; i<=num_segments; i++)); do
                echo "Phân đoạn $i:"
                read -r -p "Nhập thời gian bắt đầu (định dạng HH:MM:SS hoặc MM:SS): " start_time
                read -r -p "Nhập thời gian kết thúc (định dạng HH:MM:SS hoặc MM:SS): " end_time
                local output_file="$output_dir/${title}_cut_${i}_$(date +%s).mp4"
                
                notify "Đang cắt video từ $start_time đến $end_time..."
                yt-dlp --download-sections "*${start_time}-${end_time}" \
                    -o "$output_file" \
                    --no-progress \
                    --console-title \
                    "$url"
                
                if [[ $? -eq 0 ]]; then
                    notify "Đã cắt và lưu phân đoạn $i tại: $output_file"
                else
                    error "Cắt phân đoạn $i thất bại"
                fi
            done
            ;;
        *)
            warn "Lựa chọn không hợp lệ"
            ;;
    esac
}

# ============================ GHÉP VIDEO LẠI VỚI NHAU ============================
merge_videos() {
    local output_dir="$DOWNLOAD_DIR/merged"
    mkdir -p "$output_dir"
    
    local merge_option=$(echo -e "Ghép 1 lần\nGhép nhiều lần" | fzf --prompt="Chọn chế độ ghép: ")
    
    case "$merge_option" in
        "Ghép 1 lần")
            read -r -p "Nhập số lượng video muốn ghép: " num_videos
            local video_files=()
            
            for ((i=1; i<=num_videos; i++)); do
                local selected=$(find "$DOWNLOAD_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" \) | fzf --prompt="Chọn video $i: ")
                if [[ -z "$selected" ]]; then
                    warn "Không có video nào được chọn"
                    return 1
                fi
                video_files+=("$selected")
            done
            
            local output_file="$output_dir/merged_$(date +%s).mp4"
            
            notify "Đang ghép ${#video_files[@]} video..."
            ffmpeg -f concat -safe 0 -i <(for f in "${video_files[@]}"; do echo "file '$f'"; done) \
                -c copy \
                "$output_file" \
                -y
            
            if [[ $? -eq 0 ]]; then
                notify "Đã ghép và lưu video tại: $output_file"
            else
                error "Ghép video thất bại"
            fi
            ;;
        "Ghép nhiều lần")
            read -r -p "Nhập số lượng vòng lặp ghép: " num_loops
            
            for ((loop=1; loop<=num_loops; loop++)); do
                echo "Vòng lặp ghép thứ $loop:"
                read -r -p "Nhập số lượng video muốn ghép: " num_videos
                local video_files=()
                
                for ((i=1; i<=num_videos; i++)); do
                    local selected=$(find "$DOWNLOAD_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" \) | fzf --prompt="Chọn video $i: ")
                    if [[ -z "$selected" ]]; then
                        warn "Không có video nào được chọn"
                        continue 2
                    fi
                    video_files+=("$selected")
                done
                
                local output_file="$output_dir/merged_loop${loop}_$(date +%s).mp4"
                
                notify "Đang ghép ${#video_files[@]} video..."
                ffmpeg -f concat -safe 0 -i <(for f in "${video_files[@]}"; do echo "file '$f'"; done) \
                    -c copy \
                    "$output_file" \
                    -y
                
                if [[ $? -eq 0 ]]; then
                    notify "Đã ghép và lưu video tại: $output_file"
                else
                    error "Ghép video thất bại"
                fi
            done
            ;;
        *)
            warn "Lựa chọn không hợp lệ"
            ;;
    esac
}

# ============================ HIỂN THỊ MENU CHÍNH CỦA ANISUB ============================
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│            ${MAGENTA}ANISUB v$VERSION${CYAN}              │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Tìm kiếm và phát anime${CYAN}                     │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Lịch sử xem${CYAN}                               │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Danh sách yêu thích${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${YELLOW}4. Công cụ video (cắt/ghép)${CYAN}                 │${NC}"
        echo -e "${CYAN}│  ${YELLOW}5. Đọc manga${CYAN}                                │${NC}"
        echo -e "${CYAN}│  ${YELLOW}6. Cài đặt${CYAN}                                  │${NC}"
        echo -e "${CYAN}│  ${RED}0. Thoát${CYAN}                                      │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) search_and_play_menu ;;
            2) history_menu ;;
            3) favorites_menu ;;
            4) video_tools_menu ;;
            5) read_manga ;;
            6) settings_menu ;;
            0) exit 0 ;;
            *) warn "Lựa chọn không hợp lệ, vui lòng chọn lại" ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU TÌM KIẾM VÀ PHÁT VIDEO ============================
search_and_play_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│           ${MAGENTA}TÌM KIẾM VÀ PHÁT ANIME${CYAN}            │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Tìm kiếm từ OPhim${CYAN}                        │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Tìm kiếm từ AniData${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Nhập URL trực tiếp${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) search_ophim ;;
            2) search_anidata ;;
            3) play_from_url ;;
            0) return ;;
            *) warn "Lựa chọn không hợp lệ, vui lòng chọn lại" ;;
        esac
    done
}

# ============================ TÌM KIẾM TỪ OPHIM ============================
search_ophim() {
    read -r -p "Nhập từ khóa tìm kiếm: " keyword
    if [[ -z "$keyword" ]]; then
        warn "Từ khóa không được để trống"
        return
    fi
    
    local anime_list=$(search_anime_ophim "$keyword")
    
    if [[ -z "$anime_list" ]]; then
        warn "Không tìm thấy anime nào với từ khóa '$keyword'"
        return
    fi
    
    local selected_anime=$(echo "$anime_list" | fzf --prompt="Chọn anime: " --preview "echo {} | sed 's/.*(//;s/)//' | xargs -I{} curl -s {} | pup 'p.description text{}'")
    
    if [[ -z "$selected_anime" ]]; then
        warn "Không có anime nào được chọn"
        return
    fi
    
    local anime_url=$(echo "$selected_anime" | sed 's/.*(\(.*\))/\1/')
    local anime_name=$(echo "$selected_anime" | sed 's/^[^(]*(\([^)]*\)) \+//;s/ ([^ ]*)$//')
    
    play_anime_ophim "$anime_url" "$anime_name"
}

# ============================ PHÁT VIDEO ĐÓ TỪ OPHIM ============================
play_anime_ophim() {
    local anime_url="$1"
    local anime_name="$2"
    
    local episode_list=$(get_episode_list_ophim "$anime_url")
    if [[ -z "$episode_list" ]]; then
        error "Không thể lấy danh sách tập phim"
        return
    fi
    
    local selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: " --preview "echo {} | cut -d'|' -f2")
    
    if [[ -z "$selected_episode" ]]; then
        warn "Không có tập nào được chọn"
        return
    fi
    
    local episode_number=$(echo "$selected_episode" | cut -d'|' -f1)
    local episode_url=$(echo "$selected_episode" | cut -d'|' -f2)
    local episode_title=$(get_episode_title "$anime_url" "$episode_number")
    
    add_to_history "$anime_name" "$episode_title"
    
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│         ${MAGENTA}ĐANG PHÁT: $anime_name${CYAN}              │${NC}"
        echo -e "${CYAN}│         ${YELLOW}Tập $episode_number: $episode_title${CYAN}  │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Phát tập này${CYAN}                            │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Phát tập tiếp theo${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Phát tập trước đó${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${YELLOW}4. Chọn tập khác${CYAN}                           │${NC}"
        echo -e "${CYAN}│  ${YELLOW}5. Tải tập này xuống${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${YELLOW}6. Thêm vào yêu thích${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                play_with_mpv "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            2)
                next_episode_number=$((episode_number + 1))
                local next_episode=$(echo "$episode_list" | grep "^$next_episode_number|")
                
                if [[ -z "$next_episode" ]]; then
                    warn "Không có tập tiếp theo"
                    continue
                fi
                
                episode_number=$next_episode_number
                episode_url=$(echo "$next_episode" | cut -d'|' -f2)
                episode_title=$(get_episode_title "$anime_url" "$episode_number")
                add_to_history "$anime_name" "$episode_title"
                play_with_mpv "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            3)
                previous_episode_number=$((episode_number - 1))
                local previous_episode=$(echo "$episode_list" | grep "^$previous_episode_number|")
                
                if [[ -z "$previous_episode" || $previous_episode_number -lt 1 ]]; then
                    warn "Không có tập trước đó"
                    continue
                fi
                
                episode_number=$previous_episode_number
                episode_url=$(echo "$previous_episode" | cut -d'|' -f2)
                episode_title=$(get_episode_title "$anime_url" "$episode_number")
                add_to_history "$anime_name" "$episode_title"
                play_with_mpv "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            4)
                selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: " --preview "echo {} | cut -d'|' -f2")
                
                if [[ -z "$selected_episode" ]]; then
                    warn "Không có tập nào được chọn"
                    continue
                fi
                
                episode_number=$(echo "$selected_episode" | cut -d'|' -f1)
                episode_url=$(echo "$selected_episode" | cut -d'|' -f2)
                episode_title=$(get_episode_title "$anime_url" "$episode_number")
                add_to_history "$anime_name" "$episode_title"
                play_with_mpv "$episode_url" "$anime_name - Tập $episode_number: $episode_title"
                ;;
            5)
                download_video "$episode_url" "$anime_name - Tập $episode_number: $episode_title" "$DOWNLOAD_DIR/$anime_name"
                ;;
            6)
                add_to_favorites "$anime_name"
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# ============================ TÌM KIẾM TỪ ANIDATA (@NiyakiPham QUẢN LÝ) ============================
search_anidata() {
    local anime_list=$(get_anime_list_anidata)
    
    if [[ -z "$anime_list" ]]; then
        warn "Không thể lấy danh sách anime từ AniData"
        return
    fi
    
    local selected_anime=$(echo "$anime_list" | fzf --prompt="Chọn anime: ")
    
    if [[ -z "$selected_anime" ]]; then
        warn "Không có anime nào được chọn"
        return
    fi
    
    play_anime_anidata "$selected_anime"
}

# ============================ PHÁT VIDEO ĐÓ TỪ ANISUB (@NiyakiPham QUẢN LÝ) ============================
play_anime_anidata() {
    local anime_name="$1"
    
    local episode_list=$(get_episode_list_anidata "$anime_name")
    if [[ -z "$episode_list" ]]; then
        error "Không thể lấy danh sách tập phim"
        return
    fi
    
    local selected_episode=$(echo "$episode_list" | fzf --prompt="Chọn tập phim: ")
    
    if [[ -z "$selected_episode" ]]; then
        warn "Không có tập nào được chọn"
        return
    fi
    
    local episode_title=$(echo "$selected_episode" | awk -F' | ' '{print $1}')
    local episode_url=$(echo "$selected_episode" | awk -F' | ' '{print $3}')
    
    add_to_history "$anime_name" "$episode_title"
    
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│         ${MAGENTA}ĐANG PHÁT: $anime_name${CYAN}              │${NC}"
        echo -e "${CYAN}│         ${YELLOW}$episode_title${CYAN}                       │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Phát tập này${CYAN}                            │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Tải tập này xuống${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Thêm vào yêu thích${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                play_with_mpv "$episode_url" "$anime_name - $episode_title"
                ;;
            2)
                download_video "$episode_url" "$anime_name - $episode_title" "$DOWNLOAD_DIR/$anime_name"
                ;;
            3)
                add_to_favorites "$anime_name"
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# ============================ PHÁT VIDEO TỪ URL TRỰC TIẾP (TỪ OPHIM HOẶC ANIDATA (@NiyakiPham QUẢN LÝ)) ============================
play_from_url() {
    read -r -p "Nhập URL anime (OPhim hoặc AniData): " url
    if [[ -z "$url" ]]; then
        warn "URL không được để trống"
        return
    fi
    
    if [[ "$url" == *"ophim17.cc"* ]]; then
        local anime_name=$(curl -s "$url" | pup 'h1 text{}' | tr -d '\n')
        play_anime_ophim "$url" "$anime_name"
    elif [[ "$url" == *"raw.githubusercontent.com/toilamsao/anidata"* ]]; then
        warn "Vui lòng sử dụng tùy chọn tìm kiếm AniData thay vì nhập URL trực tiếp"
    else
        warn "URL không được hỗ trợ. Chỉ hỗ trợ OPhim và AniData."
    fi
}

# ============================ HIỂN THỊ MENI LỊCH SỬ XEM ============================
history_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│               ${MAGENTA}LỊCH SỬ XEM${CYAN}                  │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        
        local history_list=$(show_history)
        if [[ -z "$history_list" ]]; then
            echo -e "${CYAN}│  ${YELLOW}Không có lịch sử xem${CYAN}                    │${NC}"
        else
            local i=1
            while IFS= read -r line; do
                if [[ $i -le 5 ]]; then
                    echo -e "${CYAN}│  ${YELLOW}$line${CYAN}" | awk '{printf "%-40s", $0}' | sed 's/$/│/'
                fi
                i=$((i + 1))
            done <<< "$history_list"
        fi
        
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Xem toàn bộ lịch sử${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Xóa lịch sử${CYAN}                             │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                clear
                echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
                echo -e "${CYAN}│               ${MAGENTA}TOÀN BỘ LỊCH SỬ${CYAN}               │${NC}"
                echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
                echo "$history_list" | more
                echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                > "$HISTORY_FILE"
                notify "Đã xóa toàn bộ lịch sử"
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU YÊU THÍCH CỦA NGƯỜI DÙNG ============================
favorites_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│            ${MAGENTA}DANH SÁCH YÊU THÍCH${CYAN}            │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        
        local favorites_list=$(show_favorites)
        if [[ -z "$favorites_list" ]]; then
            echo -e "${CYAN}│  ${YELLOW}Không có anime nào trong danh sách yêu thích${CYAN}│${NC}"
        else
            local i=1
            while IFS= read -r line; do
                if [[ $i -le 5 ]]; then
                    echo -e "${CYAN}│  ${YELLOW}$line${CYAN}" | awk '{printf "%-40s", $0}' | sed 's/$/│/'
                fi
                i=$((i + 1))
            done <<< "$favorites_list"
        fi
        
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Xem toàn bộ yêu thích${CYAN}                   │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Phát anime từ yêu thích${CYAN}                │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Xóa anime khỏi yêu thích${CYAN}               │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                clear
                echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
                echo -e "${CYAN}│            ${MAGENTA}TOÀN BỘ YÊU THÍCH${CYAN}              │${NC}"
                echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
                echo "$favorites_list" | more
                echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                if [[ -z "$favorites_list" ]]; then
                    warn "Không có anime nào trong danh sách yêu thích"
                    continue
                fi
                
                local selected_anime=$(echo "$favorites_list" | fzf --prompt="Chọn anime từ yêu thích: " | sed 's/^[0-9]*\. //')
                
                if [[ -z "$selected_anime" ]]; then
                    warn "Không có anime nào được chọn"
                    continue
                fi
                
                # Kiểm tra xem anime có trong AniData không
                local anime_list=$(get_anime_list_anidata)
                if echo "$anime_list" | grep -q "^$selected_anime$"; then
                    play_anime_anidata "$selected_anime"
                else
                    # Nếu không có trong AniData, thử tìm trên OPhim
                    local anime_name_encoded=$(echo "$selected_anime" | sed 's/ /+/g')
                    local anime_list=$(search_anime_ophim "$anime_name_encoded")
                    
                    if [[ -z "$anime_list" ]]; then
                        warn "Không tìm thấy anime '$selected_anime' trên OPhim"
                        continue
                    fi
                    
                    local selected_anime=$(echo "$anime_list" | grep -F "$selected_anime" | head -n 1)
                    
                    if [[ -z "$selected_anime" ]]; then
                        warn "Không tìm thấy anime '$selected_anime' trên OPhim"
                        continue
                    fi
                    
                    local anime_url=$(echo "$selected_anime" | sed 's/.*(\(.*\))/\1/')
                    local anime_name=$(echo "$selected_anime" | sed 's/^[^(]*(\([^)]*\)) \+//;s/ ([^ ]*)$//')
                    play_anime_ophim "$anime_url" "$anime_name"
                fi
                ;;
            3)
                if [[ -z "$favorites_list" ]]; then
                    warn "Không có anime nào trong danh sách yêu thích"
                    continue
                fi
                
                local selected_anime=$(echo "$favorites_list" | fzf --prompt="Chọn anime để xóa: " | sed 's/^[0-9]*\. //')
                
                if [[ -z "$selected_anime" ]]; then
                    warn "Không có anime nào được chọn"
                    continue
                fi
                
                remove_from_favorites "$selected_anime"
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CÔNG CỤ VIDEO CHỈNH SỬA ============================
video_tools_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│            ${MAGENTA}CÔNG CỤ VIDEO${CYAN}                  │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Cắt video${CYAN}                              │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Ghép video${CYAN}                             │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) cut_video_menu ;;
            2) merge_videos ;;
            0) return ;;
            *) warn "Lựa chọn không hợp lệ, vui lòng chọn lại" ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CẮT VIDEO ============================
cut_video_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│               ${MAGENTA}CẮT VIDEO${CYAN}                    │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Cắt video từ URL${CYAN}                        │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Cắt video từ file đã tải${CYAN}                │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                read -r -p "Nhập URL video: " url
                if [[ -z "$url" ]]; then
                    warn "URL không được để trống"
                    continue
                fi
                
                read -r -p "Nhập tiêu đề video: " title
                if [[ -z "$title" ]]; then
                    title="Video_$(date +%s)"
                fi
                
                cut_video "$url" "$title"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                local video_file=$(find "$DOWNLOAD_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" \) | fzf --prompt="Chọn video: ")
                if [[ -z "$video_file" ]]; then
                    warn "Không có video nào được chọn"
                    continue
                fi
                
                local title=$(basename "$video_file" | sed 's/\.[^.]*$//')
                cut_video "$video_file" "$title"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# ============================ HÀM ĐỌC MANGA (CHƯA NÂNG CẤP - SẼ NÂNG CẤP SAU KHI CÓ API THÍCH HỢP)============================
# ???
read_manga() {
    if ! command -v manga-tui &> /dev/null; then
        error "manga-tui không được cài đặt. Vui lòng cài đặt nó trước khi sử dụng tính năng này."
        read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
        return
    fi
    
    notify "Đang khởi động manga-tui..."
    manga-tui lang --set 'vi'
    manga-tui
}

# ============================ HIỂN THỊ MENU CỦA CÀI ĐẶT ============================
settings_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│               ${MAGENTA}CÀI ĐẶT${CYAN}                     │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Thay đổi thư mục tải xuống${CYAN}             │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Thay đổi trình phát mặc định${CYAN}           │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Thay đổi chất lượng mặc định${CYAN}          │${NC}"
        echo -e "${CYAN}│  ${YELLOW}4. Thay đổi chủ đề${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${YELLOW}5. Bật/tắt thông báo${CYAN}                     │${NC}"
        echo -e "${CYAN}│  ${YELLOW}6. Xóa cache${CYAN}                             │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                  │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) change_download_dir ;;
            2) change_default_player ;;
            3) change_default_quality ;;
            4) change_theme ;;
            5) toggle_notifications ;;
            6) clear_cache ;;
            0) return ;;
            *) warn "Lựa chọn không hợp lệ, vui lòng chọn lại" ;;
        esac
    done
}

# ============================ HÀM THAY ĐỔI THƯ MỤC TẢI XUỐNG CỦA NGƯỜI DÙNG ============================
change_download_dir() {
    read -r -p "Nhập đường dẫn thư mục tải xuống mới: " new_dir
    if [[ -z "$new_dir" ]]; then
        warn "Đường dẫn không được để trống"
        return
    fi
    
    mkdir -p "$new_dir"
    if [[ ! -d "$new_dir" ]]; then
        error "Không thể tạo thư mục $new_dir"
        return
    fi
    
    sed -i "s|^DOWNLOAD_DIR=.*|DOWNLOAD_DIR=\"$new_dir\"|" "$CONFIG_FILE"
    DOWNLOAD_DIR="$new_dir"
    notify "Đã thay đổi thư mục tải xuống thành: $new_dir"
}

# ============================ HÀM THAY ĐỔI TRÌNH PHÁT MẶC ĐỊNH CỦA NGƯỜI DÙNG ============================
change_default_player() {
    local players=("mpv" "vlc" "ffplay")
    local selected=$(printf "%s\n" "${players[@]}" | fzf --prompt="Chọn trình phát mặc định: ")
    
    if [[ -z "$selected" ]]; then
        warn "Không có trình phát nào được chọn"
        return
    fi
    
    sed -i "s/^DEFAULT_PLAYER=.*/DEFAULT_PLAYER=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_PLAYER="$selected"
    notify "Đã thay đổi trình phát mặc định thành: $selected"
}

# ============================ HÀM THAY ĐỔI CHẤT LƯỢNG VIDEO MÀ NGƯỜI DÙNG YÊU CẦU ============================
change_default_quality() {
    local qualities=("360p" "480p" "720p" "1080p")
    local selected=$(printf "%s\n" "${qualities[@]}" | fzf --prompt="Chọn chất lượng mặc định: ")
    
    if [[ -z "$selected" ]]; then
        warn "Không có chất lượng nào được chọn"
        return
    fi
    
    sed -i "s/^DEFAULT_QUALITY=.*/DEFAULT_QUALITY=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_QUALITY="$selected"
    notify "Đã thay đổi chất lượng mặc định thành: $selected"
}

# ============================ HÀM THAY ĐỔI CHỦ ĐỀ/GIAO DIỆN TERMINAL (CHƯA TEST VÌ NGƯỜI CODE DÙNG KALI LINUX) ============================
change_theme() {
    local themes=("dark" "light" "blue" "green" "red")
    local selected=$(printf "%s\n" "${themes[@]}" | fzf --prompt="Chọn chủ đề: ")
    
    if [[ -z "$selected" ]]; then
        warn "Không có chủ đề nào được chọn"
        return
    fi
    
    sed -i "s/^THEME=.*/THEME=\"$selected\"/" "$CONFIG_FILE"
    THEME="$selected"
    notify "Đã thay đổi chủ đề thành: $selected"
}

# ============================ HÀM BẬT TẮT THÔNG BÁO CỦA ANISUB ============================
toggle_notifications() {
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=false/" "$CONFIG_FILE"
        NOTIFICATIONS="false"
        notify "Đã tắt thông báo"
    else
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=true/" "$CONFIG_FILE"
        NOTIFICATIONS="true"
        notify "Đã bật thông báo"
    fi
}

# ============================ XÓA CÁC FILE CACHE (BỘ NHỚ TẠM) ============================
clear_cache() {
    rm -rf "$CACHE_DIR"/*
    notify "Đã xóa toàn bộ cache"
}

# ============================ HÀM KHI KHỞI ĐỘNG ANISUB ============================
main() {
    init_dirs
    check_dependencies
    
    # Hiển thị thông báo khởi động
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│            ${MAGENTA}ANISUB v$VERSION${CYAN}               │${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│  ${YELLOW}Đang khởi động...${CYAN}                            │${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
    
    log "Bắt đầu Anisub - Chỉnh sửa lại bởi @Kidtomboy v$VERSION"
    
    # Kiểm tra kết nối Internet (Yêu cầu)
    if ! curl -Is https://google.com | grep -q "HTTP/2"; then
        error "Không có kết nối Internet. Vui lòng kiểm tra kết nối của bạn."
        exit 1
    fi
    
    # Chạy menu chính
    main_menu
}

# ============================ CHẠY CHƯƠNG TRÌNH ============================
main
