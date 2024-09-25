#!/bin/bash

# BASH Tools to manipulate IPv6 addresses
# Example script

SCRIPT_PATH=$(readlink -f $0)
SCRIPT_PATH=$(dirname ${SCRIPT_PATH})

#echo $SCRIPT_PATH

if [[ -f "${SCRIPT_PATH}/libipv6-tools.bash" ]]; then
    . ${SCRIPT_PATH}/libipv6-tools.bash
else
    printf "ERROR: Missing ipv6-tools.bash file!\n"
    exit 1
fi

echo "1. Check if string is a valid IPv6:"
for IPv6_TEST in "1abc:02ab::" "1abc::02ab:003a" "1abc::02ab::003a" "1zas:02ab:003a:0004:5abc::"; do
    if ipv6_check "${IPv6_TEST}"; then
	printf "    String ${IPv6_TEST} is a valid IPv6\n"
    else
	printf "    String ${IPv6_TEST} is an invalid IPv6 format.\n"
    fi
done

echo "2. IPv6 uncompress tool:"
echo "  a. Test IPv6 with compression :: at the end of address"

IPv6_TEST="1abc:02ab:003a:0004:5abc::"
for IPv6_TEST in "1abc:02ab::" "1abc:02ab:003a::" "1abc:02ab:003a:0004::" "1abc:02ab:003a:0004:5abc::" "1abc:02ab:003a:0004:5abc:6abc::" "1abc:02ab:003a:0004:5abc:6abc:7abc::"; do
    ipv6_uncompress "${IPv6_TEST}" "IPv6_TUN_6RD_EXPAND"
    printf "    Before ${IPv6_TEST} and after ${IPv6_TUN_6RD_EXPAND}\n"
done
#exit 0

# Check case with :: inside of IPv6
echo
echo "  b. Test case of IPv6 with compression :: insite of the address"
IPv6_TEST="1abc:02ab:003a:0004:5abc::"
for IPv6_TEST in "1abc::2abc" "1abc::02ab:003a" "1abc:02ab::003a:4abc" "1abc:02ab::003a:4abc:5abc" "1abc:02ab:003a::4abc:5abc:6abc" "1abc:02ab:003a:0004::5abc:6abc:7abc"; do
    ipv6_uncompress "${IPv6_TEST}" "IPv6_TUN_6RD_EXPAND"
    printf "    Before ${IPv6_TEST} and after ${IPv6_TUN_6RD_EXPAND}\n"
done
#exit 0

echo
echo "3. IPv6 compress tool:"
for IPv6_TEST in "0000:0000:0000:0000:0000:0000:0000:0000" "1abc:2abc:0000:0000:0000:0000:0000:0000" "1abc:0000:0000:0000:0000:2abc:0000:0000" "1abc:0000:0000:0000:2abc:0000:0000:0000" "1abc:0000:0000:2abc:0000:0000:0000:0000"; do
    ipv6_compression "${IPv6_TEST}" "IPv6_TUN_6RD_COMPRESS"
    printf "  Before ${IPv6_TEST} and after ${IPv6_TUN_6RD_COMPRESS}\n"
done
#exit 0

echo
echo "4. IPv6 removing 0 leading tool:"
for IPv6_TEST in "0000:0000:0000:0000:0000:0000:0000:0000" "1abc:2abc:0000:0000:0000:0000:0000:0000" "1abc:0000:0000:0000:0000:2abc:0000:0000" "1abc:0000::0000:2abc:0000:0000" "1abc:0000:0000:0000:2abc:0000:0000:0000" "1abc:0000:0000:2abc:0000:0000:0000:0000"; do
    ipv6_leading_zero_compression "${IPv6_TEST}" "IPv6_TUN_6RD_ZERO_LEADING"
    printf "  Before ${IPv6_TEST} and after ${IPv6_TUN_6RD_ZERO_LEADING}\n"
done
#exit 0

echo
echo "5. IPv6 get first address of the subnet:"
for IPv6_TEST in "1abc:2abc:3abc:4abc:5abc:6abc:7abc:8abc/28" "1abc:2abc:3abc:4abc:5abc:6abc:7abc:8abc/32" "1abc:2abc:3abc:4abc:5abc:6abc:7abc:8abc/36" "1abc:2abc:3abc:4abc:5abc:6abc:7abc:8abc/42" "1abc:2abc:3abc:4abc:5abc:6abc:7abc:8abc/48"; do
    ipv6_first_subnet_address "${IPv6_TEST}" "IPv6_FIRST_ADDRESS"
    printf "  The first IPv6 address ${IPv6_TEST} is ${IPv6_FIRST_ADDRESS}\n"
done
#exit 0
