cmake_minimum_required(VERSION 3.16)
project(xv6_Educational_GUI LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# البحث عن مكتبات Qt
find_package(Qt6 REQUIRED COMPONENTS Widgets Sql) 
find_package(PkgConfig REQUIRED)
pkg_check_modules(SQLITE3 REQUIRED sqlite3)

# تضمين المجلدات (تأكدي من غلق القوس بشكل صحيح)
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/schedulerUi
    ${CMAKE_CURRENT_SOURCE_DIR}/filesystemUi
    ${SQLITE3_INCLUDE_DIRS}
)

# بناء الملف التنفيذي
add_executable(MainGUI
    main.cpp
    mainwindow.cpp
    mainwindow.h
    schedulerUi/schedulerWindow.cpp
    schedulerUi/schedulerWindow.h
    filesystemUi/filesystemWindow.cpp
    filesystemUi/filesystemWindow.h
    filesystemUi/bufferCacheWidget.cpp
    filesystemUi/bufferCacheWidget.h
)

# ربط المكتبات
target_link_libraries(MainGUI PRIVATE 
    Qt6::Widgets 
    Qt6::Sql
    ${SQLITE3_LIBRARIES}
)