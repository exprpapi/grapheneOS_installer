#!/usr/bin/env bash
PS4="\e[34m[$(basename "${0}")"':${FUNCNAME[0]:+${FUNCNAME[0]}():}${LINENO:-}]: \e[0m'
IFS=$'\n\t'
set -euxo pipefail

die() {
  if [[ "$#" -gt 0 ]]; then
    local msg="${1}"
    printf 'Error: %s\n' "${msg}"
  fi
  exit 1
}

DEVICE='bluejay'
VERSION='2023072600'
IMAGES="${DEVICE}-factory-${VERSION}.zip"
BOOTLOADER_IMAGE=''
RADIO_IMAGE=''
SYSTEM_IMAGE=''

find_image() {
  local pattern="${1}"
  find . -maxdepth 1 -type f -name "${pattern}" | head -n 1
}

set_image_names() {
  BOOTLOADER_IMAGE="$(find_image "bootloader-${DEVICE}-*.img")"
  RADIO_IMAGE="$(find_image "radio-${DEVICE}-*.img")"
  SYSTEM_IMAGE="$(find_image "image-${DEVICE}-${VERSION}.zip")"
}

check_dependencies() {
  local dependencies=(
    'curl'
    'fastboot'
    'unzip'
  )
  for dependency in "${dependencies[@]}"; do
    if ! command -v "${dependency}" &>/dev/null; then
      die "dependency ${dependency} not fulfilled"
    fi
  done
}

check_fastboot_version() {
  local version="$(
    fastboot --version \
      | perl -ne 'print if s/.*version (\d*).(\d*).(\d*).*/\1\2\3/g'
  )"
  if [[ "${version}" -lt 3303 ]]; then
    die 'fastboot too old'
  fi
}

check_correct_product() {
  local product="$(fastboot getvar product |& head -1 | cut -d ' ' -f 2)"
  if [[ "${product}" != "${DEVICE}" ]]; then
    die "Wrong factory image: expected ${DEVICE} but device is ${product}."
  fi
}

fetch_and_verify_images() {
  local base_url='https://releases.grapheneos.org'
  local factory_key='factory.pub'
  local signature="${IMAGES}.sig"
  if ! curl &>/dev/null \
    -O "${base_url}/${signature}" \
    -O "${base_url}/${factory_key}" \
    -O "${base_url}/${IMAGES}"
  then
    die 'error fetching resources'
  fi
  if ! signify -Cqp "${factory_key}" -x "${signature}"; then
    die 'invalid signature'
  fi
}

extract_images() {
  unzip -jo "${IMAGES}"
}

unlock_bootloader() {
  fastboot flashing unlock
}

flash_bootloader() {
  fastboot flash --slot=other bootloader "${BOOTLOADER_IMAGE}"
  fastboot --set-active=other
}

flash_radio() {
  fastboot flash radio "${RADIO_IMAGE}"
}

flash_custom_key() {
  fastboot erase avb_custom_key
  fastboot flash avb_custom_key avb_pkmd.bin
}

disable_uart() {
  fastboot oem uart disable
}

erase_partitions() {
  fastboot erase fips
  fastboot erase dpm_a
  fastboot erase dpm_b
}

update_system_image() {
  fastboot snapshot-update cancel
  fastboot -w --skip-reboot update "${SYSTEM_IMAGE}"
}

reboot_bootloader() {
  fastboot reboot-bootloader
}

lock_bootloader() {
  fastboot flashing lock
}

prepare() {
  check_dependencies
  check_fastboot_version
  check_correct_product
  fetch_and_verify_images
  extract_images
  set_image_names
}

install() {
  unlock_bootloader
  sleep 5
  flash_bootloader
  reboot_bootloader
  sleep 5
  flash_bootloader
  reboot_bootloader
  sleep 5
  flash_radio
  reboot_bootloader
  sleep 5
  flash_custom_key
  reboot_bootloader
  sleep 5
  disable_uart
  erase_partitions
  update_system_image
  reboot_bootloader
  sleep 5
  lock_bootloader
  sleep 5
}

main() {
  local tmpdir='./build'
  mkdir -p "${tmpdir}"
  (
    cd "${tmpdir}"
    prepare
    install
  )
  rm -rf "${tmpdir}"
}

main "$@"
