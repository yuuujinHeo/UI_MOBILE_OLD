#include "LCMHandler.h"
#include <QQmlApplicationEngine>
#include <iostream>
#include <QDebug>
#include <QPixmap>


LCMHandler::LCMHandler()
    : lcm("udpm://239.255.76.67:7667?ttl=1")
{
    if(bThread == NULL){
        bFlag = true;
        bThread = new std::thread(&LCMHandler::bLoop, this);
    }

    probot->joystick[0] = 0;
    probot->joystick[1] = 0;

    timer = new QTimer();
    connect(timer, SIGNAL(timeout()),this,SLOT(onTimer()));
    timer->start(200);

    plog->write("[BUILDER] LCM HANDLER constructed");
}

LCMHandler::~LCMHandler(){
    if(bThread != NULL)
    {
        bFlag = false;
        bThread->join();
    }
    plog->write("[BUILDER] LCM HANDLER destroyed");
}



////*********************************************  COMMAND FUNCTIONS   ***************************************************////
void LCMHandler::sendCommand(command cmd, QString msg, bool force){
    if(!pmap->use_uicmd){
        plog->write("[LCM ERROR] SEND COMMAND (BLOCKED) : " + msg);
    }else if(isconnect){
        if(is_debug){
            lcm.publish("COMMAND_"+probot->name_debug.toStdString(),&cmd);
            plog->write("[LCM] SEND COMMAND TO COMMAND_" + probot->name_debug + ": " + msg);
        }else{
            lcm.publish("COMMAND_"+probot->name.toStdString(),&cmd);
            plog->write("[LCM] SEND COMMAND TO COMMAND_" + probot->name + ": " + msg);
        }
        flag_tx = true;
    }else{
        if(msg != ""){
            plog->write("[LCM ERROR] SEND COMMAND (DISCONNECTED) TO COMMAND_" + probot->name + ": " + msg);
            lcm.publish("COMMAND_"+probot->name.toStdString(),&cmd);
        }
    }
}

void LCMHandler::sendCommand(int cmd, QString msg){
    command send_msg;
    send_msg.cmd = cmd;

    if(!pmap->use_uicmd){
        plog->write("[LCM ERROR] SEND COMMAND (BLOCKED) : " + msg);
    }else if(isconnect){
        if(is_debug){
            lcm.publish("COMMAND_"+probot->name_debug.toStdString(),&send_msg);
            plog->write("[LCM] SEND COMMAND TO COMMAND_" + probot->name_debug + ": " + msg);
        }else{
            lcm.publish("COMMAND_"+probot->name.toStdString(),&send_msg);
            plog->write("[LCM] SEND COMMAND TO COMMAND_" + probot->name + ": " + msg);
        }
        flag_tx = true;
//        if(probot->init_state != ROBOT_INIT_NOT_READY){
//            if(is_debug){
//                lcm.publish("COMMAND_"+probot->name_debug.toStdString(),&send_msg);
//                plog->write("[LCM] SEND COMMAND TO COMMAND_" + probot->name_debug + ": " + msg);
//            }else{
//                lcm.publish("COMMAND_"+probot->name.toStdString(),&send_msg);
//                plog->write("[LCM] SEND COMMAND TO COMMAND_" + probot->name + ": " + msg);
//            }
//            flag_tx = true;
//        }else{
//            plog->write("[LCM ERROR] SEND COMMAND (ROBOT BUSY) TO COMMAND_" + probot->name + ": " + msg);
//        }
    }else{
        plog->write("[LCM ERROR] SEND COMMAND (DISCONNECTED) TO COMMAND_" + probot->name + ": " + msg);
        lcm.publish("COMMAND_"+probot->name.toStdString(),&send_msg);
    }
}

void LCMHandler::moveToLast(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_LOCATION;
    memcpy(send_msg.params,probot->curLocation.toUtf8(),sizeof(char)*255);

    sendCommand(send_msg, "MOVE LOCATION TO"+probot->curLocation);
}
void LCMHandler::moveTo(QString target_loc){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_LOCATION;
    memcpy(send_msg.params,target_loc.toUtf8(),sizeof(char)*255);

    probot->curLocation = target_loc;
    sendCommand(send_msg, "MOVE LOCATION TO"+target_loc);
}

void LCMHandler::moveTo(float x, float y, float th){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_TARGET;
    uint8_t *array;
    array = reinterpret_cast<uint8_t*>(&x);
    send_msg.params[0] = array[0];
    send_msg.params[1] = array[1];
    send_msg.params[2] = array[2];
    send_msg.params[3] = array[3];
    array = reinterpret_cast<uint8_t*>(&y);
    send_msg.params[4] = array[0];
    send_msg.params[5] = array[1];
    send_msg.params[6] = array[2];
    send_msg.params[7] = array[3];
    array = reinterpret_cast<uint8_t*>(&th);
    send_msg.params[8] = array[0];
    send_msg.params[9] = array[1];
    send_msg.params[10]= array[2];
    send_msg.params[11]= array[3];

    probot->curTarget.x = x;
    probot->curTarget.y = y;
    probot->curTarget.th = th;
    sendCommand(send_msg, "MOVE TARGET TO"+QString().sprintf("%f, %f, %f",x,y,th));
}
void LCMHandler::movePause(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_PAUSE;
    sendCommand(send_msg, "MOVE PAUSE");
}
void LCMHandler::moveResume(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_RESUME;
    sendCommand(send_msg, "MOVE RESUME");
}
void LCMHandler::moveJog(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_JOG;
    uint8_t *array;
    array = reinterpret_cast<uint8_t*>(&probot->joystick[0]);
    send_msg.params[0] = array[0];
    send_msg.params[1] = array[1];
    send_msg.params[2] = array[2];
    send_msg.params[3] = array[3];

    array = reinterpret_cast<uint8_t*>(&probot->joystick[1]);
    send_msg.params[4] = array[0];
    send_msg.params[5] = array[1];
    send_msg.params[6] = array[2];
    send_msg.params[7] = array[3];

    sendCommand(send_msg, "MOVE JOYSTICK "+QString().sprintf("%f, %f",probot->joystick[0],probot->joystick[1]));
}
void LCMHandler::moveStop(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_STOP;
    sendCommand(send_msg, "MOVE STOP");
}
void LCMHandler::moveManual(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MOVE_MANUAL;
    sendCommand(send_msg, "MOVE MANUAL START");
}

void LCMHandler::setVelocity(float vel){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_SET_VELOCITY;
    uint8_t *array;
    array = reinterpret_cast<uint8_t*>(&vel);
    send_msg.params[0] = array[0];
    send_msg.params[1] = array[1];
    send_msg.params[2] = array[2];
    send_msg.params[3] = array[3];

    sendCommand(send_msg, "SET VELOCITY TO "+QString().sprintf("%f",vel));
}

void LCMHandler::programStart(){
}

void LCMHandler::setInitPose(float x, float y, float th){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_SET_INIT;
    uint8_t *array;
    array = reinterpret_cast<uint8_t*>(&x);
    send_msg.params[0] = array[0];
    send_msg.params[1] = array[1];
    send_msg.params[2] = array[2];
    send_msg.params[3] = array[3];
    array = reinterpret_cast<uint8_t*>(&y);
    send_msg.params[4] = array[0];
    send_msg.params[5] = array[1];
    send_msg.params[6] = array[2];
    send_msg.params[7] = array[3];
    array = reinterpret_cast<uint8_t*>(&th);
    send_msg.params[8] = array[0];
    send_msg.params[9] = array[1];
    send_msg.params[10] = array[2];
    send_msg.params[11] = array[3];

    sendCommand(send_msg, "SET INIT "+QString().sprintf("%f, %f, %f",x,y,th));
}

void LCMHandler::restartSLAM(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_RESTART;
    QString msg = "RESTART SLAM";
    if(!pmap->use_uicmd){
        plog->write("[LCM ERROR] SEND COMMAND (BLOCKED) : " + msg);
    }else if(isconnect){
        lcm.publish("COMMAND_"+probot->name.toStdString(),&send_msg);
        plog->write("[LCM] SEND COMMAND TO COMMAND_" + probot->name + ": " + msg);
        flag_tx = true;
    }else{
        if(msg != ""){
            plog->write("[LCM ERROR] SEND COMMAND (DISCONNECTED) TO COMMAND_" + probot->name + ": " + msg);
            lcm.publish("COMMAND_"+probot->name.toStdString(),&send_msg);
        }
    }
}

void LCMHandler::sendMapPath(QString path){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_RESTART;
    memcpy(send_msg.params,path.toUtf8(),sizeof(char)*255);

    sendCommand(send_msg,"SEND MAP PATH ("+path+")");
}

void LCMHandler::startMapping(float grid_size){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MAPPING_START;
    uint8_t *array;
    array = reinterpret_cast<uint8_t*>(&grid_size);
    send_msg.params[0] = array[0];
    send_msg.params[1] = array[1];
    send_msg.params[2] = array[2];
    send_msg.params[3] = array[3];
    sendCommand(send_msg,"START MAPPING "+QString().sprintf("(grid size = %f)",grid_size));
}

void LCMHandler::saveMapping(QString name){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_MAPPING_SAVE;
    memcpy(send_msg.params,name.toUtf8(),sizeof(char)*255);
    sendCommand(send_msg,"SAVE MAPPING ("+name+")");

}

void LCMHandler::startObjecting(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_OBJECTING_START;
    sendCommand(send_msg,"START OBJECTING ");
}

void LCMHandler::saveObjecting(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_OBJECTING_SAVE;
    sendCommand(send_msg,"SAVE OBJECTING");
}
////*********************************************  CALLBACK FUNCTIONS   ***************************************************////
void LCMHandler::robot_status_callback(const lcm::ReceiveBuffer *rbuf, const std::string &chan, const robot_status *msg){
    isconnect = true;
//    qDebug() << "read Status";
    flag_rx = true;
    connect_count = 0;
    probot->battery_in = (msg->bat_in-44)*100/10;
    probot->battery_out = (msg->bat_out-44)*100/10;
    if(probot->battery_in > 100) probot->battery_in = 100;
    if(probot->battery_out > 100) probot->battery_out = 100;
    if(probot->battery_in < 0) probot->battery_in = 0;
    if(probot->battery_out < 0) probot->battery_out = 0;
    probot->battery_cur = msg->bat_cur;
    probot->motor[0].connection = msg->connection_m0;
    probot->motor[1].connection = msg->connection_m1;
    probot->motor[0].status = msg->status_m0;
    probot->motor[1].status = msg->status_m1;
    probot->motor[0].temperature = msg->temp_m0;
    probot->motor[1].temperature = msg->temp_m1;
    probot->status_power = msg->status_power;
    probot->status_emo = !msg->status_emo;
    probot->status_remote = msg->status_remote;
    //DEBUG
    probot->status_charge = msg->status_charge;
    probot->motor_state = msg->ui_motor_state;
    probot->localization_state = msg->ui_loc_state;
    probot->running_state = msg->ui_auto_state;
    probot->obs_state = msg->ui_obs_state;
    probot->curPose.x = msg->robot_pose[0];
    probot->curPose.y = msg->robot_pose[1];
    probot->curPose.th = msg->robot_pose[2];
    for(int i=0; i<360; i++){
        probot->lidar_data[i] = msg->robot_scan[i];
    }
}

void LCMHandler::robot_path_callback(const lcm::ReceiveBuffer *rbuf, const std::string &chan, const robot_path *msg){
    isconnect = true;
    flag_rx = true;
    connect_count = 0;
    flagPath = true;
    probot->pathSize = msg->num;
    qDebug() <<"ROBOT PATH CALL BACK " << probot->pathSize;
    for(int i=0; i<probot->pathSize; i++){
        ST_POSE temp;
        temp.x = msg->path[i][0];
        temp.y = msg->path[i][1];
        temp.th = 0;//msg->path[i][2];
        if(probot->curPath.size() > i){
            probot->curPath[i] = temp;
        }else{
            probot->curPath.push_back(temp);
        }
    }
    emit pathchanged();
    flagPath = false;
}

void LCMHandler::robot_local_path_callback(const lcm::ReceiveBuffer *rbuf, const std::string &chan, const robot_path *msg){
    qDebug() << "PATH CALLBACK " << msg->num;
    isconnect = true;
    flag_rx = true;
    connect_count = 0;
    flagLocalPath = true;
    probot->localpathSize = msg->num;
    for(int i=0; i<probot->localpathSize; i++){
        ST_POSE temp;
        temp.x = msg->path[i][0];
        temp.y = msg->path[i][1];
        temp.th = msg->path[i][2];
        probot->localPath[i] = temp;
    }
    flagLocalPath = false;
}

void LCMHandler::robot_mapping_callback(const lcm::ReceiveBuffer *rbuf, const std::string &chan, const map_data *msg){
    isconnect = true;
     connect_count = 0;
     pmap->width = msg->map_w;
     pmap->height = msg->map_h;
     pmap->gridwidth = msg->map_grid_w;
     pmap->origin[0] = msg->map_origin[0];
     pmap->origin[1] = msg->map_origin[1];
     pmap->imageSize = msg->len;

     pmap->data.clear();
     cv::Mat map1(msg->map_h, msg->map_w, CV_8U, cv::Scalar::all(0));
     memcpy(map1.data, msg->data.data(), msg->len);
     cv::flip(map1, map1, 0);
     cv::rotate(map1, map1, cv::ROTATE_90_COUNTERCLOCKWISE);
     cv::cvtColor(map1, map1,cv::COLOR_GRAY2RGBA);

     std::vector<int> vec;
     vec.assign(map1.data, map1.data + map1.cols*map1.rows*map1.channels());

     pmap->data = QVector<int>::fromStdVector(vec);
     pmap->test_mapping = QPixmap::fromImage(mat_to_qimage_cpy(map1));

     flagMapping = true;
     emit mappingin();
}

void LCMHandler::robot_objecting_callback(const lcm::ReceiveBuffer *rbuf, const std::string &chan, const map_data *msg){
     isconnect = true;
     connect_count = 0;

//     pmap->data.clear();
     int rows = 1000;//msg->map_h;
     int cols = 1000;//msg->map_w;

     cv::Mat map1(rows,cols, CV_8U, cv::Scalar::all(0));
     memcpy(map1.data, msg->data.data(), msg->len);
     cv::flip(map1, map1, 0);
     cv::rotate(map1, map1, cv::ROTATE_90_COUNTERCLOCKWISE);
     cv::cvtColor(map1, map1,cv::COLOR_GRAY2RGBA);

     std::vector<int> vec;
     vec.assign(map1.data, map1.data + map1.cols*map1.rows*map1.channels());

//     qDebug() << map1.cols << map1.rows;
     pmap->data = QVector<int>::fromStdVector(vec);
     pmap->test_objecting = QPixmap::fromImage(mat_to_qimage_cpy(map1));

     flagObjecting = true;
     emit objectingin();
}

void LCMHandler::robot_command_callback(const lcm::ReceiveBuffer *rbuf, const std::string &chan, const command *msg){
    qDebug() << "COMMAND CALLBACK" << msg->cmd;
}

void LCMHandler::robot_camera_callback(const lcm::ReceiveBuffer *rbuf, const std::string &chan, const camera_data *msg){
    for(int i=0; i<msg->num; i++){
        ST_CAMERA temp_info;

        temp_info.serial = QString::fromStdString(msg->serial[i]);
        temp_info.imageSize = msg->image_len;
        temp_info.width = msg->width;
        temp_info.height = msg->height;
        cv::Mat map1(msg->width, msg->height,  CV_8U, cv::Scalar::all(0));
        memcpy(map1.data, msg->image[i].data(), msg->image_len);
        for(size_t k =0; k<msg->image_len; ++k)
        {
           int y = k / map1.cols;
           int x = k % map1.cols;
           temp_info.data.push_back(map1.ptr<uchar>(y)[x]);
        }

        if(pmap->camera_info.count() > i){
            pmap->camera_info[i] = temp_info;
        }else{
            pmap->camera_info.push_back(temp_info);
        }

    }
    try{
        emit cameraupdate();
    }catch(std::bad_alloc){
        qDebug() << "bad alloc?";
    }
}
////***********************************************   THREADS  ********************************************************////
void LCMHandler::bLoop()
{
    /*
    sudo ifconfig lo multicast
    sudo route add -net 224.0.0.0 netmask 240.0.0.0 dev lo
    */

    // lcm init
    if(!lcm.good())
    {
        plog->write("[LCM ERROR] LCM CONNECT FAILED");
        isconnect = false;
    }

    while(bFlag)
    {
        lcm.handleTimeout(1);
    }
}

void LCMHandler::subscribe(){
    lcm.unsubscribe(sub_status);
    lcm.unsubscribe(sub_path);
    lcm.unsubscribe(sub_localpath);
    lcm.unsubscribe(sub_mapping);
    lcm.unsubscribe(sub_objecting);
    lcm.unsubscribe(sub_camera);
    lcm.unsubscribe(sub_test_cmd);
    if(is_debug){
        qDebug() << "Change Subscribe " << probot->name_debug;
        sub_mapping = lcm.subscribe("MAP_DATA_"+probot->name_debug.toStdString(), &LCMHandler::robot_mapping_callback, this);
        sub_objecting = lcm.subscribe("OBS_DATA_"+probot->name_debug.toStdString(), &LCMHandler::robot_objecting_callback, this);
        sub_status = lcm.subscribe("STATUS_DATA_"+probot->name_debug.toStdString(), &LCMHandler::robot_status_callback, this);
        sub_path = lcm.subscribe("ROBOT_PATH_"+probot->name_debug.toStdString(), &LCMHandler::robot_path_callback, this);
        sub_localpath = lcm.subscribe("ROBOT_LOCAL_PATH_"+probot->name_debug.toStdString(), &LCMHandler::robot_local_path_callback, this);
        sub_camera = lcm.subscribe("CAMERA_DATA_"+probot->name_debug.toStdString(), &LCMHandler::robot_camera_callback, this);
    }else{
        qDebug() << "Change Subscribe " << probot->name;
        sub_mapping = lcm.subscribe("MAP_DATA_"+probot->name.toStdString(), &LCMHandler::robot_mapping_callback, this);
        sub_objecting = lcm.subscribe("OBS_DATA_"+probot->name.toStdString(), &LCMHandler::robot_objecting_callback, this);
        sub_status = lcm.subscribe("STATUS_DATA_"+probot->name.toStdString(), &LCMHandler::robot_status_callback, this);
        sub_path = lcm.subscribe("ROBOT_PATH_"+probot->name.toStdString(), &LCMHandler::robot_path_callback, this);
        sub_localpath = lcm.subscribe("ROBOT_LOCAL_PATH_"+probot->name.toStdString(), &LCMHandler::robot_local_path_callback, this);
        sub_camera = lcm.subscribe("CAMERA_DATA_"+probot->name.toStdString(), &LCMHandler::robot_camera_callback, this);
        sub_test_cmd = lcm.subscribe("COMMAND_"+probot->name.toStdString(), &LCMHandler::robot_command_callback, this);
    }
}
void LCMHandler::onTimer(){
    //10ms 조이스틱 값 읽어오기
    if(flagJoystick){
        moveJog();
        flagJoystick = false;
    }else{
        if(probot->joystick[0] != 0 || probot->joystick[1] != 0 ){
            moveJog();
        }
    }

    if(is_mapping){

    }else{
        flagMapping = false;
    }

    if(is_objecting){

    }else{
        flagObjecting = false;
    }

    static int count=0;
    if(count++%5==0){
        flag_rx = false;
        flag_tx = false;
    }

    //LCM 통신 연결상태 확인(2초)
    if(connect_count++ > 5){
        isconnect = false;
    }

    if(isconnect && probot->localization_state==LOCAL_READY){
        probot->lastPose = probot->curPose;
    }
}
