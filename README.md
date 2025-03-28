# Anisub CLI - Terminal Anime Streaming Tool

![Anisub Logo](https://i.imgur.com/frMJAZ5.jpeg)

**Anisub** là một công cụ dòng lệnh mạnh mẽ để xem anime trực tiếp từ terminal, với giao diện đơn giản và nhiều tính năng hữu ích.

## 🌟 Tính năng chính

- 🎬 Phát anime từ nhiều nguồn (OPhim, AniData)
- 📺 Hỗ trợ nhiều trình phát (MPV, VLC)
- ⬇️ Tải tập phim về thiết bị
- ✂️ Công cụ cắt/ghép video tích hợp
- 📚 Lịch sử xem và danh sách yêu thích
- 🎨 Tuỳ chỉnh giao diện (theme màu sắc)
- 🔔 Hệ thống thông báo
- 🚀 Tự động cập nhật

## 📦 Yêu cầu hệ thống

- Bash 4.0+
- Các phụ thuộc:
  - `curl`, `jq`, `pup`, `fzf`
  - `mpv` (hoặc trình phát khác như vlc,...)
  - `yt-dlp`, `ffmpeg` (cho tính năng tải về và chỉnh sửa)

## 🛠 Cài đặt

1. Tải script:
```bash
curl -o anisub.sh https://raw.githubusercontent.com/kidtomboy/Remake-Anisub/main/anisub.sh
```

2. Cấp quyền thực thi:
```bash
chmod +x anisub.sh
```

3. Chạy chương trình:
```bash
./anisub.sh
```

Chương trình sẽ tự động kiểm tra và cài đặt các phụ thuộc cần thiết.

## 🎮 Cách sử dụng

```bash
./anisub.sh [TÙY_CHỌN]
```

**Tùy chọn:** *(Chưa phát triển)*
- `-u`, `--update`: Cập nhật lên phiên bản mới nhất
- `-v`, `--version`: Hiển thị phiên bản
- `-h`, `--help`: Hiển thị trợ giúp

**Menu chính:**
1. Tìm kiếm và phát anime
2. Lịch sử xem
3. Danh sách yêu thích
4. Công cụ video (cắt/ghép)
5. Đọc manga *(đang phát triển)*
6. Cài đặt
7. Kiểm tra cập nhật
8. Thông tin tác giả

## ⚙️ Cấu hình

Tất cả cấu hình được lưu tại `~/.config/anisub_cli/config.cfg`. Bạn có thể chỉnh sửa:

- Thư mục tải xuống
- Trình phát mặc định
- Chất lượng video
- Chủ đề màu sắc
- Bật/tắt thông báo

## 📜 Lịch sử phiên bản

- **v1.0**: Phát hành ban đầu
- **v1.1**: Thêm tính năng tải video
- **v1.2**: Thêm công cụ cắt/ghép video
- **v1.3**: Cải thiện hiệu suất và sửa lỗi
- **Unknown1337**: Nâng cấp lên gần 1500 dòng

## 🙏 Tác giả

- **Kidtomboy** (Remake) - [GitHub](https://github.com/kidtomboy)
- **NiyakiPham** (Original) - [GitHub](https://github.com/NiyakiPham)

<!-- ## 💖 Donate -->
<!-- Nếu bạn thích dự án này, hãy ủng hộ tác giả: -->

## 📄 Giấy phép

Dự án này được phân phối theo giấy phép MIT.

- [Giấy Phép MIT](https://raw.githubusercontent.com/Kidtomboy/Remake-Anisub/main/LICENSE)
