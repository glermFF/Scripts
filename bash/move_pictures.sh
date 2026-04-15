#!/bin/bash

show_help(){
	echo "==================="
	echo "Script Instructions"
	echo "==================="
	echo 
	echo "- Flags: "
	echo "-- Extensions >> {png, jpeg, jpg}"
	echo
	echo "E.G: ./move_pictures png"
	echo 
	echo "-- New directory >> n"
	echo
	echo "E.G: ./move_pictures n /dir_path/dir_name"
}

greet() { 
echo "========================"
echo "Transfering ${ext} files"
echo "========================"
echo
}

if [[ "$1" == "-h" ]]; then
	show_help
	exit 0
elif [[ "$1" == "n" ]]; then
	new_dir="$2"
	mkdir -p "${USER_PATH}/${new_dir}"
	exit 0
fi

USER_PATH="/home/note-guilherme"

ext="$1"

if find ~/Downloads -maxdepth 1 -name "*.${ext}" | grep -q .; then
        mv ~/Downloads/*."${ext}" ~/Imagens/Pictures
        echo
        echo "Movidas"
else
        echo
        echo "None file with ${ext} extension found"
fi

