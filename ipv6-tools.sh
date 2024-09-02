#!/bin/bash

# BASH Tools to manipulate IPv6 addresses
# BASH commands needes by this script:
#  1. BASH version >= 4.0 or a version to be able to use arrays.
#  2. printf from coreutils
#
# Avaiable functions:
#  1. ipv6_compression               - Returns a compress format of an IPv6
#  2. ipv6_leading_zero_compression  - Returns a compress format of an IPv6 from leading 0s.
#  3. ipv6_uncompress                - Returns an uncompressed format of an IPv6
#
# All functions needs first argument to be a valid IPv6 and second argument optional which is the name of a global variable (not the variable like $VAR, just VAR) where to return the value.
# In case the second argument is not given, will print the result to the stdout.
#
# echo_* functions can be override using ECHO_* variable to point to another function

if [[ -z "${ECHO_INFO}" ]]; then
echo_info()
{
	echo "INFO: $@"
}
ECHO_INFO=echo_info
fi

if [[ -z "${ECHO_WARNING}" ]]; then
echo_warning()
{
	echo "WARNING: $@"
}
ECHO_WARNING=echo_warning
fi

if [[ -z "${ECHO_DEBUG}" ]]; then
echo_debug()
{
	echo "DEBUG: $@" > /dev/stderr
}
ECHO_DEBUG=echo_debug
fi

if [[ -z "${ECHO_ERROR}" ]]; then
echo_error()
{
	echo "ERROR: $@" > /dev/stderr
}
ECHO_ERROR=echo_error
fi

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
	#   None.
	#
	# Output:
	#   In case argument $2 is missing, print the result to output.

	# Compress rules for an IPv6:
	# 1. That rule is also known as leading zero compression. You can remove the leading zeros (0s) in the 16 bits field of an IPv6 address. But each block in which you do that has at least one number remaining. If the field contains all zeros (0s), you must leave one zero (0) remaining. Removing leading zeros (0s) from the start does not have any effect on the value. However, you cannot apply that rule to trailing zeros (0s).
	# 2. That rule is also called the zero compression rule. According to that rule, if an IPv6 address contains continuous zeros, then they are replaced with (::), but only the longest continuous group of 0s!
	# Example : 1050:0000:0000:0000:0005:0000:0000:326b will be 1050:0:0:0:5:0:0:326b and in the end will be 1050::5:0:0:326b. Second group of 0s can't be compressed, becasue first group has 3 continuous 0s and the second one has only 2.
	# In case of tie, first one will be compressed.
	# 3. If zeros (0s) are present in a discontinuous pattern in IPv6 address, then at only one joining, the zeros (0s) are replaced with (::).

	local IPv6="$1"

	local IPv6_0s_GROUPS=( )
	local IPv6_0s_GROUPS_SIZE=( )
	local IDX
	local IPv6_SUBBLOCK=( )
	local IPv6_SUBBLOCK_STR=""

	local IPv6_FIRST_0s=0
	local IPv6_SKIPT_0_SUBBLOCK=0

	# Contains start and stop of the group
	local IPv6_LONGEST_0s_GROUP=( 0 0 )
	#local IPv6_LONGEST_0s_GROUP_SIZE=0

	# Contains start and stop of the group
	local IPv6_CURRENT_GROUP_SIZE=( 0 0 )
	#local IPv6_CURRENT_SIZE_0s_GROUP=0

	for (( IDX=0; IDX<${#IPv6}; IDX++ )); do
		C_CHAR=${IPv6:${IDX}:1}

		if [[ ${IPv6_DELIM} -eq 1 && "${C_CHAR}" == ":" ]]; then
			# Compression detected. Return the same IPv6
			if [[ -z "$2" ]]; then
				echo "${IPv6}"
			else
				eval ${2}="${IPv6}"
			fi
			break
		fi

		if [[ "${C_CHAR}" == ":" ]]; then
			#Clean up leading 0s
			IPv6_SUBBLOCK+=( $(printf "0x%x" "0x${IPv6_SUBBLOCK_STR}") )
			IPv6_SUBBLOCK_STR=""
			continue
		else
			IPv6_SUBBLOCK_STR+=${C_CHAR}
		fi

		# Add the last group to IPv6_SUBBLOCK
		if [[ ${IDX} -eq $((${#IPv6}-1)) ]]; then
			IPv6_SUBBLOCK+=( $(printf "0x%x" "0x${IPv6_SUBBLOCK_STR}") )
			IPv6_SUBBLOCK_STR=""
		fi
	done

	#${ECHO_DEBUG} "Total groups: ${!IPv6_SUBBLOCK[@]}"

	# Count each continuous groups of 0s blocks. Store the start and end of this group in an array
	for IDX in ${!IPv6_SUBBLOCK[@]}; do
		if [[ ${IPv6_SUBBLOCK[${IDX}]} == 0x0 ]]; then
			if [[ ${IPv6_FIRST_0s} -eq 0 ]]; then
				IPv6_FIRST_0s=1
				IPv6_CURRENT_GROUP_SIZE[0]=${IDX}
			else
				IPv6_CURRENT_GROUP_SIZE[1]=${IDX}
			fi

			# In case the IPv6 is ending in 0, we have to check
			if [[ ${IDX} -eq $((${#IPv6_SUBBLOCK[@]}-1)) ]]; then
				if [[ $((${IPv6_CURRENT_GROUP_SIZE[1]}-${IPv6_CURRENT_GROUP_SIZE[0]})) -gt $((${IPv6_LONGEST_0s_GROUP[1]}-${IPv6_LONGEST_0s_GROUP[0]})) ]]; then
					# New longer 0s group is ${IPv6_LONGEST_0s_GROUP}
					IPv6_LONGEST_0s_GROUP[0]=${IPv6_CURRENT_GROUP_SIZE[0]}
					IPv6_LONGEST_0s_GROUP[1]=${IPv6_CURRENT_GROUP_SIZE[1]}
				fi
			fi

		else
			if [[ ${IPv6_FIRST_0s} -eq 1 ]]; then
				# Reset FIRST 0 found
				IPv6_FIRST_0s=0
				# The new group of 0s is greater than previous one?
				if [[ $((${IPv6_CURRENT_GROUP_SIZE[1]}-${IPv6_CURRENT_GROUP_SIZE[0]})) -gt $((${IPv6_LONGEST_0s_GROUP[1]}-${IPv6_LONGEST_0s_GROUP[0]})) ]]; then
					# New longer 0s group is ${IPv6_LONGEST_0s_GROUP}
					IPv6_LONGEST_0s_GROUP[0]=${IPv6_CURRENT_GROUP_SIZE[0]}
					IPv6_LONGEST_0s_GROUP[1]=${IPv6_CURRENT_GROUP_SIZE[1]}
				fi
			fi
		fi
	done

	#${ECHO_DEBUG} "Longest 0s group is located between: ${IPv6_LONGEST_0s_GROUP[@]}"
	#${ECHO_DEBUG} "Compute compressed IPv6.."

	# Let's build the new format of IPv6 using IPv6_LONGEST_0s_GROUP[0] and IPv6_LONGEST_0s_GROUP[1] to compact the IPv6
	IPv6=""
	IPv6_SKIP_0_SUBBLOCK=0
	for IDX in ${!IPv6_SUBBLOCK[@]}; do
		if [[ ${IDX} -ge ${IPv6_LONGEST_0s_GROUP[0]} && ${IDX} -le ${IPv6_LONGEST_0s_GROUP[1]} ]]; then
			if [[ ${IPv6_SKIP_0_SUBBLOCK} -eq 0 ]]; then
				IPv6+="::"
				IPv6_SKIP_0_SUBBLOCK=1
			fi
			continue
		fi
		if [[ ${IDX} -eq 0 ]]; then
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
	#   None.
	#
	# Exits:
	#    1 - in case the IPv6 address is invalid.
	#
	# Output:
	#   In case argument $2 is missing, print the result to output.

	local IPv6="$1"
	local C_CHAR
	local IPv6_DELIM=0
	local IPv6_DELIM_POS=0
	local IPv6_COMPRESS_GROUP=0
	local IPv6_COUNT_DELIM=0
	local IPv6_ADD_0s=0

	local IPv6_BEFORE_GROUPS=( )
	local IPv6_AFTER_GROUPS=( )

	local IPv6_SUBBLOCK=""

	local IDX

	for (( IDX=0; IDX<${#IPv6}; IDX++ )); do
		C_CHAR=${IPv6:${IDX}:1}

		if [[ ${IPv6_DELIM} -eq 1 && "${C_CHAR}" == ":" ]]; then
			# Previous character was also a delimiter ":". Here we have a compressed zone of IPv6.
			# Let's calculate the group position of the compressed group.
			if [[ ${IPv6_COMPRESS_GROUP} -gt 1 ]]; then
				#  There is another compressed group? That's an invalid IPv6 format! Only one group can be compresed!
				IPv6_MULTIPLE_COMPRESSED_GROUPS=1
				break
			fi
			((IPv6_COMPRESS_GROUP=${IPv6_COUNT_DELIM}+1))

			# Save the delimiter position to check the last group. Last group doesn't have any ":" delimiters after it.
			IPv6_DELIM_POS=${IDX}
			continue
		fi
		if [[ "${C_CHAR}" == ":" ]]; then

			# Save the delimiter position to check the last group. Last group doesn't have any ":" delimiters after it.
			IPv6_DELIM_POS=${IDX}
			IPv6_DELIM=1
			((IPv6_COUNT_DELIM++))

			# Add group to IPv6_BEFORE_GROUPS or IPv6_AFTER_GROUPS
			if [[ $IPv6_COMPRESS_GROUP -eq 0 ]]; then
				# Remove leading zeros and convert to hexa
				IPv6_BEFORE_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
			else
				# Remove leading zeros and convert to hexa
				IPv6_AFTER_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
			fi
			IPv6_SUBBLOCK=""
			continue
		else
			IPv6_DELIM=0
			IPv6_SUBBLOCK+="${C_CHAR}"
		fi

		# This is the last group
		if [[ ${IDX} -eq $((${#IPv6}-1)) ]]; then
			IPv6_AFTER_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
		fi
	done

	# Decrese one position. We count the positions from 0 and last character is at strlen of IPv6 minus 1
	#((IDX--))

	# In case last position in IPv6 is greater than IPv6_DELIM_POS, we have a last group in IPv6
	#if [[ ${IPv6_DELIM_IPv6_SKIP_0_SUBBLOCKPOS} -lt ${i} ]]; then
	#	# Add group to IPv6_BEFORE_GROUPS or IPv6_AFTER_GROUPS
	#	if [[ ${IPv6_COMPRESS_GROUP} -eq 0 ]]; then
	#		# Remove leading zeros and convert to hexa
	#		IPv6_BEFORE_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
	#	else
	#		# Remove leading zeros and convert to hexa
	#		IPv6_BEFORE_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
	#	fi
	#fi

	# Rewrite hex value of IPv6 sub-block without leading 0s
	IPv6=""

	for IDX in ${!IPv6_BEFORE_GROUPS[@]}; do
		if [[ $IDX -eq 0 ]]; then
			IPv6+=$(printf "%x" ${IPv6_BEFORE_GROUPS[${IDX}]})
		else
			IPv6+=$(printf ":%x" ${IPv6_BEFORE_GROUPS[${IDX}]})
		fi
	done
	if [[ ${#IPv6_AFTER_GROUPS[@]} -gt 0 ]]; then
		IPv6+=":"
		for IDX in ${!IPv6_AFTER_GROUPS[@]}; do
			IPv6+=$(printf ":%x" ${IPv6_AFTER_GROUPS[${IDX}]})
		done
	fi

	if [[ -z "$2" ]]; then
		echo "${IPv6}"
	else
		eval ${2}="${IPv6}"
	fi
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
	#   None.
	#
	# Exits:
	#    1 - in case the IPv6 address is invalid.
	#
	# Output:
	#   In case argument $2 is missing, print the result to output.

	local IPv6="$1"
	local C_CHAR
	local IPv6_DELIM=0
	local IPv6_DELIM_POS=0
	local IPv6_COMPRESS_GROUP=0
	local IPv6_COUNT_DELIM=0
	local IPv6_ADD_0s=0

	# Number of groups before and after compression. Needed for computation for decompression.
	local IPv6_BEFORE_GROUPS=( )
	local IPv6_AFTER_GROUPS=( )

	local IPv6_SUBBLOCK=""

	local IPv6_TOTAL_GROUPS=0

	local IDX

	local IPv6_MULTIPLE_COMPRESSED_GROUPS=0

	# Each IPv6 uncompressed must have 7 delimiters

	for (( IDX=0; IDX<${#IPv6}; IDX++ )); do
		C_CHAR=${IPv6:${IDX}:1}

		if [[ ${IPv6_DELIM} -eq 1 && "${C_CHAR}" == ":" ]]; then
			# Previous character was also a delimiter ":". Here we have a compressed zone of IPv6.
			# Let's calculate the group position of the compressed group.
			if [[ ${IPv6_COMPRESS_GROUP} -gt 1 ]]; then
				#  There is another compressed group? That's an invalid IPv6 format! Only one group can be compresed!
				IPv6_MULTIPLE_COMPRESSED_GROUPS=1
				break
			fi
			((IPv6_COMPRESS_GROUP=${IPv6_COUNT_DELIM}+1))

			# Save the delimiter position to check the last group. Last group doesn't have any ":" delimiters after it.
			IPv6_DELIM_POS=${IDX}
			IPv6_SUBBLOCK=""
			continue
		fi

		if [[ "${C_CHAR}" == ":" ]]; then

			# Save the delimiter position to check the last group. Last group doesn't have any ":" delimiters after it.
			IPv6_DELIM_POS=${IDX}
			IPv6_DELIM=1
			((IPv6_COUNT_DELIM++))

			# Add group to IPv6_BEFORE_GROUPS or IPv6_AFTER_GROUPS
			if [[ $IPv6_COMPRESS_GROUP -eq 0 ]]; then
				# Remove leading zeros and convert to hexa
				IPv6_BEFORE_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
			else
				# Remove leading zeros and convert to hexa
				IPv6_AFTER_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
			fi
			IPv6_SUBBLOCK=""
		else
			IPv6_DELIM=0
			IPv6_SUBBLOCK+="${C_CHAR}"
		fi
	done

	# Decrese one position. We count the positions from 0 and last character is at strlen of IPv6 minus 1
	((IDX--))

	# In case last position in IPv6 is greater than IPv6_DELIM_POS, we have a last group in IPv6
	#${ECHO_DEBUG} "IPv6_DELIM_POS=${IPv6_DELIM_POS} IDX=${IDX}"
	if [[ ${IPv6_DELIM_POS} -lt ${IDX} ]]; then
		# Add group to IPv6_BEFORE_GROUPS or IPv6_AFTER_GROUPS
		if [[ $IPv6_COMPRESS_GROUP -eq 0 ]]; then
			# Remove leading zeros and convert to hexa
			IPv6_BEFORE_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
		else
			# Remove leading zeros and convert to hexa
			IPv6_AFTER_GROUPS+=( $(printf "0x%x" 0x${IPv6_SUBBLOCK}) )
		fi
	fi

	((IPv6_TOTAL_GROUPS=${#IPv6_BEFORE_GROUPS[@]}+${#IPv6_AFTER_GROUPS[@]}))

	if [[ ${IPv6_MULTIPLE_COMPRESSED_GROUPS} -gt 0 ]]; then
		${ECHO_ERROR} "Found compressed IPv6 with more than 1 0s sub-blocks compresed! This is an invalid IPv6 format!"
		${ECHO_ERROR} "Compressed blocks rules: in case of tie, first group of 0s of sub-blocks must be compressed, otherwise the longest 0s sub-blocks groups must be compressed!"
		${ECHO_ERROR} "Plase check format for IPv6 ${IPv6}!"
		exit 1
	fi

	if [[ ${IPv6_COMPRESS_GROUP} -eq 0 && ${IPv6_TOTAL_GROUPS} -lt 8 ]]; then
		${ECHO_ERROR} "Found uncompressed IPv6 with less than 8 sub-blocks! Invalid IPv6 format!"
		${ECHO_ERROR} "Plase check format for IPv6 ${IPv6}!"
		exit 1
	fi

	if [[ ${IPv6_COMPRESS_GROUP} -gt 0 && ${IPv6_TOTAL_GROUPS} -ge 8 ]]; then
		${ECHO_ERROR} "Found compressed IPv6 with 8 or more sub-blocks! Invalid IPv6 format!"
		${ECHO_ERROR} "Plase check format for IPv6 ${IPv6}!"
		exit 1
	fi

	if [[ ${IPv6_TOTAL_GROUPS} -lt 8 ]]; then
		#${ECHO_DEBUG} "Details about IPv6 ${IPv6}"
		#${ECHO_DEBUG} "IPv6 is compressed at group ${IPv6_COMPRESS_GROUP}"
		#${ECHO_DEBUG} "IPv6 has ${#IPv6_BEFORE_GROUPS[@]} sub-blocks before compression and ${#IPv6_AFTER_GROUPS[@]} sub-blocks after compression"
		# Walk through the IPv6 and check where is the compression.
		((IPv6_ADD_0s=8-${IPv6_TOTAL_GROUPS}))
		#${ECHO_DEBUG} "We must add ${IPv6_ADD_0s} more of groups of 0s."

		# Let's split the parts before compression and the part after compression.
		#local IPv6_BEFORE_GROUPS_STR=${IPv6%%::*}
		#local IPv6_AFTER_GROUPS_STR=${IPv6##*::}
		#local IPv6_BEFORE_GROUPS_STR=${IPv6_BEFORE_GROUPS[@]}
		#local IPv6_AFTER_GROUPS_STR=${IPv6_AFTER_GROUPS[@]}

		local IPv6_DECOMPRESS_0s_GROUPS=""

		#echo ${IPv6_BEFORE_GROUPS[@]}
		#echo ${IPv6_AFTER_GROUPS[@]}

		# Build first part of the IPv6
		IPv6=""
		for IDX in ${!IPv6_BEFORE_GROUPS[@]}; do
			if [[ $IDX -eq 0 ]]; then
				IPv6+=$(printf "%x" ${IPv6_BEFORE_GROUPS[${IDX}]})
			else
				IPv6+=$(printf ":%x" ${IPv6_BEFORE_GROUPS[${IDX}]})
			fi
		done

		for (( IDX=0; IDX<((${IPv6_ADD_0s})); IDX++)); do
			IPv6+=":0"
		done

		for IDX in ${!IPv6_AFTER_GROUPS[@]}; do
			IPv6+=$(printf ":%x" ${IPv6_AFTER_GROUPS[${IDX}]})
		done

	fi
	# Return uncompressed IPv6 with compressed leading 0s
	if [[ -z "$2" ]]; then
		echo "${IPv6}"
	else
		eval ${2}="${IPv6}"
	fi
}
