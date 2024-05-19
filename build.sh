#!/bin/bash

set -o errexit
set -o xtrace

TMP_DIR="./tmp"
BUILD_DIR="./build"
SRC_ASSETS_DIR="./assets"
SRC_HOMEBREW="./homebrew"

UNZIP_COMMAND="unzip -o"

prepare_hekate() {
    curl -O -L https://github.com/CTCaer/hekate/releases/download/v6.1.1/hekate_ctcaer_6.1.1_Nyx_1.6.1.zip --output-dir $TMP_DIR
    $UNZIP_COMMAND $TMP_DIR/hekate_ctcaer_*.zip -d $BUILD_DIR
}

prepare_atmosphere() {
	curl -H "Authorization: Bearer $GITHUB_TOKEN" -O -L https://github.com/laleeroy/Atmosphere-/releases/download/1/atmosphere-1.7.0-master-00354a99e.zip --output-dir $TMP_DIR
#    curl -O -L https://github.com/Atmosphere-NX/Atmosphere/releases/download/1.7.0-prerelease/atmosphere-1.7.0-master-35d93a7c4+hbl-2.4.4+hbmenu-3.6.0.zip --output-dir $TMP_DIR
	ls $TMP_DIR
	$UNZIP_COMMAND $TMP_DIR/atmosphere-*.zip
}

prepare_overlays() {
    # curl -O -L https://sigmapatches.su/sys-patch.zip --output-dir $TMP_DIR
    curl -O -L https://f38d61784492.hosting.myjino.ru/NintendoSwitch/sys-patch-1.5.1.zip --output-dir $TMP_DIR
    $UNZIP_COMMAND $TMP_DIR/sys-patch-*.zip -d $BUILD_DIR
    rm $BUILD_DIR/atmosphere/contents/420000000000000B/flags/boot2.flag
}

prepare_sx_gear() {
    curl -O -L https://f38d61784492.hosting.myjino.ru/NintendoSwitch/SX_Gear_v1.1.zip --output-dir $TMP_DIR
    $UNZIP_COMMAND $TMP_DIR/SX_Gear_*.zip -d $BUILD_DIR
}

prepare_payload() {
    # curl -O -L https://f38d61784492.hosting.myjino.ru/NintendoSwitch/Lockpick_RCM.zip --output-dir $TMP_DIR
    # $UNZIP_COMMAND $TMP_DIR/Lockpick_RCM.zip -d $BUILD_DIR/bootloader/payloads/

    # curl -O -L https://sigmapatches.su/Lockpick_RCM_v1.9.12.zip --output-dir $TMP_DIR
    # $UNZIP_COMMAND $TMP_DIR/Lockpick_RCM_v1.9.12.zip -d $TMP_DIR/

    curl -O -L https://github.com/Decscots/Lockpick_RCM/releases/download/v1.9.12/Lockpick_RCM.bin --output-dir $TMP_DIR
    cp $TMP_DIR/Lockpick_RCM.bin $BUILD_DIR/bootloader/payloads/

    curl -O -L https://f38d61784492.hosting.myjino.ru/NintendoSwitch/mod_chip_toolbox.zip --output-dir $TMP_DIR
    $UNZIP_COMMAND $TMP_DIR/mod_chip_toolbox.zip -d $BUILD_DIR/bootloader/payloads/
}

prepare_homebrew() {
    mkdir $BUILD_DIR/switch/DBI
    curl -O -L https://github.com/rashevskyv/dbi/releases/download/658/DBI.nro --output-dir $TMP_DIR
    cp $TMP_DIR/DBI.nro $BUILD_DIR/switch/DBI/
}

patch_hekate() {
    cp $BUILD_DIR/hekate_ctcaer_*.bin $BUILD_DIR/payload.bin
    rm $BUILD_DIR/hekate_ctcaer_*.bin
}

patch_home_menu() {
    mkdir $BUILD_DIR/games
    curl -O -L "https://f38d61784492.hosting.myjino.ru/NintendoSwitch/hbmenu_0104444444440000.zip" --output-dir $TMP_DIR
    $UNZIP_COMMAND $TMP_DIR/hbmenu_*zip -d $BUILD_DIR/games/
}

patch_homebrew() {
    cp $SRC_HOMEBREW/dbi/dbi.config $BUILD_DIR/switch/DBI/dbi.config
}

patch_splash_hekate() {
    label=hekate
    convert $SRC_ASSETS_DIR/bootlogo-$label.png -rotate 270 $TMP_DIR/bootlogo-$label.png
    convert $TMP_DIR/bootlogo-$label.png -resize 720x1280 -depth 8 -type TrueColorAlpha $TMP_DIR/bootlogo-$label.bmp
    cp -f $TMP_DIR/bootlogo-$label.bmp $BUILD_DIR/bootloader/bootlogo.bmp
}

patch_bootlogo_exefs() {
    label=exefs
    convert $SRC_ASSETS_DIR/bootlogo-$label.png  -rotate 270 $TMP_DIR/bootlogo-$label.png
    convert $TMP_DIR/bootlogo-$label.png -resize 308x350 -depth 8 -type TrueColorAlpha $TMP_DIR/bootlogo-$label.bmp

    mkdir -p $BUILD_DIR/atmosphere/exefs_patches/bootlogo
    python3 $BUILD_DIR/switch-logo-patcher/gen_patches.py $BUILD_DIR/atmosphere/exefs_patches/bootlogo $TMP_DIR/bootlogo_$label.bmp
}

patch_icons() {
    label=icon
    mkdir $TMP_DIR/res
    for png_file in "$SRC_ASSETS_DIR"/icons/*.png ; do
        convert $SRC_ASSETS_DIR/icons/"$png_file" -resize 192x192 -depth 8 -type TrueColorAlpha $TMP_DIR/res/"$label"_"${png_file%.*}".bmp
    done
    mkdir $BUILD_DIR/bootloader/res
    cp -f $TMP_DIR/res/*.bmp $BUILD_DIR/bootloader/res/
}


mkdir $TMP_DIR $BUILD_DIR
prepare_atmosphere
prepare_hekate
prepare_sx_gear
prepare_payload
prepare_homebrew

patch_hekate
patch_homebrew
patch_home_menu

cd ./build && zip -r ../AIO.zip ./*
