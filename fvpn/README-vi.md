# fvpn — FortiGate SSL VPN trên command line (macOS)

FortiClient bản macOS **không có** lệnh CLI để kết nối tunnel (`epctrl` chỉ đăng ký EMS,
`fcconfig` chỉ import/export profile). Thư mục này dùng `openfortivpn` để đưa đúng cái SSL
VPN đó ra shell — nên dùng được trong script, trong Hammerspoon, hay nhờ một assistant bật hộ.

Các lệnh:

| lệnh | việc nó làm |
| --- | --- |
| `fvpn up <gateway> [giây]` | kết nối, chờ approve trên FortiToken (mặc định 30s) |
| `fvpn down [gateway]` | ngắt (không cần tên — chỉ có một tunnel) |
| `fvpn manual <gateway>` | dự phòng tương tác: tự gõ mật khẩu + OTP trong terminal |
| `fvpn status` | `connected ip=…` / `default -> ppp0` / `dns …`, hoặc `disconnected` |
| `fvpn list` | liệt kê gateway đã cài, đánh dấu cái đang kết nối |
| `fvpn logs <gateway> [dòng]` | xem `/var/log/fvpn-<gateway>.log` |

Hai phần phụ (không bắt buộc):

* `fvpn-watch.sh` + `ai.fvpn.watch.plist` — launchd agent bắn notification macOS khi
  tunnel rớt hoặc không lên được.
* dòng VPN trong alert `opt+T` của Hammerspoon (xem `../.hammerspoon/private/config.lua`).

## Yêu cầu

* macOS 13+, Homebrew.
* `brew install openfortivpn`.
* Mật khẩu tài khoản VPN, và FortiToken Mobile (approve push) hoặc mã OTP.
* Không bắt buộc: FortiClient đã có profile VPN — script setup đọc để tự dò danh sách gateway.

## Cài đặt

```bash
brew install openfortivpn

cd ~/tung/dotfiles/fvpn
cp fvpn.local.example.sh fvpn.local.sh      # rồi sửa: VPN_USER, GATEWAY_DOMAIN, ...
$EDITOR fvpn.local.sh

bash fvpn-setup.sh
```

`fvpn-setup.sh` hỏi mật khẩu macOS một lần, sau đó:

1. lưu mật khẩu VPN vào **login keychain** (item theo `KEYCHAIN_ITEM`);
2. dò gateway từ `vpn.plist` của FortiClient (profile SSL có server dạng
   `<GATEWAY_PREFIX><tên>.<GATEWAY_DOMAIN>`), hoặc dùng `FVPN_GATEWAYS` trong
   `fvpn.local.sh`;
3. kiểm chứng cert của từng gateway (platform trust + đúng hostname) rồi pin SHA-256;
4. cài **bản copy root-owned** của `openfortivpn` + các dylib vào `/usr/local/libexec/fvpn/`,
   và stub pinentry `/usr/local/libexec/fvpn-pinentry`;
5. ghi `/usr/local/etc/openfortivpn/<gateway>.conf` (mode 600, **không có mật khẩu**);
6. cài `/usr/local/sbin/fvpn-root` (helper chạy root) và `/usr/local/bin/fvpn` (wrapper
   cho user), kèm đúng một dòng `NOPASSWD` trong sudoers cho helper đó;
7. tự kiểm tra: binary pinned chạy được bằng root, stub trả lời đúng hội thoại pinentry
   lấy từ keychain.

Chạy lại bất cứ lúc nào: nó giữ nguyên item keychain (dùng `--reset-cred` nếu muốn thay
mật khẩu) và làm mới config, pin, binary.

### Không bắt buộc: notification khi rớt

```bash
mkdir -p ~/bin
ln -sf ~/tung/dotfiles/fvpn/fvpn-watch.sh ~/bin/fvpn-watch.sh
cp ai.fvpn.watch.plist ~/Library/LaunchAgents/
# sửa đường dẫn trong plist nếu home khác
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.fvpn.watch.plist
launchctl print gui/$(id -u)/ai.fvpn.watch | grep -E 'state|runs|run interval'
```

Notification hiện dưới tên **Script Editor**; bật trong System Settings → Notifications.
Nó chỉ bắn khi đã `fvpn up` mà tunnel không khoẻ — không bắn khi bạn chủ động `fvpn down`,
không bắn khi vừa đăng nhập máy mà chưa yêu cầu VPN, và mỗi lần yêu cầu tối đa một banner.

## Sử dụng

```bash
fvpn list                  # asia1  <- connected / east2 / eu1 / west1
fvpn up asia1              # approve push trên điện thoại khi nó hiện
fvpn up asia1 90           # cho 90s để approve (15..900)
fvpn status
fvpn down                  # không cần tên gateway
fvpn manual asia1          # push không hiện: gõ mật khẩu rồi OTP
fvpn logs asia1 40
```

## Cách hoạt động và vì sao làm vậy

* **Mật khẩu không nằm trên đĩa.** Nó ở login keychain; `openfortivpn` hỏi qua
  `--pinentry=/usr/local/libexec/fvpn-pinentry` — stub Assuan trả lời yêu cầu
  `<user>_<realm>_<host>_password` từ keychain và từ chối mọi yêu cầu khác (yêu cầu token
  không bao giờ được trả bằng mật khẩu tài khoản).
* **Root chỉ chạy code root-owned.** `/opt/homebrew` do user admin sở hữu, nên chạy binary
  Homebrew bằng root qua `NOPASSWD` là một đường leo thang đặc quyền. Setup copy
  `openfortivpn` + `libssl`/`libcrypto` vào `/usr/local/libexec/fvpn`, đổi load command
  sang `@executable_path`/`@loader_path`, ký lại ad-hoc; helper từ chối mọi thứ không phải
  root-owned hoặc group/world writable — kể cả thư mục cha và file config.
* **Config được kiểm chứ không tin.** Helper còn từ chối config có `host` khác
  `<GATEWAY_PREFIX><tên>.<GATEWAY_DOMAIN>`, vì `host` bị sửa là cách gửi mật khẩu trong
  keychain sang server khác.
* **Cert được verify rồi mới pin.** Setup chứng minh platform trust (chain + hostname) và
  kiểm lại đúng cert sắp pin bằng `security verify-cert`, rồi lưu SHA-256 vào
  `trusted-cert`.
* **Không reconnect tự động.** `--persistent` gọi lại login mỗi vài giây bất kể lý do, nên
  khi mật khẩu đổi sẽ bắn liên tục và khoá tài khoản AD. Mỗi `fvpn up` chỉ một lần thử.

## Xử lý sự cố

| hiện tượng | nguyên nhân / cách sửa |
| --- | --- |
| `ERROR: Could not authenticate` | mật khẩu đã đổi (`bash fvpn-setup.sh --reset-cred`), hoặc gateway đòi token mà bạn chưa approve |
| tunnel không lên, không thấy push | chưa approve trong thời gian chờ, hoặc gateway chuyển sang OTP → `fvpn manual <gateway>` |
| `refuse: … not root-owned` / `group/world writable` | có thứ gì đã thay binary pinned hoặc config — chạy lại `fvpn-setup.sh` |
| `missing config … (re-run setup)` | gateway chưa cài: thêm profile trong FortiClient rồi chạy lại setup |
| tunnel chết đúng một ngày cố định mỗi năm | cert gateway đã renew, digest pinned không còn khớp — chạy lại setup |
| `ERROR: ppp0 already exists` | FortiClient (hoặc tunnel khác) đang bật: `fvpn down` trước |
| không thấy notification | bật quyền cho *Script Editor*, xem `~/Library/Logs/fvpn-watch.log` |

Log: `/var/log/fvpn-<gateway>.log` (openfortivpn), `/var/log/fvpn-pinentry.log` (nó hỏi
credential gì), `~/Library/Logs/fvpn-watch.log` (watcher).

## Thêm gateway

Thêm profile trong FortiClient, rồi chạy lại `bash fvpn-setup.sh` và kiểm `fvpn list`.
Chỉ nhận profile SSL VPN (`VpnType 0`) có server đúng dạng
`<GATEWAY_PREFIX><tên>.<GATEWAY_DOMAIN>`; profile IPsec bị bỏ qua.

## Gỡ cài đặt

```bash
launchctl bootout gui/$(id -u)/ai.fvpn.watch 2>/dev/null
rm -f ~/Library/LaunchAgents/ai.fvpn.watch.plist
sudo rm -f /etc/sudoers.d/fvpn /usr/local/bin/fvpn /usr/local/sbin/fvpn-root \
           /usr/local/libexec/fvpn-pinentry /var/log/fvpn-intent
sudo rm -rf /usr/local/libexec/fvpn /usr/local/etc/openfortivpn
security delete-generic-password -s "${KEYCHAIN_ITEM:-fvpn-vpn-password}"
```
