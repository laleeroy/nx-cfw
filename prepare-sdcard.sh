#!/bin/bash

set -o errexit
set -o xtrace

sudo parted -l
read -p -r "SELECT DEVICE: " DEVICE_BLOCK
SD_SIZE=$(sudo blockdev --getsize64 /dev/"$DEVICE_BLOCK")
OFFSET=$(python -c "print(1 * (1024**2))")
read -p -r "EmuNAND Size in GB: " EMUNAND_SIZE_GB
EMUNAND_SIZE_BYTES=$(python -c "print($EMUNAND_SIZE_GB*(1024**3))")

sudo umount /dev/"${DEVICE_BLOCK}"1 || true
sudo umount /dev/"${DEVICE_BLOCK}"2 || true
sudo parted --script /dev/"$DEVICE_BLOCK" rm 1 || true
sudo parted --script /dev/"$DEVICE_BLOCK" rm 2 || true
sudo parted --script /dev/"$DEVICE_BLOCK" mkpart primary fat32 "${OFFSET}B" "$(python -c "print(($SD_SIZE-$EMUNAND_SIZE_BYTES) - (1+($OFFSET*2)))")B"
sudo parted --script /dev/"$DEVICE_BLOCK" mkpart primary fat32 "$(python -c "print($SD_SIZE-($EMUNAND_SIZE_BYTES+$OFFSET))")B" "$(python -c "print($SD_SIZE-$OFFSET)")B"

sudo mkfs.fat /dev/"${DEVICE_BLOCK}1"
