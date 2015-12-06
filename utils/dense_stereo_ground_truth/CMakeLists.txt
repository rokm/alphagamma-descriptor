cmake_minimum_required(VERSION 2.8)
project(ground_truth_map CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC TRUE)
set(CMAKE_AUTORCC TRUE)

find_package(Qt5Core REQUIRED 5.4)
find_package(Qt5Gui REQUIRED 5.4)
find_package(Qt5Widgets REQUIRED 5.4)

include(GNUInstallDirs)

# Common settings for gcc compiler
if(CMAKE_COMPILER_IS_GNUCXX)
    add_definitions(-std=c++11)
    add_definitions(-Wall -Wextra)
endif()

include_directories(${PROJECT_SOURCE_DIR})
include_directories(${PROJECT_BINARY_DIR})

add_executable(${PROJECT_NAME} main.cpp resources.qrc)

target_link_libraries(${PROJECT_NAME} Qt5::Core Qt5::Gui Qt5::Widgets)

install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_BINDIR})
