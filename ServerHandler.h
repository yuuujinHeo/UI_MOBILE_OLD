#ifndef SERVERHANDLER_H
#define SERVERHANDLER_H

#include <QObject>
#include <QThread>
#include <QSettings>
#include <QTimer>
#include <chrono>
#include <thread>
#include <math.h>
#include <QWebSocket>
#include <QDir>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include "GlobalHeader.h"
#include <QGuiApplication>

#define MOVING_TIMER_MS     40

enum{
    MS_STOP = 0,
    MS_MOVE,
    MS_PAUSE
};

class ServerHandler : public QObject
{
    Q_OBJECT
public:
    ServerHandler();
    ~ServerHandler();

    ////*********************************************  FLAGS   ***************************************************////
    //서버 연결상태
    bool isconnect = false;
    bool acceptCmd = true;

    ////*********************************************  SEND FUNCTIONS   ***************************************************////
    void sendCalllist();
    void sendMap(QString map_name);
    void requestMap();

    QString server_map_name = "test1";

signals:
    void server_pause();
    void server_resume();
    void server_new_target();
    void server_new_call();
    void server_set_ini();
    void server_get_map();
public slots:
    void onConnected();
    void onDisconnected();
    void onTextMessageReceived(QString message);
    void onBinaryMessageReceived(QByteArray message);

    void onTimer();
private:
    QTimer  *timer;
    QWebSocket  socket;
};

#endif // SERVERHANDLER_H
