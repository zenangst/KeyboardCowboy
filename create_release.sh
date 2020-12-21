cd Release
MARKETING_VERSION=`cat .marketing_version`
BUILD_DIRECTORY=`cat .build_dir`
ROOT_DIRECTORY="$BUILD_DIRECTORY/../.."
BIN_DIRECTORY="$ROOT_DIRECTORY/SourcePackages/artifacts/Sparkle/bin"
DOWNLOAD_URL_PREFIX="https://github.com/zenangst/KeyboardCowboy/releases/download/$MARKETING_VERSION/"
APPLICATION_NAME="Keyboard Cowboy.app"
ARCHIVE_FILENAME="Keyboard.Cowboy.zip"
ZIPOUPUT=`zip -r $ARCHIVE_FILENAME "Keyboard Cowboy.app"`
OUTPUT=`$BIN_DIRECTORY/generate_appcast -o ../appcast.xml --download-url-prefix $DOWNLOAD_URL_PREFIX .`
