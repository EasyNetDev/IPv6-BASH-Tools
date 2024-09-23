#!/bin/sh

# SHELL/DASH lib to calculate execution time of a command.
# SHELL/DASH doesn't implement "time" command.
#
# Usage:
# __START_MEASURE__
# COMMAD_TO_BE_MEASURED
# __END_TIME__
# __EXECUTION_TIME__
#
# Copyright (R) EasyNet Consuling SRL, Romania
# https://github.com/EasyNetDev
#

__START_TIME__="0.0"
__END_TIME__="0.0"

# By default show the execution time
case ${__SHOW_EXECUTION_TIME__} in
	*[!0-9]*|"")
		__SHOW_EXECUTION_TIME__=1
	;;
esac
if [ ${__SHOW_EXECUTION_TIME__} -ne 0 ]; then
	__SHOW_EXECUTION_TIME__=1
fi

__START_MEASURE__()
{
	if [ ${__SHOW_EXECUTION_TIME__} -eq 0 ]; then
		return 0
	fi
	__START_TIME__=$(date +"%s.%N")
}

__END_MEASURE__()
{

	if [ ${__SHOW_EXECUTION_TIME__} -eq 0 ]; then
		return 0
	fi
	__END_TIME__=$(date +"%s.%N")
}

__EXECUTION_TIME__()
{
	local _START_NANO_SEC_
	local _END_NANO_SEC_
	local _START_SEC_
	local _END_SEC_

	local _EXEC_NANO_=0
	local _EXEC_SEC_=0

	local _EXEC_TIME_=""

	if [ ${__SHOW_EXECUTION_TIME__} -eq 0 ]; then
		return 0
	fi

	_START_SEC_=${__START_TIME__%.*}
	_START_NANO_SEC_=${__START_TIME__#*.}
	_END_SEC_=${__END_TIME__%.*}
	_END_NANO_SEC_=${__END_TIME__#*.}

	_START_NANO_SEC_=$(echo ${_START_NANO_SEC_} | sed "s/^0\+//")
	_END_NANO_SEC_=$(echo ${_END_NANO_SEC_} | sed "s/^0\+//")

	if [ ${_END_SEC_} -eq ${_START_SEC_} ]; then
		# This case implies end seconds equal start seconds, we will have the end nanosec higher than start nanosec.
		# We calculate just the difference between end nanosec and start nanosec.
		_EXEC_NANO_=$((${_END_NANO_SEC_}-${_START_NANO_SEC_}))
		_EXEC_SEC_=0
	else
		# This case implies end seconds greater than start seconds
		# Here we have few cases:
		# 1. End nanosec higher or equal than start nanosec. Just calculate exec_sec = end_sec - start_sec and exec_nano = end_nanosec - start_nanosec.
		# 2. End nanosec lower than start nanosec. That means we change to next second but in reality we will have only 1000000000-start_nanosec+end_nanosec which is less than 1 second. We have to calculate the exec_seconds by substracting 1 second.

		if [ ${_END_NANO_SEC_} -ge ${_START_NANO_SEC_} ]; then
			_EXEC_NANO_=$((${_END_NANO_SEC_}-${_START_NANO_SEC_}))
			_EXEC_SEC_=$((${_END_SEC_}-${_START_SEC_}))
		else
			_EXEC_NANO_=$((1000000000-${_START_NANO_SEC_}+${_END_NANO_SEC_}))
			_EXEC_SEC_=$((${_END_SEC_}-${_START_SEC_}-1))
		fi
	fi

	_EXEC_NANO_=$((${_EXEC_NANO_}/1000))
	_EXEC_TIME_=$(printf "%d.%06d" ${_EXEC_SEC_} ${_EXEC_NANO_})

	printf "Execution time: %0.06fs\n" ${_EXEC_TIME_}
}
