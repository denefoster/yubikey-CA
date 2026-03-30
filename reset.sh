#!/bin/bash
#
#yubico-piv-tool -averify-pin -P471112
cat /dev/null >database
rm database.attr
rm database.old
rm serial.old
echo '00' >serial
rm newcerts/*
rm munin*
rm sub*
rm slush_root*
# These are intentionally incorrect, to lock the yubikey forcing a factory reset
yubico-piv-tool -averify-pin -P471112
yubico-piv-tool -averify-pin -P471112
yubico-piv-tool -averify-pin -P471112
yubico-piv-tool -achange-puk -P471112 -N6756789
yubico-piv-tool -achange-puk -P471112 -N6756789
yubico-piv-tool -achange-puk -P471112 -N6756789
yubico-piv-tool -achange-puk -P471112 -N6756789
yubico-piv-tool -areset
yubico-piv-tool -aset-chuid
yubico-piv-tool -aset-ccc
