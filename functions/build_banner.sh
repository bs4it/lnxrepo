#/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
fill_line () {
    for i in $(eval echo "{1..$1}"); do echo -en " "; done
}

build_banner () {
    text=$1
    text2=$2
    if [ -z $3 ]; then
        color="42"
    else
        color=$3
    fi
    text_size=${#text}
    text2_size=${#text2}
    terminal_size=$(tput cols)
    space_before_text=$(expr $(expr $terminal_size - $text_size) / 2)
    space_after_text=$(expr $terminal_size - $space_before_text - $text_size)
    # Clear any format
    echo -n -e "\e[0m"
    # Empty Header Line
    echo -n -e "\e[1;97;${color}m"
    fill_line $terminal_size
    echo -e "\e[0m"
    # Title line
    echo -n -e "\e[1;97;${color}m"
    fill_line $space_before_text
    echo -n -e "$text"
    fill_line $space_after_text
    echo -e "\e[0m"
    # 3rd line
    echo -n -e "\e[1;97;${color}m"
    fill_line $(expr $terminal_size - $text2_size - 1)
    echo -n -e "\e[1;90;${color}m$text2"
    fill_line 1
    echo -e "\e[0m"
}