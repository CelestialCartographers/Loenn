@echo off
rem ; if false; then
bash -l %0 "%CD%"
exit
rem Fuck batch.
rem ; fi
cd "${1}"


APP_AUTHOR=$(cat "./meta/AUTHOR")
APP_DESCRIPTION=$(cat "./meta/DESCRIPTION")
APP_TITLE=$(cat "./meta/TITLE")

OUTPUT_DIR="./builds"

LOVE_UTILS=$(realpath ../../utilities)
POTION=$LOVE_UTILS/3ds/LovePotion
LOVE=$LOVE_UTILS/love-0.11.2-win32
ZIP=$LOVE_UTILS/7za920/7za
START_GAME_DEV=$LOVE_UTILS/StartGamedev-170112-win

rm -rf "${OUTPUT_DIR}/latest/"
mkdir -p "${OUTPUT_DIR}/latest/"

mkdir -p "${OUTPUT_DIR}"
NEXT_BUILD=$(( $(ls -1 "${OUTPUT_DIR}" | grep -P '^[0-9]+$' | sort -n | tail -n1) + 1 ))

WORKDIR=$(pwd)

OUTPUT_NAME="${APP_TITLE}-${NEXT_BUILD}"

$ZIP a -tzip "${OUTPUT_DIR}/latest/${OUTPUT_NAME}.love" "./src/*"

if [ -d "meta" ]; then
    export APP_AUTHOR APP_DESCRIPTION APP_TITLE

    rm -rf "${POTION}/temp"
    mkdir -p "${POTION}/temp"

    cp -rf "${POTION}/meta" "${POTION}/temp"
    cp -rf ./meta "${POTION}/temp"
    cp -rf ./src "${POTION}/temp"


    cd "${POTION}"
    make
    cd "${WORKDIR}"


    mkdir -p "${OUTPUT_DIR}/latest/3ds"

    cp "${POTION}/LovePotion.3ds" "${OUTPUT_DIR}/latest/3ds/${OUTPUT_NAME}.3ds"
    cp "${POTION}/LovePotion.cia" "${OUTPUT_DIR}/latest/3ds/${OUTPUT_NAME}.cia"


    echo "Setting up Android build..."
    mkdir -p "${OUTPUT_DIR}/latest/android"

    cp -rf ./meta/icon.png "${START_GAME_DEV}/icon.png"
    cp "${OUTPUT_DIR}/latest/${OUTPUT_NAME}.love" "${START_GAME_DEV}/game.love"

    echo "Building APK"
    cmd //c "CD E:\Dropbox\Code\Lua\Love\utilities\StartGamedev-170112-win && make-apk.bat"

    cp "${START_GAME_DEV}/game.apk" "${OUTPUT_DIR}/latest/android/${OUTPUT_NAME}.apk"
fi

mkdir -p "${OUTPUT_DIR}/latest/x86/${OUTPUT_NAME}-x86/"

cat "${LOVE}/love.exe" "${OUTPUT_DIR}/latest/${OUTPUT_NAME}.love" > "${OUTPUT_DIR}/latest/x86/${OUTPUT_NAME}-x86/${OUTPUT_NAME}-x86.exe"

cp -rf "${LOVE}/"*.dll "${OUTPUT_DIR}/latest/x86/${OUTPUT_NAME}-x86/"

$ZIP a -tzip "${OUTPUT_DIR}/latest/${OUTPUT_NAME}-x86.zip" "${OUTPUT_DIR}/latest/x86/./*"

cp -rf "${OUTPUT_DIR}/latest/" "${OUTPUT_DIR}/${NEXT_BUILD}/"

read -sn 1 -p "Press any key to exit..."