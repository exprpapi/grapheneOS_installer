# GrapheneOS Installer

## Usage

Make sure you have the right device.
This script is written for `pixel6a=bluejay`.

Adapt the Variables `DEVICE` and `VERSION` in the script if necessary.

Make sure the phone is OEM unlocked, connected and booted into the bootloader interface.

```bash
git clone 'https://github.com/exprpapi/grapheneos_installer'
cd grapheneos_installer
make
```

After the script is finished, re-enable OEM lock in your GrapheneOS settings.

## Dependencies

On Arch Linux
```bash
sudo pacman -S --noconfirm --needed \
  android-tools \
  android-udev \
  signify \
  unzip
```
