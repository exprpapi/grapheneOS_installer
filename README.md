# GrapheneOS Installer

## Usage

Make sure to have the right device. Adapt the script if necessary.

This script is written for `pixel6a=bluejay`.

Make sure the phone is OEM unlocked, connected and in the bootloader interface.

```bash
git clone 'https://github.com/exprpapi/grapheneos_installer'
cd grapheneos_installer
sh install.sh
```

## Dependencies

```bash
pacman -S \
  android-tools \
  android-udev \
  signify \
  unzip
```
