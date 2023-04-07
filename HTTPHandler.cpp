#include "HTTPHandler.h"
#include <iostream>
#include <QDataStream>

#define TIMER_MS    250


using namespace std;
HTTPHandler::HTTPHandler()
{
    // 네트워크 연결 관리
    manager = new QNetworkAccessManager(this);
    connect(manager, SIGNAL(finished(QNetworkReply*)), &connection_loop, SLOT(quit()));
}

// 공통적으로 사용되는 POST 구문 : 출력으로 응답 정보를 보냄
QByteArray HTTPHandler::generalPost(QByteArray post_data, QString url){
    QByteArray postDataSize = QByteArray::number(post_data.size());
    QUrl serviceURL(url);
    QNetworkRequest request(serviceURL);
//    qDebug() << serviceURL;
    request.setRawHeader("Content-Type", "application/x-www-form-urlencoded");
    request.setRawHeader("Content-Length", postDataSize);
    request.setRawHeader("Connection", "Keep-Alive");
    request.setRawHeader("AcceptEncoding", "gzip, deflate");
    request.setRawHeader("AcceptLanguage", "ko-KR,en,*");

    QNetworkReply *reply = manager->post(request, post_data);
    connection_loop.exec();

    reply->waitForReadyRead(200);
    QByteArray ret = reply->readAll();
    reply->deleteLater();
    return ret;
}

QByteArray HTTPHandler::generalGet(QString url){
    QUrl serviceURL(url);
    QNetworkRequest request(serviceURL);

    QNetworkReply *reply = manager->get(request);
    connection_loop.exec();

    reply->waitForReadyRead(200);
    QByteArray ret = reply->readAll();
    reply->deleteLater();
    return ret;
}


void HTTPHandler::testGit(){
    updateGitArray();

    for(int i=0; i<probot->gitList.size(); i++){
        qDebug() << probot->gitList[i].commit;
    }

    if(probot->program_version == ""){
        getlocalLog();
    }

    if(probot->gitList[0].commit == probot->program_version){
        plog->write("[GIT] Program Version already lastest");
    }else{
        plog->write("[GIT] Program Version Detected : "+probot->gitList[0].commit+" (Old ver : "+probot->program_version+")");

        pullGit();

    }
}

void HTTPHandler::getlocalLog(){
    process = new QProcess();
    process->setWorkingDirectory(QGuiApplication::applicationDirPath());
    process->start("git log");

    connect(process, SIGNAL(readyReadStandardOutput()), this, SLOT(processLogOutput()));
}
void HTTPHandler::pullGit(){
    //로컬 패스에서 git pull
    process = new QProcess();
    process->setWorkingDirectory(QGuiApplication::applicationDirPath());
    process->start("git pull");

    connect(process, SIGNAL(readyReadStandardOutput()), this, SLOT(processPullOutput()));
    connect(process, SIGNAL(readyReadStandardError()), this, SLOT(processPullError()));
}
void HTTPHandler::resetGit(){
    //로컬 패스에서 git pull
    process_1 = new QProcess();
    process_1->setWorkingDirectory(QGuiApplication::applicationDirPath());
    process_1->start("git reset --hard origin/master");

    qDebug() << "=========================================";
    connect(process_1, SIGNAL(readyReadStandardOutput()), this, SLOT(processResetOutput()));
    connect(process_1, SIGNAL(readyReadStandardError()), this, SLOT(processResetError()));
}
void HTTPHandler::updateGitArray(){
    //Server에서 Git commits 받아와서 gitList에 채움

    QString server = GIT_REPO_COMMIT;
    QByteArray ret = generalGet(server);

    json_in = QJsonDocument::fromJson(ret);
    QJsonArray git_array = json_in.array();

    probot->gitList.clear();

    for(int i=0; i<git_array.size(); i++){

        ST_GIT temp_git;
        temp_git.date = git_array[i].toObject()["commit"].toObject()["author"].toObject()["date"].toString();
        temp_git.commit = git_array[i].toObject()["sha"].toString();
        temp_git.message = git_array[i].toObject()["commit"].toObject()["message"].toString();
        probot->gitList.push_back(temp_git);
    }

    for(int i=0; i<probot->gitList.size(); i++){
        qDebug() << probot->gitList[i].commit << probot->gitList[i].date << probot->gitList[i].message;
    }

}
void HTTPHandler::processPullError(){
    QString error = QString(process->readAllStandardError());
    plog->write("[GIT] Program Update Failed : "+error);
    probot->program_version = probot->gitList[0].commit;
    probot->program_date = probot->gitList[0].date;
    probot->program_message = probot->gitList[0].message;
    emit pullFailed();
}

void HTTPHandler::processResetError(){
    QString error = QString(process->readAllStandardError());
    plog->write("[GIT] Program Reset Failed : "+error);
    QProcess::startDetached(QApplication::applicationFilePath());
    QApplication::exit(12);
}

void HTTPHandler::processResetOutput(){
    QString output = QString(process->readAllStandardOutput());
    plog->write("[GIT] Program Reset Success : "+output);
    QProcess::startDetached(QApplication::applicationFilePath());
    QApplication::exit(12);
}
void HTTPHandler::processPullOutput(){
    QString output = QString(process->readAllStandardOutput());
    plog->write("[GIT] Program Update Success : "+output+probot->gitList[0].date);
    probot->program_version = probot->gitList[0].commit;
    probot->program_date = probot->gitList[0].date;
    probot->program_message = probot->gitList[0].message;
    emit pullSuccess();
}
void HTTPHandler::processLogOutput(){
    QString output = QString(process->readAllStandardOutput());
    plog->write("[GIT] Program Log : "+output);
}


void HTTPHandler::ClearJson(QJsonObject &json){
    QStringList keys = json.keys();
    for(int i=0; i<keys.size(); i++){
        json.remove(keys[i]);
    }
}
