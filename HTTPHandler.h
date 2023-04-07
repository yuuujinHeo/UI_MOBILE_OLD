#ifndef HTTPHANDLER_H
#define HTTPHANDLER_H

#include <QObject>
#include <QtNetwork>
#include <QTimer>
#include <QDebug>

#include <QGuiApplication>
// json -----------------------
#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>

// connection ------------------
#include <QEventLoop>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrl>
#include <QNetworkRequest>

#include "GlobalHeader.h"

// websocket ------------------
#include <websocket/QtHttpServer.h>
#include <websocket/QtHttpRequest.h>
#include <websocket/QtHttpReply.h>
#include <QApplication>
#include <websocket/QtHttpHeader.h>

#define GIT_REPO_COMMIT "https://api.github.com/repos/yuuujinHeo/UI_MOBILE_release/commits"
//#define GIT_REPO_COMMIT "https://api.github.com/repos/yuuujinHeo/UI_MOBILE/commits"

class HTTPHandler : public QObject
{
    Q_OBJECT

public:
    HTTPHandler();
    QByteArray generalPost(QByteArray post_data, QString url);
    QByteArray generalGet(QString url);

    QString getLocalVersion();

    void testGit();

    void getlocalLog();
    void pullGit();
    void resetGit();
    void updateGitArray();

    QJsonDocument json_in;
    QJsonObject json_out;
    QProcess *process;
    QProcess *process_1;

    void ClearJson(QJsonObject &json);
signals:
    void pullSuccess();
    void pullFailed();
public slots:
    void processLogOutput();
    void processPullOutput();
    void processPullError();
    void processResetOutput();
    void processResetError();

private:
    // 네트워크 커넥션 관리 -----------------
    QNetworkAccessManager   *manager;
    QEventLoop              connection_loop;

};

#endif // HTTPHANDLER_H
