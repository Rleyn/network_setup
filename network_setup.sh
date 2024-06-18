#!/bin/bash

# Проверка наличия root прав
if [ "$EUID" -ne 0 ]; then 
  echo "Пожалуйста, запустите скрипт с правами root."
  exit 1
fi

# Функция для вывода сообщения об ошибке и завершения скрипта
function error_exit {
  echo "$1" 1>&2
  exit 1
}

# Проверка количества аргументов
if [ "$#" -lt 1 ]; then
  error_exit "Использование: $0 <новый IP-адрес> [маска подсети] [шлюз] [интерфейс]"
fi

NEW_IP=$1
SUBNET_MASK=${2:-"255.255.255.0"} # Маска по умолчанию
GATEWAY=${3:-"192.168.1.1"} # Шлюз по умолчанию
INTERFACE=${4:-"eth0"} # Интерфейс по умолчанию

# Резервное копирование файла конфигурации
cp /etc/network/interfaces /etc/network/interfaces.bak || error_exit "Ошибка резервного копирования файла конфигурации."

# Обновление конфигурации сети с использованием sed
sed -i "s/^\(iface $INTERFACE inet static\)/\1\n    address $NEW_IP\n    netmask $SUBNET_MASK\n    gateway $GATEWAY/" /etc/network/interfaces || error_exit "Ошибка изменения файла конфигурации."

# Перезапуск сетевого интерфейса
ifdown $INTERFACE && ifup $INTERFACE || error_exit "Ошибка перезапуска сетевого интерфейса."

# Получение текущей сетевой конфигурации
CURRENT_CONFIG=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
CURRENT_GATEWAY=$(ip route | grep default | grep $INTERFACE | awk '{print $3}')

# Вывод текущей конфигурации
echo "Текущая сетевая конфигурация:"
echo "IP-адрес: ${CURRENT_CONFIG%/*}"
echo "Маска подсети: $SUBNET_MASK"
echo "Шлюз: $CURRENT_GATEWAY"
echo "Интерфейс: $INTERFACE"

echo "Конфигурация сети успешно изменена."

# Логирование действий
LOGFILE="/var/log/network_setup.log"
{
  echo "[$(date)] Изменение конфигурации сети"
  echo "Новый IP-адрес: $NEW_IP"
  echo "Маска подсети: $SUBNET_MASK"
  echo "Шлюз: $GATEWAY"
  echo "Интерфейс: $INTERFACE"
  echo "========================================="
} >> $LOGFILE

exit 0
