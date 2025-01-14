cmake_minimum_required(VERSION 3.10)
project(Main VERSION 1.0 LANGUAGES C OBJC)

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")

set(METAL_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Shaders.metal")
set(AIR_FILE "${CMAKE_CURRENT_BINARY_DIR}/Shaders.air")
set(LIB_FILE "${CMAKE_CURRENT_BINARY_DIR}/Shaders.metallib")

add_custom_command(
    OUTPUT ${AIR_FILE}
    COMMAND xcrun -sdk macosx metal -c ${METAL_FILE} -o ${AIR_FILE}
    DEPENDS ${METAL_FILE}
    VERBATIM
)

add_custom_command(
    OUTPUT ${LIB_FILE}
    COMMAND xcrun -sdk macosx metallib ${AIR_FILE} -o ${LIB_FILE}
    DEPENDS ${AIR_FILE}
    VERBATIM
)

set(SOURCE_FILES triangle.m)
add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${SOURCE_FILES})

find_library(COCOA_LIBRARY Cocoa)
find_library(FOUNDATION_LIBRARY Foundation)
find_library(METAL_LIBRARY Metal)
find_library(QUARTZ_CORE QuartzCore)

target_link_libraries(${PROJECT_NAME}
    ${COCOA_LIBRARY}
    ${FOUNDATION_LIBRARY}
    ${METAL_LIBRARY}
    ${QUARTZ_CORE}
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME ${PROJECT_NAME}
    MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
)

set_source_files_properties(${LIB_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
target_sources(${PROJECT_NAME} PRIVATE ${LIB_FILE})
