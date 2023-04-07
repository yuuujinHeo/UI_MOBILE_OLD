QT += core gui quick widgets network websockets sql quickcontrols2 serialport #multimedia

CONFIG += c++11 qtquickcompiler

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS
#unix{
#   CONFIG+= use_gold_linker  # betterlink speed
#   QMAKE_CXX = ccache $$QMAKE_CXX # use ccache. apt install ccache
#   QMAKE_CC = ccache $$QMAKE_CC # use ccache
#}

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    CallbellHandler.cpp \
    JoystickHandler.cpp \
    LCMHandler.cpp \
    MapView.cpp \
    ServerHandler.cpp \
    SoundHandler.cpp \
    cv_to_qt.cpp \
    Logger.cpp \
    Supervisor.cpp \
    main.cpp \
    websocket/QtHttpServer.cpp \
    websocket/QtHttpReply.cpp \
    websocket/QtHttpRequest.cpp \
    websocket/QtHttpHeader.cpp \
    websocket/QtHttpClientWrapper.cpp \
    HTTPHandler.cpp


RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH += $$PWD/modules

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    CallbellHandler.h \
    GlobalHeader.h \
    JoystickHandler.h \
    Keyemitter.h \
    LCMHandler.h \
    Logger.h \
    MapView.h \
    ServerHandler.h \
    SoundHandler.h \
    cv_to_qt.h \
    Supervisor.h\
    websocket/QtHttpServer.h \
    websocket/QtHttpReply.h \
    websocket/QtHttpRequest.h \
    websocket/QtHttpHeader.h \
    websocket/QtHttpClientWrapper.h \
    HTTPHandler.h

# Libraries setting (for x86_64)
contains(QT_ARCH, x86_64){
    # OpenCV library all
    INCLUDEPATH += /usr/include/opencv4/
    LIBS += -L/usr/lib/x86_64-linux-gnu/
    LIBS += -L/usr/lib/aarch64-linux-gnu/
    LIBS += -lopencv_core \
            -lopencv_highgui \
            -lopencv_imgcodecs \
            -lopencv_imgproc \
            -lopencv_calib3d \
            -lopencv_features2d \
            -lopencv_flann \
            -lopencv_objdetect \
            -lopencv_photo \
            -lopencv_video \
            -lopencv_videoio \
            -lboost_system \
            -lopencv_ximgproc

    # LCM
    INCLUDEPATH += /usr/local/include/
    LIBS += -L/usr/local/lib/
    INCLUDEPATH += /usr/include/lcm/
    LIBS += -L/usr/lib/aarch64-linux-gnu/
    LIBS += -llcm

    # USB
    LIBS += -lusb
}


# Libraries setting (for aarch64)
contains(QT_ARCH, arm64) {
    # OpenCV library all
    INCLUDEPATH += /usr/include/opencv4/
    LIBS += -L/usr/lib/aarch64-linux-gnu/
    LIBS += -lopencv_core \
            -lopencv_highgui \
            -lopencv_imgcodecs \
            -lopencv_imgproc \
            -lopencv_calib3d \
            -lopencv_features2d \
            -lopencv_flann \
            -lopencv_objdetect \
            -lopencv_photo \
            -lopencv_video \
            -lopencv_videoio \
            -lboost_system \
            -lopencv_ximgproc

    # LCM
    INCLUDEPATH += /usr/include/lcm/
    LIBS += -L/usr/lib/aarch64-linux-gnu/
    LIBS += -llcm


    # USB
    LIBS += -lusb
}
