#!/bin/bash

# BASH Tools to manipulate IPv6 addresses
# BASH commands needes by this script:
#  1. BASH version >= 4.0 or a version to be able to use arrays.
#  2. printf from coreutils
#
# Avaiable functions:
#  1. ipv6_compression			- Returns a compress format of an IPv6
#  2. ipv6_leading_zero_compression	- Returns a compress format of an IPv6 from leading 0s.
#  3. ipv6_uncompress			- Returns an uncompressed format of an IPv6.
#  4. ipv6_network_address		- Returns the first IPv6 address of a given IPv6 subnet.
#  5. ipv6_check			- Checks if the given string is a valid IPv6 address.
#
# All functions needs first argument to be a valid IPv6 and second argument optional which is the name of a global variable (not the variable like $VAR, just VAR) where to store the result.
# In case the second argument is not given, will print the result to the stdout.
#
# All functions returns 0 in case the successful or 1 in case there is an error occured. A debug message to stderr will be displayed.
# The error must be treated by the main script, like exit the script or do something else.
#
# _echo_* functions can be override using _ECHO_* variable to point to another function
#
# If __DEBUG__ is used, some debug information will be showen for troubleshoot. There are 5 levels of debugging. Level 5 enables DASH/SHELL tracing.
# _echo_* functions can be override using _ECHO_* variable to point to another function
#
# To disable warnings to be displayed, set __SHOW_WARNINGS__=0
# To disable errors to be displayed, set __SHOW_ERRORS__=0
#
#
# This script can be used for free.
#
# Copyright (R) EasyNet Consuling SRL, Romania
# https://easynet.dev/
# https://github.com/EasyNetDev
#

unset __OLD_IFS__

if [[ -z "${__SHOW_INFO__}" ]]; then
    __SHOW_INFO__=1
else
    # Check if __SHOW_WARNINGS_ is an integer. Otherwise set to 1
    case ${__SHOW_INFO__} in
    *[!0-9]*)
	__SHOW_INFO__=1
    ;;
    esac
    if [[ ${__SHOW_INFO__} -gt 1 ]]; then
	# Enable script info to be displayed
	__SHOW_INFO__=1
    fi
fi

if [[ -z "${__SHOW_WARNINGS__}" ]]; then
    __SHOW_WARNINGS__=1
else
    # Check if __SHOW_WARNINGS_ is an integer. Otherwise set to 1
    case ${__SHOW_WARNINGS__} in
    *[!0-9]*)
	__SHOW_WARNINGS__=1
    ;;
    esac
    if [[ ${__SHOW_WARNINGS__} -gt 1 ]]; then
	# Enable script warnings to be displayed
	__SHOW_WARNINGS__=1
    fi
fi

if [[ -z "${__SHOW_ERRORS__}" ]]; then
    __SHOW_ERRORS__=1
else
    # Check if __SHOW_ERRORS__ is an integer. Otherwise set to 1
    case ${__SHOW_ERRORS__} in
    *[!0-9]*)
	__SHOW_ERRORS__=1
    ;;
    esac
    if [[ ${__SHOW_ERRORS__} -gt 1 ]]; then
	    # Enable script errors to be displayed
	__SHOW_ERRORS__=1
    fi
fi

if [[ -z "${__DEBUG__}" ]]; then
    __DEBUG__=0
else
    # Check if __DEBUG__ is an integer. Otherwise set to 1
    case ${__DEBUG__} in
    *[!0-9]*)
	__DEBUG__=1
    ;;
    esac
    if [[ ${__DEBUG__} -ge 5 ]]; then
	# Enable DASH script debugging
	set -x
    fi
fi

if [[ -z "${_ECHO_INFO_}" ]]; then
_echo_info_()
{
    if [[ ${__SHOW_INFO__} -eq 1 ]]; then
	echo "INFO: $@" > /dev/stderr
    fi
}
_ECHO_INFO_=_echo_info_
fi

if [[ -z "${_ECHO_WARNING_}" ]]; then
_echo_warning_()
{
    if [[ ${__SHOW_WARNING__} -eq 1 ]]; then
	echo "WARNING: $@" > /dev/stderr
    fi
}
_ECHO_WARNING_=_echo_warning_
fi

# DEBUG level 1
if [[ -z "${_ECHO_DEBUG_1_}" ]]; then
_echo_debug_1_()
{
    if [[ ${__DEBUG__} -ge 1 ]]; then
	echo "DEBUG: $@" > /dev/stderr
    fi
}
_ECHO_DEBUG_1_=_echo_debug_1_
fi

# DEBUG level 2
if [[ -z "${_ECHO_DEBUG_2_}" ]]; then
_echo_debug_2_()
{
    if [[ "${__DEBUG__}" -ge 2 ]]; then
	echo "DEBUG: $@" > /dev/stderr
    fi
}
_ECHO_DEBUG_2_=_echo_debug_2_
fi

# DEBUG level 3
if [[ -z "${_ECHO_DEBUG_3_}" ]]; then
_echo_debug_3_()
{
    if [[ "${__DEBUG__}" -ge 3 ]]; then
	echo "DEBUG: $@" > /dev/stderr
    fi
}
_ECHO_DEBUG_3_=_echo_debug_3_
fi

# DEBUG level 4
if [[ -z "${_ECHO_DEBUG_4_}" ]]; then
_echo_debug_4_()
{
    if [[ "${__DEBUG__}" -ge 4 ]]; then
	echo "DEBUG: $@" > /dev/stderr
    fi
}
_ECHO_DEBUG_4_=_echo_debug_4_
fi

if [[ -z "${_ECHO_ERROR_}" ]]; then
_echo_error_()
{
    if [[ ${__SHOW_ERRORS__} -eq 1 ]]; then
	echo "ERROR: $@" > /dev/stderr
    fi
}
_ECHO_ERROR_=_echo_error_
fi

__set_IFS() {
    # Set IFS to argument $1
    unset IFS
    IFS=${1}
}

__save_IFS() {
    # Save current IFS to be restored by __restore_IFS
    __OLD_IFS__=${IFS}
}

__restore_IFS() {
    # Restore the previous IFS only if __OLD_IFS__ was saved previously
    if [ -n "${__OLD_IFS__}" ]; then
	    IFS=${__OLD_IFS__}
	    unset __OLD_IFS__
    fi
}

__default_IFS() {
    unset IFS
    IFS=$' \t\n'
}

ipv6_check()
{
    # Check if the given string is a valid IPv6
    # Arguments:
    #   $1 - IPv6 to be checked
    #
    # Returns:
    #   0 - if is a valid IPv6
    #   1 - if is not a valid IPv6.
    #

    local IDX

    local IPv6="$1"

    local IPv6_COMPRESS_SUBBLOCK=0
    local IPv6_SUBBLOCKS=( )

    local SUBBLOCK
    local SUBBLOCK_LEN
    local SUBBLOCK_START=0
    local tmpIPv6="$IPv6"

    # Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
    __save_IFS
    __default_IFS

    # Loop until we don't have any sub-blocks.
    for ((IDX=0; IDX<40; IDX++)); do

	# In case tmpIPv6 is empty after stripping, let's stop.
	if [[ -z "$tmpIPv6" ]]; then
	    break
	fi

	# Let's check if we have compression delimiter "::"
	if [[ "${tmpIPv6:0:2}" == "::" ]]; then
	    ((IPv6_COMPRESS_SUBBLOCK++))
	    if [[ ${IPv6_COMPRESS_SUBBLOCK} -gt 1 ]]; then
		__restore_IFS
		return 1
		break
	    fi
	    # strip this :: delimiter and continue with the search
	    tmpIPv6=${tmpIPv6:2}
	    continue
	fi

	# Let's check if we have only "delimier"
	if [[ "${tmpIPv6:0:1}" == ":" ]]; then
	    tmpIPv6=${tmpIPv6:1}
	    continue
	fi

	SUBBLOCK=${tmpIPv6%%:*}
	SUBBLOCK_LEN=${#SUBBLOCK}
	# Check if the sub-block contains only HEX characters
	if ! [[ "${SUBBLOCK}" =~ ^[0-9a-fA-F]+$ ]]; then
	    __restore_IFS
	    return 1
	    break
	fi

	IPv6_SUBBLOCKS+=( $(printf "0x%x" "0x${SUBBLOCK}") )

	# Strip the sub-block in front of the IPv6
	tmpIPv6=${tmpIPv6:${SUBBLOCK_LEN}}
	#${_ECHO_DEBUG_1_} "new sub-string: ${tmpIPv6}"

	((SUBBLOCK_START=${SUBBLOCK_LEN}+1))
    done

    if [[ ${#IPv6_SUBBLOCKS[@]} -gt 8 ]]; then
	__restore_IFS
	return 1
    fi
    # 8 sub-blocks with compression is an invalid IPv6 format
    if [[ ${IPv6_COMPRESS_SUBBLOCK} -ne 0 && ${IPv6_SUBBLOCKS} -eq 8 ]]; then
	__restore_IFS
	return 1
    fi
    # Less than 8 sub-blocks without compression is an invalid IPv6 format.
    if [[ ${IPv6_COMPRESS_SUBBLOCK} -eq 0 && ${IPv6_SUBBLOCKS} -lt 8 ]]; then
	__restore_IFS
	return 1
    fi

    __restore_IFS
    return 0
}

ipv6_compression()
{
    # Compress IPv6 address.
    # Argumets:
    #   $1 - IPv6 address
    #
    # Optional Arguments:
    #   $2 - Name of global variable where we will store the result. Use only just "VAR", not "$VAR"
    #
    # Returns:
    #   0 - in case the compression was successful
    #   1 - in case there is an error in IPv6 format.
    #
    # Output:
    #   In case argument $2 is missing, print the result to output. Can be captured into a variable.
    #
    # Compress rules for an IPv6:
    # 1. That rule is also known as leading zero compression. You can remove the leading zeros (0s) in the 16 bits field of an IPv6 address. But each block in which you do that has at least one number remaining. If the field contains all zeros (0s), you must leave one zero (0) remaining. Removing leading zeros (0s) from the start does not have any effect on the value. However, you cannot apply that rule to trailing zeros (0s).
    # 2. That rule is also called the zero compression rule. According to that rule, if an IPv6 address contains continuous zeros, then they are replaced with (::), but only the longest continuous group of 0s!
    # Example : 1050:0000:0000:0000:0005:0000:0000:326b will be 1050:0:0:0:5:0:0:326b and in the end will be 1050::5:0:0:326b. Second group of 0s can't be compressed, becasue first group has 3 continuous 0s and the second one has only 2.
    # In case of tie, first one will be compressed.
    # 3. If zeros (0s) are present in a discontinuous pattern in IPv6 address, then at only one joining, the zeros (0s) are replaced with (::).

    local IPv6="$1"

    local IDX

    local IPv6_SUBBLOCK=( )

    local IPv6_FIRST_0s=0

    # Vars to save start and stop of the longes 0s groups
    local IPv6_LONGEST_0s_START=0
    local IPv6_LONGEST_0s_END=0

    # Vars to save start and stop of the current group
    local IPv6_CURRENT_GROUP_START=0
    local IPv6_CURRENT_GROUP_END=0

    local SUBBLOCK
    local SUBBLOCK_LEN
    local SUBBLOCK_START=0
    local tmpIPv6="$IPv6"

    # Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
    __save_IFS
    __default_IFS

    # Using substrigs. Could be much faster and less complex.
    # In case we see ::, the address is already compressed. Just retur i
    if [[ "${IPv6}" =~ :: ]]; then
	    # Compression detected. Return the same IPv6
	    if [[ -z "$2" ]]; then
		    echo "${IPv6}"
	    else
		    eval ${2}="${IPv6}"
	    fi
	    break
    fi

    #${_ECHO_DEBUG_1_} "IPv6 ${tmpIPv6}"
    # Loop until we don't have any sub-blocks.
    for ((IDX=0; IDX<8; IDX++)); do

	    SUBBLOCK=${tmpIPv6%%:*}
	    SUBBLOCK_LEN=${#SUBBLOCK}

	    # Check if the sub-block contains only HEX characters
	    if ! [[ "${SUBBLOCK}" =~ ^[0-9a-fA-F]+$ ]]; then
		    ${_ECHO_ERROR_} "provided string ${IPv6} contains characters which are not valid HEXA value! Allowed characters are: 0-9, a-f and A-F only!"
		    __restore_IFS
		    return 1
	    fi
	    IPv6_SUBBLOCK+=( $(printf "0x%x" "0x${SUBBLOCK}") )


	    # Strip the sub-block in front of the IPv6
	    tmpIPv6=${tmpIPv6:((${SUBBLOCK_LEN}+1))}
	    #${_ECHO_DEBUG_1_} "IPv6: ${tmpIPv6}"

	    ((SUBBLOCK_START=${SUBBLOCK_LEN}+1))
	    if [[ -z "$tmpIPv6" ]]; then
		    break
	    fi
    done

    # Let's check if we have 8 sub-blocks. In case nofirstt, the string is not a valid IPv6.
    if [[ $IDX -lt 7 ]]; then
	    ${_ECHO_ERROR_} "provided string ${IPv6} doesn't have 8 sub-blocks to match IPv6 format!"
	    ${_ECHO_ERROR_} "provid only uncompressed IPv6 for this tool."
	    __restore_IFS
	    return 1
    fi

    #${_ECHO_DEBUG_1_} "Total groups: ${!IPv6_SUBBLOCK[@]}"

    # Count each continuous groups of 0s blocks. Store the start and end of this group in IPv6_CURRENT_GROUP_*
    for IDX in ${!IPv6_SUBBLOCK[@]}; do
	# Check if IPv6_SUBBLOCK[${IDX}] is 0x0
	if [[ ${IPv6_SUBBLOCK[${IDX}]} == 0x0 ]]; then
	    # Start count how many continuous 0s sub-blocks we have
	    # Is this the first 0 in the group? If yes, mark it in IPv6_FIRST_0s and set the start group with IDX
	    if [[ ${IPv6_FIRST_0s} -eq 0 ]]; then
		IPv6_FIRST_0s=1
		IPv6_CURRENT_GROUP_START=${IDX}
	    else
		# If we already have a start of continuous 0s sub-blocks (marked in IPv6_FIRST_0s), update the current end with IDX.
		IPv6_CURRENT_GROUP_END=${IDX}
	    fi

	    # In case the IPv6 is ending in 0, we have to check this and add to calculation.
	    if [[ ${IDX} -eq $((${#IPv6_SUBBLOCK[@]}-1)) ]]; then
		if [[ $((${IPv6_CURRENT_GROUP_END}-${IPv6_CURRENT_GROUP_START})) -gt $((${IPv6_LONGEST_0s_END}-${IPv6_LONGEST_0s_START})) ]]; then
		    # New longer 0s group is ${IPv6_LONGEST_0s_GROUP}
		    IPv6_LONGEST_0s_START=${IPv6_CURRENT_GROUP_START}
		    IPv6_LONGEST_0s_END=${IPv6_CURRENT_GROUP_END}
		fi
	    fi
	else
	    # If IPv6_SUBBLOCK[${IDX}] is not 0x0, then reset IPv6_FIRST_0s and check if the current number of continuous 0s sub-blocks is the longest one.
	    if [[ ${IPv6_FIRST_0s} -eq 1 ]]; then
		# Reset FIRST 0 found
		IPv6_FIRST_0s=0
		# The new group of 0s is greater than previous one?
		if [[ $((${IPv6_CURRENT_GROUP_END}-${IPv6_CURRENT_GROUP_START})) -gt $((${IPv6_LONGEST_0s_END}-${IPv6_LONGEST_0s_START})) ]]; then
		    # New longer 0s group is ${IPv6_LONGEST_0s_GROUP}
		    IPv6_LONGEST_0s_START=${IPv6_CURRENT_GROUP_START}
		    IPv6_LONGEST_0s_END=${IPv6_CURRENT_GROUP_END}
		fi
	    fi
	fi
    done

    #${_ECHO_DEBUG_1_} "Longest 0s group is located between: ${IPv6_LONGEST_0s_GROUP[@]}"
    #${_ECHO_DEBUG_1_} "Compute compressed IPv6.."

    # Let's build the new format of IPv6 using IPv6_LONGEST_0s_START and IPv6_LONGEST_0s_END to compact the IPv6
    IPv6=""
    for IDX in ${!IPv6_SUBBLOCK[@]}; do
	if [[ ${IDX} -ge ${IPv6_LONGEST_0s_START} && ${IDX} -le ${IPv6_LONGEST_0s_END} ]]; then
	    if [[ ${IDX} -eq ${IPv6_LONGEST_0s_START} ]]; then
		IPv6+="::"
	    fi
	    continue
	fi
	# Don't add delimier in first sub-block or just after the "::"
	if [[ ${IDX} -eq 0 || ${IDX} -eq $((${IPv6_LONGEST_0s_END}+1)) ]]; then
	    IPv6+=$(printf "%x" ${IPv6_SUBBLOCK[${IDX}]})
	else
	    IPv6+=$(printf ":%x" ${IPv6_SUBBLOCK[${IDX}]})
	fi
    done

    if [[ -z "$2" ]]; then
	echo "${IPv6}"
    else
	eval ${2}="${IPv6}"
    fi

    __restore_IFS
    return 0
}

ipv6_uncompress()
{
    # Uncompress/expand IPv6
    # Arguments:
    #   $1 - IPv6 to be expanded
    #
    # Optional Arguments:
    #   $2 - Name of global variable where we will store the result. Use only just "VAR", not "$VAR"
    #
    # Returns:
    #   0 - in case uncompress was successful.
    #   1 - in case the IPv6 address is invalid.
    #
    # Output:
    #   In case argument $2 is missing, print the result to output.

    local IDX

    local IPv6="$1"

    local IPv6_COMPRESS_SUBBLOCK=0
    local IPv6_ADD_0s=0

    # Number of groups before and after compression. Needed for computation for decompression.
    local IPv6_BEFORE_SUBBLOCKS=( )
    local IPv6_AFTER_SUBBLOCKS=( )
    local IPv6_TOTAL_SUBBLOCKS=0

    # Each IPv6 uncompressed must have 7 delimiters

    local SUBBLOCK
    local SUBBLOCK_LEN
    local tmpIPv6="$IPv6"


    # Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
    __save_IFS
    __default_IFS

    #${_ECHO_DEBUG_1_} "IPv6 ${tmpIPv6}"

    # Loop until we don't have any sub-blocks.
    for ((IDX=0; IDX<40; IDX++)); do

	    # In case tmpIPv6 is empty after stripping, let's stop.
	    if [[ -z "$tmpIPv6" ]]; then
		    break
	    fi

	    # Let's check if we have compression delimiter "::"
	    if [[ "${tmpIPv6:0:2}" == "::" ]]; then
		    ((IPv6_COMPRESS_SUBBLOCK++))
		    if [[ ${IPv6_COMPRESS_SUBBLOCK} -gt 1 ]]; then
			    ${_ECHO_ERROR_} "privided string ${IPv6} contains multiple compression delimiters \"::\". Please check your IPv6."
			    __restore_IFS
			    return 1
		    fi
		    # strip this :: delimiter and continue with the search
		    tmpIPv6=${tmpIPv6:2}
		    continue
	    fi

	    # Let's check if we have only "delimier"
	    if [[ "${tmpIPv6:0:1}" == ":" ]]; then
		    tmpIPv6=${tmpIPv6:1}
		    continue
	    fi

	    SUBBLOCK=${tmpIPv6%%:*}
	    SUBBLOCK_LEN=${#SUBBLOCK}
	    # Check if the sub-block contains only HEX characters
	    if ! [[ "${SUBBLOCK}" =~ ^[0-9a-fA-F]+$ ]]; then
		    ${_ECHO_ERROR_} "provided string ${IPv6} contains characters which are not valid HEXA value! Allowed characters are: 0-9, a-f and A-F only!"
		    __restore_IFS
		    return 1
	    fi

	    if [[ ${IPv6_COMPRESS_SUBBLOCK} -eq 0 ]]; then
		    IPv6_BEFORE_SUBBLOCKS+=( $(printf "0x%x" "0x${SUBBLOCK}") )
	    else
		    IPv6_AFTER_SUBBLOCKS+=( $(printf "0x%x" "0x${SUBBLOCK}") )
	    fi

	    # Strip the sub-block in front of the IPv6
	    tmpIPv6=${tmpIPv6:${SUBBLOCK_LEN}}
	    #${_ECHO_DEBUG_1_} "new sub-string: ${tmpIPv6}"

    done

    ((IPv6_TOTAL_SUBBLOCKS=${#IPv6_BEFORE_SUBBLOCKS[@]}+${#IPv6_AFTER_SUBBLOCKS[@]}))

    # Post-checks:
    # More that 8 sub-blocks is an invalid IPv6 format
    if [[ ${IPv6_TOTAL_SUBBLOCKS} -gt 8 ]]; then
	    ${_ECHO_ERROR_} "provided string ${IPv6} has more than 8 sub-blocks! This is an invalid IPv6 format! Please check the IPv6 format!"
	    __restore_IFS
	    return 1
    fi
    # 8 sub-blocks with compression is an invalid IPv6 format
    if [[ ${IPv6_COMPRESS_SUBBLOCK} -ne 0 && ${IPv6_TOTAL_SUBBLOCKS} -eq 8 ]]; then
	    ${_ECHO_ERROR_} "provided string ${IPv6} 8 sub-blocks and compression! This is an invalid IPv6 format! Please check the IPv6 format!"
	    __restore_IFS
	    return 1
    fi
    # Less than 8 sub-blocks without compression is an invalid IPv6 format.
    if [[ ! ${IPv6_COMPRESS_SUBBLOCK} && ${IPv6_TOTAL_SUBBLOCKS} -lt 8 ]]; then
	    ${_ECHO_ERROR_} "provided string ${IPv6} has less than 8 sub-blocks without compression! This is an invalid IPv6 format! Please check the IPv6 format!"
	    __restore_IFS
	    return 1
    fi

    if [[ ${IPv6_TOTAL_SUBBLOCKS} -lt 8 ]]; then
	# Walk through the IPv6 and check where is the compression.
	((IPv6_ADD_0s=8-${IPv6_TOTAL_SUBBLOCKS}))
	#${_ECHO_DEBUG_1_} "We must add ${IPv6_ADD_0s} more of groups of 0s."

	# Build first part of the IPv6
	IPv6=""
	for IDX in ${!IPv6_BEFORE_SUBBLOCKS[@]}; do
	    if [[ $IDX -eq 0 ]]; then
		IPv6+=$(printf "%x" ${IPv6_BEFORE_SUBBLOCKS[${IDX}]})
	    else
		IPv6+=$(printf ":%x" ${IPv6_BEFORE_SUBBLOCKS[${IDX}]})
	    fi
	done

	for (( IDX=0; IDX<((${IPv6_ADD_0s})); IDX++)); do
	    IPv6+=":0"
	done

	for IDX in ${!IPv6_AFTER_SUBBLOCKS[@]}; do
	    IPv6+=$(printf ":%x" ${IPv6_AFTER_SUBBLOCKS[${IDX}]})
	done

    fi

    # Return uncompressed IPv6 with compressed leading 0s
    if [[ -z "$2" ]]; then
	echo "${IPv6}"
    else
	eval ${2}="${IPv6}"
    fi

    __restore_IFS
    return 0
}

ipv6_leading_zero_compression()
{
    # Remove leading zeros from each sub-block of the IPv6
    # Arguments:
    #   $1 - IPv6 to remove leading zeros.
    #
    # Optional Arguments:
    #   $2 - Name of global variable where we will store the result. Use only just "VAR", not "$VAR"
    #
    # Returns:
    #    0 - in case leading zero compression was successful.
    #    1 - in case the IPv6 address is invalid.
    #
    # Output:
    #   In case argument $2 is missing, print the result to output.

    local IDX

    local IPv6="$1"
    local IPv6_COMPRESS_SUBBLOCK=0

    local IPv6_BEFORE_SUBBLOCKS=( )
    local IPv6_AFTER_SUBBLOCKS=( )

    local SUBBLOCK
    local SUBBLOCK_LEN
    local tmpIPv6="$IPv6"

    # Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
    __save_IFS
    __default_IFS

    # Loop until we don't have any sub-blocks.
    for ((IDX=0; IDX<40; IDX++)); do

	# In case tmpIPv6 is empty after stripping, let's stop.
	if [[ -z "$tmpIPv6" ]]; then
	    break
	fi

	# Let's check if we have compression delimiter "::"
	if [[ "${tmpIPv6:0:2}" == "::" ]]; then
	    ((IPv6_COMPRESS_SUBBLOCK++))
	    if [[ ${IPv6_COMPRESS_SUBBLOCK} -gt 1 ]]; then
		${_ECHO_ERROR_} "privided string ${IPv6} contains multiple compression delimiters \"::\". Please check your IPv6."
		__restore_IFS
		return 1
	    fi
	    # strip this :: delimiter and continue with the search
	    tmpIPv6=${tmpIPv6:2}
	    continue
	fi

	# Let's check if we have only "delimier"
	if [[ "${tmpIPv6:0:1}" == ":" ]]; then
	    tmpIPv6=${tmpIPv6:1}
	    continue
	fi

	SUBBLOCK=${tmpIPv6%%:*}
	SUBBLOCK_LEN=${#SUBBLOCK}
	# Check if the sub-block contains only HEX characters
	if ! [[ "${SUBBLOCK}" =~ ^[0-9a-fA-F]+$ ]]; then
	    ${_ECHO_ERROR_} "provided string ${IPv6} contains characters which are not valid HEXA value! Allowed characters are: 0-9, a-f and A-F only!"
	    __restore_IFS
	    return 1
	fi

	if [[ ${IPv6_COMPRESS_SUBBLOCK} -eq 0 ]]; then
	    IPv6_BEFORE_SUBBLOCKS+=( $(printf "0x%x" "0x${SUBBLOCK}") )
	else
	    IPv6_AFTER_SUBBLOCKS+=( $(printf "0x%x" "0x${SUBBLOCK}") )
	fi

	# Strip the sub-block in front of the IPv6
	tmpIPv6=${tmpIPv6:${SUBBLOCK_LEN}}
	#${_ECHO_DEBUG_1_} "new sub-string: ${tmpIPv6}"

    done

    # Rewrite hex value of IPv6 sub-block without leading 0s
    IPv6=""

    for IDX in ${!IPv6_BEFORE_SUBBLOCKS[@]}; do
	if [[ $IDX -eq 0 ]]; then
	    IPv6+=$(printf "%x" ${IPv6_BEFORE_SUBBLOCKS[${IDX}]})
	else
	    IPv6+=$(printf ":%x" ${IPv6_BEFORE_SUBBLOCKS[${IDX}]})
	fi
    done
    if [[ ${#IPv6_AFTER_SUBBLOCKS[@]} -gt 0 ]]; then
	IPv6+=":"
	for IDX in ${!IPv6_AFTER_SUBBLOCKS[@]}; do
	    IPv6+=$(printf ":%x" ${IPv6_AFTER_SUBBLOCKS[${IDX}]})
	done
    fi

    if [[ -z "$2" ]]; then
	echo "${IPv6}"
    else
	eval ${2}="${IPv6}"
    fi

    __restore_IFS
    return 0
}

ipv6_network_address()
{
    # Calculate the first address of IPv6 using the prefix
    # Arguments:
    #   $1 - IPv6 subnet (IPv6/PREFIX format).
    #
    # Optional Arguments:
    #   $2 - Name of global variable where we will store the result. Use only just "VAR", not "$VAR"
    #
    # Returns:
    #   IPv6 first address of the subnet.
    #
    # Exits:
    #    1 - in case the IPv6 address is invalid.
    #
    # Output:
    #   In case argument $2 is missing, print the result to output.
    #
    # To simplify the maths, we are using an array which contains 16 types of prefix masks and we will map prefixes from 0 to 15 to this array
    # The array will contain:
    # 0x0000 (0000000000000000b), 0x8000 (1000000000000000b), 0xC000 (1100000000000000b), 0xE000 (1110000000000000b), 0xF000 (1111000000000000b), 0xF800 (1111100000000000b), 0xFC00 (1111110000000000b), 0xFE00 (1111111000000000b), 0xFF00 (1111111100000000b),
    # 0xFF80 (1111111110000000b), 0xFFC0 (1111111111000000b), 0xFFE0 (1111111111100000b), 0xFFF0 (1111111111110000b), 0xFFF8 (1111111111111000b), 0xFFFC (1111111111111100b), 0xFFFE (1111111111111110b)
    #
    # We are using 16 bits of mask because IPv6 has sub-blocks of 16 bits and will be easy to map each prefix sub-block to each uncompressed IPv6 sub-block.
    #
    # We will split the prefix in groups of 16 and reminder.
    # For example:
    #    Prefix 28: 28/16 = 1 and reminder 12. We will have only one group of 16 bits which by default will be 0xFFFF and second group will be 12 bits mapped to 0xFFF0 and the reset 0x0000.
    #    Prefix 48: 42/16 = 2 and reminder 10. We will have only two groups of 16 bits which by default will be 0xFFFF and third group will be 10 bits mapped to 0xFFC0 and the reset 0x0000.
    #

    local IDX
    local IPv6="$1"
    local IPv6_PREFIX
    local VAR_NAME=""

    local SPLIT_PREFIX_1
    local SPLIT_PREFIX_2

    # Prefix to mask mapping using index in array
    local PREFIX_MAP=( 0x0000 0x8000 0xC000 0xE000 0xF000 0xF800 0xFC00 0xFE00 0xFF00 0xFF80 0xFFC0 0xFFE0 0xFFF0 0xFFF8 0xFFFC 0xFFFE )

    local IPv6_SUBBLOCKS=( )
    # We will set IPv6 mask sub-blocks with 0x0000 by default
    local IPv6_MASK_SUBBLOCKS=( 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 )
    local newValue

    # Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
    __save_IFS
    __default_IFS

    IPv6_PREFIX=${IPv6#*/}
    IPv6=${IPv6%/*}

    # Check if we have IPv6/PREFIX format
    if [[ "${IPv6_PREFIX}" == "${IPv6}" ]]; then
	# Prefix couldn't be extracted from argument $IPv6, we will check the second argument
	# Presume 128 prefix
	IPv6_PREFIX=128
    fi

    if [[ ! "${IPv6_PREFIX}" =~ ^[0-9]+$ ]]; then
	${_ECHO_ERROR_} "Invalid IPv6 prefix ${IPv6_PREFIX}! Please correct the IPv6 string!"
	__restore_IFS
	return 1
    fi

    if [[ ${IPv6_PREFIX} -lt 1 || ${IPv6_PREFIX} -gt 128 ]]; then
	${_ECHO_ERROR_} "Invalid IPv6 prefix ${IPv6_PREFIX}! Prefix must be between 1 and 128! Please correct the IPv6 string!"
	__restore_IFS
	return 1
    fi

    local IPv6_SUBBLOCKS=( )

    IPv6=$(ipv6_uncompress "${IPv6}")

    IPv6_SUBBLOCKS=( ${IPv6//:/ } )

    ((SPLIT_PREFIX_1=${IPv6_PREFIX}/16))
    ((SPLIT_PREFIX_2=${IPv6_PREFIX}%16))

    # Build an array for prefixes
    # We have 2 bytes pre sub-block multipy by 8 sub-blocks = 16 and multipy by 8
    for (( IDX=0; IDX<${SPLIT_PREFIX_1}; IDX++)); do
	IPv6_MASK_SUBBLOCKS[${IDX}]=0xFFFF
    done

    IPv6_MASK_SUBBLOCKS[${IDX}]=${PREFIX_MAP[${SPLIT_PREFIX_2}]}

    for IDX in ${!IPv6_SUBBLOCKS[@]}; do
	((newValue=0x${IPv6_SUBBLOCKS[${IDX}]} & IPv6_MASK_SUBBLOCKS[${IDX}]))
	IPv6_SUBBLOCKS[${IDX}]=$(printf "%x" ${newValue})
    done

    IPv6=${IPv6_SUBBLOCKS[@]}
    IPv6=${IPv6// /:}
    IPv6=$(ipv6_compression "${IPv6}")
    IPv6="${IPv6}/${IPv6_PREFIX}"

    if [[ -z "${2}" ]]; then
	    echo ${IPv6}
    else
	    eval ${2}="${IPv6}"
    fi

    __restore_IFS
    return 0
}
