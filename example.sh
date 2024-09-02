#!/bin/bash

# BASH Tools to manipulate IPv6 addresses
# Example script

SCRIPT_PATH=$(readlink -f $0)
SCRIPT_PATH=$(dirname ${SCRIPT_PATH})

echo $SCRIPT_PATH

if [[ -f "${SCRIPT_PATH}/ipv6-tools.sh" ]]; then
	. ${SCRIPT_PATH}/ipv6-tools.sh
else
	echo "ERROR: Missing ipv6-tools.sh file!"
	exit 1
fi

echo "1. IPv6 uncompress tool:"
echo "  Test IPv6 with compression :: at the end of address"

for IPv6_TEST in "1abc:02ab::" "1abc:02ab:003a::" "1abc:02ab:003a:0004::" "1abc:02ab:003a:0004:5abc::" "1abc:02ab:003a:0004:5abc:6abc::" "1abc:02ab:003a:0004:5abc:6abc:7abc::"; do
	ipv6_uncompress "${IPv6_TEST}" "IPv6_TUN_6RD_EXPAND"
	echo -e "    Original IPv6: ${IPv6_TEST} and uncompress " ${IPv6_TUN_6RD_EXPAND}
done

echo
# Check case with :: inside of IPv6
echo "  Test case of IPv6 with compression :: insite of the address"
for IPv6_TEST in "1abc::2abc" "1abc::02ab:003a" "1abc:02ab::003a:4abc" "1abc:02ab::003a:4abc:5abc" "1abc:02ab:003a::4abc:5abc:6abc" "1abc:02ab:003a:0004::5abc:6abc:7abc"; do
	ipv6_uncompress "${IPv6_TEST}" "IPv6_TUN_6RD_EXPAND"
	echo -e "    Original IPv6: ${IPv6_TEST} and uncompress " ${IPv6_TUN_6RD_EXPAND}
done

echo "2. IPv6 uncompress tool:"
for IPv6_TEST in "0000:0000:0000:0000:0000:0000:0000:0000" "1abc:2abc:0000:0000:0000:0000:0000:0000" "1abc:0000:0000:0000:0000:2abc:0000:0000" "1abc:0000:0000:0000:2abc:0000:0000:0000" "1abc:0000:0000:2abc:0000:0000:0000:0000"; do
	ipv6_compression "${IPv6_TEST}" "IPv6_TUN_6RD_COMPRESS"
	echo -e "  Original IPv6: ${IPv6_TEST} and compressed " ${IPv6_TUN_6RD_COMPRESS}
done

echo "3. IPv6 removing 0 leading tool:"
for IPv6_TEST in "0000:0000:0000:0000:0000:0000:0000:0000" "1abc:2abc:0000:0000:0000:0000:0000:0000" "1abc:0000:0000:0000:0000:2abc:0000:0000" "1abc:0000::0000:2abc:0000:0000" "1abc:0000:0000:0000:2abc:0000:0000:0000" "1abc:0000:0000:2abc:0000:0000:0000:0000"; do
	ipv6_leading_zero_compression "${IPv6_TEST}" "IPv6_TUN_6RD_ZERO_LEADING"
	echo -e "  Original IPv6: ${IPv6_TEST} and compressed " ${IPv6_TUN_6RD_ZERO_LEADING}
done
