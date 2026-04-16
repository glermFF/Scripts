#!/bin/bash

show_help(){
        echo "==================="
        echo "Script Instructions"
        echo "==================="
        echo 
        echo "- Flags: "
        echo "-- Extensions >> {png, jpeg, jpg, pdf}"
        echo
        echo "E.G: ./move_pictures png dest_dir"
        echo 
        echo "-- New directory >> -n"
        echo
        echo "E.G: ./move_pictures n /dir_path/dir_name"
}

info() { 
echo "========================"
echo
echo "Transfering ${ext} files to ${dest_dir}"
echo
echo "========================"
echo
}

if [[ "$1" == "-h" ]]; then
        show_help
        exit 0
elif [[ "$1" == "-n" ]]; then
        new_dir="$2"
        mkdir -p "${HOME}/${new_dir}"
        exit 0
fi

ext="$1"
dest_dir="$2"

info

if find ~/Downloads -maxdepth 1 -name "*.${ext}" | grep -q .; then
        mv ~/Downloads/*."${ext}" "${HOME}/${dest_dir}"
        echo
        echo "Transfered"
else
        echo
        echo "None file with ${ext} extension found"
fi
