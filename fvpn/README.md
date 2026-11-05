# fvpn — moved to its own repository

The FortiGate SSL VPN CLI that used to live here now has its own repo:

**https://github.com/tibuchivn/fvpn**

```bash
git clone git@github.com:tibuchivn/fvpn.git ~/tung/fvpn
```

Everything is there: `fvpn-setup.sh` (installer), `fvpn-watch.sh` + the launchd
agent, `SECURITY.md` (threat model and accepted risks) and both READMEs
(`README.md`, `README-vi.md`). Gateway maintenance, password resets and the
watcher settings are documented there too.

Only a pointer is kept in this dotfiles repo so old links keep working.

---

Công cụ `fvpn` đã chuyển sang repo riêng ở trên. Clone lại bằng lệnh trong khối
trên (đích `~/tung/fvpn`), rồi chạy `bash ~/tung/fvpn/fvpn-setup.sh`. Thư mục
này chỉ còn file dẫn link.
