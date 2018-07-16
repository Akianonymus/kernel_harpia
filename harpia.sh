KERNEL_DIR=$PWD
Anykernel_DIR=$KERNEL_DIR/Anykernel2/harpia
TOOLCHAINDIR=$(pwd)/toolchain/linaro-7.2
DATE=$(date +"%d%m%Y")
KERNEL_NAME="BLEEDING_EDGE-Kernel"
DEVICE="-harpia-"
VER="-v70"
TYPE="-OREO"
FINAL_ZIP="$KERNEL_NAME""$DEVICE""$DATE""$TYPE""$VER".zip

export ARCH=arm
export KBUILD_BUILD_USER="Aki"
export KBUILD_BUILD_HOST="A_DEAD_PLANET"
export CROSS_COMPILE=$TOOLCHAINDIR/bin/arm-eabi-
export USE_CCACHE=1

if [ -e  arch/arm/boot/zImage ];
then
rm arch/arm/boot/zImage #Just to make sure it doesn't make flashable zip with previous zImage
fi;

echo "Making kernel binary"
make harpia_defconfig
make -j$( nproc --all ) zImage

if [ -e  arch/arm/boot/zImage ];
then
echo "Kernel compilation completed"

cp  $KERNEL_DIR/arch/arm/boot/zImage $Anykernel_DIR

cd $Anykernel_DIR

echo "Making Flashable zip"

echo "Generating changelog"

if [ -e $Anykernel_DIR/changelog.txt ];
then
rm $Anykernel_DIR/changelog.txt
fi;

git log --graph --pretty=format:'%s' --abbrev-commit -n 200  > changelog.txt

echo "Changelog generated"

if [ -e $Anykernel_DIR/*.zip ];
then 
rm *.zip
fi;

zip -r9 $FINAL_ZIP * -x *.zip $FINAL_ZIP > /dev/null

echo "Flashable zip Created"
echo "Flashable zip is stored in $Anykernel_DIR folder with name $FINAL_ZIP"
exit 0
else
echo "Kernel not compiled,fix errors and compile again"
exit 1
fi;

