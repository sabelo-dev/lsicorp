cmake_minimum_required(VERSION 3.22)

project(lsitools VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(lsitools src/main.cpp)

set(singletons qml/Theme.qml qml/Nav.qml qml/Supabase.qml qml/Store.qml)
set_source_files_properties(${singletons} PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

file(GLOB qml_files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS qml/*.qml qml/*.mjs)

qt_add_qml_module(lsitools
    URI LsiTools
    VERSION 1.0
    QML_FILES ${qml_files}
    SOURCES src/platform.h src/platform.cpp
    RESOURCES
        seed/seed.json
        assets/logo-mark.png
        assets/logo-full.png
        assets/fonts/Inter-Regular.ttf
        assets/fonts/Inter-SemiBold.ttf
        assets/fonts/Inter-Bold.ttf
)

target_include_directories(lsitools PRIVATE src)
target_link_libraries(lsitools PRIVATE Qt6::Quick Qt6::QuickControls2)

if(EMSCRIPTEN)
    # No eval() or new Function() in the generated JavaScript, so the site runs
    # under a Content-Security-Policy without 'unsafe-eval'.
    target_link_options(lsitools PRIVATE -sDYNAMIC_EXECUTION=0)

    # The page that hosts the app, plus the files a deployment edits or serves as-is.
    foreach(file index.html shell.css shell.js config.js favicon.png icon-192.png icon-512.png apple-touch-icon.png logo-mark.png manifest.webmanifest robots.txt)
        configure_file(web/${file} ${CMAKE_CURRENT_BINARY_DIR}/${file} COPYONLY)
    endforeach()
else()
    set_target_properties(lsitools PROPERTIES WIN32_EXECUTABLE FALSE)
endif()
