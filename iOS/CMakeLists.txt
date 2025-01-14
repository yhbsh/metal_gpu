cmake_minimum_required(VERSION 3.15)

project(Main CXX OBJC)

set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_OSX_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.2.sdk")
set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos;-iphonesimulator")

set(APP_NAME "Main")

set(SOURCE ../hello_ios.m)

add_executable(${APP_NAME} MACOSX_BUNDLE ${SOURCE})

set_target_properties(${APP_NAME} PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/Info.plist
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "12.0"
    XCODE_ATTRIBUTE_PRODUCT_NAME "${APP_NAME}"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.livsho.livsho"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "76R7R2ADC2"
)

target_link_libraries(${APP_NAME} 
    "-framework UIKit"
    "-framework Foundation"
)
