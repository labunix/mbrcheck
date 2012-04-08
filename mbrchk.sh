#!/bin/bash

if [ `id -u` -eq "0" ];then
  echo "INFO:root check ok."
  echo ""
else
  echo "ERROR:Please run as root"
  exit 1
fi

# example : /dev/sda /dev/hda
devlist=$(df -h | grep '^/dev/[hs]d' | awk '{print $1}' | sed s/[0-9]//g | sort | uniq)


for bootdev in ${devlist};do
  #MBR enable check, Signature = 0xAA55
  BOOTSIG=$(dd if=${bootdev} bs=2 skip=255 count=1 2> /dev/null | od -tx1 | \
    awk '{print "0x" $3$2}' | grep '0xaa55')
  if [ ${BOOTSIG} == '0xaa55' ];then
    echo -e "INFO:${bootdev} \t${BOOTSIG}"
  else
    echo "ERROR:Not found boot signature ${bootdev}"
  fi

  #MBR boot Partition check, /dev/[hs]d[abcd] = 0x80
  BOOTFLAG=$(dd if=${bootdev} bs=2 skip=223 count=32 2> /dev/null | od -tx1 | \
    awk '{print $2}' | nl | grep '80' | awk '{print $1 " " $2}')
  echo ${BOOTFLAG} | grep 80 > /dev/null 2>&1 && \
    echo "INFO:${bootdev}${BOOTFLAG}" | awk '{print $1 " \t0x" $2}' || \
    echo "ERROR:Not Found Active Partition ${bootdev}"

  #MBR first binary check, 0x48eb
  JUMP=$(dd if=${bootdev} bs=2 count=1 2> /dev/null | od -tx1 | \
    awk '{print "0x" $3$2}' | grep '48eb')
  echo ${JUMP} | grep '48eb' > /dev/null 2>&1 && \
    echo -e "INFO:JUMP\t${JUMP}" || \
    echo "ERROR:${bootdev} MBR first jump ${JUMP}"

  # boot loader version check
  VERSION=$(dd if=${bootdev} bs=2 skip=31 count=1 2> /dev/null | od -tx1 | \
    awk '{print "0x" $3$2}' | grep "0x[0-9a-f]")
  if [ ${VERSION} == "0x0203" ];then
    echo -e "INFO:GRUB \t${VERSION}"
  else
    echo -e "ERROR:Other bootloader version ${VERSION}"
  fi

  echo "#Stage2"
  STAGE2LOAD=$(dd if=${bootdev} bs=2 skip=33 count=1 2> /dev/null | od -tx1 | \
    awk '{print "0x" $3$2}' | grep "0x[0-9a-f]")
  echo -e "INFO:load\t${STAGE2LOAD}"

  STAGE2SECT=$(dd if=${bootdev} bs=2 skip=34 count=2 2> /dev/null | od -tx1 | \
    awk '{print "0x" $5$4$3$3}' | grep "0x[0-9a-f]")
  echo -e "INFO:Secter\t${STAGE2SECT}"

  STAGE2SEG=$(dd if=${bootdev} bs=2 skip=36 count=1 2> /dev/null | od -tx1 | \
    awk '{print "0x" $3$3}' | grep "0x[0-9a-f]")
  echo -e "INFO:Segment\t${STAGE2SEG}"


  # End loop
  echo ""
done 
