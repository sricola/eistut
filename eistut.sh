#!/bin/bash

TEMP="/tmp/eistut"
APPLICATION_PATH="/Applications/"
INSTALLS="${TEMP}/installs"
BACKUP_PATH="/tmp/eistut_backup/"

SOFTWARES=(adium
# appcleaner
# audacity
bean
# boxee
# breakaway
burn
# camino
# chrome
# cyberduck
# diskwave
# dropbox
# elasticfox
# firefox
# growlf
# handbrake
# iamfox
# iterm
# onyx
# opera
# picasa
# raven
# remotedesktopconnection
# skype
# sourcetree
# spotify
# textwrangler
theunarchiver
thunderbird
transmission
# virtualbox
# vlc
writeroom)

# check if the temp directory exists and blow it away
if [ -d "$TEMP" ]; then
  rm -rf ${TEMP}
fi

# make the temp directory
mkdir -p ${INSTALLS}
mkdir -p ${BACKUP_PATH}

# http://stackoverflow.com/questions/4023830/bash-how-compare-two-strings-in-version-format
function version_compare () {
    if [[ $INSTALLED_VERSION == $VERSION ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($INSTALLED_VERSION) ver2=($VERSION)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

function backup_current_application() {
    if [ -d "${EXPECTED_APP_PATH}" ]; then
      echo "Removing currently installed version"
      mv "${EXPECTED_APP_PATH}" "${BACKUP_PATH}${APP}.app"
      #echo "${EXPECTED_APP_PATH}"
    fi
}

function install_application () {
    echo "Downloading ${APP} ..."
    cd ${INSTALLS}
    case "$URL" in
        *zip*)
          curl -# -o "${APP}.zip" $URL
          unzip -qq "${APP}.zip"
          backup_current_application
          echo "Installing new version."
          mv "`find . -name "${APP}.app"`" "${APPLICATION_PATH}"
          ;;
        *dmg*)
          curl -# -o "${APP}.dmg" $URL
          backup_current_application
          mkdir "${TEMP}/curr_dmg"
          yes | /usr/bin/hdiutil mount -mountpoint "${TEMP}/curr_dmg" -nobrowse -quiet "${APP}.dmg"
          cd "${TEMP}/curr_dmg"
          cp -R "`find . -name "${APP}.app"`" "${APPLICATION_PATH}"
          /usr/bin/hdiutil unmount -quiet "${TEMP}/curr_dmg" -force
          echo "Done!"
          ;;
        *)
          echo "Invalid Installer"
          ;;
    esac
}

function check_version () {
        
    # get the currently installed version number
    INSTALLED_VERSION=`defaults read "/Applications/${APP}.app/Contents/Info.plist" "CFBundleShortVersionString"`
    
    version_compare

    case $? in
      0) echo "You have Version : ${INSTALLED_VERSION} \nYou have the latest version installed!\nNo acion needed."
         ;;
      1) echo "You have Version : ${INSTALLED_VERSION} \nYou have a later version installed!\nNo action needed."
         printf "${APP} ${INSTALLED_VERSION} ${VERSION}" | mail -s "${APP}: New Version Found!" sri.umd+eistut@gmail.com
         ;;
      2) echo "You have Version : ${INSTALLED_VERSION} \nI will install the latest and greatest for you!"
         install_application
         ;;
    esac
}

# cycle through the list of software calling the appropriate actions
for SOFTWARE in ${SOFTWARES[@]}; do
  
    # get the Application's bootstrap script and source it
    curl -s https://raw.github.com/bitsri/eistut/master/apps/${SOFTWARE} > ${TEMP}/${SOFTWARE}.sh
    source ${TEMP}/${SOFTWARE}.sh
    
    echo "\n--\n${APP}\n--\nAvailable Version: ${VERSION}"

    EXPECTED_APP_PATH="${APPLICATION_PATH}${APP}.app"
    #echo $EXPECTED_APP_PATH

    # check to see if the Application is already installed
    if [ -d "${EXPECTED_APP_PATH}" ]; then
        check_version
    else
        install_application
    fi  
      
done

# rm -rf ${TEMP}
echo "\n\n\nDone!"