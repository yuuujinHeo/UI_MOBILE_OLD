#include "ServerHandler.h"
#include <QGuiApplication>
#include <QPixmap>

ServerHandler::ServerHandler()
{
    isconnect = false;

    connect(&socket, SIGNAL(connected()), this, SLOT(onConnected()));
    connect(&socket, SIGNAL(disconnected()), this, SLOT(onDisconnected()));
    connect(&socket, SIGNAL(textMessageReceived(QString)), this, SLOT(onTextMessageReceived(QString)));
    connect(&socket, SIGNAL(binaryMessageReceived(QByteArray)), this, SLOT(onBinaryMessageReceived(QByteArray)));

    timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(onTimer()));
    timer->start(200);
    plog->write("[BUILDER] SERVER HANDLER constructed");
}

ServerHandler::~ServerHandler(){
    plog->write("[BUILDER] SERVER HANDLER destroyed");
}

void ServerHandler::onConnected(){
    plog->write("[SERVER] CONNECTED TO SERVER");
}

void ServerHandler::onDisconnected(){
    if(isconnect){
        isconnect = false;
        plog->write("[SERVER] DISCONNECTED TO SERVER");
    }
}

void ServerHandler::onTextMessageReceived(QString message){
    QJsonObject json = QJsonDocument::fromJson(message.toUtf8()).object();
    QString cmd = json["cmd"].toString();
    plog->write("[SERVER] NEW COMMAND : "+cmd);

    if(!acceptCmd){
        QJsonObject json;
        if(is_debug){
            json["name"] = probot->name_debug;
        }else{
            json["name"] = probot->name;
        }
        json["msg_type"] = cmd;
        json["accept"] = false;
        json["error"] = "Ignored";

        QJsonDocument doc(json);
        QString str(doc.toJson(QJsonDocument::Indented));
        socket.sendTextMessage(str);
        plog->write("[SERVER] Ignored.");
    }else{
        if(cmd == "PAUSE"){
            emit server_pause();
        }else if(cmd == "RESUME"){
            emit server_resume();
        }else if(cmd == "NEW_TARGET"){
            float x = json["x"].toDouble();
            float y = json["y"].toDouble();
            float th = json["th"].toDouble();

            probot->targetPose.x = x;
            probot->targetPose.y = y;
            probot->targetPose.th = th;
            emit server_new_target();
        }else if(cmd == "NEW_CALL"){
            probot->targetLocation = json["location"].toString();
            bool check = false;
            for(int i=0; i<probot->call_list.size(); i++){
                if(probot->call_list[i] == probot->targetLocation){
                    plog->write("[SERVER] NEW CALL : " + probot->targetLocation + " BUT IGNORE (CALL LIST SIZE = " + QString::number(probot->call_list.size()) + ")");
                    check = true;
                    break;
                }
            }
            if(!check){
                probot->call_list.push_back(probot->targetLocation);
                plog->write("[SERVER] NEW CALL : " + probot->targetLocation + " (CALL LIST SIZE = " + QString::number(probot->call_list.size()) + ")");
                emit server_new_call();
            }
        }else if(cmd == "MAP_REQ"){
            sendMap(pmap->map_name);
        }else if(cmd == "MAP_PUB"){
            QFile *file;
            plog->write("[SERVER] Push Map : ");

            //RAW MAP
            file = new QFile(QDir::homePath()+"/maps/"+json["map_name"].toString()+"/map_raw.png");
            file->open(QIODevice::WriteOnly);
            file->write(QByteArray::fromBase64(json["raw_map"].toString().toLocal8Bit()));
            file->close();
            delete file;

            //ANNOTATED MAP
            server_map_name = json["map_name"].toString();
            file = new QFile(QDir::homePath()+"/maps/"+json["map_name"].toString()+"/map_edited.png");
            file->open(QIODevice::WriteOnly);
            file->write(QByteArray::fromBase64(json["map"].toString().toLocal8Bit()));
            file->close();
            delete file;

            //.ini
            file = new QFile(QDir::homePath()+"/maps/"+json["map_name"].toString()+"/annotation.ini");
            file->open(QIODevice::WriteOnly);
            file->write(QByteArray::fromBase64(json["annot"].toString().toLocal8Bit()));
            file->close();

//            file = new QFile(QDir::homePath()+"/maps/"+json["map_name"].toString()+"/map_meta.ini");
//            file->open(QIODevice::WriteOnly);
//            file->write(QByteArray::fromBase64(json["meta"].toString().toLocal8Bit()));
//            file->close();

            emit server_get_map();

        }else if(cmd == "SET_ROBOT"){
            QString ini_path = QDir::homePath()+"/robot_config.ini";
            QSettings settings(ini_path, QSettings::IniFormat);
            settings.setValue("ROBOT_HW/model",json["model"].toString());
            settings.setValue("ROBOT_HW/serial_num",json["serial_num"].toString());
            settings.setValue("ROBOT_HW/type",json["type"].toString());
            settings.setValue("ROBOT_SW/travelline",json["travel_line"].toInt());
            emit server_set_ini();
            plog->write("[SERVER] Set Robot Data : name("+json["name"].toString()+") type("+json["type"].toString()+")");
        }else if(cmd == "CALL_REQ"){
            sendCalllist();
        }
    }
}

void ServerHandler::sendCalllist(){
    QJsonObject json;
    if(is_debug){
        json["name"] = probot->name_debug;
    }else{
        json["name"] = probot->name;
    }
    json["msg_type"] = "CALL_LIST";
    json["move_count"] = probot->call_moving_count;
    json["num"] = probot->call_list.size();

    QJsonArray call_array;
    for(int i=0; i<probot->call_list.size(); i++){
        QJsonObject temp;
        temp["location"] = probot->call_list[i];
        call_array.push_back(temp);
    }
    json["call_list"] = call_array;

    QJsonDocument doc(json);
    QString str(doc.toJson(QJsonDocument::Indented));
    socket.sendTextMessage(str);
    plog->write("[SERVER] SEND CALL LIST");
}

void ServerHandler::onBinaryMessageReceived(QByteArray message){
    ;
}

void ServerHandler::requestMap(){
    QJsonObject json;
    if(is_debug){
        json["name"] = probot->name_debug;
    }else{
        json["name"] = probot->name;
    }
    json["msg_type"] = "MAP_REQ";
    QJsonDocument doc(json);
    QString str(doc.toJson(QJsonDocument::Indented));
    socket.sendTextMessage(str);
    plog->write("[SERVER] MAP REQUEST");
}

void ServerHandler::onTimer(){ // 200ms
    static int cnt = 0;

    if(socket.state() == QAbstractSocket::ConnectedState){
        isconnect = true;

        QJsonObject json;
        QJsonArray path_array;
        QJsonArray local_path_array;
        QJsonArray lidar_array;

        // name
        if(is_debug){
            json["name"] = probot->name_debug;
        }else{
            json["name"] = probot->name;
        }
        json["msg_type"] = "DATA";

        // status
        json["motor_state"] = probot->motor_state;
        json["local_state"] = probot->localization_state;
        json["moving_state"] = probot->running_state;
        json["ui_state"] = ui_state;

        json["robot_type"] = probot->type;
        // cur_pose
        json["cur_pose_x"] = probot->curPose.x;
        json["cur_pose_y"] = probot->curPose.y;
        json["cur_pose_th"] = probot->curPose.th;

        // target_pose
        json["target_pose_x"] = probot->targetPose.x;
        json["target_pose_y"] = probot->targetPose.y;
        json["target_pose_th"] = probot->targetPose.th;

        // path
        QJsonObject path_element;
        for(int i=0; i<probot->pathSize; i++){
            path_element["x"] = probot->curPath[i].x;
            path_element["y"] = probot->curPath[i].y;
            path_element["th"] = probot->curPath[i].th;
            path_array.push_back(path_element);
        }
        json["path"] = path_array;

        QJsonObject path_element_local;
        for(int i=0; i<probot->localpathSize; i++){
            path_element_local["x"] = probot->localPath[i].x;
            path_element_local["y"] = probot->localPath[i].y;
            path_element_local["th"] = probot->localPath[i].th;
            local_path_array.push_back(path_element_local);
        }
        json["local_path"] = local_path_array;

        QJsonObject lidar_element;
        for(int i=0; i<360; i++){
            lidar_element["data"] = std::round(probot->lidar_data[i]*pmap->height)/pmap->width;
            lidar_array.push_back(lidar_element);
        }
        json["lidar"] = lidar_array;

        QJsonDocument doc(json);
        QString str(doc.toJson(QJsonDocument::Indented));
        socket.sendTextMessage(str);
    }else if(socket.state() == QAbstractSocket::ConnectingState){
        ;
    }else{
        isconnect = false;
        if(++cnt%5 == 0){
            socket.open(QUrl("ws://192.168.100.200:22334"));
        }
    }
}

void ServerHandler::sendMap(QString map_name){
    QFile* file = new QFile(QDir::homePath()+"/maps/"+map_name+"/map_edited.png");
    file->open(QIODevice::ReadOnly);
    QByteArray ba_map = file->readAll();
    file->close();
    delete file;

    file = new QFile(QDir::homePath()+"/maps/"+map_name+"/map_raw.png");
    file->open(QIODevice::ReadOnly);
    QByteArray ba_map2 = file->readAll();
    file->close();
    delete file;

    file = new QFile(QDir::homePath()+"/maps"+map_name+"/map_meta.ini");
    file->open(QIODevice::ReadOnly);
    QByteArray ba_meta = file->readAll();
    file->close();
    delete file;

    file = new QFile(QDir::homePath()+"/maps"+map_name+"/annotation.ini");
    file->open(QIODevice::ReadOnly);
    QByteArray ba_anot = file->readAll();
    file->close();
    delete file;

    QJsonObject json;
    if(is_debug){
        json["name"] = probot->name + "_" + probot->name_debug;
    }else{
        json["name"] = probot->name;
    }
    json["map_name"] = map_name;
    json["msg_type"] = "MAP";
    json["raw_map"] = QString(ba_map2.toBase64());
    json["annot_map"] = QString(ba_map.toBase64());
    json["annot"] = QString(ba_anot.toBase64());
    json["meta"] = QString(ba_meta.toBase64());

    QJsonDocument doc(json);
    QString str(doc.toJson(QJsonDocument::Indented));
    socket.sendTextMessage(str);
    plog->write("[SERVER] SEND MAP");
}
