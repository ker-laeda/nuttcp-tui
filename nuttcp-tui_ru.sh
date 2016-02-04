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
	echo -en "\E[3;3f  Скрипт для работы с утилитой nuttcp"
	print_line 5
	echo -en "\E[14;3f    (прервать выполнение - Ctrl+C)"
	print_line 15
	echo -en "\E[9;3f"
	if [[  "${LS_NUM}" = "" ]]; then
		echo -en "\E[7;3f  Введите лицевой счёт абонента:"
		echo -en "\E[8;5f                                "
		echo -en "\E[8;5f"
		read LS_NUM
	fi
	if [[  "${ADDR_TEST}" = "" ]]; then
		echo -en "\E[7;3f  Введите адрес сервера:        "
		echo -en "\E[8;5f                                "
		echo -en "\E[8;5f"
		read ADDR_TEST
	fi
	if valid_ip ${ADDR_TEST} || valid_host ${ADDR_TEST} && valid_ls_num ${LS_NUM}; then
		local LOG_NAME="$(date +"%Y-%m-%d_%H-%M-%S")_${LS_NUM}.log"
		echo -en "\E[7;3f  Тестирование запущено     "
		echo -en "\E[8;3f  (Подробные результаты будут находиться в: ${LOG_DIR})  "
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
		echo -en "\E[8;3f\E[31m  Неверный адрес или лицевой счёт!           \E[0m"
		echo -en "\E[16;0f"
		sleep 2
		start_test ${TIME_TEST}
	fi
	send_log_ftp ${LOG_DIR} ${LOG_NAME}
	print_line -1
	echo -en "\n    Тестирование завершено"
	echo -en "\n    (Подробные результаты находятся в: ${LOG_DIR})"
	echo -en "\n    Нажмите любую клавишу..."
	echo -en "\n"
	KEY=0
	while ( [ $KEY -eq 0 ] ) do
		read -s -n 1 KEY
	done
	echo -en "\E[2J"
	echo -en "\E[3;3f  Скрипт для работы с утилитой nuttcp"
	print_line 5
	echo -en "\E[7;3f Тестирование завершено"
	echo -en "\E[8;3f (Подробные результаты находятся в: ${LOG_DIR})"
	echo -en "\E[10;3f 1)Повторить"
	echo -en "\E[11;3f 2)Назад"
	echo -en "\E[14;3f    (выбор цифровыми клавишами 1-2)"
	print_line 15
	echo -en "\E[16;0f"
	local KEY=0
	local QUIT_S=0
	while ( [ $QUIT_S -eq 0 ] ) do
		read -s -n 1 KEY
		if [[ "${KEY}" = "1" ]]; then
			echo -en "\E[10;3f\E[30m\E[41m 1)Повторить  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test ${TIME_TEST} ${ADDR_TEST} ${LS_NUM}
		elif [[ "${KEY}" = "2" ]]; then
			echo -en "\E[11;3f\E[30m\E[41m 2)Назад  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			QUIT_S=1
		fi
	done
	start_test_mnu;
}

function start_test_mnu(){
	echo -en "\E[2J"
	echo -en "\E[3;3f  Скрипт для работы с утилитой nuttcp"
	print_line 5
	echo -en "\E[7;3f  Продолжительность теста:"
	echo -en "\E[9;3f 1)1 минута  "
	echo -en "\E[10;3f 2)15 минут  "
	echo -en "\E[11;3f 3)2 часа  "
	echo -en "\E[12;3f 4)Отмена  "
	echo -en "\E[14;3f    (выбор цифровыми клавишами 1-4)"
	print_line 15
	local KEY=0
	local QUIT_S=0
	while ( [ $QUIT_S -eq 0 ] ) do
		read -s -n 1 KEY
		if [[ "${KEY}" = "1" ]]; then
			echo -en "\E[9;3f\E[30m\E[41m 1)1 минута  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test 1m
		elif [[ "${KEY}" = "2" ]]; then
			echo -en "\E[10;3f\E[30m\E[41m 2)15 минут  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test 15m
		elif [[ "${KEY}" = "3" ]]; then
			echo -en "\E[11;3f\E[30m\E[41m 3)2 часа  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test 2h
		elif [[ "${KEY}" = "4" ]]; then
			echo -en "\E[12;3f\E[30m\E[41m 4)Отмена  \E[0m"
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
	echo -en "\E[3;3f  Скрипт для работы с утилитой nuttcp"
	print_line 5
	echo -en "\E[7;3f  Выберите действия:"
	echo -en "\E[9;3f 1)Тест пропускной способности канала  "
	if [[ $RESULT -eq 0 ]]; then
		echo -en "\E[10;3f 2)Запустить сервер nuttcp  "
	else
		echo -en "\E[10;3f 2)Остановить сервер nuttcp  "
	fi
	echo -en "\E[11;3f 3)Выход  "
	echo -en "\E[14;3f    (выбор цифровыми клавишами 1-3)"
	print_line 15
	local KEY=0
	local QUIT_S=0
	while ( [ $QUIT_S -eq 0 ] ) do
		read -s -n 1 KEY
		if [[ "${KEY}" = "1" ]]; then
			echo -en "\E[9;3f\E[30m\E[41m 1)Тест пропускной способности канала  \E[0m"
			echo -en "\E[16;0f"
			sleep 1
			start_test_mnu
		elif [[ "${KEY}" = "2" ]]; then
			if [[ $RESULT -eq 0 ]]; then
				echo -en "\E[10;3f\E[30m\E[41m 2)Запустить сервер nuttcp  \E[0m"
				echo -en "\E[16;0f"
			else
				echo -en "\E[10;3f\E[30m\E[41m 2)Остановить сервер nuttcp  \E[0m"
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