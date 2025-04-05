# Anisub Pro Max - Công cụ xem và tải anime từ terminal

![GitHub](https://img.shields.io/github/license/kidtomboy/Anisub)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=flat&logo=gnu-bash&logoColor=white)
![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Anisub Logo](https://i.imgur.com/frMJAZ5.jpeg)

**Anisub Pro Max** là một công cụ mạnh mẽ giúp bạn tìm kiếm, xem và tải anime trực tiếp từ terminal với nhiều tính năng ưu việt.

## 🌟 Tính năng nổi bật

- 🔍 **Tìm kiếm anime** từ nhiều nguồn: OPhim17, AniData, YouTube
- ▶️ **Phát trực tiếp** với trình phát yêu thích (mpv/vlc/ffplay)
- 💾 **Tải xuống** tập phim với nhiều tùy chọn chất lượng
- 🛠️ **Công cụ video** mạnh mẽ: cắt/ghép/xem trước
- 🕒 **Lịch sử xem** chi tiết
- ⭐ **Danh sách yêu thích** thông minh
- ⚙️ **Hệ thống cache** và cấu hình linh hoạt
- 📱 **Hỗ trợ đa nền tảng**: Linux, Windows, macOS, Android/Termux
- 🎨 **Giao diện terminal** đẹp với nhiều theme

## 📥 Cài đặt

### Yêu cầu hệ thống
- Bash 4.0+
- Các công cụ cần thiết: `curl`, `jq`, `pup`, `fzf`, `mpv` (hoặc trình phát khác)

### Cài đặt tự động
```bash
bash <(curl -s https://raw.githubusercontent.com/kidtomboy/Anisub/main/anisun.sh)
```

### Cài đặt thủ công
1. Tải script:
```bash
curl -o anisub.sh https://raw.githubusercontent.com/kidtomboy/Anisub/main/anisub.sh
```

2. Cấp quyền thực thi:
```bash
chmod +x anisub.sh
```

3. Chạy chương trình:
```bash
./anisub.sh
```

## 🚀 Cách sử dụng

### Chế độ tương tác
```bash
./anisub.sh
```
Sau đó chọn các tùy chọn từ menu

### Chế độ dòng lệnh
- Phát trực tiếp:
```bash
./anisub.sh --play "Tên Anime"
```

- Tìm kiếm:
```bash
./anisub.sh --search "Từ khóa"
```

- Tải video:
```bash
./anisub.sh --download "URL"
```

## 🛠 Công cụ tích hợp

1. **Cắt video**:
   - Cắt đoạn video từ thời gian A đến B
   - Hỗ trợ cắt nhiều phân đoạn

2. **Ghép video**:
   - Ghép nhiều video thành một
   - Hỗ trợ ghép nhiều vòng lặp

3. **Quản lý cache**:
   - Xóa cache thủ công/tự động
   - Tùy chỉnh thời gian lưu cache

## ⚙️ Cấu hình

Chương trình tự động tạo file cấu hình tại:
- Linux/macOS: `~/.config/anisub_pro/config.cfg`
- Windows: `%APPDATA%/anisub_pro/config.cfg`
- Termux: `~/.config/anisub_pro/config.cfg`

Các tùy chọn cấu hình chính:
- Trình phát mặc định (mpv/vlc/ffplay)
- Chất lượng video (360p/480p/720p/1080p)
- Theme giao diện (dark/light/blue/green/red)
- Thư mục tải xuống
- Bật/tắt thông báo

## 📜 Lịch sử phiên bản

### v2.0.0 (04/04/2025)
- [x] Thêm hỗ trợ nguồn AniData (@NiyakiPham)
- [x] Cải thiện hiệu năng tìm kiếm
- [x] Thêm tính năng cắt/ghép video
- [x] Hỗ trợ Termux trên Android

### v1.0.0 (15/03/2025)
- [x] Phiên bản đầu tiên
- [x] Thêm hệ thống cache
- [x] Cải thiện giao diện (sẽ update lại sau)

---

## 🐛 Báo cáo lỗi (Bug Reports)

Nếu bạn gặp bất kỳ lỗi nào khi sử dụng Anisub Pro Max, vui lòng làm theo các bước sau:

### Cách báo cáo lỗi
1. **Kiểm tra lỗi đã được báo cáo chưa**:
   - Xem qua [mục Issues](https://github.com/kidtomboy/Anisub/issues) để chắc chắn lỗi chưa được báo cáo

2. **Thu thập thông tin**:
   - Phiên bản Anisub: `./anisub.sh --version`
   - Hệ điều hành và phiên bản
   - Các thông báo lỗi từ terminal
   - File log (nằm trong `~/.config/anisub_pro/logs/`)

3. **Tạo báo cáo lỗi mới**:
   - Truy cập [trang Issues](https://github.com/kidtomboy/Anisub/issues/new/choose)
   - Chọn "Bug Report"
   - Điền đầy đủ thông tin theo mẫu

### Mẫu báo cáo lỗi chuẩn
```markdown
**Mô tả lỗi**
Mô tả rõ ràng và chi tiết về lỗi gặp phải

**Các bước để tái tạo lỗi**
1. Bước 1...
2. Bước 2...
3. Xem lỗi xảy ra

**Kết quả mong đợi**
Bạn mong đợi điều gì sẽ xảy ra?

**Ảnh chụp màn hình/Ghi hình**
Nếu có thể, hãy đính kèm ảnh chụp hoặc video

**Thông tin hệ thống**
- OS: [e.g. Ubuntu 22.04]
- Anisub Version: [e.g. 2.0.0]
- Terminal: [e.g. Terminator, GNOME Terminal]

**File log**
Đính kèm file log hoặc paste nội dung lỗi (xóa thông tin nhạy cảm)
```

### Xử lý lỗi khẩn cấp
Đối với lỗi nghiêm trọng ảnh hưởng đến trải nghiệm, bạn có thể:
1. Tạm thời sử dụng phiên bản cũ:
```bash
git checkout tags/v1.0.0
```
2. Liên hệ trực tiếp qua email: kidtomboy@example.com

## 🛠 Tự khắc phục lỗi thường gặp

Một số lỗi phổ biến và cách khắc phục:

### 1. Lỗi thiếu phụ thuộc
```bash
[ERROR] Thiếu package: mpv
```
**Cách khắc phục**:
```bash
# Ubuntu/Debian
sudo apt install mpv

# Arch Linux
sudo pacman -S mpv

# Termux
pkg install mpv-x
```

### 2. Lỗi kết nối
```bash
[ERROR] Không thể kết nối đến OPhim17
```
**Cách khắc phục**:
- Kiểm tra kết nối Internet
- Thử đổi DNS (8.8.8.8 hoặc 1.1.1.1)
- Chờ 5 phút và thử lại

### 3. Lỗi phát video
```bash
[ERROR] Không thể phát video
```
**Cách khắc phục**:
1. Thử đổi trình phát mặc định:
```bash
# Trong menu cài đặt
Chọn "Thay đổi trình phát mặc định"
```
2. Cập nhật driver đồ họa
3. Kiểm tra file cấu hình tại `~/.config/anisub_pro/config.cfg`

### 4. Lỗi font chữ
```bash
[WARNING] Hiển thị font chữ không đúng
```
**Cách khắc phục**:
- Cài đặt font đầy đủ:
```bash
# Linux
sudo apt install fonts-noto

# Termux
pkg install fontconfig
```

## 🤝 Đóng góp sửa lỗi

Chúng tôi hoan nghênh mọi đóng góp để cải thiện Anisub:
1. Fork repository
2. Tạo branch mới (`git checkout -b fix/bug-name`)
3. Commit thay đổi
4. Push lên branch
5. Tạo Pull Request

### **Do một mình mình sửa và code lại nên rất cần người thử nghiệm code và báo cáo cho mình, mình cũng chưa muốn nhờ người code cùng nên cứ có lỗi thì xin vui lòng báo cho mình biết nhé!**

## 🙏 Cảm ơn

- **NiyakiPham** - Tác giả bản gốc
- **Cộng đồng mã nguồn mở** - Đóng góp ý tưởng và công cụ

## 👨‍💻 Tác giả
Original: [NiyakiPham](https://github.com/niyakipham)
Remake & Enhance: [Kidtomboy](https://github.com/kidtomboy)

## 💖 Donate

Nếu thấy dự án hữu ích, bạn có thể ủng hộ tác giả qua:
- [GitHub Sponsors](https://raw.githubusercontent.com/Kidtomboy/Kidtomboy/refs/heads/main/images/bank/BIDV_Kidtomboy.jpg)
- Momo: 038.783.1869 | Cherry🍒

## 📄 Dự án này được phân phối theo giấy phép MIT.

- [Giấy Phép MIT](https://raw.githubusercontent.com/Kidtomboy/Anisub/main/LICENSE)

---

**Anisub Pro Max** - Xem anime mọi lúc, mọi nơi! 🎉
