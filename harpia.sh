echo "Setting Up environment variables"
printf '\n'
KERNEL_DIR=$PWD
DEFCONFIG=harpia_defconfig
Anykernel_DIR=$KERNEL_DIR/AnyKernel2/harpia
TOOLCHAINDIR=$(pwd)/../toolchain/linaro-4.9
DATE=$(env TZ='Asia/Kolkata' date +"%F-%r" | sed -e "s|:|_|g" | sed -e "s| |_|")
KERNEL_NAME="BLEEDING_EDGE"
DEVICE="-harpia-"
VER="-v69"
TYPE="-PIE"
FINAL_ZIP="$KERNEL_NAME""$DEVICE""$DATE""$TYPE""$VER".zip
FULL_ZIP_PATH="$Anykernel_DIR"/"$FINAL_ZIP"
# key= bot api key
# id= channel id here

export ARCH=arm
export KBUILD_BUILD_USER="Aki"
export KBUILD_BUILD_HOST="A_DEAD_PLANET"
export USE_CCACHE=1

function senddocument {
    curl -F chat_id="$id" -F document="@${1}" -F caption="${2}" parse_mode="Markdown" "https://api.telegram.org/bot$key/sendDocument" >/dev/null 2>&1
}

function sendmessage {
    curl -F chat_id="$id" -F parse_mode="markdown" -F disable_web_page_preview="true" -F text="${1}" "https://api.telegram.org/bot$key/sendMessage" >/dev/null 2>&1
}

function deldog() {
    RESULT=$(curl -sf --data-binary @"${1:--}" https://del.dog/documents) || {
        echo "ERROR: failed to post document" >&2
        exit 1
    }
    KEY=$(jq -r .key <<<"${RESULT}")
    echo "https://del.dog/${KEY}"
}

function transfer() {
    zipname=$(echo "$1" | awk -F '/' '{print $NF}')
    url=$(curl -# -T "$1" https://transfer.sh)
    printf '\n'
    echo -e "$url"
}

function upload() {
    curl -s -F 'file=@'"$1" "https://pixeldrain.com/api/file" >/dev/null 2>&1

    DOWNLOAD='https://pixeldrain.com/api/file/'$(curl -s -F 'file=@'"$1" "https://pixeldrain.com/api/file" | cut -d '"' -f 4)'?download'

    echo $DOWNLOAD
}

head="$(git log --graph --pretty=format:'%h-%d %s (%cr) <%an>' --abbrev-commit -n 1 | sed -e 's|*||')"
urlhead="$(git config --get remote.origin.url | sed -e 's|git@github.com:|https://github.com/|' | sed -e 's|git@gitlab.com:|https://gitlab.com/|' | sed -e 's|\.git||')/commit/$(git rev-parse HEAD)"
commits="$(git config --get remote.origin.url | sed -e 's|git@github.com:|https://github.com/|' | sed -e 's|git@gitlab.com:|https://gitlab.com/|' | sed -e 's|\.git||')/commits"
sendmessage "Starting build

Latest Commit: [$head]($urlhead)

Last 69 commits: [Tap this bruh]($commits)

Branch: $(git branch | grep \* | cut -d ' ' -f2)
"
echo "Checking for toolchain"
printf '\n'
if [ -e $TOOLCHAINDIR ]; then
    echo "Toolchain already present in required path"
    printf '\n'
    export CROSS_COMPILE=$TOOLCHAINDIR/bin/arm-eabi-
else
    echo "Toolchain not present, cloning in required path"
    printf '\n'
    git clone https://github.com/Akianonymus/Linaro-arm $TOOLCHAINDIR --depth 1 -b 4.9
    export CROSS_COMPILE=$TOOLCHAINDIR/bin/arm-eabi-
    echo "Toolchain sucessfully cloned"
    printf '\n'
fi

if [ -e arch/arm/boot/zImage ]; then rm arch/arm/boot/zImage;  fi
if [ -e log ]; then mv log log.bak; fi
if [ -e logwe ]; then mv logwe logwe.bak; fi
if [ -e $Anykernel_DIR/*tmp* ]; then rm $Anykernel_DIR/*tmp*; fi

if [[ $1 == "clean" ]]; then
    echo "Preparing for clean build user requested"
    make mrproper 2>&1 >>logwe 2>&1 >>log
    echo "Done"
    printf '\n'
fi

START=$(date +"%s")

echo "Loading" $DEFCONFIG
printf '\n'
make $DEFCONFIG 2>&1 >>logwe 2>&1 >>log
echo "Making kernel binary"
printf '\n'
make -j$(nproc --all) zImage 2>&1 >>logwe 2>&1 >>log

END=$(date +"%s")

DIFF=$((END - START))

if [ -e arch/arm/boot/zImage ]; then

    echo "Kernel compilation completed"
    printf '\n'
    echo "You can see normal compilation logs in $PWD/log"
    printf '\n'
    echo "For warnings, see $PWD/logwe"
    printf '\n'

    cp $KERNEL_DIR/arch/arm/boot/zImage $Anykernel_DIR

    cd $Anykernel_DIR

    echo "Generating changelog"
    printf '\n'
    if [ -e $Anykernel_DIR/changelog.txt ]; then
        rm $Anykernel_DIR/changelog.txt
    fi
    git log --graph --pretty=format:'%s' --abbrev-commit -n 150 >changelog.txt
    echo "Changelog generated"
    printf '\n'

    if [ -e $Anykernel_DIR/*.zip ]; then rm $Anykernel_DIR/*.zip; fi

    echo "Making Flashable zip"
    printf '\n'
    zip -r9 $FINAL_ZIP * -x *.zip $FINAL_ZIP >/dev/null
    echo "Flashable zip Created"
    printf '\n'
    echo "Path: ""$FULL_ZIP_PATH"
    printf '\n'

    echo "Build completed successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"

    if [ ! -z $id ]; then
        sendmessage "Build completed successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
        printf '\n'
        echo "Uploading zip to Telegram"
        printf '\n'
        senddocument "$FULL_ZIP_PATH" "Flashable Zip"
        echo "Uploaded"
        printf '\n'
        echo "Normal Logs:" >>tmp
        printf '\n' >>tmp
        deldog $KERNEL_DIR/log >>tmp
        printf '\n\n' >>tmp
        if [[ -s $KERNEL_DIR/logwe ]]; then
            echo "Warning Logs:" >>tmp
            printf '\n' >>tmp
            deldog $KERNEL_DIR/logwe >>tmp
        fi
        sendmessage "$(cat tmp)"
    elif curl -sI transfer.sh | grep -q "Moved Permanently"; then
        echo "Uploading zip to transfer"
        printf '\n'
        echo "Download link of kernel zip:" >>tmp
        printf '\n' >>tmp
        transfer "$FULL_ZIP_PATH" >>tmp
        printf '\n\n' >>tmp
        echo "Normal Logs:" >>tmp
        printf '\n' >>tmp
        deldog $KERNEL_DIR/log >>tmp
        printf '\n\n' >>tmp
        if [[ -s $KERNEL_DIR/logwe ]]; then
            echo "Warning Logs:" >>tmp
            printf '\n' >>tmp
            deldog $KERNEL_DIR/logwe >>tmp
        fi
        printf '\n\n' >>tmp
        echo "Last 150 Git changelogs:" >>tmp
        cat "$Anykernel_DIR/changelog.txt" >>tmp
        echo "Pasting to deldog"
        printf '\n'
        deldog tmp
    elif     curl -sI pixeldrain.com | grep -q "Moved Permanently"; then
        printf '\n'
        echo "Uploading zip to pixeldrain"
        printf '\n'
        echo "Download link of kernel zip:" >>tmp
        printf '\n' >>tmp
        upload "$FULL_ZIP_PATH" | sed 's/^.*https/https/' >>tmp
        printf '\n\n' >>tmp
        echo "Normal Logs:" >>tmp
        printf '\n' >>tmp
        deldog $KERNEL_DIR/log >>tmp
        printf '\n\n' >>tmp
        if [[ -s $KERNEL_DIR/logwe ]]; then
            echo "Warning Logs:" >>tmp
            printf '\n' >>tmp
            deldog $KERNEL_DIR/logwe >>tmp
        fi
        printf '\n\n' >>tmp
        echo "Last 150 Git changelogs:" >>tmp
        cat "$Anykernel_DIR/changelog.txt" >>tmp
        echo "Pasting to deldog"
        printf '\n'
        deldog tmp
    else
        echo "Not able to upload anywhere"
        echo "Upload yourself"
    fi

    exit 0

else

    echo "Kernel not compiled, fix errors and compile again"
    printf '\n'
    echo "See file $PWD/logwe for errors"
    printf '\n'
    echo "Uploading $PWD/logwe to deldog"
    printf '\n'
    deldog $PWD/logwe >a
    cat a
    if [ ! -z $id ]; then
        sendmessage "Build failed, here is the error log
$(cat a)"
    fi
    rm a

    exit 1
fi
