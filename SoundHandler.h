#ifndef SOUNDHANDLER_H
#define SOUNDHANDLER_H

#include <QObject>
#include <QtNetwork>
#include <QTimer>
#include <QDebug>
//#include <QtMultimedia>
#include "GlobalHeader.h"

class SoundHandler : public QObject
{
    Q_OBJECT
public:
    SoundHandler();

//    QMediaPlayer *player;
};

#endif // SOUNDHANDLER_H
