# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=1
device.name1=Moto g play
device.name2=harpia
device.name3=Moto G4 Play
device.name4=Mota G play
device.name5=Mutu G4 play
supported.versions=
'; } # end properties

# shell variables
block=/dev/block/platform/soc.0/7824900.sdhci/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

write_boot;

## end install

