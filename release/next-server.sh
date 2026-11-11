#!/bin/bash

# NeXT-Server 管理脚本

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: 必须使用root用户运行此脚本！${plain}\n" && exit 1

check_status() {
    if [[ ! -f /etc/systemd/system/next-server.service ]]; then
        return 2
    fi
    temp=$(systemctl status next-server 2>/dev/null | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

status_text() {
    check_status
    case $? in
        0)
            echo -e "${green}运行中${plain}"
            ;;
        1)
            echo -e "${yellow}未运行${plain}"
            ;;
        2)
            echo -e "${red}未安装${plain}"
            ;;
    esac
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}next-server 已经在运行！${plain}"
    elif [[ $? == 2 ]]; then
        echo -e "${red}next-server 未安装，请先安装！${plain}"
    else
        systemctl start next-server
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}next-server 启动成功！${plain}"
        else
            echo -e "${red}next-server 启动失败，请使用 next-server log 查看日志${plain}"
        fi
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${yellow}next-server 已经停止！${plain}"
    elif [[ $? == 2 ]]; then
        echo -e "${red}next-server 未安装！${plain}"
    else
        systemctl stop next-server
        sleep 1
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}next-server 停止成功！${plain}"
        else
            echo -e "${red}next-server 停止失败！${plain}"
        fi
    fi
}

restart() {
    systemctl restart next-server
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}next-server 重启成功！${plain}"
    else
        echo -e "${red}next-server 重启失败，请使用 next-server log 查看日志${plain}"
    fi
}

status() {
    systemctl status next-server --no-pager
}

enable() {
    systemctl enable next-server
    if [[ $? == 0 ]]; then
        echo -e "${green}next-server 设置开机自启成功！${plain}"
    else
        echo -e "${red}next-server 设置开机自启失败！${plain}"
    fi
}

disable() {
    systemctl disable next-server
    if [[ $? == 0 ]]; then
        echo -e "${green}next-server 取消开机自启成功！${plain}"
    else
        echo -e "${red}next-server 取消开机自启失败！${plain}"
    fi
}

log() {
    journalctl -u next-server -e --no-pager -f
}

config() {
    if [[ -f /etc/next-server/config.yml ]]; then
        if command -v nano >/dev/null 2>&1; then
            nano /etc/next-server/config.yml
        elif command -v vim >/dev/null 2>&1; then
            vim /etc/next-server/config.yml
        elif command -v vi >/dev/null 2>&1; then
            vi /etc/next-server/config.yml
        else
            cat /etc/next-server/config.yml
        fi
    else
        echo -e "${red}配置文件 /etc/next-server/config.yml 不存在！${plain}"
    fi
}

version() {
    if [[ -f /usr/local/next-server/next-server ]]; then
        /usr/local/next-server/next-server version
    else
        echo -e "${red}next-server 二进制文件不存在！${plain}"
    fi
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/IngressPrime/NeXT-Server/main/release/install.sh)
}

update() {
    if [[ $# == 0 ]]; then
        bash <(curl -Ls https://raw.githubusercontent.com/IngressPrime/NeXT-Server/main/release/install.sh)
    else
        bash <(curl -Ls https://raw.githubusercontent.com/IngressPrime/NeXT-Server/main/release/install.sh) $1
    fi
}

uninstall() {
    read -rp "确定要卸载 next-server 吗？[y/N]: " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && echo "已取消卸载" && exit 0

    systemctl stop next-server 2>/dev/null
    systemctl disable next-server 2>/dev/null
    rm -f /etc/systemd/system/next-server.service
    systemctl daemon-reload
    rm -rf /usr/local/next-server/
    rm -f /usr/bin/next-server
    echo -e "${green}next-server 卸载完成！配置文件保留在 /etc/next-server/ (如需删除请手动执行 rm -rf /etc/next-server)${plain}"
}

show_menu() {
    clear
    echo "=========================================="
    echo "         NeXT-Server 管理脚本             "
    echo "=========================================="
    echo -e " 状态: $(status_text)"
    echo "------------------------------------------"
    echo "  1. 启动 next-server"
    echo "  2. 停止 next-server"
    echo "  3. 重启 next-server"
    echo "  4. 查看运行状态"
    echo "  5. 查看实时日志"
    echo "  6. 设置开机自启"
    echo "  7. 取消开机自启"
    echo "------------------------------------------"
    echo "  8. 修改配置文件"
    echo "  9. 更新 next-server"
    echo " 10. 卸载 next-server"
    echo " 11. 查看版本信息"
    echo "  0. 退出脚本"
    echo "=========================================="
    read -rp "请输入数字 [0-11]: " choice
    case "$choice" in
        1) start ;;
        2) stop ;;
        3) restart ;;
        4) status ;;
        5) log ;;
        6) enable ;;
        7) disable ;;
        8) config ;;
        9) update ;;
        10) uninstall ;;
        11) version ;;
        0) exit 0 ;;
        *) echo -e "${red}请输入有效数字 [0-11]！${plain}" ;;
    esac
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) restart ;;
    status) status ;;
    enable) enable ;;
    disable) disable ;;
    log) log ;;
    config) config ;;
    update) update "$2" ;;
    install) install ;;
    uninstall) uninstall ;;
    version) version ;;
    "") show_menu ;;
    *)
        echo "未知命令: $1"
        echo "使用方法: next-server [start|stop|restart|status|enable|disable|log|config|update|uninstall|version]"
        exit 1
        ;;
esac
