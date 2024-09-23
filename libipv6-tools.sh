#!/bin/sh

# SHELL/DASH Tools to manipulate IPv6 addresses. This version is using non ARRAY workaround to be more portable over the systems
# DHClient is using by default /bin/sh which in Debian for example is using SHELL/DASH. Trying to use the BASH version will fail to run and DHClient will refuse the IPv4 address.
#
# SHELL/DASH commands needes by this script:
#  1. SHELL/DASH or similar shell interpreter
#  2. printf builtin or from coreutils. DASH has a builtin printf
#
# Avaiable functions:
#  1. ipv6_compress						- Returns a compress format of an IPv6
#  2. ipv6_leading_zero_compression		- Returns a compress format of an IPv6 from leading 0s.
#  3. ipv6_decompress					- Returns an uncompressed format of an IPv6.
#  4. ipv6_first_subnet_address			- Returns the first IPv6 address of a given IPv6 subnet.
#  5. ipv6_last_subnet_address			- Returns the last IPv6 address of a given IPv6 subnet.
#  6. ipv6_check						- Checks if the given string is a valid IPv6 address.
#
# All functions needs first argument to be a valid IPv6 and second argument optional which is the name of a variable (not the variable like $VAR, just VAR) where to store the result.
# In case the second argument is not given, will print the result to the stdout.
#
# All functions returns 0 in case the successful or 1 in case there is an error occured. A debug message to stderr will be displayed.
# The error must be treated by the main script, like exit the script or do something else.
#
# _echo_* functions can be override using _ECHO_* variable to point to another function
#
# If __DEBUG__ is used, some debug information will be showen for troubleshoot. There are 5 levels of debugging. Level 5 enables SHELL/DASH tracing.
# _echo_* functions can be override using _ECHO_* variable to point to another function
#
# To disable warnings to be displayed, set __SHOW_WARNINGS__=0
# To disable errors to be displayed, set __SHOW_ERRORS__=0
#
# SHELL/DASH has an issue using IFS=$' \t\n', like BASH. Even I'm unset IFS, I'm still geting errors in my functions.
# To fix it, we have to set it like this:
#IFS=" \t
#"
# And in this way is setting <space><tab><newline> correctly.
#
#I've created 4 functions:
# __save_IFS()     -> save current IFS in __OLD_IFS_X__, using index __OLD_IFS_IDX__, to be restored later by __restore_IFS(). Each time we enter in a function, we have to call this function.
# __restore_IFS()  -> restore the newest __OLD_IFS_X__, using index __OLD_IFS_IDX__. Each time we exit from the function (before return or in the last line of the function) we need to call this funcion.
# __set_IFS()      -> set IFS to a desired delimiter.
# __default_IFS()  -> set SHELL/DASH default IFS.
#
#
# This script can be used for free.
#
# Copyright (R) EasyNet Consuling SRL, Romania
# https://easynet.dev/
# https://github.com/EasyNetDev
#

__OLD_IFS_IDX__=0
__SKIP_IPV6_CHECK__=0


if [ -z "${__SHOW_INFO__}" ]; then
	__SHOW_INFO__=1
else
	# Check if __SHOW_WARNINGS_ is an integer. Otherwise set to 1
	case ${__SHOW_INFO__} in
		*[!0-9]*)
			__SHOW_INFO__=1
		;;
	esac
	if [ ${__SHOW_INFO__} -gt 1 ]; then
		# Enable script info to be displayed
		__SHOW_INFO__=1
	fi
fi

if [ -z "${__SHOW_WARNINGS__}" ]; then
	__SHOW_WARNINGS__=1
else
	# Check if __SHOW_WARNINGS_ is an integer. Otherwise set to 1
	case ${__SHOW_WARNINGS__} in
		*[!0-9]*)
			__SHOW_WARNINGS__=1
		;;
	esac
	if [ ${__SHOW_WARNINGS__} -gt 1 ]; then
		# Enable script warnings to be displayed
		__SHOW_WARNINGS__=1
	fi
fi

if [ -z "${__SHOW_ERRORS__}" ]; then
	__SHOW_ERRORS__=1
else
	# Check if __SHOW_ERRORS__ is an integer. Otherwise set to 1
	case ${__SHOW_ERRORS__} in
		*[!0-9]*)
			__SHOW_ERRORS__=1
		;;
	esac
	if [ ${__SHOW_ERRORS__} -gt 1 ]; then
		# Enable script errors to be displayed
		__SHOW_ERRORS__=1
	fi
fi

if [ -z "${__DEBUG__}" ]; then
	__DEBUG__=0
else
	# Check if __DEBUG__ is an integer. Otherwise set to 1
	case ${__DEBUG__} in
		*[!0-9]*)
			__DEBUG__=1
		;;
	esac
	if [ ${__DEBUG__} -ge 5 ]; then
		# Enable SHELL/DASH script debugging
		set -x
	fi
fi

if [ -z "${_ECHO_INFO_}" ]; then
_echo_info_()
{
	if [ ${__SHOW_INFO__} -eq 1 ]; then
		echo "INFO: $@" > /dev/stderr
	fi
}
_ECHO_INFO_=_echo_info_
fi

if [ -z "${_ECHO_WARNING_}" ]; then
_echo_warning_()
{
	if [ ${__SHOW_WARNING__} -eq 1 ]; then
		echo "WARNING: $@" > /dev/stderr
	fi
}
_ECHO_WARNING_=_echo_warning_
fi

# DEBUG level 1
if [ -z "${_ECHO_DEBUG_1_}" ]; then
_echo_debug_1_()
{
	if [ ${__DEBUG__} -ge 1 ]; then
		echo "DEBUG: $@" > /dev/stderr
	fi
}
_ECHO_DEBUG_1_=_echo_debug_1_
fi

# DEBUG level 2
if [ -z "${_ECHO_DEBUG_2_}" ]; then
_echo_debug_2_()
{
	if [ "${__DEBUG__}" -ge 2 ]; then
		echo "DEBUG: $@" > /dev/stderr
	fi
}
_ECHO_DEBUG_2_=_echo_debug_2_
fi

# DEBUG level 3
if [ -z "${_ECHO_DEBUG_3_}" ]; then
_echo_debug_3_()
{
	if [ "${__DEBUG__}" -ge 3 ]; then
		echo "DEBUG: $@" > /dev/stderr
	fi
}
_ECHO_DEBUG_3_=_echo_debug_3_
fi

# DEBUG level 4
if [ -z "${_ECHO_DEBUG_4_}" ]; then
_echo_debug_4_()
{
	if [ "${__DEBUG__}" -ge 4 ]; then
		echo "DEBUG: $@" > /dev/stderr
	fi
}
_ECHO_DEBUG_4_=_echo_debug_4_
fi

if [ -z "${_ECHO_ERROR_}" ]; then
_echo_error_()
{
	if [ ${__SHOW_ERRORS__} -eq 1 ]; then
		echo "ERROR: $@" > /dev/stderr
	fi
}
_ECHO_ERROR_=_echo_error_
fi

__save_IFS() {
	# Save current IFS to __OLD_IFS_X__ stack
	eval __OLD_IFS_${__OLD_IFS_IDX__}__=\"\${IFS}\"

	# Increase the stack __OLD_IFS_X__
	__OLD_IFS_IDX__=$((__OLD_IFS_IDX__+=1))
}

__restore_IFS() {

	# Decrese the stack ID.
	__OLD_IFS_IDX__=$((__OLD_IFS_IDX__-=1))

	# Restore the previous IFS from last __OLD_IFS_X__ that was saved previously and unset it.
	eval IFS=\"\${__OLD_IFS_${__OLD_IFS_IDX__}__}\"
	eval unset __OLD_IFS_${__OLD_IFS_IDX__}__
}

__set_IFS() {
	# Set IFS to argument $1
	unset IFS
	IFS=${1}
}

__default_IFS() {
	unset IFS
	IFS=" \t
"
}

__get_number_of_el_in_list()
{
	# To simulate an array like, we will use this function to walk through a list space-separated and return total number of elements.
	# Arguments:
	#   $1 - Name of the variable (can be local in a function or global) that contains the list. Use only just "VAR", not "$VAR"
	#   $2 - Separator to be use in the list. Default is "space", but for IPv6 we will use ":", for example. If you want default separator, set this argument to ""
	#
	# Optional Arguments:
	#   $3 - Name of variable (can be local in a function or global) where we will store the result. Use only just "VAR", not "$VAR"
	#
	# Returns:
	#   0 - in case the was successful
	#   1 - in case there is an error.
	#
	# Outputs:
	# If $2 is defined, then the total number of elements will be store in this variable, otherwise to the standard output.
	#

	local __LIST_NAME_1__="$1"
	local __SEPARATOR__="$2"
	local __RETURN_VAR__="$3"

	local __IDX__

	local __LIST_1__=""
	local __VAL__=""


	# Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
	__save_IFS

	if [ -z "${__LIST_NAME_1__}" ]; then
 		__restore_IFS
		return 1
	fi

	eval __LIST_1__=\$${__LIST_NAME_1__}

	if [ -z "${__SEPARATOR__}" ]; then
		__set_IFS " "
	else
		__set_IFS "${__SEPARATOR__}"
	fi
	__IDX__=0
	for __VAL__ in ${__LIST_1__}; do
		# Let's skip "" values. In IPv6 with compression "::" we will get NULL strings
		if [ -z "${__VAL__}" ]; then
			continue
		fi
		__IDX__=$((__IDX__+=1))
	done

 	if [ -n "${__RETURN_VAR__}" ]; then
 		eval ${__RETURN_VAR__}=\${__IDX__}
 	else
 		echo ${__IDX__}
 	fi

 	__restore_IFS
	return 0
}

__get_value_from_list_by_index()
{
	# To simulate an array like, we will use this function to walk through a list space-separated and return the value of the specific index.
	# Arguments:
	#   $1 - Name of the variable (can be local in a function or global) that contains the list. Use only just "VAR", not "$VAR"
	#   $2 - Index of which element we want to return. Starting from 0.
	#   $3 - Separator to be use in the list. Default is "space", but for IPv6 we will use ":", for example. If you want default separator, set this argument to ""
	#
	# Optional Arguments:
	#   $4 - Name of variable (can be local in a function or global) where we will store the result. Use only just "VAR", not "$VAR"
	#
	# Returns:
	#   0 - in case the compression was successful
	#   1 - in case there is no match for the index given
	#

	# Keep __LIST_2 different from __LIST_1, Seems that is not working to use the same local variable in both functions.
	local __LIST_NAME_2__="$1"
	local __IDX_SEARCH__="$2"
	local __SEPARATOR__="$3"
	local __RETURN_VAR__="$4"

	local __IDX__
	local __FN_NAME__="__get_value_from_list_by_index()"

	local __LIST_2__=""
	local __VAL__=""

	local __RESULT__

	local __TOTAL_EL__

	__save_IFS
	__default_IFS

	if [ -z "${__LIST_NAME_2__}" ]; then
		${_ECHO_ERROR_} "${__FN_NAME__}: Argument 1 is empty!"
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 1
	fi

	# Check if $2 is integer. String comparation is faster than sed
	case "${__IDX_SEARCH__}" in
		*[0-9]*)
		;;
		*|"")
			${_ECHO_ERROR_} "${__FN_NAME__}: Argument 2 is not an integer!"
			if [ -n "${__RETURN_VAR__}" ]; then
				eval ${__RETURN_VAR__}=""
			fi
			__restore_IFS
			return 1
		;;
	esac

	eval __LIST_2__=\$${__LIST_NAME_2__}

	__get_number_of_el_in_list "__LIST_2__" "${__SEPARATOR__}" "__TOTAL_EL__"

	__IDX__=0
	for __VAL__ in ${__LIST_2__}; do
		${_ECHO_DEBUG_3_} "${__FN_NAME__}: Current sub-block: ${__VAL__}"
		${_ECHO_DEBUG_4_} "${__FN_NAME__}: __IDX__=${__IDX__}"
		if [ ${__IDX__} -eq ${__IDX_SEARCH__} ]; then
			break
		fi
		__IDX__=$((__IDX__+=1))
		${_ECHO_DEBUG_4_} "${__FN_NAME__}: __IDX__=${__IDX__}"
	done

	${_ECHO_DEBUG_4_} "${__FN_NAME__}: ${__TOTAL_EL__} vs ${__IDX__}"

	if [ ${__IDX__} -eq ${__TOTAL_EL__} ]; then
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 1
	fi

 	if [ -n "${__RETURN_VAR__}" ]; then
 		eval ${__RETURN_VAR__}=\${__VAL__}
 	else
 		echo ${__VAL__}
 	fi

 	__restore_IFS
	return 0
}

ipv6_check_skip_set()
{
	__SKIP_IPV6_CHECK__=1
}

ipv6_check_skip_reset()
{
	__SKIP_IPV6_CHECK__=0
}

ipv6_check_errno()
{
	# Print explained error for ipv6_check() returns
	#
	# Arguments:
	#   $1 - ipv6_check() return error
	#	$2 - if is 1 then use newline. if is 0, don't use newline.
	#
	# Returns:
	#   0 - on success
	#   1 - if $1 is an invalid value
	#
	# Output:
	#   Explained error text for the specific ipv6_check() return error
	#

	local __NEWLINE__=0
	local __RET__=0

	case ${1} in
		*[!0-9]*)
			printf "Invalid \"${1}\" ipv6_check() return code."
			return 1
		;;
	esac

	# Default to print newline.
	case ${2} in
		*[!0-9]*|"")
			__NEWLINE__=1
		;;
		*)
			if [ ${2} -lt 0 ]; then
				__NEWLINE__=0
			elif [ ${2} -gt 1 ]; then
				__NEWLINE__=1
			fi
		;;
	esac

	case ${1} in
		0)
			printf "Valid IPv6."
		;;
		1)
			printf "Found multiple compression delimiter \"::\"!"
		;;
		2)
			printf "Found more than 2 consecuvive compression delimiter \":\"!"
		;;
		3)
			printf "Found invalid characters! Allowed characters are: 0-9,a-f,A-F and :"
		;;
		4)
			printf "Found more than 8 sub-blocks!"
		;;
		5)
			printf "Found a sub-block with a value greater than 0xFFFF!"
		;;
		10)
			printf "Compression needs 8 sub-blocks! Provide an uncompressed IPv6!"
		;;
		20)
			printf "Uncompression found more than 8 sub-blocks! Please check your IPv6."
		;;
		21)
			printf "Uncompression returns an error when it tried to count number of sub-blocks before compression!"
		;;
		30)
			printf "Invalid IPv6 prefix! IPv6 prefix must be an integer number between 1 and 128!"
		;;
		31)
			printf "IPv6 prefix out of range! IPv6 prefix must be between 1 and 128!"
		;;
		*)
			printf "Unknown error."
			__RET__=1
		;;
	esac

	if [ ${__NEWLINE__} -eq 1 ]; then
		printf "\n"
	fi
	return ${__RET__}
}

ipv6_check()
{
	# Check if the given string is a valid IPv6
	# Arguments:
	#   $1 - IPv6 to be checked
	#
	# Returns:
	#   0 - if is a valid IPv6
	#   1 - if multiple compression delimiters "::"
	#   2 - if we found more than 2 consecutive delimiters ":"
	#   3 - if there is sub-block with invalid hexa characters
	#   4 - if there are more than 8 sub-blocks
	#   5 - if there is a sub-block with a value greater than 0xFFFF or 65535
	#

	local __IPv6__="$1"
	local __IPv6__2="${__IPv6__}"

	local __FN_NAME__="ipv6_check()"

	local __SUBBLOCK__
	# total sub-blocks can't be less than 3 (the case of "::") or more than 8.
	local __TOTAL_SUBBLOCKS__=0

	local __RESULT__

	local __IPv6_COMPRESS_SUBBLOCK__=0
	local __IPv6_ADD_GROUPS_0s__=0

	local __IPv6_REAR_SUBBLOCKS__

	${_ECHO_DEBUG_2_} "${__FN_NAME__}: Starting function.."

	__save_IFS

	${_ECHO_DEBUG_3_} "${__FN_NAME__}: Processing IPv6 \"${__IPv6__}\""
	# Split in 2 sub-blocks: BEFORE and AFTER
	__IPv6_REAR_SUBBLOCKS__=${__IPv6__#*::}

	# Get next character from the remaining __IPv6_REAR_SUBBLOCKS__
	__RESULT__=$(printf "%-.1s" "${__IPv6_REAR_SUBBLOCKS__}")

	if [ "${__IPv6_REAR_SUBBLOCKS__}" != "${__IPv6_REAR_SUBBLOCKS__#*::}" ]; then
		${_ECHO_DEBUG_1_} "${__FN_NAME__}: Found more multiple compressions delimiters \"::\" in IPv6!"
		__restore_IFS
		return 1
	fi

	# In case we have compression, we have to check if there are more than 2 consecutive delimiters ":"
	if [ "${__IPv6__}" != "${__IPv6_REAR_SUBBLOCKS__}" ]; then
		# Check for more than 2 ":" consecutive delimiters
		if [ "${__RESULT__}" = ":" ]; then
			${_ECHO_DEBUG_1_} "${__FN_NAME__}: Found more than more than 2 consecutive delimiters \":\" in IPv6!"
			__restore_IFS
			return 2
		fi
	fi

	# IPv6 Unspecified address is a special case and we don't need to go through all the code.
	if [ "${__IPv6__}" = "::" ]; then
		${_ECHO_DEBUG_1_} "${__FN_NAME__}: Found valid IPv6 (${__IPv6__}) Unspecified address."
 		__restore_IFS
 		return 0
	fi

	# Check if the IPv6 contains only valid characters
	# string comparation is faster than sed
	case "${__IPv6__}" in
		*[!a-fA-F0-9:]*|"")
			${_ECHO_DEBUG_1_} "ipv6_check(): Found invalid characters in IPv6! Allowed characters are [a-fA-F0-9:]!"
			__restore_IFS
			return 3
			break
		;;
	esac

	__set_IFS ":"
	for __SUBBLOCK__ in ${__IPv6__}; do

		# When we use IFS=":" and we have compression in IPv6, we will get a NULL string ("") in these cases:
		# 1. NULL between the ":"s, ex: "a001::b002"
		# 2. In the beginning of the string and between the ":"s, ex: "::012a"
		# 3. Between the ":"s and the end of the string, ex: "a001::"
		# In these cases must be ingnored and we must continue with the next sub-block.
		#
		if [ -z "${__SUBBLOCK__}" ]; then
			continue
		fi

		# Count only the valid sub-blocks, not also the compression sub-blocks.
		__TOTAL_SUBBLOCKS__=$((__TOTAL_SUBBLOCKS__+=1))

		if [ ${__TOTAL_SUBBLOCKS__} -gt 8 ]; then
			${_ECHO_DEBUG_1_} "${__FN_NAME__}: Provided IPv6 has more than 8 sub-blocks!"
 			__restore_IFS
 			return 4
		fi

		${_ECHO_DEBUG_4_} "${__FN_NAME__}: Proccess sub-block: ${__SUBBLOCK__}"
		${_ECHO_DEBUG_4_} "${__FN_NAME__}: Total sub-blocks  : ${__TOTAL_SUBBLOCKS__}"

		# Convert hexa value to decimal to check if is between 0 and 65535.
		__RESULT__=$(printf "%d" "0x${__SUBBLOCK__}")

		if [ ${__RESULT__} -gt 65535 ]; then
			${_ECHO_DEBUG_1_} "${__FN_NAME__}: sub-block ${__SUBBLOCK__} is overlapping 0xFFFF value!"
 			__restore_IFS
 			return 5
			break
		fi
	done

	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Total sub-blocks  : ${__TOTAL_SUBBLOCKS__}"

 	__restore_IFS
 	return 0
}

ipv6_compress()
{
	# Compress IPv6 address.
	# Argumets:
	#   $1 - IPv6 address
	#
	# Optional Arguments:
	#   $2 - Name of variable where we will store the result. Use only just "VAR", not "$VAR"
	#
	# Returns:
	#   0 - in case the compression was successful
	#   >0 - in case there is an error in IPv6 format. Check ipv6_check() returns codes
	#
	# In case __SKIP_IPV6_CHECK__ is set to 1, the function will not call ipv6_check().
	# Is usefull when you have to decompress, work on IPv6 then you have to compress the IP and we don't want to call twice ipv6_check().
	#
	# Output:
	#   In case argument $3 is missing, print the result to output. Can be captured into a variable.
	#

	local __IPv6__="$1"
	local __RETURN_VAR__="$2"

	local __IDX__
	local __RET__
	local __FN_NAME__="ipv6_compress()"


	local __IPv6_SUBBLOCKS__=""
	local __IPv6_TOTAL_SUBBLOCKS__=""

	local __IPv6_FIRST_0s__=0

	# Vars to save start and stop of the longes 0s groups
	local IPv6_LONGEST_0s_START=0
	local IPv6_LONGEST_0s_END=0

	# Vars to save start and stop of the current group
	local IPv6_CURRENT_GROUP_START=0
	local IPv6_CURRENT_GROUP_END=0

	local __SUBBLOCK__
	local __SUBBLOCK_LEN__
	local __SUBBLOCK_START__=0
	local __TOTAL_SUBBLOCKS__=0
	local __newIPv6__=""

	local __RESULT__
	local __COMPRESSION__

	${_ECHO_DEBUG_2_} "${__FN_NAME__}: Starting function.."

	# Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
	__save_IFS
	__default_IFS

	# Let's check if we have valid IPv6
	if [ "${__SKIP_IPV6_CHECK__}" != "1" ]; then
		ipv6_check "${__IPv6__}"
		__RET__=$?
		if [ ${__RET__} -gt 0 ]; then
			if [ -n "${__RETURN_VAR__}" ]; then
				eval ${__RETURN_VAR__}=""
			fi
			__restore_IFS
			return ${__RET__}
		fi
	fi


	# Using substrigs. Could be much faster and less complex.
	# In case we see ::, the address is already compressed. Just return it
	__COMPRESSION__=${__IPv6__%%::}

	if [ "${__IPv6__}" != "${__COMPRESSION__}" ]; then
		# Compression detected. Return the same IPv6
		${_ECHO_DEBUG_1_} "${__FN_NAME__}: Compression detected: ${__IPv6__} vs ${__COMPRESSION__}"
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}="${__IPv6__}"
		else
			# Print if we have something stored in __STRING__
			printf "${__IPv6__}"
		fi
		__restore_IFS
		return 0
	fi

	# Loop until we don't have any sub-blocks. We will loop through the string by splitting it using ":" delimiter. If we have less than 8 or more sub-groups in __IPv6__, then there is something wrong with the IPv6 format!

	# Count each continuous groups of 0s sub-blocks. Store the start and end of this group in IPv6_CURRENT_GROUP_*
	__IPv6_FIRST_0s__=0
	__IDX__=0
	__set_IFS ":"
	for __SUBBLOCK__ in ${__IPv6__}; do

		${_ECHO_DEBUG_3_} "${__FN_NAME__}: We processing sub-block ${__SUBBLOCK__} on index ${__IDX__}"

		# SHELL/DASH can't do HEXA checks. We need to change to decimal.
		__RESULT__=$(printf "%d" "0x${__SUBBLOCK__}")

		# Check if current __SUBBLOCK__ is 0x0
		if [ ${__RESULT__} -eq 0 ]; then
			# Start to count how many continuous 0s sub-blocks we have
			# Is this the first 0x0 in the group? If yes, mark it in __IPv6_FIRST_0s__ and set the start group with __IDX__
			if [ ${__IPv6_FIRST_0s__} -eq 0 ]; then
				__IPv6_FIRST_0s__=1
				IPv6_CURRENT_GROUP_START=${__IDX__}
			else
				# If we already have a start of continuous 0s sub-blocks (marked in __IPv6_FIRST_0s__), update the current end with __IDX__.
				IPv6_CURRENT_GROUP_END=${__IDX__}
			fi

			# In case the IPv6 is ending in 0x0, we have to check this and add to calculation.
			if [ ${__IDX__} -eq 7 ]; then
				if [ $((${IPv6_CURRENT_GROUP_END}-${IPv6_CURRENT_GROUP_START})) -gt $((${IPv6_LONGEST_0s_END}-${IPv6_LONGEST_0s_START})) ]; then
					# New longer 0s group is ${IPv6_LONGEST_0s_GROUP}
					IPv6_LONGEST_0s_START=${IPv6_CURRENT_GROUP_START}
					IPv6_LONGEST_0s_END=${IPv6_CURRENT_GROUP_END}
				fi
			fi
		else
			# If current __SUBBLOCK__ is not 0x0, then reset __IPv6_FIRST_0s__ and check if the current number of continuous 0s sub-blocks is the longest one.
			if [ ${__IPv6_FIRST_0s__} -eq 1 ]; then
				# Reset FIRST 0 found
				__IPv6_FIRST_0s__=0
				# The new group of 0s is greater than previous one?
				if [ $((${IPv6_CURRENT_GROUP_END}-${IPv6_CURRENT_GROUP_START})) -gt $((${IPv6_LONGEST_0s_END}-${IPv6_LONGEST_0s_START})) ]; then
					# New longer 0s group is ${IPv6_LONGEST_0s_GROUP}
					IPv6_LONGEST_0s_START=${IPv6_CURRENT_GROUP_START}
					IPv6_LONGEST_0s_END=${IPv6_CURRENT_GROUP_END}
				fi
			fi
		fi
		__IDX__=$((__IDX__+=1))
	done

	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Longest 0s group is located between index: ${IPv6_LONGEST_0s_START} and ${IPv6_LONGEST_0s_END}"
	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Compute compressed IPv6.."

	# Let's build the new format of IPv6 using IPv6_LONGEST_0s_START and IPv6_LONGEST_0s_END to compact the IPv6
	__newIPv6__=""
	__IDX__=0
	for __SUBBLOCK__ in ${__IPv6__}; do
		${_ECHO_DEBUG_3_} "${__FN_NAME__}: Processing sub-block: ${__SUBBLOCK__} on index ${__IDX__}"
		if [ ${__IDX__} -ge ${IPv6_LONGEST_0s_START} -a ${__IDX__} -le ${IPv6_LONGEST_0s_END} ]; then
			if [ ${__IDX__} -eq ${IPv6_LONGEST_0s_START} ]; then
				__newIPv6__="${__newIPv6__}::"
				${_ECHO_DEBUG_3_} "Add delimiter ::"
			fi
			${_ECHO_DEBUG_3_} "${__FN_NAME__}: Sub-block skipped ${__SUBBLOCK__}"
			__IDX__=$((__IDX__+=1))
			continue
		fi
		# Don't add delimier in first sub-block or just after the "::"
		if [ ${__IDX__} -eq 0 -o ${__IDX__} -eq $((${IPv6_LONGEST_0s_END}+1)) ]; then
			__newIPv6__="${__newIPv6__}"$(printf "%x" 0x${__SUBBLOCK__})
		else
			__newIPv6__="${__newIPv6__}"$(printf ":%x" 0x${__SUBBLOCK__})
		fi
		__IDX__=$((__IDX__+=1))
	done

	if [ -n "${__RETURN_VAR__}" ]; then
		eval ${__RETURN_VAR__}="${__newIPv6__}"
	else
		# Print if we have something stored in __STRING__
		printf "${__newIPv6__}"
	fi
	__restore_IFS
	return 0

}

ipv6_decompress()
{
	# Decompress/expand IPv6
	# Arguments:
	#   $1 - IPv6 to be expanded
	#
	# Optional Arguments:
	#   $2 - Name of global variable where we will store the result. Use only just "VAR", not "$VAR"
	#
	# In case __SKIP_IPV6_CHECK__ is set to 1, the function will not call ipv6_check().
	# Is usefull when you have to decompress, work on IPv6 then you have to compress the IP and we don't want to call twice ipv6_check().
	#
	# Returns:
	#   0 - in case decompress was successful.
	#   >=1 - in case the IPv6 address is invalid. Check ipv6_check() returns codes.
	#
	# Output:
	#   In case argument $3 is missing, print the result to output.

	local __IPv6__="$1"
	local __RETURN_VAR__="$2"

	local __IDX_0s__
	local __FN_NAME__="ipv6_decompress()"

	local __RET__=0
	local __newIPv6__=""

	local __IPv6_COMPRESS_SUBBLOCK__=0
	local __IPv6_ADD_GROUPS_0s__=0

	# Number of groups before and after compression. Needed for computation for decompression.
	local __IPv6_FRONT_SUBBLOCKS__=""
	local __IPv6_REAR_SUBBLOCKS__=""
	local __IPv6_BEFORE_TOTAL_SUBBLOCKS__=""
	local __IPv6_AFTER_TOTAL_SUBBLOCKS__=""
	local __IPv6_TOTAL_SUBBLOCKS__=0

	# Each IPv6 uncompressed must have 7 delimiters
	local __SUBBLOCK__

	${_ECHO_DEBUG_2_} "${__FN_NAME__}: Starting function.."

	# Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
	__save_IFS
	__default_IFS

	# Let's check if we have valid IPv6
	if [ "${__SKIP_IPV6_CHECK__}" != "1" ]; then
		ipv6_check "${__IPv6__}"
		__RET__=$?
		if [ ${__RET__} -gt 0 ]; then
			if [ -n "${__RETURN_VAR__}" ]; then
				eval ${__RETURN_VAR__}=""
			fi
			__restore_IFS
			return ${__RET__}
		fi
	fi

	if [ "${__IPv6__}" = "::" ]; then
		__newIPv6__="0:0:0:0:0:0:0:0"
		${_ECHO_DEBUG_1_} "${__FN_NAME__}: Found valid IPv6 (${__IPv6__}) Unspecified address."
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}="${__newIPv6__}"
		else
			# Print if we have something stored in __STRING__
			printf "${__newIPv6__}"
		fi
		__restore_IFS
		return 0
	fi

	# Split in 2 big sub-blocks: BEFORE and AFRTER
	__IPv6_FRONT_SUBBLOCKS__=${__IPv6__%%::*}
	__IPv6_REAR_SUBBLOCKS__=${__IPv6__#*::}

	# Replace the IFS with ":" to avoid using sed/tr
	__get_number_of_el_in_list "__IPv6__" ":" "__IPv6_TOTAL_SUBBLOCKS__"

	if [ ${__IPv6_TOTAL_SUBBLOCKS__} -gt 8 ]; then
		${_ECHO_ERROR_} "${__FN_NAME__}: provided IPv6 ${__IPv6__} has more than 8 sub-blocks! Please check your IPv6."
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 20
	fi

	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Front Sub-blocks: ${__IPv6_FRONT_SUBBLOCKS__}"
	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Rear Sub-blocks : ${__IPv6_REAR_SUBBLOCKS__}"

	# If both BEFORE and AFTER are the same, there is no compression
	if [ "${__IPv6_FRONT_SUBBLOCKS__}" = "${__IPv6_REAR_SUBBLOCKS__}" ]; then
		# Return uncompressed IPv6 with compressed leading 0s
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}="${__IPv6__}"
		else
			# Print if we have something stored in __STRING__
			printf "${__IPv6__}"
		fi
		__restore_IFS
		return 0
	fi

	# If in __IPv6_REAR_SUBBLOCKS__ we find again ::, then there is a double compression in IPv6 and we have to stop processing it. This is an invalid format
	if [ "${__IPv6_REAR_SUBBLOCKS__}" != "${__IPv6_REAR_SUBBLOCKS__#*::}" ]; then
		${_ECHO_ERROR_} "${__FN_NAME__}: provided string ${__IPv6__} contains multiple compression delimiters \"::\". Please check your IPv6."
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 1
	fi

	# Let's calculate how many groups of 0s we need to add to our IPv6.
	if ! __get_number_of_el_in_list "__IPv6_FRONT_SUBBLOCKS__" ":" "__IPv6_BEFORE_TOTAL_SUBBLOCKS__"; then
		${_ECHO_ERROR_} "${__FN_NAME__}: an error occured when we tried to count number of sub-blocks before compression!"
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 21
	fi

	if ! __get_number_of_el_in_list "__IPv6_REAR_SUBBLOCKS__" ":" "__IPv6_AFTER_TOTAL_SUBBLOCKS__"; then
		${_ECHO_ERROR_} "${__FN_NAME__}: an error occured when we tried to count number of sub-blocks after compression!"
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 21
	fi

	__IPv6_TOTAL_SUBBLOCKS__=$((${__IPv6_BEFORE_TOTAL_SUBBLOCKS__}+${__IPv6_AFTER_TOTAL_SUBBLOCKS__}))
	__IPv6_ADD_GROUPS_0s__=$((8-${__IPv6_TOTAL_SUBBLOCKS__}))

	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Sub-blocks before compression (__IPv6_BEFORE_TOTAL_SUBBLOCKS__) : ${__IPv6_BEFORE_TOTAL_SUBBLOCKS__}"
	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Sub-blocks after compression (__IPv6_AFTER_TOTAL_SUBBLOCKS__)   : ${__IPv6_AFTER_TOTAL_SUBBLOCKS__}"
	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Total IPv6 sub-blocks (__IPv6_TOTAL_SUBBLOCKS__)                : ${__IPv6_TOTAL_SUBBLOCKS__}"
	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Total 0s groups to add (__IPv6_ADD_GROUPS_0s__)                 : ${__IPv6_ADD_GROUPS_0s__}"

	__newIPv6__=""

	# Compute first part of IPv6 using BEFORE sub-blocks
	__set_IFS ":"
	for __SUBBLOCK__ in ${__IPv6_FRONT_SUBBLOCKS__}; do

		${_ECHO_DEBUG_4_} "${__FN_NAME__}: Subblock: "${__SUBBLOCK__}

		__RESULT__=$(printf "%d" "0x${__SUBBLOCK__}")
		if [ -z "${__newIPv6__}" ]; then
			__newIPv6__=$(printf "%x" ${__RESULT__})
		else
			__newIPv6__=$(printf "%s:%x" "${__newIPv6__}" ${__RESULT__})
		fi
	done
	__default_IFS

	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Partial uncompressed IPv6: ${__IPv6__}"

	# Compute compression IPv6 by repace compression delimiter "::" with 0s sub-blocks
	for __IDX_0s__ in `seq 1 ${__IPv6_ADD_GROUPS_0s__}`; do
		${_ECHO_DEBUG_3_} "${__FN_NAME__}: Add zero group number ${__IDX_0s__}"
		if [ -z "${__newIPv6__}" ]; then
			__newIPv6__="0"
		else
			__newIPv6__="${__newIPv6__}:0"
		fi
	done

	# Compute last part of IPv6 using BEFORE sub-blocks
	__set_IFS ":"
	for __SUBBLOCK__ in ${__IPv6_REAR_SUBBLOCKS__}; do

		${_ECHO_DEBUG_3_} "${__FN_NAME__}: Subblock: "${__SUBBLOCK__}

		__RESULT__=$(printf "%d" "0x${__SUBBLOCK__}")

		if [ -z "${__newIPv6__}" ]; then
			__newIPv6__=$(printf "%x" ${__RESULT__})
		else
			__newIPv6__=$(printf "%s:%x" "${__newIPv6__}" ${__RESULT__})
		fi
	done

	${_ECHO_DEBUG_3_} "${__FN_NAME__}: Computed IPv6: ${__newIPv6__}"
	# Return uncompressed IPv6 with compressed leading 0s
	if [ -n "${__RETURN_VAR__}" ]; then
		eval ${__RETURN_VAR__}="${__newIPv6__}"
	else
		# Print if we have something stored in __STRING__
		printf "${__newIPv6__}"
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
	#    >0 - in case the IPv6 address is invalid. Check ipv6_check() error codes
	#
	# Output:
	#   In case argument $2 is missing, print the result to output.

	local __IPv6__="$1"
	local __RETURN_VAR__="$2"

	local __IDX__
	local __FN_NAME__="ipv6_leading_zero_compression()"

	local __newIPv6__=""
	local IPv6_COMPRESS_SUBBLOCK=0
	local __IPv6_FRONT_SUBBLOCKS__=""
	local __IPv6_REAR_SUBBLOCKS__=""
	local __SUBBLOCK__
	#local SUBBLOCK_LEN

	${_ECHO_DEBUG_2_} "${__FN_NAME__}: Starting function.."

	# Reset IFS to default. Sometimes if IFS is set somewhere in the code, can lead to errors!
	__save_IFS
	__default_IFS

	# Let's check if we have valid IPv6
	ipv6_check "${__IPv6__}"
	__RET__=$?
	if [ ${__RET__} -gt 0 ]; then
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 1
	fi

	# Split in 2 big sub-blocks: BEFORE and AFRTER
	__IPv6_FRONT_SUBBLOCKS__=${__IPv6__%%::*}
	__IPv6_REAR_SUBBLOCKS__=${__IPv6__#*::}

	# Let's calculate how many groups of 0s we need to add to our IPv6.
	__newIPv6__=""
	__set_IFS ":"
	for __SUBBLOCK__ in ${__IPv6_FRONT_SUBBLOCKS__}; do

		${_ECHO_DEBUG_3_} "${__FN_NAME__}: Subblock: "${__SUBBLOCK__}
		#${_ECHO_DEBUG_3_} "Subblock len: "${__SUBBLOCK_LEN__}

		__RESULT__=$(printf "%d" "0x${__SUBBLOCK__}")
		if [ -z "${__newIPv6__}" ]; then
			__newIPv6__=$(printf "%x" ${__RESULT__})
		else
			__newIPv6__=$(printf "%s:%x" "${__newIPv6__}" ${__RESULT__})
		fi
		__IDX__=$((__IDX__+=1))
	done

	if [ "${__IPv6_FRONT_SUBBLOCKS__}" = "${__IPv6_REAR_SUBBLOCKS__}" ]; then
		# Return zero leading removed IPv6
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}="${__newIPv6__}"
		else
			# Print if we have something stored in __STRING__
			printf "${__newIPv6__}"
		fi
		__restore_IFS
		return 0
	fi

	# Add additional ":" to form compression delimiter "::"
	__newIPv6__="${__newIPv6__}:"
	__set_IFS ":"
	for __SUBBLOCK__ in ${__IPv6_REAR_SUBBLOCKS__}; do

		${_ECHO_DEBUG_1_} "${__FN_NAME__}: Sub-block: "${__SUBBLOCK__}
		#${_ECHO_DEBUG_1_} "Subblock len: "${__SUBBLOCKipv6_first_subnet_address_LEN__}

		__RESULT__=$(printf "%d" "0x${__SUBBLOCK__}")
		__newIPv6__=$(printf "%s:%x" "${__newIPv6__}" ${__RESULT__})
		__IDX__=$((__IDX__+=1))
	done

	# Return zero leading removed IPv6
	if [ -n "${__RETURN_VAR__}" ]; then
		eval ${__RETURN_VAR__}="${__newIPv6__}"
	else
		# Print if we have something stored in __STRING__
		printf "${__newIPv6__}"
	fi
	__restore_IFS
	return 0
}

ipv6_first_subnet_address()
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
	#    0 - if the process was successful
	#    1 - in case the IPv6 address is invalid.
	#
	# Output:
	#   In case argument $2 is missing, print the result to output.
	#

	local __IPv6__="$1"
	local __RETURN_VAR__="$2"

	local __IDX__
	local __IDX2__

	local __newIPv6__
	local __IPv6_PREFIX__
	local __IPv6_MASK__
	local __VAR_NAME__=""
	local __RET__
	local __RESULT__
	local __VALUE__
	local __FN_NAME__="ipv6_first_subnet_address()"

	local __IPv6_LIST__
	local __SUBBLOCK__
	local __newSUBBLOCK__
	local __SUBBLOCK_PREFIX__


	local __SPLIT_PREFIX_1__
	local __SPLIT_PREFIX_2__
	local __PREFIX_2__

	# Prefix to mask mapping using index in array
	local __PREFIX_MAP__="0x0000 0x8000 0xC000 0xE000 0xF000 0xF800 0xFC00 0xFE00 0xFF00 0xFF80 0xFFC0 0xFFE0 0xFFF0 0xFFF8 0xFFFC 0xFFFE"

	local __IPv6_SUBBLOCKS__=""
	# We will set IPv6 mask sub-blocks with 0x0000 by default
	local __IPv6_MASK_SUBBLOCKS__=""
	local newValue

	${_ECHO_DEBUG_2_} "${__FN_NAME__}: Starting function.."

	__save_IFS
	__default_IFS

	# Split the IPv6 and IPv6_PREFIX
	__IPv6_PREFIX__=${__IPv6__#*/}
	__IPv6__=${__IPv6__%/*}

	# Let's check if we have valid IPv6
	ipv6_check "${__IPv6__}"
	__RET__=$?
	if [ ${__RET__} -gt 0 ]; then
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 1
	fi

	# Force ipv6_compress and ipv6_decompress to not use ipv6_check(). We already used before.
	ipv6_check_skip_set

	# Check if we have IPv6/PREFIX format
	if [ "${__IPv6_PREFIX__}" = "${__IPv6__}" ]; then
		# Prefix couldn't be extracted from argument ${__IPv6__}
		# Presume 128 prefix
		__IPv6_PREFIX__=128
	fi

	# Check if __IPv6_PREFIX__ is an integer.
	case ${__IPv6_PREFIX__} in
		*[!0-9]*)
			${_ECHO_ERROR_} "${__FN_NAME__}: Invalid IPv6 prefix ${__IPv6_PREFIX__}! IPv6 prefix must be an integer number between 1 and 128!"
			if [ -n "${__RETURN_VAR__}" ]; then
				eval ${__RETURN_VAR__}=""
			fi
			__restore_IFS
			return 30
		;;
	esac

	if [ ${__IPv6_PREFIX__} -lt 1 -o ${__IPv6_PREFIX__} -gt 128 ]; then
		${_ECHO_ERROR_} "${__FN_NAME__}: Invalid IPv6 prefix ${__IPv6_PREFIX__}! Prefix must be between 1 and 128! Please correct the IPv6 string!"
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return 31
	fi

	# Uncompress the IPv6. Skipping ipv6_check().
	__newIPv6__=$(ipv6_decompress "${__IPv6__}")
	__RET__=$?
	if [ ${__RET__} -ne 0 ]; then
		if [ -n "${__RETURN_VAR__}" ]; then
			eval ${__RETURN_VAR__}=""
		fi
		__restore_IFS
		return ${__RET__}
		__restore_IFS
	fi

	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Uncompressed IPv6: ${__newIPv6__}."

	# Calculate the prefix, by dividing __IPv6_PREFIX__ to 16 and calculate the modulo 16.
	__SPLIT_PREFIX_1__=$((${__IPv6_PREFIX__}/16))
	__SPLIT_PREFIX_2__=$((${__IPv6_PREFIX__}%16))

	__IDX__=0
	__IPv6__=${__newIPv6__}
	__newIPv6__=""
	__set_IFS ":"
	# Add first sub-blocks from 1 to ${__SPLIT_PREFIX_1__} to __newIPv6__, because the prefix is 0xFFFF.
	for __SUBBLOCK__ in ${__IPv6__}; do

		if [ ${__IDX__} -le $((${__SPLIT_PREFIX_1__}-1)) ]; then
			# Just copy the current sub-block to new IPv6.
			${_ECHO_DEBUG_3_} "${__FN_NAME__}: Add ${__SUBBLOCK__} as it is, using 0xFFFF prefix."
			__newSUBBLOCK__="${__SUBBLOCK__}"
		elif [ ${__IDX__} -eq $((${__SPLIT_PREFIX_1__})) -a ${__SPLIT_PREFIX_2__} -ge 1 ]; then
			# At the __SPLIT_PREFIX_1__ sub-block and if we have __SPLIT_PREFIX_2__ greater or equal than 1,
			# we have to get the prefix for this sub-block and then calculate the sub-block
			__get_value_from_list_by_index "__PREFIX_MAP__" "${__SPLIT_PREFIX_2__}" "" "__PREFIX_2__"
			${_ECHO_DEBUG_3_} "${__FN_NAME__}: Calculate sub-block ${__SUBBLOCK__} using prefix ${__PREFIX_2__}."
			__newSUBBLOCK__="0x${__SUBBLOCK__}"
			__VALUE__=$((${__newSUBBLOCK__} & ${__PREFIX_2__}))
			__VALUE__=$(printf "%x" ${__VALUE__})
			__newSUBBLOCK__=${__VALUE__}
		else
			# The rest of sub-blocks should be 0x0000
			__newSUBBLOCK__="0"
		fi


		if [ -z "${__newIPv6__}" ]; then
			__newIPv6__="${__newSUBBLOCK__}"
		else
			__newIPv6__="${__newIPv6__}:${__newSUBBLOCK__}"
		fi

		__IDX__=$((__IDX__+=1))

	done

	# Compress IPv6, but without rechecking the IPv6.
	__IPv6__=$(ipv6_compress "${__newIPv6__}")
	${_ECHO_DEBUG_4_} "${__FN_NAME__}: Compressed IPv6 ${__IPv6__}"

	# Re-enable the global ipv6_check() for ipv6_compress and ipv6_decompress to use ipv6_check().
	ipv6_check_skip_reset

	# Return zero leading removed IPv6
	if [ -n "${__RETURN_VAR__}" ]; then
		eval ${__RETURN_VAR__}="${__IPv6__}"
	else
		# Print if we have something stored in __STRING__
		printf "${__IPv6__}"
	fi
	__restore_IFS
	return 0

}
