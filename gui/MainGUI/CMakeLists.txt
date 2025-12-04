cmake_minimum_required(VERSION 3.16)

project(MainGUI LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

add_executable(MainGUI
    main.cpp
    mainwindow.cpp
    mainwindow.h
)

target_link_libraries(MainGUI PRIVATE Qt6::Widgets)
