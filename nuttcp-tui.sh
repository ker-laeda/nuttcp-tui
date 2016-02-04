#!/bin/bash

function valid_ip(){
	local IP=$1
	local STAT=1
	if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		IP=($IP)
		IFS=$OIFS
		[[ ${IP[0]} -le 255 && ${IP[1]} -le 255 && ${IP[2]} -le 255 && ${IP[3]} -le 255 ]]
		STAT=$?
	fi
	return $STAT
}

function valid_host(){
	local H_NAME=$1
	local STAT=1
	if [[ $H_NAME =~ ^(.{1,100}\.*)+\..{2,6}$ ]]; then
		STAT=$?
	elif [[ "${H_NAME}" = "localhost" ]]; then
		STAT=$?
	fi
	return $STAT
}

function valid_ls_num(){
	local LS_NUM=$1
	local STAT=1
	if [[ $LS_NUM =~ ^.{3,100}$ ]]; then
		STAT=$?
	fi
	return $STAT
}

function print_line(){
	local X=$(tput cols)
	local Y=$1
	if [[ $Y -lt 0 ]]; then
		echo -en "\n"
	else
		echo -en "\E[0;0f"
		for (( N=0; N<Y-1; N++ )) do
			echo -en "\n"
		done
	fi
	for (( N=0; N<X; N++ )) do
		echo -en "-"
	done
	echo -en "\n"
}

function send_log_ftp(){
	local FTP_HOST="localhost"
	local FTP_USER="user"
	local FTP_PASS="123qwe"
	local LOCAL_DIR=$1; shift
	local LOCAL_FILE=$1; shift
	local SEND_FILE="ftp/${LOCAL_FILE}"
	ftp -n ${FTP_HOST} 2>/dev/null 1>/dev/null << INPUT_END
	quote USER ${FTP_USER}
	quote PASS ${FTP_PASS}
	bin
	put ${LOCAL_DIR}${LOCAL_FILE} ${SEND_FILE}
	site chmod 777 ${SEND_FILE}
	quit
INPUT_END
}

function start_test(){
	local LOG_DIR="/home/user/NUTTCP/"
	local TIME_TEST=$1; shift
	local ADDR_TEST=$1; shift
	local LS_NUM=$1; shift
    echo -en "\E[2J"
    echo -en "\E[3;3f  Front-end script for nuttcp utility"
	print_line 5
	echo -en "\E[14;3f    (press to abort - Ctrl+C)"
    print_line 15
    echo -en "\E[9;3f"
	if [[  "${LS_NUM}" = "" ]]; then
		echo -en "\E[7;3f  Enter the customer ID:        "
		echo -en "\E[8;5f                                "
		echo -en "\E[8;5f"
		read LS_NUM
	fi
	if [[  "${ADDR_TEST}" = "" ]]; then
		echo -en "\E[7;3f  Enter the server address:     "
		echo -en "\E[8;5f                                "
		echo -en "\E[8;5f"
		read ADDR_TEST
	fi
	if valid_ip ${ADDR_TEST} || valid_host ${ADDR_TEST} && valid_ls_num ${LS_NUM}; then
		local LOG_NAME="$(date +"%Y-%m-%d_%H-%M-%S")_${LS_NUM}.log"
		echo -en "\E[7;3f  Test run...                   "
		echo -en "\E[8;3f  (Detailed results will be in: ${LOG_DIR})  "
		echo -en "\E[16;0f"
		if [[ "${TIME_TEST}" = "1m" ]]; then
			local TEST_STR="nuttcp -r -F -vv -i 1 -T 1m -w1M -N2 "
		elif [[ "${TIME_TEST}" = "15m" ]]; then
			local TEST_STR="nuttcp -r -F -vv -i 1m -T 15m -w1M -N2 "
		elif [[ "${TIME_TEST}" = "2h" ]]; then
			local TEST_STR="nuttcp -r -F -vv -i 1m -T 120m -w1M -N2 "
		else
			local TEST_STR="nuttcp -r -F -vv -i 1m -T 1m -w1M -N2 "
		fi
		${TEST_STR} ${ADDR_TEST} 2>&1 | tee "${LOG_DIR}${LOG_NAME}" | grep "nuttcp-r: connect to\|bps"
	else
		echo -en "\E[8;3f\E[31m  Invalid address or customer ID!           \E[0m"
        echo -en "\E[16;0f"
		sleep 2
		start_test ${TIME_TEST}
	fi
	send_log_ftp ${LOG_DIR} ${LOG_NAME}
	print_line -1
	echo -en "\n    Testing completed"
	echo -en "\n    (Detailed results will be in: ${LOG_DIR})"
	echo -en "\n    Press any key to continue..."
	echo -en "\n"
	KEY=0
        while ( [ $KEY -eq 0 ] ) do
                read -s -n 1 KEY
        done
    echo -en "\E[2J"
    echo -en "\E[3;3f  Front-end script for nuttcp utility"
	print_line 5
	echo -en "\E[7;3f Testing completed"
	echo -en "\E[8;3f (Detailed results will be in: ${LOG_DIR})"
	echo -en "\E[10;3f 1)Repeat"
	echo -en "\E[11;3f 2)Back"
	echo -en "\E[14;3f    (using the number keys 1-2)"
	print_line 15
	echo -en "\E[16;0f"
    local KEY=0
    local QUIT_S=0
    while ( [ $QUIT_S -eq 0 ] ) do
		read -s -n 1 KEY
        if [[ "${KEY}" = "1" ]]; then
			echo -en "\E[10;3f\E[30m\E[41m 1)Repeat  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test ${TIME_TEST} ${ADDR_TEST} ${LS_NUM}
        elif [[ "${KEY}" = "2" ]]; then
			echo -en "\E[11;3f\E[30m\E[41m 2)Back  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			QUIT_S=1
        fi
    done
	start_test_mnu;
}

function start_test_mnu(){
	echo -en "\E[2J"
	echo -en "\E[3;3f  Front-end script for nuttcp utility"
	print_line 5
	echo -en "\E[7;3f  The duration of the test:"
	echo -en "\E[9;3f 1)1 min  "
	echo -en "\E[10;3f 2)15 min  "
	echo -en "\E[11;3f 3)2 hours  "
	echo -en "\E[12;3f 4)Cancel  "
	echo -en "\E[14;3f    (using the number keys 1-4)"
	print_line 15
	local KEY=0
	local QUIT_S=0
	while ( [ $QUIT_S -eq 0 ] ) do
		read -s -n 1 KEY
		if [[ "${KEY}" = "1" ]]; then
			echo -en "\E[9;3f\E[30m\E[41m 1)1 min  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test 1m
		elif [[ "${KEY}" = "2" ]]; then
			echo -en "\E[10;3f\E[30m\E[41m 2)15 min  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test 15m
		elif [[ "${KEY}" = "3" ]]; then
			echo -en "\E[11;3f\E[30m\E[41m 3)2 hours  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test 2h
		elif [[ "${KEY}" = "4" ]]; then
			echo -en "\E[12;3f\E[30m\E[41m 4)Cancel  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			QUIT_S=1
		fi
	done
	main_menu
}

function start_stop_server(){
	local RESULT="$(ps -ax|grep 'nuttcp -S'|grep Ss|wc -l)"
	if [[ $RESULT -eq 0 ]]; then
		nuttcp -S 2>/dev/null 1>/dev/null
	else
		sudo killall nuttcp 2>/dev/null 1>/dev/null
	fi
	sleep 1
	main_menu
}

function main_menu(){
	local RESULT="$(ps -ax|grep 'nuttcp -S'|grep Ss|wc -l)"
	echo -en "\E[2J"
	echo -en "\E[3;3f  Front-end script for nuttcp utility"
	print_line 5
	echo -en "\E[7;3f  Select action:"
	echo -en "\E[9;3f 1)Bandwidth test  "
	if [[ $RESULT -eq 0 ]]; then
		echo -en "\E[10;3f 2)Start nuttcp server  "
	else
		echo -en "\E[10;3f 2)Stop nuttcp server  "
	fi
	echo -en "\E[11;3f 3)Exit  "
	echo -en "\E[14;3f    (using the number keys 1-3)"
	print_line 15
	local KEY=0
	local QUIT_S=0
	while ( [ $QUIT_S -eq 0 ] ) do
		read -s -n 1 KEY
		if [[ "${KEY}" = "1" ]]; then
			echo -en "\E[9;3f\E[30m\E[41m 1)Bandwidth test  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test_mnu
		elif [[ "${KEY}" = "2" ]]; then
		        if [[ $RESULT -eq 0 ]]; then
					echo -en "\E[10;3f\E[30m\E[41m 2)Start nuttcp server  \E[0m"
					echo -en "\E[16;0f"
        		else
					echo -en "\E[10;3f\E[30m\E[41m 2)Stop nuttcp server  \E[0m"
					echo -en "\E[16;0f"
        		fi
				sleep 1
				start_stop_server
		elif [[ "${KEY}" = "3" ]]; then
			echo -en "\E[11;3f\E[30m\E[41m 3)Выход  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			echo -en "\E[0;0f]\E[2J"
			exit 0
		fi
	done
}

main_menu