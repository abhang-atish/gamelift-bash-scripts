#!/bin/bash
game_folder=
build_type=
build_name=
build_version=
region=

while ! [[ "$s" != "" ]]
do
    echo  "1: WINDOWS"
    echo  "2: LINUX"
    echo -n "Select build type: "
    read  s
done

case $s in
    
    '1')
        build_type="WINDOWS_2012"
    ;;
    
    '2')
        build_type="AMAZON_LINUX"
    ;;
    
    *)
        echo "Invalid input"
        exit 1
    ;;
esac



while ! [[ "$f" != "" ]]
do
    read -e -p "Enter game folder path: " f
done

case $build_type in
    
    'WINDOWS_2012')
        if ls ${f}/*.exe &>/dev/null
        then
            game_folder=$f
        else
            echo 'Folder does not have .exe files for windows build'
            exit 1
        fi
    ;;
    'AMAZON_LINUX')
        if ls ${f}/*.x86_64 &>/dev/null
        then
            game_folder=$f
        else
            echo 'Folder does not have .x86_64 linux build'
            exit 1
        fi
    ;;
esac



while ! [[ "$n" != "" ]]
do
    echo -n "Enter build name: "
    read n
done
build_name=$n



while ! [[ "$r" != "" ]]
do
    echo -n "Enter region: "
    read r
done
region=$r


echo Preparing to upload $build_name build...


aws gamelift upload-build --operating-system $build_type --build-root $game_folder --name $build_name --build-version $build_version --region $region


echo 'Done.'
echo 'Upload complete'





