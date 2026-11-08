# RT Dev Kernel Driver Loader

Author: **MD MAWA ISLAM** — Telegram: [@mawa4k](https://t.me/mawa4k)

Termux এ চালানোর জন্য kernel driver selector। **Root + Internet লাগবে।**

## Install & Run (এক কমান্ডে)

```bash
pkg update -y && pkg install git tsu -y && rm -rf ~/Driver && git clone https://github.com/Mawa4k/Driver ~/Driver && cd ~/Driver && bash driver_select.sh
```

প্রথমবার Magisk / KernelSU এ Termux এর root permission **Grant** করতে হবে।

## পরের বার চালাতে

```bash
cd ~/Driver && bash driver_select.sh
```

## Features

- Device info (Model, Android, Arch, Kernel, Root)
- আগে driver folder সিলেক্ট, তারপর তার ভেতরের সব driver দেখায়
- Kernel version অনুযায়ী `EXACT` / `BEST` / `RECOMMENDED` চিহ্ন
- সিলেক্ট করা driver `/data/local/tmp` এ copy হয়ে execute হয়
- প্রথমবার extract, পরের বার সরাসরি মেনু

## Update

এক কমান্ডের install কমান্ডটাই আবার চালালে সব আপডেট হয়ে যাবে।
