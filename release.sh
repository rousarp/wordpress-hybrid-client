#!/bin/sh

set -e

read -p "Release major, minor or patch? " version
version=${version:-""}

read -p "Which platforms do you want to build? (android ios): " platforms
platforms=${platforms:-"android ios"}

# updgrade version before release
gulp cordova:release --${version}

# package the app
npm run dumpprod

if [ "${platforms}" == "android" ]; then
    npm run buildProdAndroid
elif [ "${platforms}" == "ios" ]; then
    npm run buildProdIOS
elif [ "${platforms}" == "android ios" ]; then
    npm run buildProdAll
fi

if [ "${platforms}" == "android" -o "${platforms}" == "android ios" ]; then
    # Android
    jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ~/.ssh/android_wphc.keystore platforms/android/build/outputs/apk/android-x86-release-unsigned.apk wphc
    jarsigner -verify -certs platforms/android/build/outputs/apk/android-x86-release-unsigned.apk
    ~/Library/Android/sdk/build-tools/21.1.2/zipalign -vf 4 platforms/android/build/outputs/apk/android-x86-release-unsigned.apk ./build/wphc-android-x86.apk

    jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ~/.ssh/android_wphc.keystore platforms/android/build/outputs/apk/android-armv7-release-unsigned.apk wphc
    jarsigner -verify -certs platforms/android/build/outputs/apk/android-armv7-release-unsigned.apk
    ~/Library/Android/sdk/build-tools/21.1.2/zipalign -vf 4 platforms/android/build/outputs/apk/android-armv7-release-unsigned.apk ./build/wphc-android-armv7.apk
fi

if [ "${platforms}" == "ios" -o "${platforms}" == "android ios" ]; then
    rm -rf ./build/ios.app
    mv ./platforms/ios/build/device/*.app ./build/ios.app
    xcrun -sdk iphoneos PackageApplication -v $PWD/build/ios.app
    sigh resign ./build/ios.ipa
fi
