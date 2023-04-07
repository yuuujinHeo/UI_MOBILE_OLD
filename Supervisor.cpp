#include "Supervisor.h"
#include <QQmlApplicationEngine>
#include <QKeyEvent>
#include <iostream>
#include <fstream>
#include <iostream>
#include <sys/stat.h>
#include <sys/types.h>
#include <QQmlEngine>
#include <QTextCodec>
#include <QSslSocket>
#include <exception>
#include <QGuiApplication>
#include <usb.h>
#include <QDir>
#include <QFileSystemWatcher>
#include <QtQuick/qquickimageprovider.h>

extern QObject *object;

ST_ROBOT *probot;
ST_MAP *pmap;
int ui_state = 0;
bool is_debug = false;

Supervisor::Supervisor(QObject *parent)
    : QObject(parent)
{
    timer = new QTimer();
    connect(timer, SIGNAL(timeout()),this,SLOT(onTimer()));
    timer->start(200);
    canvas.clear();
    flag_clear = false;

    probot = &robot;
    pmap = &map;
    mMain = nullptr;

    usb_map_list.clear();
    usb_check = false;
    usb_check_count = 0;
    map_rotate_angle = 0;
    canvas.clear();
    canvas_redo.clear();
    minimap_grid.clear();

    lcm = new LCMHandler();
    server = new ServerHandler();
    joystick = new JoystickHandler();
    call = new CallbellHandler();
    git = new HTTPHandler();
    connect(call, SIGNAL(new_call()),this,SLOT(new_call()));
    connect(git, SIGNAL(pullSuccess()),this,SLOT(git_pull_success()));
    connect(git, SIGNAL(pullFailed()),this,SLOT(git_pull_failed()));

    //Test USB
    QFileSystemWatcher *FSwatcher;
    FSwatcher = new QFileSystemWatcher(this);
    std::string user = getenv("USER");
    std::string path = "/media/" + user;
    FSwatcher->addPath(path.c_str());
    connect(FSwatcher, SIGNAL(directoryChanged(QString)),this,SLOT(usb_detect()));
    usb_detect();

    isaccepted = false;
    readSetting();
    ui_state = UI_STATE_NONE;

    connect(server,SIGNAL(server_pause()),this,SLOT(server_cmd_pause()));
    connect(server,SIGNAL(server_resume()),this,SLOT(server_cmd_resume()));
    connect(server,SIGNAL(server_new_target()),this,SLOT(server_cmd_newtarget()));
    connect(server,SIGNAL(server_new_call()),this,SLOT(server_cmd_newcall()));
    connect(server,SIGNAL(server_set_ini()),this,SLOT(server_cmd_setini()));
    connect(server,SIGNAL(server_get_map()),this,SLOT(server_get_map()));
    connect(lcm, SIGNAL(pathchanged()),this,SLOT(path_changed()));
    connect(lcm, SIGNAL(mappingin()),this,SLOT(mapping_update()));
    connect(lcm, SIGNAL(objectingin()),this,SLOT(objecting_update()));
    connect(lcm, SIGNAL(cameraupdate()),this,SLOT(camera_update()));
    plog->write("");
    plog->write("");
    plog->write("");
    plog->write("");
    plog->write("[BUILDER] SUPERVISOR constructed");

    QProcess *process = new QProcess(this);
    QString file = QDir::homePath() + "/auto_kill.sh";//"/code/build-SLAMNAV-Desktop-Release/SLAMNAV";
    process->start(file);
    QThread::sleep(1);
    startSLAM();
}

Supervisor::~Supervisor(){
    plog->write("[BUILDER] SUPERVISOR desployed");
    slam_process->kill();
    slam_process->close();
    QString file = QDir::homePath() + "/auto_kill.sh";//"/code/build-SLAMNAV-Desktop-Release/SLAMNAV";
    slam_process->start(file);
    QThread::sleep(1);
    slam_process->kill();
    slam_process->close();
    plog->write("[BUILDER] KILLED SLAMNAV");
}

////*********************************************  WINDOW 관련   ***************************************************////
void Supervisor::setWindow(QQuickWindow *Window){
    plog->write("[BUILDER] SET WINDOW ");
    mMain = Window;
}
QQuickWindow *Supervisor::getWindow()
{
    return mMain;
}
void Supervisor::setObject(QObject *object)
{
    mObject = object;
}
QObject *Supervisor::getObject()
{
    //rootobject를 리턴해준다.
    return mObject;
}
void Supervisor::programRestart(){
    plog->write("[USER INPUT] PROGRAM RESTART");
    slam_process->kill();
    QProcess::startDetached(QApplication::applicationFilePath());
    QApplication::exit(12);

}
void Supervisor::programExit(){
    plog->write("[USER INPUT] PROGRAM EXIT");
    slam_process->kill();
    QCoreApplication::quit();
}
void Supervisor::programHide(){
    plog->write("[USER INPUT] PROGRAM MINIMIZE");
}
void Supervisor::writelog(QString msg){
    plog->write(msg);
}

QString Supervisor::getRawMapPath(QString name){
    return QDir::homePath()+"/maps/"+name+"/map_raw.png";
}
QString Supervisor::getMapPath(QString name){
    return QDir::homePath()+"/maps/"+name+"/map_edited.png";
}
QString Supervisor::getAnnotPath(QString name){
    return QDir::homePath()+"/maps/"+name+"/annotation.ini";
}
QString Supervisor::getMetaPath(QString name){
    return QDir::homePath()+"/maps/"+name+"/map_meta.ini";
}
QString Supervisor::getTravelRawPath(QString name){
    return QDir::homePath()+"/maps/"+name+"/travel_raw.png";
}
QString Supervisor::getTravelPath(QString name){
    return QDir::homePath()+"/maps/"+name+"/travel_edited.png";
}
QString Supervisor::getCostPath(QString name){
    return QDir::homePath()+"/maps/"+name+"/map_cost.png";
}
QString Supervisor::getIniPath(){
    return QDir::homePath()+"/robot_config.ini";
}

////*********************************************  CALLING 관련   ***************************************************////
void Supervisor::new_call(){
    if(setting_call_id > -1){
        plog->write("[SUPERVISOR] NEW CALL ("+call->getBellID()+") SETTING");
        setSetting("CALLING/call_"+QString::number(setting_call_id),call->getBellID());
        QMetaObject::invokeMethod(mMain, "call_setting");
    }else{
        bool already_in = false;
        for(int i=0; i<call_list.size(); i++){
            if(call_list[i] == call->getBellID()){
                already_in = true;
                plog->write("[SUPERVISOR] NEW CALL ("+call_list[i]+") BUT ALREADY LIST IN");
                break;
            }
        }
        if(already_in){

        }else{
            call_list.push_back(call->getBellID());
            plog->write("[SUPERVISOR] NEW CALL ("+call->getBellID()+") GET -> LIST SIZE IS "+QString::number(call_list.size()));
        }
    }
}

void Supervisor::setCallbell(int id){
    setting_call_id = id;
}

QString Supervisor::getCallName(QString id){
    for(int i=0; i<getSetting("CALLING","call_num").toInt(); i++){
        if(getSetting("CALLING","call_"+QString::number(i)) == id){
            return "Serving_"+QString::number(i);
        }
    }
    return id;
}

void Supervisor::removeCall(int id){
    plog->write("[USER INPUT] REMOVE CALL_LIST "+QString::number(id));
    call_list.remove(id);
}
void Supervisor::removeCallAll(){
    plog->write("[USER INPUT] REMOVE CALL_LIST ALL");
    call_list.clear();
}

////*********************************************  SETTING 관련   ***************************************************////
void Supervisor::git_pull_success(){
    QString date = probot->program_date;
    plog->write("[SUPERVISOR] GIT PULL SUCCESS : "+probot->program_date+", "+date);
    setSetting("ROBOT_SW/version_msg",probot->program_message);
    setSetting("ROBOT_SW/version_date",date);//probot->program_date);
    setSetting("ROBOT_SW/version",probot->program_version);
    readSetting();
}
void Supervisor::git_pull_failed(){
    QString date = probot->program_date;
    plog->write("[SUPERVISOR] GIT PULL FAILED : "+probot->program_date+", "+date);
    setSetting("ROBOT_SW/version_msg",probot->program_message);
    setSetting("ROBOT_SW/version_date",date);//probot->program_date);
    setSetting("ROBOT_SW/version",probot->program_version);
    readSetting();
    git->resetGit();
}
bool Supervisor::isNewVersion(){
    git->updateGitArray();
    if(probot->gitList[0].date == probot->program_date){
        return true;
    }else{
        return false;
    }
}
QString Supervisor::getLocalVersion(){
    return probot->program_version;
}
QString Supervisor::getServerVersion(){
    if(probot->gitList.size() > 0){
        return probot->gitList[0].commit;
    }else{
        return "";
    }
}
QString Supervisor::getLocalVersionDate(){
    return probot->program_date;
}
QString Supervisor::getServerVersionDate(){
    if(probot->gitList.size() > 0){
        return probot->gitList[0].date;
    }else{
        return "";
    }
}
QString Supervisor::getLocalVersionMessage(){
    return probot->program_message;
}
QString Supervisor::getServerVersionMessage(){
    if(probot->gitList.size() > 0){
        return probot->gitList[0].message;
    }else{
        return "";
    }
}
void Supervisor::pullGit(){
    git->pullGit();

}

void Supervisor::setSetting(QString name, QString value){
    QString ini_path = getIniPath();
    QSettings setting(ini_path, QSettings::IniFormat);
    setting.setValue(name,value);
    plog->write("[SETTING] SET "+name+" VALUE TO "+value);
}
QString Supervisor::getSetting(QString group, QString name){
    QString ini_path = getIniPath();
    QSettings setting_robot(ini_path, QSettings::IniFormat);
    setting_robot.beginGroup(group);
    return setting_robot.value(name).toString();
}
void Supervisor::readSetting(QString map_name){
    //Robot Setting================================================================
    QString ini_path = getIniPath();
    QSettings setting_robot(ini_path, QSettings::IniFormat);

    setting_robot.beginGroup("ROBOT_HW");
    probot->model = setting_robot.value("model").toString();
    probot->serial_num = setting_robot.value("serial_num").toInt();
    probot->name = probot->model + QString::number(probot->serial_num);

    setting.tray_num = setting_robot.value("tray_num").toInt();
    probot->radius = setting_robot.value("radius").toFloat();
    probot->type = setting_robot.value("type").toString();
    setting_robot.endGroup();

    setting_robot.beginGroup("ROBOT_SW");
    probot->program_version = setting_robot.value("version").toString();
    probot->program_message = setting_robot.value("version_msg").toString();
    probot->program_date = setting_robot.value("version_date").toString();
    probot->velocity = setting_robot.value("velocity").toFloat();
    setting.useVoice = setting_robot.value("use_voice").toBool();
    setting.useAutoInit = setting_robot.value("use_autoinit").toBool();
    setting.useBGM = setting_robot.value("use_bgm").toBool();
    pmap->use_uicmd = setting_robot.value("use_uicmd").toBool();
    pmap->width = setting_robot.value("map_size").toInt();
    pmap->height = setting_robot.value("map_size").toInt();
    pmap->origin[0] = pmap->width/2;
    pmap->origin[1] = pmap->height/2;
    pmap->gridwidth = setting_robot.value("grid_size").toFloat();
    qDebug() << "READ GRID WIDTH " << pmap->gridwidth;
    setting_robot.endGroup();


    setting_robot.beginGroup("CALLING");
    probot->max_moving_count = setting_robot.value("call_maximum").toInt();
    setting_robot.endGroup();

    setting_robot.beginGroup("FLOOR");
    pmap->margin = setting_robot.value("margin").toFloat();
    pmap->use_server = setting_robot.value("map_server").toBool();
    server->acceptCmd = pmap->use_server;
    pmap->map_loaded = setting_robot.value("map_load").toBool();
    pmap->map_name = setting_robot.value("map_name").toString();
    pmap->map_path = setting_robot.value("map_path").toString();
    setting.table_num = setting_robot.value("table_num").toInt();
    setting.table_col_num = setting_robot.value("table_col_num").toInt();
    setting_robot.endGroup();

    setting_robot.beginGroup("SERVER");
    setting.useServerCMD = setting_robot.value("use_servercmd").toBool();
    setting.useTravelline = setting_robot.value("use_travelline").toBool();
    setting.travelline = setting_robot.value("travelline").toInt();
    setting_robot.endGroup();

    setting_robot.beginGroup("PATROL");
    patrol.filename = setting_robot.value("curfile").toString();
    patrol.mode = setting_robot.value("patrol_mode").toInt();
    setting_robot.endGroup();

    setting_robot.beginGroup("SENSOR");
    pmap->left_camera = setting_robot.value("left_camera").toString();
    pmap->right_camera = setting_robot.value("right_camera").toInt();
    setting_robot.endGroup();



    if(map_name == ""){
        map_name = pmap->map_name;
    }

    plog->write("[SUPERVISOR] READ SETTING : "+map_name);
    //Map Meta Data======================================================================
    ini_path = getMetaPath(map_name);
    QSettings setting_meta(ini_path, QSettings::IniFormat);

    setting_meta.beginGroup("map_metadata");
//    pmap->width = setting_meta.value("map_w").toInt();
//    pmap->height = setting_meta.value("map_h").toInt();
//    pmap->gridwidth = setting_meta.value("map_grid_width").toFloat();
//    pmap->origin[0] = setting_meta.value("map_origin_u").toInt();
//    pmap->origin[1] = setting_meta.value("map_origin_v").toInt();
//    qDebug() << "Read Setting " << pmap->gridwidth;
    setting_meta.endGroup();

    //Annotation======================================================================
    ini_path = getAnnotPath(map_name);
    QSettings setting_anot(ini_path, QSettings::IniFormat);

    setting_anot.beginGroup("charging_locations");
    int charge_num = setting_anot.value("num").toInt();
    qDebug() << charge_num;
    pmap->vecLocation.clear();
    ST_POSE temp_pose;
    ST_LOCATION temp_loc;
    for(int i=0; i<charge_num; i++){
        QString loc_str = setting_anot.value("loc"+QString::number(i)).toString();
        QStringList strlist = loc_str.split(",");
        temp_pose.x = strlist[1].toFloat();
        temp_pose.y = strlist[2].toFloat();
        temp_pose.th = strlist[3].toFloat();
        temp_loc.pose = temp_pose;
        temp_loc.type = "Charging";
        temp_loc.name = strlist[0];
        pmap->vecLocation.push_back(temp_loc);
    }
    setting_anot.endGroup();


    setting_anot.beginGroup("other_locations");
    int patrol_num = setting_anot.value("num").toInt();
    for(int i=0; i<patrol_num; i++){
        QString loc_str = setting_anot.value("loc"+QString::number(i)).toString();
        QStringList strlist = loc_str.split(",");
        temp_pose.x = strlist[1].toFloat();
        temp_pose.y = strlist[2].toFloat();
        temp_pose.th = strlist[3].toFloat();
        temp_loc.pose = temp_pose;
        temp_loc.type = "Other";
        temp_loc.name = strlist[0];
        pmap->vecLocation.push_back(temp_loc);
    }
    setting_anot.endGroup();


    setting_anot.beginGroup("resting_locations");
    int rest_num = setting_anot.value("num").toInt();
    for(int i=0; i<rest_num; i++){
        QString loc_str = setting_anot.value("loc"+QString::number(i)).toString();
        QStringList strlist = loc_str.split(",");
        temp_pose.x = strlist[1].toFloat();
        temp_pose.y = strlist[2].toFloat();
        temp_pose.th = strlist[3].toFloat();
        temp_loc.pose = temp_pose;
        temp_loc.type = "Resting";
        temp_loc.name = strlist[0];
        pmap->vecLocation.push_back(temp_loc);
    }
    setting_anot.endGroup();

    setting_anot.beginGroup("serving_locations");
    int serv_num = setting_anot.value("num").toInt();
    for(int i=0; i<serv_num; i++){
        QString loc_str = setting_anot.value("loc"+QString::number(i)).toString();
        QStringList strlist = loc_str.split(",");
        temp_pose.x = strlist[1].toFloat();
        temp_pose.y = strlist[2].toFloat();
        temp_pose.th = strlist[3].toFloat();
        temp_loc.pose = temp_pose;
        temp_loc.type = "Serving";
        temp_loc.name = strlist[0];
        pmap->vecLocation.push_back(temp_loc);
    }
    setting_anot.endGroup();

    qDebug() << pmap->vecLocation.size() << map_name;

    setting_anot.beginGroup("objects");
    int obj_num = setting_anot.value("num").toInt();

    pmap->vecObject.clear();
    ST_FPOINT temp_point;
    for(int i=0; i<obj_num; i++){
        QString name = setting_anot.value("poly"+QString::number(i)).toString();
        QStringList strlist = name.split(",");
        ST_OBJECT temp_obj;
        if(strlist[0].left(5) == "Table"){
            temp_obj.type = "Table";
        }else if(strlist[0].left(5) == "Chair"){
            temp_obj.type = "Chair";
        }else if(strlist[0].left(4) == "Wall"){
            temp_obj.type = "Wall";
        }else{
            temp_obj.type = "Unknown";
        }
        QStringList templist = strlist[1].split(":");

        if(templist.size() > 1){
            temp_obj.is_rect = false;
            for(int j=1; j<strlist.size(); j++){
                temp_point.x = strlist[j].split(":")[0].toFloat();
                temp_point.y = strlist[j].split(":")[1].toFloat();
                temp_obj.pose.push_back(temp_point);
            }
        }else{
            if(strlist[1].toInt() == 1){
                temp_obj.is_rect = true;
            }else{
                temp_obj.is_rect = false;
            }
            for(int j=2; j<strlist.size(); j++){
                temp_point.x = strlist[j].split(":")[0].toFloat();
                temp_point.y = strlist[j].split(":")[1].toFloat();
                temp_obj.pose.push_back(temp_point);
            }
        }
        pmap->vecObject.push_back(temp_obj);
    }
    setObjPose();
    setting_anot.endGroup();

    setting_anot.beginGroup("travel_lines");
    int trav_num = setting_anot.value("num").toInt();
    pmap->vecTline.clear();
    for(int i=0; i<trav_num; i++){
        QString loc_str = setting_anot.value("line"+QString::number(i)).toString();
        QStringList strlist = loc_str.split(",");
        QVector<ST_FPOINT> temp_v;
        for(int j=1; j<strlist.size(); j++){
            temp_point.x = strlist[j].split(":")[0].toFloat();
            temp_point.y = strlist[j].split(":")[1].toFloat();
            temp_v.push_back(temp_point);
        }
        pmap->vecTline.push_back(temp_v);
    }
    setting_anot.endGroup();


    //Set Variable
    probot->trays.clear();
    for(int i=0; i<setting.tray_num; i++){
        probot->trays.push_back(0);
    }

    lcm->subscribe();
    flag_read_ini = true;

    QMetaObject::invokeMethod(mMain, "update_ini");
}

void Supervisor::setVelocity(float vel){
    probot->velocity = vel;
    setSetting("ROBOT_SW/velocity",QString::number(vel));
    readSetting();
    lcm->setVelocity(vel);
}
float Supervisor::getVelocity(){
    return probot->velocity;
}
bool Supervisor::getuseTravelline(){
    return setting.useTravelline;
}
void Supervisor::setuseTravelline(bool use){
    setSetting("SERVER/use_travelline",QVariant(use).toString());
    readSetting();
}
int Supervisor::getnumTravelline(){
    return setting.travelline;
}
void Supervisor::setnumTravelline(int num){
    setSetting("SERVER/travelline",QString::number(num));
    readSetting();
}
int Supervisor::getTrayNum(){
    return setting.tray_num;
}
void Supervisor::setTrayNum(int tray_num){
    setSetting("ROBOT_SW/tray_num",QString::number(tray_num));
    readSetting();
}
int Supervisor::getTableNum(){
    return setting.table_num;
}
void Supervisor::setTableNum(int table_num){
    setSetting("FLOOR/table_num",QString::number(table_num));
    readSetting();
}
int Supervisor::getTableColNum(){
    return setting.table_col_num;
}
void Supervisor::setTableColNum(int col_num){
    setSetting("FLOOR/table_col_num",QString::number(col_num));
    readSetting();
}
bool Supervisor::getuseVoice(){
    return setting.useVoice;
}
void Supervisor::setuseVoice(bool use){
    setSetting("ROBOT_SW/use_voice",QVariant(use).toString());
    readSetting();
}
bool Supervisor::getuseBGM(){
    return setting.useBGM;
}
void Supervisor::setuseBGM(bool use){
    setSetting("ROBOT_SW/use_bgm",QVariant(use).toString());
    readSetting();
}
bool Supervisor::getserverCMD(){
    return setting.useServerCMD;
}
void Supervisor::setserverCMD(bool use){
    setSetting("SERVER/use_servercmd",QVariant(use).toString());
    readSetting();
}
void Supervisor::setRobotType(int type){
    if(type == 0){
        setSetting("ROBOT_HW/type","SERVING");
    }else{
        setSetting("ROBOT_HW/type","CALLING");
    }
    readSetting();
}
QString Supervisor::getRobotType(){
    return probot->type;
}
void Supervisor::setDebugName(QString name){
    plog->write("[SETTING] SET DEBUG NAME : "+name);
    robot.name_debug = name;
    lcm->subscribe();
}
QString Supervisor::getDebugName(){
    return robot.name_debug;
}
bool Supervisor::getDebugState(){
    return is_debug;
}
void Supervisor::setDebugState(bool isdebug){
    if(isdebug)
        plog->write("[SETTING] SET DEBUG STATE : TRUE" );
    else
        plog->write("[SETTING] SET DEBUG STATE : FALSE" );
    is_debug = isdebug;
}


void Supervisor::requestCamera(){
    command send_msg;
    send_msg.cmd = ROBOT_CMD_REQ_CAMERA;
    lcm->sendCommand(send_msg, "");
}
void Supervisor::setCamera(QString left, QString right){
    setSetting("SENSOR/left_camera",left);
    setSetting("SENSOR/right_camera",right);
    readSetting();
}
QString Supervisor::getLeftCamera(){
    return pmap->left_camera;
}
QString Supervisor::getRightCamera(){
    return pmap->right_camera;
}
int Supervisor::getCameraNum(){
    return pmap->camera_info.size();
}
QList<int> Supervisor::getCamera(int num){
    try{
        return pmap->camera_info[num].data;
    }catch(...){
        qDebug() << "Something Wrong to get Camera " << num << pmap->camera_info.size();
        QList<int> temp;
        return temp;
    }
}
QString Supervisor::getCameraSerial(int num){
    try{
        return pmap->camera_info[num].serial;
    }catch(...){
        qDebug() << "Something Wrong to get Camera Serial " << num << pmap->camera_info.size();
        return "";
    }
}


////*********************************************  INIT PAGE 관련   ***************************************************////
bool Supervisor::isConnectServer(){
    return server->isconnect;
}

void Supervisor::deleteAnnotation(){
    plog->write("[USER INPUT] Remove Annotation Data");

    pmap->vecLocation.clear();
    pmap->vecTline.clear();
    pmap->vecObject.clear();

    list_obj_dR.clear();
    list_obj_uL.clear();

//    readSetting();
}
bool Supervisor::isExistAnnotation(QString name){
    QString file_meta = getMetaPath(name);
    QString file_annot = getAnnotPath(name);
    return QFile::exists(file_annot);
}
bool Supervisor::isExistTravelRaw(QString name){
    QString file = getTravelRawPath(name);
    return QFile::exists(file);
}
bool Supervisor::isExistTravelEdited(QString name){
    QString file = getTravelPath(name);
    return QFile::exists(file);
}

QList<int> Supervisor::getMapData(QString filename){
    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_edited.png";
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);
    uchar* map_data = map.data;
    QList<int> list;

    for(int i=0; i<map.rows; i++){
        for(int j=0; j<map.cols; j++){
            list.push_back(map_data[i*map.cols + j]);
        }
    }
    return list;
}
int Supervisor::getAvailableMap(){
    std::string path = QString(QDir::homePath()+"/maps").toStdString();
    QDir directory(path.c_str());
    QStringList FileList = directory.entryList();
    map_list.clear();
    for(int i=0; i<FileList.size(); i++){
        QStringList namelist = FileList[i].split(".");
        if(namelist.size() == 1){
            map_list.push_back(FileList[i]);
        }
    }
    return map_list.size();
}
QString Supervisor::getAvailableMapPath(int num){
    if(num>-1 && num<map_list.size()){
        return map_list[num];
    }
    return "";
}
int Supervisor::getMapFileSize(QString name){
    std::string path = QString(QDir::homePath()+"/maps/"+name).toStdString();
    QDir directory(path.c_str());
    QStringList FileList = directory.entryList();
    map_detail_list.clear();
    for(int i=0; i<FileList.size(); i++){
        if(FileList[i] == "." || FileList[i] == ".."){
            continue;
        }
        map_detail_list.push_back(FileList[i]);
    }
    return map_detail_list.size();
}
QString Supervisor::getMapFile(int num){
    return map_detail_list[num];
}
bool Supervisor::isExistMap(QString name){
    if(QFile::exists(getMapPath(name))){
        if(QFile::exists(getRawMapPath(name))){

        }else{
            //make map_raw.png
            QFile::copy(getMapPath(name),getRawMapPath(name));
        }
        return true;
    }else{
        return false;
    }
}
bool Supervisor::isExistRawMap(QString name){
    if(QFile::exists(getRawMapPath(name))){
        return true;
    }else{
        return false;
    }
}
bool Supervisor::isExistMap(){
    //기본 설정된 맵파일 확인
    if(pmap->map_loaded){
        if(QFile::exists(getMapPath(getMapname()))){
            return true;
        }else{

            plog->write("[SETTING - ERROR] "+getMapname()+" not found. map unloaded.");
            setSetting("FLOOR/map_load","false");
            readSetting();
        }
    }
    return false;
}
bool Supervisor::loadMaptoServer(){
    if(server->isconnect){
        plog->write("[USER INPUT] load map to server : request");
        server->requestMap();
        return true;
    }else{
        plog->write("[USER INPUT - ERROR] load map to server : server not connected");
        QMetaObject::invokeMethod(mMain, "loadmap_server_fail");
        return false;
    }
}

bool Supervisor::isUSBFile(){
    return false;
}
QString Supervisor::getUSBFilename(){
    return "";
}
bool Supervisor::loadMaptoUSB(){
    return false;
}
bool Supervisor::isuseServerMap(){
    return pmap->use_server;
}
void Supervisor::setuseServerMap(bool use){
    QString ini_path = QDir::homePath()+"/robot_config.ini";
    QSettings settings(ini_path, QSettings::IniFormat);
    settings.setValue("FLOOR/map_server",use);
    if(use){
        settings.setValue("FLOOR/map_load",true);
        settings.setValue("FLOOR/map_name",server->server_map_name);
        settings.setValue("FLOOR/map_path",QDir::homePath()+"/maps/"+server->server_map_name);
        readSetting();
        plog->write("[SETTING] USE SERVER MAP Changed : True");
    }else{
        plog->write("[SETTING] USE SERVER MAP Changed : False");
    }
    readSetting();
}
void Supervisor::removeMap(QString filename){
    plog->write("[USER INPUT] Remove Map : "+filename);
//    QFile *file = new QFile(QDir::homePath()+"/maps/"+filename);
    QDir dir(QDir::homePath()+"/maps/" + filename);

    if(dir.removeRecursively()){
        qDebug() << "true";
    }else{
        qDebug() << "false";
    }
//    file->remove();
}
bool Supervisor::isloadMap(){
    return pmap->map_loaded;
}
void Supervisor::setloadMap(bool load){
    QString ini_path = getIniPath();
    QSettings settings(ini_path, QSettings::IniFormat);
    if(settings.value("FLOOR/map_load").toBool() == load){

    }else{
        settings.setValue("FLOOR/map_load",load);
        if(load){
            plog->write("[SETTING] LOAD MAP Changed : True");
        }else{
            plog->write("[SETTING] LOAD MAP Changed : False");
        }
        readSetting();
    }
}
bool Supervisor::isExistRobotINI(){
    QString file = getIniPath();
    return QFile::exists(file);
}
void Supervisor::makeRobotINI(){
    plog->write("[SETTING] Make robot_config.ini basic format");
    setSetting("ROBOT_HW/model","TEMP");
    setSetting("ROBOT_HW/serial_num","1");
    setSetting("ROBOT_HW/radius","0.35");
    setSetting("ROBOT_HW/tray_num","3");
    setSetting("ROBOT_HW/type","SERVING");
    setSetting("ROBOT_HW/wheel_base","0.3542");
    setSetting("ROBOT_HW/wheel_radius","0.0635");

    setSetting("ROBOT_SW/version","");
    setSetting("ROBOT_SW/version_msg","");
    setSetting("ROBOT_SW/version_date","");
    setSetting("ROBOT_SW/use_bgm","true");
    setSetting("ROBOT_SW/use_voice","true");
    setSetting("ROBOT_SW/use_autoinit","false");
    setSetting("ROBOT_SW/use_avoid","true");
    setSetting("ROBOT_SW/velocity","1.0");
    setSetting("ROBOT_SW/volume_bgm","50");
    setSetting("ROBOT_SW/volume_voice","50");
    setSetting("ROBOT_SW/use_uicmd","true");
    setSetting("ROBOT_SW/k_curve","0.005");
    setSetting("ROBOT_SW/k_v","1.0");
    setSetting("ROBOT_SW/k_w","1.0");
    setSetting("ROBOT_SW/limit_manual_v","0.3");
    setSetting("ROBOT_SW/limit_manual_w","30.0");
    setSetting("ROBOT_SW/limit_pivot","30.0");
    setSetting("ROBOT_SW/limit_v","0.5");
    setSetting("ROBOT_SW/limit_w","90.0");
    setSetting("ROBOT_SW/limit_v_acc","0.5");
    setSetting("ROBOT_SW/limit_w_acc","120.0");
    setSetting("ROBOT_SW/look_ahead_dist","0.50");


    setSetting("SERVER/travelline","0");
    setSetting("SERVER/use_servercmd","true");
    setSetting("SERVER/use_travelline","true");

    setSetting("FLOOR/map_load","true");
    setSetting("FLOOR/map_server","false");
    setSetting("FLOOR/table_col_num","1");
    setSetting("FLOOR/table_num","5");
    setSetting("FLOOR/map_name","");
    setSetting("FLOOR/map_path","");

    setSetting("PATROL/patrol_mode","0");
    setSetting("PATROL/curfile","");

    setSetting("MOTOR/gear_ratio","1.0");
    setSetting("MOTOR/k_d","4900.0");
    setSetting("MOTOR/k_i","0.0");
    setSetting("MOTOR/k_p","100.0");
    setSetting("MOTOR/left_id","1");
    setSetting("MOTOR/right_id","0");
    setSetting("MOTOR/limit_acc","0.5");
    setSetting("MOTOR/limit_dec","0.5");
    setSetting("MOTOR/limit_vel","0.1");
    setSetting("MOTOR/limit_v","1.5");
    setSetting("MOTOR/limit_v_acc","1.0");
    setSetting("MOTOR/limit_w","360.0");
    setSetting("MOTOR/limit_w_acc","360.0");
    setSetting("MOTOR/wheel_dir","-1");

    setSetting("SENSOR/baudrate","256000");
    setSetting("SENSOR/cam_exposure","2000.0");
    setSetting("SENSOR/mask","10.0");
    setSetting("SENSOR/max_range","40.0");
    setSetting("SENSOR/offset_x","0.0");
    setSetting("SENSOR/offset_y","0.0");
    setSetting("SENSOR/left_camera","");
    setSetting("SENSOR/right_camera","");

    readSetting();
    restartSLAM();
}
bool Supervisor::rotate_map(QString _src, QString _dst, int mode){
    cv::Mat map1 = cv::imread(_src.toStdString());

    cv::rotate(map1,map1,cv::ROTATE_90_CLOCKWISE);
    cv::flip(map1, map1, 0);
    QImage temp_image = QPixmap::fromImage(mat_to_qimage_cpy(map1)).toImage();
    QString path = QDir::homePath()+"/maps/"+_dst;
    QDir directory(path);
    if(!directory.exists()){
        directory.mkpath(".");

    }
    //Save PNG File
    if(mode == 1){//edited
        if(temp_image.save(QDir::homePath()+"/maps/"+_dst+"/map_edited.png","PNG")){
            QFile *file = new QFile(QGuiApplication::applicationDirPath()+"/"+_src);
            file->remove();
            plog->write("[MAP] Save edited Map : "+_dst);
            return true;
        }else{
            plog->write("[MAP] Fail to save edited Map : "+_dst);
            return false;
        }
    }else if(mode == 2){//raw
        qDebug() << QDir::homePath()+"/maps/"+_dst+"/map_raw.png";
        if(temp_image.save(QDir::homePath()+"/maps/"+_dst+"/map_raw.png","PNG")){
            QFile *file = new QFile(QGuiApplication::applicationDirPath()+"/"+_src);
            file->remove();
            plog->write("[MAP] Save raw Map : "+_dst);
            return true;
        }else{
            plog->write("[MAP] Fail to save raw Map : "+_dst);
            return false;
        }
    }
}
bool Supervisor::getLCMConnection(){
    return lcm->isconnect;
}
bool Supervisor::getLCMRX(){
    return lcm->flag_rx;
}
bool Supervisor::getLCMTX(){
    return lcm->flag_tx;
}
bool Supervisor::getLCMProcess(){
    return false;
}
bool Supervisor::getIniRead(){
    return flag_read_ini;
}
int Supervisor::getUsbMapSize(){
    return usb_map_list.size();
}
QString Supervisor::getUsbMapPath(int num){
    QStringList templist = usb_map_list[num].split("/");
    QString temp = templist[templist.size() - 2] + "/" + templist[templist.size()-1];
    return temp;
}
QString Supervisor::getUsbMapPathFull(int num){
    return usb_map_list[num];
}
void Supervisor::saveMapfromUsb(QString path){
    std::string user = getenv("USER");
    std::string path1 = "/media/" + user + "/";

    QString orin_path = path1.c_str() + path;
    QStringList kk = path.split('/');


    QString new_path = QCoreApplication::applicationDirPath() + "/image/" + kk[kk.length()-1];
    if(QFile::exists(orin_path)){
        if(QFile::copy(orin_path, new_path)){
            plog->write("[SETTING] Save Map from USB : "+kk[kk.length()-1]);
        }else{
            plog->write("[SETTING - ERROR] Save Map from USB (Copy failed): "+kk[kk.length()-1]);
        }
    }else{
        plog->write("[SETTING - ERROR] Save Map from USB (Origin not found): "+kk[kk.length()-1]);
    }
}

void Supervisor::setMap(QString name){
    setSetting("FLOOR/map_path",QDir::homePath()+"/maps/"+name);
    setSetting("FLOOR/map_name",name);
    readSetting(name);
    setloadMap(true);
    restartSLAM();
//    lcm->restartSLAM();
}

void Supervisor::loadMap(QString name){
//    readSetting()
}

void Supervisor::restartSLAM(){
    plog->write("[USER INPUT] Restart SLAM");
    if(slam_process != nullptr){
        plog->write("[SUPERVISOR] RESTART SLAM -> PID : "+QString::number(slam_process->pid()));
        if(slam_process->state() == QProcess::NotRunning){
            plog->write("[SUPERVISOR] RESTART SLAM -> NOT RUNNING -> KILL");
            slam_process->kill();
            slam_process->close();
            probot->localization_state = LOCAL_NOT_READY;
            probot->motor_state = MOTOR_NOT_READY;
            probot->status_charge = 0;
            probot->status_emo = 0;
            probot->status_power = 0;
            probot->status_remote = 0;
            lcm->isconnect = false;
            QString file = "xterm ./auto_test.sh";
            slam_process->setWorkingDirectory(QDir::homePath());
            slam_process->start(file);
            plog->write("[SUPERVISOR] RESTART SLAM -> START SLAM "+QString::number(slam_process->pid()));
        }else if(slam_process->state() == QProcess::Starting){
            plog->write("[SUPERVISOR] RESTART SLAM -> STARTING");
        }else{
            plog->write("[SUPERVISOR] RESTART SLAM -> RUNNING");
            QProcess *tempprocess = new QProcess(this);
            tempprocess->start(QDir::homePath() + "/kill_slam.sh");
            QThread::sleep(2);
//            tempprocess->kill();
//            delete tempprocess;
        }
        probot->localization_state = LOCAL_NOT_READY;
        probot->motor_state = MOTOR_NOT_READY;
        probot->status_charge = 0;
        probot->status_emo = 0;
        probot->status_power = 0;
        probot->status_remote = 0;
        lcm->isconnect = false;
    }else{
        plog->write("[SUPERVISOR] RESTART SLAM -> SLAM PROCESS IS NEW ");
        slam_process = new QProcess(this);
        QString file = "xterm ./auto_test.sh";
        slam_process->setWorkingDirectory(QDir::homePath());
        slam_process->start(file);
        plog->write("[SUPERVISOR] RESTART SLAM -> START SLAM "+QString::number(slam_process->pid()));
    }
    probot->localization_state = LOCAL_NOT_READY;
    probot->motor_state = MOTOR_NOT_READY;
    probot->status_charge = 0;
    probot->status_emo = 0;
    probot->status_power = 0;
    probot->status_remote = 0;
    lcm->isconnect = false;
}

void Supervisor::startSLAM(){
    plog->write("[SUPERVISOR] START SLAM");
    probot->localization_state = LOCAL_NOT_READY;
    probot->motor_state = MOTOR_NOT_READY;
    probot->status_charge = 0;
    probot->status_emo = 0;
    probot->status_power = 0;
    probot->status_remote = 0;
    lcm->isconnect = false;

    slam_process = new QProcess(this);
    QString file = "xterm ./auto_test.sh";
    slam_process->setWorkingDirectory(QDir::homePath());
    slam_process->start(file);
    plog->write("[SUPERVISOR] RESTART SLAM -> START SLAM "+QString::number(slam_process->pid()));
}

////*******************************************  SLAM(LOCALIZATION) 관련   ************************************************////
void Supervisor::startMapping(float grid){
    plog->write("[USER INPUT] START MAPPING");
    lcm->startMapping(grid);
    lcm->is_mapping = true;
}
void Supervisor::stopMapping(){
    plog->write("[USER INPUT] STOP MAPPING");
    lcm->flagMapping = false;
    lcm->is_mapping = false;
    lcm->sendCommand(ROBOT_CMD_MAPPING_STOP, "MAPPING STOP");
}
void Supervisor::saveMapping(QString name){
    lcm->saveMapping(name);
}
void Supervisor::startObjecting(){
    plog->write("[USER INPUT] START OBJECTING");
    lcm->startObjecting();
    lcm->is_objecting = true;
}
void Supervisor::stopObjecting(){
    plog->write("[USER INPUT] STOP OBJECTING");
    lcm->flagObjecting = false;
    lcm->is_objecting = false;
    lcm->sendCommand(ROBOT_CMD_OBJECTING_STOP, "OBJECTING STOP");
}
void Supervisor::saveObjecting(){
    lcm->saveObjecting();
}
void Supervisor::setSLAMMode(int mode){

}
void Supervisor::setInitPos(int x, int y, float th){
    ST_FPOINT temp = canvasTomap(x,y);
    pmap->init_pose.x = temp.x;
    pmap->init_pose.y = temp.y;
    pmap->init_pose.th = th;
    plog->write("[LOCALIZATION] SET INIT POSE : "+QString().sprintf("%f, %f, %f",temp.x, temp.y, th));
}
float Supervisor::getInitPoseX(){
    ST_POSE temp = setAxis(pmap->init_pose);
    return temp.x;
}
float Supervisor::getInitPoseY(){
    ST_POSE temp = setAxis(pmap->init_pose);
    return temp.y;
}
float Supervisor::getInitPoseTH(){
    ST_POSE temp = setAxis(pmap->init_pose);
    return temp.th;
}
void Supervisor::slam_setInit(){
    plog->write("[SLAM] SLAM SET INIT : "+QString().sprintf("%f, %f, %f",pmap->init_pose.x,pmap->init_pose.y,pmap->init_pose.th));
    lcm->setInitPose(pmap->init_pose.x, pmap->init_pose.y, pmap->init_pose.th);
}
void Supervisor::slam_run(){
    lcm->sendCommand(ROBOT_CMD_SLAM_RUN, "LOCALIZATION RUN");
}
void Supervisor::slam_stop(){
    lcm->sendCommand(ROBOT_CMD_SLAM_STOP, "LOCALIZATION STOP");
}
void Supervisor::slam_autoInit(){
    lcm->sendCommand(ROBOT_CMD_SLAM_AUTO, "LOCALIZATION AUTO INIT");
}
bool Supervisor::is_slam_running(){
    if(probot->localization_state == LOCAL_READY){
        return true;
    }else{
        return false;
    }
}
bool Supervisor::getMappingflag(){
    return lcm->flagMapping;
}
void Supervisor::setMappingflag(bool flag){
    lcm->flagMapping = flag;
}
bool Supervisor::getObjectingflag(){
    return lcm->flagObjecting;
}
void Supervisor::setObjectingflag(bool flag){
    lcm->flagObjecting = flag;
}

QList<int> Supervisor::getListMap(QString filename){
    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_edited.png";
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);
    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);

    uchar* map_data = map.data;
    QList<int> list;

    for(int i=0; i<map.rows; i++){
        for(int j=0; j<map.cols; j++){
            list.push_back(map_data[i*map.cols + j]);
        }
    }
    return list;
}

QList<int> Supervisor::getRawListMap(QString filename){
    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_raw.png";
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);


    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);

    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);


    uchar* map_data = map.data;
    QList<int> list;

    for(int i=0; i<map.rows; i++){
        for(int j=0; j<map.cols; j++){
            list.push_back(map_data[i*map.cols + j]);
        }
    }
    return list;
}
//QList<int> Supervisor::getRawMap(QString filename){
//    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_raw.png";
//    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
//    cv::flip(map,map,0);
//    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);
//    uchar* map_data = map.data;
//    QList<int> list;

//    for(int i=0; i<map.rows; i++){
//        for(int j=0; j<map.cols; j++){
//            list.push_back(map_data[i*map.cols + j]);
//        }
//    }
//    return list;
//}

//QList<int> Supervisor::getMiniMap(QString filename){
//    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_edited.png";
//    minimap = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
//    cv::flip(minimap,minimap,0);
//    cv::rotate(minimap,minimap,cv::ROTATE_90_COUNTERCLOCKWISE);

//    plog->write("[MAP] Make Minimap Start : "+filename);
//    int dp = 3;
//    for(int i=0; i<minimap.rows; i=i+dp){
//        for(int j=0; j<minimap.cols; j=j+dp){
//            int pixel = 0;
//            bool outline = false;
//            for(int k=0; k<dp; k++){
//                for(int m=0; m<dp; m++){
//                    if(i+k>minimap.rows-1)
//                        continue;
//                    if(j+m>minimap.cols-1)
//                        continue;
//                    pixel+=minimap.at<cv::Vec3b>(i+k,j+m)[0];
//                    if(minimap.at<cv::Vec3b>(i+k,j+m)[0] == 0)
//                        outline = true;
//                }
//            }
//            float kk = pixel/(dp*dp);
//            if(kk < 10 || outline)
//                pixel = 0;
//            else if(kk > 100)
//                pixel = 255;
//            else
//                pixel = 38;

//            for(int k=0; k<dp; k++){
//                for(int m=0; m<dp; m++){
//                    if(i+k>minimap.rows-1)
//                        continue;
//                    if(j+m>minimap.cols-1)
//                        continue;
//                    minimap.data[((i+k)*minimap.cols + (j+m))*3] = pixel;
//                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 1] = pixel;
//                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 2] = pixel;
//                }
//            }
//        }
//    }
//    dp = 15;
//    for(int i=0; i<minimap.rows; i=i+dp){
//        for(int j=0; j<minimap.cols; j=j+dp){

//            int pixel = 0;
//            int outline = 0;
//            for(int k=0; k<dp; k++){
//                for(int m=0; m<dp; m++){
//                    if(i+k>minimap.rows-1)
//                        continue;
//                    if(j+m>minimap.cols-1)
//                        continue;
//                    pixel+=minimap.at<cv::Vec3b>(i+k,j+m)[0];
//                    if(minimap.at<cv::Vec3b>(i+k,j+m)[0] == 0)
//                        outline++;
//                }
//            }
//            float kk = pixel/(dp*dp);
//            if(outline > (dp*dp)/3)
//                pixel = 0;
//            else if(kk > 100)
//                pixel = 255;
//            else
//                pixel = 38;

//            for(int k=0; k<dp; k++){
//                for(int m=0; m<dp; m++){
//                    if(i+k>minimap.rows-1)
//                        continue;
//                    if(j+m>minimap.cols-1)
//                        continue;
//                    minimap.data[((i+k)*minimap.cols + (j+m))*3] = pixel;
//                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 1] = pixel;
//                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 2] = pixel;
//                }
//            }
//        }
//    }

//    cv::cvtColor(minimap, minimap,cv::COLOR_BGR2HSV);
//    cv::GaussianBlur(minimap, minimap,cv::Size(3,3),0);
//    cv::Scalar lower(0,0,37);
//    cv::Scalar upper(0,0,255);
//    cv::inRange(minimap,lower,upper,minimap);
//    cv::Canny(minimap,minimap,600,600);
//    cv::Mat kernel = getStructuringElement(cv::MORPH_RECT, cv::Size(5,5));
//    dilate(minimap, minimap, kernel);
//    QImage temp_image = QPixmap::fromImage(mat_to_qimage_cpy(minimap)).toImage();
//    uchar* map_data = minimap.data;
//    QList<int> list;

//    for(int i=0; i<minimap.rows; i++){
//        for(int j=0; j<minimap.cols; j++){
//            list.push_back(map_data[i*minimap.cols + j]);
//        }
//    }
//    return list;
//}

QObject *Supervisor::getMapping() const{
    PixmapContainer *pc = new PixmapContainer();
    pc->pixmap = pmap->test_mapping;
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}
QObject *Supervisor::getObjecting() const{
//    PixmapContainer *pc = new PixmapContainer();
////    cv::Mat argb_map;
////    pmap->test_objecting.copyTo(argb_map);
////    for(int i=0; i<pmap->data.size(); i++){
////        if(pmap->data[i] == 0){
////            argb_map.ptr<cv::Vec4b>(i/1000)[i%1000] = cv::Vec4b(0,0,0,0);
////        }else{
////            argb_map.ptr<cv::Vec4b>(i/1000)[i%1000] = cv::Vec4b(pmap->data[i],pmap->data[i],pmap->data[i],255);
////        }/*
////        if(canvas[i] == 255){
////            argb_map.ptr<cv::Vec4b>(i/1000)[i%1000] = cv::Vec4b(0,0,255,255);
////        }else if(canvas[i] == 100){
////            argb_map.ptr<cv::Vec4b>(i/1000)[i%1000] = cv::Vec4b(0,0,0,0);
////        }*/
////    }
//    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(argb_map));
//    Q_ASSERT(!pc->pixmap.isNull());
//    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
//    return pc;





    PixmapContainer *pc = new PixmapContainer();
    pc->pixmap = pmap->test_objecting;
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

QObject *Supervisor::getMinimap(QString filename) const{
    PixmapContainer *pc = new PixmapContainer();

    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_edited.png";
    if(filename == "" || !QFile::exists(file_path)){
        QPixmap blank(pmap->height, pmap->width);{
            QPainter painter(&blank);
            painter.fillRect(blank.rect(),"black");
        }

        pc->pixmap = blank;
        Q_ASSERT(!pc->pixmap.isNull());
        QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
        return pc;
    }
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);




    plog->write("[MAP] Make Minimap Start : "+filename);
    int dp = 3;
    for(int i=0; i<minimap.rows; i=i+dp){
        for(int j=0; j<minimap.cols; j=j+dp){
            int pixel = 0;
            bool outline = false;
            for(int k=0; k<dp; k++){
                for(int m=0; m<dp; m++){
                    if(i+k>minimap.rows-1)
                        continue;
                    if(j+m>minimap.cols-1)
                        continue;
                    pixel+=minimap.at<cv::Vec3b>(i+k,j+m)[0];
                    if(minimap.at<cv::Vec3b>(i+k,j+m)[0] == 0)
                        outline = true;
                }
            }
            float kk = pixel/(dp*dp);
            if(kk < 10 || outline)
                pixel = 0;
            else if(kk > 200)
                pixel = 255;
            else
                pixel = 127;

            for(int k=0; k<dp; k++){
                for(int m=0; m<dp; m++){
                    if(i+k>minimap.rows-1)
                        continue;
                    if(j+m>minimap.cols-1)
                        continue;
                    minimap.data[((i+k)*minimap.cols + (j+m))*3] = pixel;
                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 1] = pixel;
                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 2] = pixel;
                }
            }
        }
    }
    dp = 15;
    for(int i=0; i<minimap.rows; i=i+dp){
        for(int j=0; j<minimap.cols; j=j+dp){

            int pixel = 0;
            int outline = 0;
            for(int k=0; k<dp; k++){
                for(int m=0; m<dp; m++){
                    if(i+k>minimap.rows-1)
                        continue;
                    if(j+m>minimap.cols-1)
                        continue;
                    pixel+=minimap.at<cv::Vec3b>(i+k,j+m)[0];
                    if(minimap.at<cv::Vec3b>(i+k,j+m)[0] == 0)
                        outline++;
                }
            }
            float kk = pixel/(dp*dp);
            if(outline > (dp*dp)/3)
                pixel = 0;
            else if(kk > 200)
                pixel = 255;
            else
                pixel = 127;

            for(int k=0; k<dp; k++){
                for(int m=0; m<dp; m++){
                    if(i+k>minimap.rows-1)
                        continue;
                    if(j+m>minimap.cols-1)
                        continue;
                    minimap.data[((i+k)*minimap.cols + (j+m))*3] = pixel;
                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 1] = pixel;
                    minimap.data[((i+k)*minimap.cols + (j+m))*3 + 2] = pixel;
                }
            }
        }
    }

    cv::cvtColor(minimap, minimap,cv::COLOR_BGR2HSV);
    cv::GaussianBlur(minimap, minimap,cv::Size(3,3),0);
    cv::Scalar lower(0,0,37);
    cv::Scalar upper(0,0,255);
    cv::inRange(minimap,lower,upper,minimap);
    cv::Canny(minimap,minimap,600,600);
    cv::Mat kernel = getStructuringElement(cv::MORPH_RECT, cv::Size(5,5));
    dilate(minimap, minimap, kernel);



    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(minimap));
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

QObject *Supervisor::getMap(QString filename) const{
    PixmapContainer *pc = new PixmapContainer();
    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_edited.png";

    if(filename == "" || !QFile::exists(file_path)){
        QPixmap blank(pmap->height, pmap->width);{
            QPainter painter(&blank);
            painter.fillRect(blank.rect(),"black");
        }

        pc->pixmap = blank;
        Q_ASSERT(!pc->pixmap.isNull());
        QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
        return pc;
    }

    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);

    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);


    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(map));
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

QObject *Supervisor::getRawMap(QString filename) const{
    PixmapContainer *pc = new PixmapContainer();
    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_raw.png";

    if(filename == "" || !QFile::exists(file_path)){
//        QPixmap blank(pmap->height, pmap->width);{
        QPixmap blank(1000,1000);{
            QPainter painter(&blank);
            painter.fillRect(blank.rect(),"black");
        }

        pc->pixmap = blank;
        Q_ASSERT(!pc->pixmap.isNull());
        QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
        return pc;
    }
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    qDebug() << map.rows << map.cols;
    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);
    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);

    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(map));

    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

cv::Mat map_test;
QObject *Supervisor::getTravelRawMap(QString filename) const{
    PixmapContainer *pc = new PixmapContainer();
    QString file_path = QDir::homePath()+"/maps/"+filename+"/travel_raw.png";
    if(filename == "" || !QFile::exists(file_path)){
        QPixmap blank(pmap->height, pmap->width);{
            QPainter painter(&blank);
            painter.fillRect(blank.rect(),"black");
        }

        pc->pixmap = blank;
        Q_ASSERT(!pc->pixmap.isNull());
        QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
        return pc;
    }

    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);
    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);

    cv::Mat argb_map(map.rows, map.cols, CV_8UC4, cv::Scalar::all(0));
    for(int i = 0; i < map.rows; i++)
    {
        for(int j = 0; j < map.cols; j++)
        {
            if(map.ptr<uchar>(i)[j] == 255)
            {
                argb_map.ptr<cv::Vec4b>(i)[j] = cv::Vec4b(0,0,255,255);
            }
        }
    }
    map_test = argb_map;

    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(map_test));
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

QObject *Supervisor::getTravel(QList<int> canvas) const{
    PixmapContainer *pc = new PixmapContainer();
    cv::Mat argb_map;
    map_test.copyTo(argb_map);

    for(int i=0; i<canvas.size(); i++){
        if(canvas[i] == 255){
            argb_map.ptr<cv::Vec4b>(i/pmap->height)[i%pmap->width] = cv::Vec4b(0,0,255,255);
        }else if(canvas[i] == 100){
            argb_map.ptr<cv::Vec4b>(i/pmap->height)[i%pmap->width] = cv::Vec4b(0,0,0,0);
        }
    }
    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(argb_map));
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

QObject *Supervisor::getTest(QList<int> canvas) const{
    PixmapContainer *pc = new PixmapContainer();
    cv::Mat argb_map = map_test;
    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(argb_map));
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

QObject *Supervisor::getTravelMap(QString filename) const{
    PixmapContainer *pc = new PixmapContainer();
    QString file_path = QDir::homePath()+"/maps/"+filename+"/travel_edited.png";
    if(filename == "" || !QFile::exists(file_path)){
        QPixmap blank(pmap->height, pmap->width);{
            QPainter painter(&blank);
            painter.fillRect(blank.rect(),"black");
        }

        pc->pixmap = blank;
        Q_ASSERT(!pc->pixmap.isNull());
        QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
        return pc;
    }
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);
    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);

    cv::Mat argb_map(map.rows, map.cols, CV_8UC4, cv::Scalar::all(0));
    for(int i = 0; i < map.rows; i++)
    {
        for(int j = 0; j < map.cols; j++)
        {
            if(map.ptr<uchar>(i)[j] == 255)
            {
                argb_map.ptr<cv::Vec4b>(i)[j] = cv::Vec4b(0,0,255,255);
            }
        }
    }
    map_test = argb_map;

    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(argb_map));
    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}
QObject *Supervisor::getCostMap(QString filename) const{
    PixmapContainer *pc = new PixmapContainer();
    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_cost.png";
    if(filename == "" || !QFile::exists(file_path)){
        QPixmap blank(pmap->height, pmap->width);{
            QPainter painter(&blank);
            painter.fillRect(blank.rect(),"black");
        }

        pc->pixmap = blank;
        Q_ASSERT(!pc->pixmap.isNull());
        QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
        return pc;
    }
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);
    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);

    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(map));

    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}

QObject *Supervisor::getObjectMap(QString filename) const{
    PixmapContainer *pc = new PixmapContainer();
    QString file_path = QDir::homePath()+"/maps/"+filename+"/map_obs.png";
    if(filename == "" || !QFile::exists(file_path)){
        QPixmap blank(pmap->height, pmap->width);{
            QPainter painter(&blank);
            painter.fillRect(blank.rect(),"black");
        }

        pc->pixmap = blank;
        Q_ASSERT(!pc->pixmap.isNull());
        QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
        return pc;
    }
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);
    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);

    cv::Mat argb_map(map.rows, map.cols, CV_8UC4, cv::Scalar::all(0));
    for(int i = 0; i < map.rows; i++)
    {
        for(int j = 0; j < map.cols; j++)
        {
            if(map.ptr<uchar>(i)[j] != 0)
            {
                argb_map.ptr<cv::Vec4b>(i)[j] = cv::Vec4b(map.ptr<uchar>(i)[j],map.ptr<uchar>(i)[j],map.ptr<uchar>(i)[j],255);
            }
        }
    }
    pc->pixmap = QPixmap::fromImage(mat_to_qimage_cpy(argb_map));

    Q_ASSERT(!pc->pixmap.isNull());
    QQmlEngine::setObjectOwnership(pc, QQmlEngine::JavaScriptOwnership);
    return pc;
}
QPixmap Supervisor::getMappingImage(){
    return pmap->test_mapping;
}

void Supervisor::pushMapData(QList<int> data){
    pmap->data.clear();
    for(int i=0; i<data.size(); i++){
        pmap->data.push_back(data[i]);
    }
}

QString Supervisor::getnewMapname(){
    int max_num = -1;
    for(int i=0; i<getAvailableMap(); i++){
        QStringList name = map_list[i].split("_");
        if(name.size() > 1 && name[0] == "map"){
            if(name[1].toInt() > max_num){
                max_num = name[1].toInt();
            }
        }
    }
    if(max_num == -1){
        return "map_0";
    }else{
        return "map_"+QString::number(max_num+1);
    }
}

////*********************************************  JOYSTICK 관련   ***************************************************////
bool Supervisor::isconnectJoy(){
    return joystick->connection;
}
float Supervisor::getJoyAxis(int num){
    return joystick->JoyAxis[num];
}
int Supervisor::getJoyButton(int num){
    return joystick->JoyButton[num];
}
QString Supervisor::getKeyboard(int mode){
    return "";
}
QString Supervisor::getJoystick(int mode){
    return "";
}
void Supervisor::usb_detect(){
    plog->write("[USB] NEW USB Detected");
    usb_check = true;
    usb_check_count = 0;
}




////*********************************************  ANNOTATION 관련   ***************************************************////
int Supervisor::getCanvasSize(){
    return canvas.size();
}
void Supervisor::setRotateAngle(float angle){
    annotation_edit = true;
    qDebug() << "SET ROTATE ANGLE : " << angle;
    map_rotate_angle = angle;
}
int Supervisor::getRedoSize(){
    return canvas_redo.size();
}
QVector<int> Supervisor::getLineX(int index){
    QVector<int>    temp_x;
    for(int i=0; i<canvas[index].line.size(); i++){
        temp_x.push_back(canvas[index].line[i].x);
    }
    return temp_x;
}
QVector<int> Supervisor::getLineY(int index){
    QVector<int>    temp_y;
    for(int i=0; i<canvas[index].line.size(); i++){
        temp_y.push_back(canvas[index].line[i].y);
    }
    return temp_y;
}
QString Supervisor::getLineColor(int index){
    if(index < canvas.size()){
        return canvas[index].color;
    }
    return "";
}
void Supervisor::saveTravel(bool mode, QList<int> canvas){
    QString file_path;
    if(mode){
        file_path = QDir::homePath()+"/maps/"+getMapname()+"/travel_edited.png";
    }else{
        file_path = QDir::homePath()+"/maps/"+getMapname()+"/travel_raw.png";
    }
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat argb_map(map.rows, map.cols, CV_8UC4, cv::Scalar::all(0));
    for(int i = 0; i < map.rows; i++)
    {
        for(int j = 0; j < map.cols; j++)
        {
            if(map.ptr<uchar>(i)[j] == 255 || canvas[i*map.rows + j] == 255)
            {
                argb_map.ptr<cv::Vec4b>(i)[j] = cv::Vec4b(255,255,255,255);
            }else{
                argb_map.ptr<cv::Vec4b>(i)[j] = cv::Vec4b(0,0,0,255);
            }
            if(canvas[i*map.rows + j] == 100){
                argb_map.ptr<cv::Vec4b>(i)[j] = cv::Vec4b(0,0,0,255);
            }
        }
    }

    cv::rotate(argb_map,argb_map,cv::ROTATE_90_CLOCKWISE);
    cv::flip(argb_map,argb_map,0);
    QImage temp_image = QPixmap::fromImage(mat_to_qimage_cpy(argb_map)).toImage();
    QString path = getTravelPath(getMapname());
    if(temp_image.save(path,"PNG")){
        plog->write("[MAP] Save travle : "+path);
        restartSLAM();
    }else{
        plog->write("[MAP] Fail to save travle : "+path);
    }
}
void Supervisor::saveMap(QString mode, QString src, QString dst, QList<int> data, QList<int> alpha){
    annotation_edit = true;
    QString file_path;
    if(mode == "EDITED"){
        file_path = QDir::homePath()+"/maps/"+src+"/map_edited.png";
    }else if(mode == "RAW"){
        file_path = QDir::homePath()+"/maps/"+src+"/map_raw.png";
    }else{
        return;
    }
    cv::Mat map = cv::imread(file_path.toStdString(),cv::IMREAD_GRAYSCALE);
    cv::flip(map,map,0);
    cv::rotate(map,map,cv::ROTATE_90_COUNTERCLOCKWISE);

    cv::Mat rot = cv::getRotationMatrix2D(cv::Point(map.cols/2, map.rows/2),-map_rotate_angle, 1.0);
    cv::warpAffine(map,map,rot,map.size(),cv::INTER_NEAREST);

    for(int i=0; i<alpha.size(); i++){
        if(alpha[i] > 200){
            map.data[i] = data[i];
        }
    }
    map_rotate_angle = 0;
    cv::rotate(map,map,cv::ROTATE_90_CLOCKWISE);
    cv::flip(map,map,0);
    QImage temp_image = QPixmap::fromImage(mat_to_qimage_cpy(map)).toImage();
    QString path = QDir::homePath()+"/maps/"+dst;
    QDir directory(path);
    if(!directory.exists()){
        directory.mkpath(".");
    }
    if(temp_image.save(QDir::homePath()+"/maps/"+dst+"/map_edited.png","PNG")){
        plog->write("[MAP] Save edited Map : "+dst);
        restartSLAM();
    }else{
        plog->write("[MAP] Fail to save edited Map : "+dst);
    }
}
float Supervisor::getLineWidth(int index){
    if(index < canvas.size()){
        return canvas[index].width;
    }
    return 0;
}
void Supervisor::setLine(int x, int y){
    ST_POINT temp_point;
    temp_point.x = x;
    temp_point.y = y;
    temp_line.line.push_back(temp_point);
}
void Supervisor::startLine(QString color, float width){
    annotation_edit = true;
    temp_line.line.clear();
    temp_line.color = color;
    temp_line.width = width;
    plog->write("[ANNOTATION] START LINE : color("+color+") width("+QString::number(width)+")");
}
void Supervisor::stopLine(){
    canvas.push_back(temp_line);
    canvas_redo.clear();
}

void Supervisor::undo(){
    annotation_edit = true;
    ST_LINE temp;
    if(canvas.size() > 0){
        temp = canvas.back();
        canvas.pop_back();
        canvas_redo.push_back(temp);
        plog->write("[ANNOTATION] UNDO [canvas size = "+QString::number(canvas.size())+ "] redo size = " + QString::number(canvas_redo.size()));
    }
}
void Supervisor::redo(){
    annotation_edit = true;
    if(canvas_redo.size() > 0){
        if(flag_clear){
            flag_clear = false;
            if(canvas.size() > 0){

            }else{
                canvas = canvas_redo;
                canvas_redo.clear();
            }
        }else{
            canvas.push_back(canvas_redo.back());
            canvas_redo.pop_back();
        }
        plog->write("[ANNOTATION] REDO [canvas size = "+QString::number(canvas.size())+ "] redo size = " + QString::number(canvas_redo.size()));
    }
}
void Supervisor::clear_all(){
    if(canvas.size() > 0 || canvas_redo.size() > 0 || temp_object.size() > 0){
        plog->write("[ANNOTATION] CLEAR [canvas size = "+QString::number(canvas.size())+ "] redo size = " + QString::number(canvas_redo.size()));
    }
    canvas_redo.clear();
    for(int i=0; i<canvas.size(); i++){
        canvas_redo.push_back(canvas[i]);
        flag_clear = true;
    }
    temp_object.clear();
    canvas.clear();
}
void Supervisor::setObjPose(){
    list_obj_dR.clear();
    list_obj_uL.clear();
    for(int i=0; i<pmap->vecObject.size(); i++){
        ST_FPOINT temp_uL;
        ST_FPOINT temp_dR;
        //Find Square Pos
        temp_uL.x = pmap->vecObject[i].pose[0].x;
        temp_uL.y = pmap->vecObject[i].pose[0].y;
        temp_dR.x = pmap->vecObject[i].pose[0].x;
        temp_dR.y = pmap->vecObject[i].pose[0].y;
        for(int j=1; j<pmap->vecObject[i].pose.size(); j++){
            if(temp_uL.x > pmap->vecObject[i].pose[j].x){
                temp_uL.x = pmap->vecObject[i].pose[j].x;
            }
            if(temp_uL.y > pmap->vecObject[i].pose[j].y){
                temp_uL.y = pmap->vecObject[i].pose[j].y;
            }
            if(temp_dR.x < pmap->vecObject[i].pose[j].x){
                temp_dR.x = pmap->vecObject[i].pose[j].x;
            }
            if(temp_dR.y < pmap->vecObject[i].pose[j].y){
                temp_dR.y = pmap->vecObject[i].pose[j].y;
            }
        }
        list_obj_dR.push_back(temp_uL);
        list_obj_uL.push_back(temp_dR);
    }
}
void Supervisor::setMarginObj(){
    for(int i=0; i<list_obj_dR.size(); i++){
        ST_POINT pixel_uL = mapTocanvas(list_obj_uL[i].x,list_obj_uL[i].y);
        ST_POINT pixel_bR = mapTocanvas(list_obj_dR[i].x,list_obj_dR[i].y);
        for(int x=pixel_uL.x; x<pixel_bR.x; x++){
            for(int y=pixel_uL.y; y<pixel_bR.y; y++){
                list_margin_obj.push_back(x + y*pmap->width);
            }
        }
    }
    plog->write("[QML] SET MARGIN OBJECT DONE");
}
void Supervisor::clearMarginObj(){
    list_margin_obj.clear();
}
void Supervisor::setMarginPoint(int pixel_num){
    list_margin_obj.push_back(pixel_num);
}
QVector<int> Supervisor::getMarginObj(){
    return list_margin_obj;
}
float Supervisor::getMargin(){
    return pmap->margin;
}
int Supervisor::getLocationNum(){
    return pmap->vecLocation.size();
}
int Supervisor::getLocationSize(QString type){
    int count = -1;
    for(int i=0; i<pmap->vecLocation.size(); i++){
        if(pmap->vecLocation[i].type == type){
            QStringList namelist = pmap->vecLocation[i].name.split("_");
            if(namelist[0] == type && namelist.size() >1){
                if(namelist[1].toInt() > count){
                    count = namelist[1].toInt();
                }
            }
        }
    }
    return count + 1;
}
QString Supervisor::getLocationName(int num){
    if(num > -1 && num < pmap->vecLocation.size()){
        return pmap->vecLocation[num].name;
    }
    return "";
}
QString Supervisor::getLocationTypes(int num){
    if(num > -1 && num < pmap->vecLocation.size()){
        return pmap->vecLocation[num].type;
    }
    return "";
}
float Supervisor::getLocationx(int num){
    if(num > -1 && num < pmap->vecLocation.size()){
        ST_POSE temp = setAxis(pmap->vecLocation[num].pose);
        return temp.x;
    }
    return 0.;
}
float Supervisor::getLocationy(int num){
    if(num > -1 && num < pmap->vecLocation.size()){
        ST_POSE temp = setAxis(pmap->vecLocation[num].pose);
        return temp.y;
    }
    return 0.;
}
float Supervisor::getLocationth(int num){
    if(num > -1 && num < pmap->vecLocation.size()){
        ST_POSE temp = setAxis(pmap->vecLocation[num].pose);
        return temp.th;
    }
    return 0.;
}
bool Supervisor::isExistLocation(int num){
    for(int i=0; i<pmap->vecLocation.size(); i++){
        if(pmap->vecLocation[i].name.split("_").size() > 1 && pmap->vecLocation[i].name.split("_")[0] == "Serving"){
            if(pmap->vecLocation[i].name.split("_")[1].toInt() == num){
                return true;
            }
        }
    }
    return false;
}
float Supervisor::getLidar(int num){
    return probot->lidar_data[num];
}

ST_POSE Supervisor::setAxis(ST_POSE _pose){
    ST_POSE temp;
    temp.x = -_pose.y;
    temp.y = -_pose.x;
    temp.th = _pose.th;
    return temp;
}
ST_FPOINT Supervisor::setAxis(ST_FPOINT _point){
    ST_FPOINT temp;
    temp.x = -_point.y;
    temp.y = -_point.x;
    return temp;
}
ST_FPOINT Supervisor::canvasTomap(int x, int y){
    ST_FPOINT temp;
    temp.x = -pmap->gridwidth*(y-pmap->origin[1]);
    temp.y = -pmap->gridwidth*(x-pmap->origin[0]);
    qDebug() << pmap->gridwidth << pmap->origin[0] << x << temp.y;
    return temp;
}
ST_POINT Supervisor::mapTocanvas(float x, float y){
    ST_POINT temp;
    temp.x = -y/pmap->gridwidth + pmap->origin[1];
    temp.y = -x/pmap->gridwidth + pmap->origin[0];
    return temp;
}

int Supervisor::getObjectNum(){
    return pmap->vecObject.size();
}
QString Supervisor::getObjectName(int num){
    int count = 0;
    if(num > -1 && num < pmap->vecObject.size()){
        for(int i=0; i<num; i++){
            if(pmap->vecObject[i].type == pmap->vecObject[num].type){
                count++;
            }
        }
        return pmap->vecObject[num].type + "_" + QString::number(count);
    }
}
int Supervisor::getObjectPointSize(int num){
    return pmap->vecObject[num].pose.size();
}
float Supervisor::getObjectX(int num, int point){
    if(num > -1 && num < pmap->vecObject.size()){
        if(point > -1 && point < pmap->vecObject[num].pose.size()){
            ST_FPOINT temp = setAxis(pmap->vecObject[num].pose[point]);
            return temp.x;
        }
    }
    return 0;
}
float Supervisor::getObjectY(int num, int point){
    if(num > -1 && num < pmap->vecObject.size()){
        if(point > -1 && point < pmap->vecObject[num].pose.size()){
            ST_FPOINT temp = setAxis(pmap->vecObject[num].pose[point]);
            return temp.y;
        }
    }
    return 0;
}

bool Supervisor::getAnnotEditFlag(){
    return annotation_edit;
}
void Supervisor::setAnnotEditFlag(bool flag){
    annotation_edit = flag;
}

int Supervisor::getTempObjectSize(){
    return temp_object.size();
}
float Supervisor::getTempObjectX(int num){
    ST_FPOINT temp = setAxis(temp_object[num]);
    return temp.x;
}
float Supervisor::getTempObjectY(int num){
    ST_FPOINT temp = setAxis(temp_object[num]);
    return temp.y;
}

int Supervisor::getObjNum(QString name){
    QStringList namelist = name.split("_");
    int num = namelist[1].toInt();
    int count = 0;
    for(int i=0; i<pmap->vecObject.size(); i++){
        if(pmap->vecObject[i].type == namelist[0]){
            if(num == count){
                return i;
            }else{
                count++;
            }
        }
    }
    return -1;
}
int Supervisor::getObjNum(int x, int y){
    for(int i=0; i<list_obj_uL.size(); i++){
        ST_FPOINT pos = canvasTomap(x,y);
        if(pos.x<list_obj_uL[i].x && pos.x>list_obj_dR[i].x){
            if(pos.y<list_obj_uL[i].y && pos.y>list_obj_dR[i].y){
                return i;
            }
        }
    }
    return -1;
}
int Supervisor::getObjPointNum(int obj_num, int x, int y){
    ST_FPOINT pos = canvasTomap(x,y);
    if(obj_num < pmap->vecObject.size() && obj_num > -1){
        qDebug() << "check obj" << obj_num << pmap->vecObject[obj_num].pose.size();
        if(obj_num != -1){
            for(int j=0; j<pmap->vecObject[obj_num].pose.size(); j++){
                qDebug() << pmap->vecObject[obj_num].pose[j].x << pmap->vecObject[obj_num].pose[j].y;
                if(fabs(pmap->vecObject[obj_num].pose[j].x - pos.x) < 0.1){
                    if(fabs(pmap->vecObject[obj_num].pose[j].y - pos.y) < 0.1){
                        qDebug() << "Match Point !!" << obj_num << j;
                        return j;
                    }
                }
            }
        }
    }
    qDebug() << "can't find obj num : " << x << y;
    return -1;
}

int Supervisor::getLocNum(QString name){
    for(int i=0; i<pmap->vecLocation.size(); i++){
        if(pmap->vecLocation[i].name == name){
            return i;
        }
    }
    return -1;
}
int Supervisor::getLocNum(int x, int y){
    for(int i=0; i<pmap->vecLocation.size(); i++){
        ST_FPOINT pos = canvasTomap(x,y);
        if(fabs(pmap->vecLocation[i].pose.x - pos.x) < probot->radius){
            if(fabs(pmap->vecLocation[i].pose.y - pos.y) < probot->radius){
                return i;
            }
        }
    }
    return -1;
}


void Supervisor::removeLocation(QString name){
    annotation_edit = true;
    clear_all();
    for(int i=0; i<pmap->vecLocation.size(); i++){
        if(pmap->vecLocation[i].name == name){
            plog->write("[UI-MAP] REMOVE LOCATION "+ name);
            pmap->vecLocation.remove(i);
            QMetaObject::invokeMethod(mMain, "updatelocation");
            return;
        }
    }
    plog->write("[UI-MAP] REMOVE OBJECT BUT FAILED "+ name);
}
void Supervisor::addLocation(QString type, QString name, int x, int y, float th){
    annotation_edit = true;
    ST_LOCATION temp_loc;
    temp_loc.type = type;
    temp_loc.name = name;
    ST_POSE temp_pose;
    ST_FPOINT temp = canvasTomap(x,y);
    temp_pose.x = temp.x;
    temp_pose.y = temp.y;
    temp_pose.th = th;
    temp_loc.pose = temp_pose;
    plog->write("[ANNOTATION] ADD LOCATION : " +type+", "+name+", "+QString().sprintf("%d, %d, %f",x,y,th));
    pmap->vecLocation.push_back(temp_loc);
    QMetaObject::invokeMethod(mMain, "updatecanvas");
    QMetaObject::invokeMethod(mMain, "updatelocation");

    plog->write("[DEBUG] addLocation "+ name);
}
void Supervisor::moveLocationPoint(int loc_num, int x, int y, float th){
    if(loc_num > -1 && loc_num < pmap->vecLocation.size()){
        annotation_edit = true;
        ST_FPOINT temp = canvasTomap(x,y);
        pmap->vecLocation[loc_num].pose.x = temp.x;
        pmap->vecLocation[loc_num].pose.y = temp.y;
        pmap->vecLocation[loc_num].pose.th = th;
        qDebug() << loc_num << x << y << th;
        plog->write("[DEBUG] moveLocation "+QString().sprintf("%d -> %f, %f, %f",loc_num , temp.x ,temp.y , th));
    }
}

void Supervisor::addObjectPoint(int x, int y){
    annotation_edit = true;
    qDebug() << "addObjetPoint " << x << y << pmap->gridwidth;
    ST_FPOINT temp = canvasTomap(x,y);
    plog->write("[ANNOTATION] addObjectPoint " + QString().sprintf("[%d] %f, %f",temp_object.size(),temp.x,temp.y));
    temp_object.push_back(temp);

    QMetaObject::invokeMethod(mMain, "updatecanvas");
}
void Supervisor::removeObjectPoint(int num){
    annotation_edit = true;
    if(num < temp_object.size()){
        temp_object.remove(num);
        QMetaObject::invokeMethod(mMain, "updatecanvas");
    }else{
        plog->write("[ANNOTATION] removeObjectPoint " + QString().sprintf("%d, %d",num,temp_object.size()));
    }
}
void Supervisor::removeObjectPointLast(){
    annotation_edit = true;
    if(temp_object.size() > 0){
        temp_object.pop_back();
        plog->write("[ANNOTATION] Remove Object Point Last");
        QMetaObject::invokeMethod(mMain, "updatecanvas");
    }
}
void Supervisor::clearObjectPoints(){
    temp_object.clear();
    plog->write("[ANNOTATION] Clear Object Point");
    QMetaObject::invokeMethod(mMain, "updatecanvas");
}
int Supervisor::getObjectSize(QString type){
    int size = 0;
    for(int i=0; i<pmap->vecObject.size(); i++){
        if(pmap->vecObject[i].type == type)
            size++;
    }
    return size;
}
void Supervisor::addObject(QString type){
    QString num;
    annotation_edit = true;
    if(temp_object.size() > 0){
        ST_OBJECT temp;
        temp.pose = temp_object;
        temp.is_rect = false;
        temp.type = type;
        pmap->vecObject.push_back(temp);
        temp_object.clear();
        setObjPose();
        QMetaObject::invokeMethod(mMain, "updatecanvas");
        QMetaObject::invokeMethod(mMain, "updateobject");
        plog->write("[DEBUG] addObject " + type);
    }else{
        plog->write("[DEBUG] addObject " + type + " but size = 0");
    }
}
void Supervisor::addObjectRect(QString type){
    QString num;
    annotation_edit = true;
    if(temp_object.size() > 4){
        plog->write("[DEBUG] addObjectRect " + type + " but size > 4");
    }else if(temp_object.size() > 0){
        ST_OBJECT temp;
        temp.pose = temp_object;
        temp.is_rect = true;
        temp.type = type;
        pmap->vecObject.push_back(temp);
        temp_object.clear();
        setObjPose();
        QMetaObject::invokeMethod(mMain, "updatecanvas");
        QMetaObject::invokeMethod(mMain, "updateobject");
        plog->write("[DEBUG] addObjectRect " + type);
    }else{
        plog->write("[DEBUG] addObjectRect " + type + " but size = 0");
    }
}

void Supervisor::editObject(int num, int point, int x, int y){
    annotation_edit = true;
    if(num > -1 && num < pmap->vecObject.size()){
        if(pmap->vecObject[num].is_rect){
            if(point == 0){
                ST_FPOINT pos = canvasTomap(x,y);
                pmap->vecObject[num].pose[0].x = pos.x;
                pmap->vecObject[num].pose[0].y = pos.y;
                pmap->vecObject[num].pose[1].y = pos.y;
                pmap->vecObject[num].pose[3].x = pos.x;
                QMetaObject::invokeMethod(mMain, "updatecanvas");
            }else if(point == 1){
                ST_FPOINT pos = canvasTomap(x,y);
                pmap->vecObject[num].pose[1].x = pos.x;
                pmap->vecObject[num].pose[1].y = pos.y;
                pmap->vecObject[num].pose[0].y = pos.y;
                pmap->vecObject[num].pose[2].x = pos.x;
                QMetaObject::invokeMethod(mMain, "updatecanvas");
            }else if(point == 2){
                ST_FPOINT pos = canvasTomap(x,y);
                pmap->vecObject[num].pose[2].x = pos.x;
                pmap->vecObject[num].pose[2].y = pos.y;
                pmap->vecObject[num].pose[3].y = pos.y;
                pmap->vecObject[num].pose[1].x = pos.x;
                QMetaObject::invokeMethod(mMain, "updatecanvas");
            }else if(point == 3){
                ST_FPOINT pos = canvasTomap(x,y);
                pmap->vecObject[num].pose[3].x = pos.x;
                pmap->vecObject[num].pose[3].y = pos.y;
                pmap->vecObject[num].pose[2].y = pos.y;
                pmap->vecObject[num].pose[0].x = pos.x;
                QMetaObject::invokeMethod(mMain, "updatecanvas");
            }
            plog->write("[ANNOTATION] editObject " + QString().sprintf("(%d, %d, %d, %d)",num,point,x,y));
        }else{
            if(point > -1 && point < pmap->vecObject[num].pose.size()){
                ST_FPOINT pos = canvasTomap(x,y);
                pmap->vecObject[num].pose[point].x = pos.x;
                pmap->vecObject[num].pose[point].y = pos.y;
                plog->write("[ANNOTATION] editObject "+ QString().sprintf("(%d, %d, %d, %d)",num,point,x,y));
                QMetaObject::invokeMethod(mMain, "updatecanvas");
            }else{
                plog->write("[ANNOTATION - ERROR] editObject " + QString().sprintf("(%d, %d, %d, %d)",num,point,x,y) + " but pose size error");
            }
        }
    }else{
        plog->write("[ANNOTATION - ERROR] editObject " + QString().sprintf("(%d, %d, %d, %d)",num,point,x,y) + " but size error");
    }
}

void Supervisor::removeObject(int num){
    annotation_edit = true;
    clear_all();
    if(num > -1 && num < pmap->vecObject.size()){
        pmap->vecObject.remove(num);
        setObjPose();
        QMetaObject::invokeMethod(mMain, "updateobject");
        plog->write("[ANNOTATION - ERROR] removeObject " + QString().sprintf("(%d)",num));
    }else{
        plog->write("[ANNOTATION - ERROR] removeObject " + QString().sprintf("(%d)",num) + " but size error");
    }
}

int Supervisor::getTlineSize(){
    return pmap->vecTline.size();
}
int Supervisor::getTlineSize(int num){
    if(num > -1 && num < pmap->vecTline.size()){
        return pmap->vecTline[num].size();
    }else{
        return 0;
    }
}
QString Supervisor::getTlineName(int num){
    if(num > -1 && num < pmap->vecTline.size()){
        return "Travel_line_"+QString::number(num);
    }else{
        return "";
    }
}
float Supervisor::getTlineX(int num, int point){
    if(num > -1 && num < pmap->vecTline.size()){
        ST_FPOINT temp = setAxis(pmap->vecTline[num][point]);
        return temp.x;
    }else{
        return 0;
    }
}
float Supervisor::getTlineY(int num, int point){
    if(num > -1 && num < pmap->vecTline.size()){
        ST_FPOINT temp = setAxis(pmap->vecTline[num][point]);
        return temp.y;
    }else{
        return 0;
    }
}

void Supervisor::addTline(int num, int x1, int y1, int x2, int y2){
    if(num < pmap->vecTline.size() && num > -1){
        pmap->vecTline[num].push_back(canvasTomap(x1,y1));
        pmap->vecTline[num].push_back(canvasTomap(x2,y2));

    }else{
        QVector<ST_FPOINT> temp;
        temp.push_back(canvasTomap(x1,y1));
        temp.push_back(canvasTomap(x2,y2));
        pmap->vecTline.push_back(temp);

    }
    plog->write("[ANNOTATION] ADD Travel Line "+ QString().sprintf("%d : point1(%d, %d), point2(%d, %d)",num,x1,y1,x2,y2));
    QMetaObject::invokeMethod(mMain,"updatetravelline");
}
void Supervisor::removeTline(int num, int line){
    if(num > -1 && num < pmap->vecTline.size()){
        if(line > -1 && line*2+1 < pmap->vecTline[num].size()){
            pmap->vecTline[num].remove(line*2);
            pmap->vecTline[num].remove(line*2);
            if(pmap->vecTline[num].size() < 1){
                pmap->vecTline.remove(num);
                plog->write("[ANNOTATION] REMOVE Travel Line "+ QString().sprintf("%d : line(%d)",num,line));
                QMetaObject::invokeMethod(mMain,"updatetravelline2");
            }else{
                QMetaObject::invokeMethod(mMain,"updatetravelline");
            }
        }
    }
}
int Supervisor::getTlineNum(int x, int y){
    ST_FPOINT temp = canvasTomap(x,y);
    ST_FPOINT uL;
    ST_FPOINT dR;
    if(pmap->vecTline.size() > 0){
        for(int i=0; i<pmap->vecTline[0].size(); i=i+2){
            uL.x = pmap->vecTline[0][i].x;
            uL.y = pmap->vecTline[0][i].y;
            dR.x = pmap->vecTline[0][i].x;
            dR.y = pmap->vecTline[0][i].y;


            if(uL.x < pmap->vecTline[0][i+1].x)
                uL.x = pmap->vecTline[0][i+1].x;
            if(dR.x > pmap->vecTline[0][i+1].x)
                dR.x = pmap->vecTline[0][i+1].x;

            if(uL.y < pmap->vecTline[0][i+1].y)
                uL.y = pmap->vecTline[0][i+1].y;
            if(dR.y > pmap->vecTline[0][i+1].y)
                dR.y = pmap->vecTline[0][i+1].y;

            float margin = 0.3;

            if(temp.x < uL.x+margin && temp.x > dR.x-margin){
                if(temp.y < uL.y+margin && temp.y > dR.y-margin){
                    //match box

                    float ang_line = atan2(uL.y-dR.y,uL.x-dR.x);
    //                qDebug() << i << atan2(uL.y-dR.y,uL.x-dR.x) << fabs(ang_line - atan2(uL.y-temp.y, uL.x-temp.x)) ;
                    if(fabs(ang_line - atan2(uL.y-temp.y, uL.x-temp.x)) < 0.5){
                        return i;
                    }

                }
            }
        }
    }

    return -1;
}
bool Supervisor::saveMetaData(QString filename){
    //기존 파일 백업
//    QString backup = QDir::homePath()+"/maps/"+filename+"/map_meta_backup.ini";
//    QString origin = getMetaPath(filename);
//    if(QFile::exists(origin) == true){
//        if(QFile::copy(origin, backup)){
//            plog->write("[DEBUG] Copy map_meta.ini to map_meta_backup.ini");
//        }else{
//            plog->write("[DEBUG] Fail to copy map_meta.ini to map_meta_backup.ini");
//            return false;
//        }
//    }else{
//        plog->write("[DEBUG] Fail to copy map_meta.ini to map_meta_backup.ini (No file found)");
//        return false;
//    }

    //데이터 입력(맵데이터)
//    QSettings settings(getMetaPath(filename), QSettings::IniFormat);
//    settings.clear();
//    settings.setValue("map_metadata/map_w",pmap->width);
//    settings.setValue("map_metadata/map_h",pmap->height);
//    settings.setValue("map_metadata/map_grid_width",QString::number(pmap->gridwidth));
//    settings.setValue("map_metadata/map_origin_u",pmap->origin[0]);
//    settings.setValue("map_metadata/map_origin_v",pmap->origin[1]);
    return true;

}
bool Supervisor::saveAnnotation(QString filename){
    qDebug() << "SaveAnnotation " << filename;
    //기존 파일 백업
    QString backup = QDir::homePath()+"/maps/"+filename+"/annotation_backup.ini";
    QString origin = getAnnotPath(filename);
    if(QFile::exists(origin) == true){
        if(QFile::copy(origin, backup)){
            plog->write("[DEBUG] Copy annotation.ini to annotation_backup.ini");
        }else{
            plog->write("[DEBUG] Fail to copy annotation.ini to annotation_backup.ini");
        }
    }else{
        plog->write("[DEBUG] Fail to copy annotation.ini to annotation_backup.ini (No file found)");
    }

    //데이터 입력(로케이션)
    int other_num = 0;
    int resting_num = 0;
    int charging_num = 0;
    int serving_num = 0;
    QString str_name;
    QSettings settings(getAnnotPath(filename), QSettings::IniFormat);
    settings.clear();
    for(int i=0; i<pmap->vecLocation.size(); i++){
        if(pmap->vecLocation[i].type == "Resting"){
            str_name = pmap->vecLocation[i].name + QString().sprintf(",%f,%f,%f",pmap->vecLocation[i].pose.x,pmap->vecLocation[i].pose.y,pmap->vecLocation[i].pose.th);
            settings.setValue("resting_locations/loc"+QString::number(resting_num),str_name);
            resting_num++;
        }else if(pmap->vecLocation[i].type == "Other"){
            str_name = pmap->vecLocation[i].name + QString().sprintf(",%f,%f,%f",pmap->vecLocation[i].pose.x,pmap->vecLocation[i].pose.y,pmap->vecLocation[i].pose.th);
            settings.setValue("other_locations/loc"+QString::number(other_num),str_name);
            other_num++;
        }else if(pmap->vecLocation[i].type == "Serving"){
            str_name = pmap->vecLocation[i].name + QString().sprintf(",%f,%f,%f",pmap->vecLocation[i].pose.x,pmap->vecLocation[i].pose.y,pmap->vecLocation[i].pose.th);
            settings.setValue("serving_locations/loc"+QString::number(serving_num),str_name);
            serving_num++;
        }else if(pmap->vecLocation[i].type == "Charging"){
            str_name = pmap->vecLocation[i].name + QString().sprintf(",%f,%f,%f",pmap->vecLocation[i].pose.x,pmap->vecLocation[i].pose.y,pmap->vecLocation[i].pose.th);
            settings.setValue("charging_locations/loc"+QString::number(charging_num),str_name);
            charging_num++;
        }
    }
    settings.setValue("resting_locations/num",resting_num);
    settings.setValue("serving_locations/num",serving_num);
    settings.setValue("other_locations/num",other_num);
    settings.setValue("charging_locations/num",charging_num);

    //데이터 입력(오브젝트)
    int table_num = 0;
    int chair_num = 0;
    int wall_num = 0;
    for(int i=0; i<pmap->vecObject.size(); i++){
        if(pmap->vecObject[i].type == "Table"){
            str_name = pmap->vecObject[i].type + "_" + QString::number(table_num++);
        }else if(pmap->vecObject[i].type == "Chair"){
            str_name = pmap->vecObject[i].type + "_" + QString::number(chair_num++);
        }else if(pmap->vecObject[i].type == "Wall"){
            str_name = pmap->vecObject[i].type + "_" + QString::number(wall_num++);
        }else{
            str_name = pmap->vecObject[i].type;
        }

        if(pmap->vecObject[i].is_rect){
            str_name += ",1";
        }else{
            str_name += ",0";
        }

        for(int j=0; j<pmap->vecObject[i].pose.size(); j++){
            str_name += QString().sprintf(",%f:%f",pmap->vecObject[i].pose[j].x, pmap->vecObject[i].pose[j].y);
        }
        settings.setValue("objects/poly"+QString::number(i),str_name);
    }
    settings.setValue("objects/num",pmap->vecObject.size());

    //데이터 입력(트래블라인)
    for(int i=0; i<pmap->vecTline.size(); i++){
        str_name = "Travel_line_"+QString::number(i);
        for(int j=0; j<pmap->vecTline[i].size(); j++){
            str_name += QString().sprintf(",%f:%f",pmap->vecTline[i][j].x, pmap->vecTline[i][j].y);
        }
        settings.setValue("travel_lines/line"+QString::number(i),str_name);
    }
    settings.setValue("travel_lines/num",pmap->vecTline.size());

    readSetting(filename);
    restartSLAM();
//    lcm->restartSLAM();
    annotation_edit = false;
    return true;
}
void Supervisor::sendMaptoServer(){
    server->sendMap(pmap->map_name);
}



////*********************************************  SCHEDULER(CALLING) 관련   ***************************************************////
void Supervisor::acceptCall(bool yes){

}



////*********************************************  SCHEDULER(SERVING) 관련   ***************************************************////
void Supervisor::setTray(int tray_num, int table_num){
    if(tray_num > -1 && tray_num < setting.tray_num){
        probot->trays[tray_num] = table_num;
        plog->write("[USER INPUT] SERVING START : tray("+QString::number(tray_num)+") = table "+QString::number(table_num));
    }
    ui_cmd = UI_CMD_MOVE_TABLE;
}
void Supervisor::confirmPickup(){
    ui_cmd = UI_CMD_PICKUP_CONFIRM;
}
QVector<int> Supervisor::getPickuptrays(){
    return probot->pickupTrays;
}





////*********************************************  ROBOT MOVE 관련   ***************************************************////
void Supervisor::moveTo(QString target_num){
    lcm->moveTo(target_num);
}
void Supervisor::moveToLast(){
    lcm->moveToLast();
}
void Supervisor::moveTo(float x, float y, float th){
    lcm->moveTo(x,y,th);
}
void Supervisor::movePause(){
    lcm->movePause();
}
void Supervisor::moveResume(){
    lcm->moveResume();
}
void Supervisor::moveStop(){
    lcm->moveStop();
    ui_cmd = UI_CMD_NONE;
    ui_state = UI_STATE_INIT_DONE;
    isaccepted = false;
    QMetaObject::invokeMethod(mMain, "movestopped");
}
void Supervisor::moveManual(){
    lcm->moveManual();
}
void Supervisor::moveToCharge(){
    ui_cmd = UI_CMD_MOVE_CHARGE;
}
void Supervisor::moveToWait(){
    ui_cmd = UI_CMD_MOVE_WAIT;
}
QString Supervisor::getcurLoc(){
    return probot->curLocation;
}
QString Supervisor::getcurTable(){
    if(probot->curLocation.left(7) == "Serving"){
        int table = probot->curLocation.split("_")[1].toInt() + 1;
        qDebug() << probot->curLocation << table;
        return QString::number(table);
    }
    return "0";
}
QVector<float> Supervisor::getcurTarget(){
    QVector<float> temp;
    temp.push_back(probot->curTarget.x);
    temp.push_back(probot->curTarget.y);
    temp.push_back(probot->curTarget.th);
    return temp;
}
void Supervisor::joyMoveXY(float x){
//    qDebug() << "JOY MOVE XY : " << x;
    probot->joystick[0] = x;
    lcm->flagJoystick = true;
}
void Supervisor::joyMoveR(float r){
//    qDebug() << "JOY MOVE R : " << r;
    probot->joystick[1] = r;
    lcm->flagJoystick = true;
}
float Supervisor::getJoyXY(){
    return probot->joystick[0];
}
float Supervisor::getJoyR(){
    return probot->joystick[1];
}

void Supervisor::resetHomeFolders(){
    plog->write("[USER INPUT] RESET HOME FOLDERS");

    QDir lcm_orin(QGuiApplication::applicationDirPath() + "/lcm_types");
    QDir lcm_target(QDir::homePath() + "/lcm_types");

    qDebug() <<QGuiApplication::applicationDirPath() + "/lcm_types";
    qDebug() <<QDir::homePath() + "/lcm_types";
    if(lcm_orin.exists()){
        if(!lcm_target.exists()){
            plog->write("[SUPERVISOR] MAKE LCM_TYPES FOLDER INTO HOME");
            lcm_target.mkpath(".");
        }

        QStringList files = lcm_orin.entryList(QDir::Files);
        for(int i=0; i<files.count(); i++){
            qDebug() << QGuiApplication::applicationDirPath() + "/lcm_types/" + files[i];
            qDebug() << QDir::homePath() + "/lcm_types/" + files[i];
            QFile::copy(QGuiApplication::applicationDirPath() + "/lcm_types/" + files[i],
                        QDir::homePath() + "/lcm_types/" + files[i]);
            plog->write("[SUPERVISOR] COPY LCM_TYPES : " + files[i]);
        }
        files.clear();
    }
}


////*********************************************  ROBOT STATUS 관련   ***************************************************////
float Supervisor::getBattery(){
    return probot->battery_out;
}
bool Supervisor::getMotorConnection(int id){
    return probot->motor[id].connection;
}
int Supervisor::getMotorStatus(int id){
    return probot->motor[id].status;
}
QString Supervisor::getMotorStatusStr(int id){
    if(probot->motor[id].status == 0){
        return " ";
    }else{
        QString str = "";
        if(MOTOR_RUN(probot->motor[id].status) == 1)
            str += "RUN";

        if(MOTOR_MOD_ERROR(probot->motor[id].status) == 1)
            str += " MOD";

        if(MOTOR_JAM_ERROR(probot->motor[id].status) == 1)
            str += " JAM";

        if(MOTOR_CUR_ERROR(probot->motor[id].status) == 1)
            str += " CUR";

        if(MOTOR_BIG_ERROR(probot->motor[id].status) == 1)
            str += " BIG";

        if(MOTOR_INP_ERROR(probot->motor[id].status) == 1)
            str += " INP";

        if(MOTOR_PS_ERROR(probot->motor[id].status) == 1)
            str += " PS";

        if(MOTOR_COL_ERROR(probot->motor[id].status) == 1)
            str += " COL";

        return str;
    }
}
int Supervisor::getMotorTemperature(int id){
    return probot->motor[id].temperature;
}
int Supervisor::getMotorWarningTemperature(){
    return 50;
}
int Supervisor::getPowerStatus(){
    return probot->status_power;
}
int Supervisor::getRemoteStatus(){
    return probot->status_remote;
}
int Supervisor::getChargeStatus(){
    return probot->status_charge;
}
int Supervisor::getEmoStatus(){
    return probot->status_emo;
}
float Supervisor::getBatteryIn(){
    return probot->battery_in;
}
float Supervisor::getBatteryOut(){
    return probot->battery_out;
}
float Supervisor::getBatteryCurrent(){
    return probot->battery_cur;
}
float Supervisor::getPower(){
    return probot->power;
}
float Supervisor::getPowerTotal(){
    return probot->total_power;
}
int Supervisor::getMotorState(){
    return probot->motor_state;
}
int Supervisor::getObsState(){
    return probot->obs_state;
}
int Supervisor::getLocalizationState(){
    return probot->localization_state;
}
int Supervisor::getStateMoving(){
    return probot->running_state;
}
int Supervisor::getErrcode(){
    return probot->err_code;
}
QString Supervisor::getRobotName(){
    if(is_debug){
        return robot.name + "_" + robot.name_debug;
    }else{
        return robot.name;
    }
}

float Supervisor::getRobotRadius(){
    return probot->radius;
}
float Supervisor::getRobotx(){
    ST_POSE temp = setAxis(probot->curPose);
    return temp.x;
}
float Supervisor::getRoboty(){
    ST_POSE temp = setAxis(probot->curPose);
    return temp.y;
}
float Supervisor::getRobotth(){
    ST_POSE temp = setAxis(probot->curPose);
    return temp.th;
}
float Supervisor::getlastRobotx(){
    ST_POSE temp = setAxis(probot->lastPose);
    return temp.x;
}
float Supervisor::getlastRoboty(){
    ST_POSE temp = setAxis(probot->lastPose);
    return temp.y;
}
float Supervisor::getlastRobotth(){
    ST_POSE temp = setAxis(probot->lastPose);
    return temp.th;
}
int Supervisor::getPathNum(){
    if(lcm->flagPath){
        return 0;
    }else{
        return probot->pathSize;
    }
}
float Supervisor::getPathx(int num){
    if(lcm->flagPath){
        return 0;
    }else{
        ST_POSE temp = setAxis(probot->curPath[num]);
        return temp.x;
    }
}
float Supervisor::getPathy(int num){
    if(lcm->flagPath){
        return 0;
    }else{
        ST_POSE temp = setAxis(probot->curPath[num]);
        return temp.y;
    }
}
float Supervisor::getPathth(int num){
    if(lcm->flagPath){
        return 0;
    }else{
        ST_POSE temp = setAxis(probot->curPath[num]);
        return temp.th;
    }
}
int Supervisor::getLocalPathNum(){
    return probot->localpathSize;

}
float Supervisor::getLocalPathx(int num){
    ST_POSE temp = setAxis(probot->localPath[num]);
    return temp.x;

}
float Supervisor::getLocalPathy(int num){
    ST_POSE temp = setAxis(probot->localPath[num]);
    return temp.y;
}

int Supervisor::getuistate(){
    return ui_state;
}

void Supervisor::initdone(){
    plog->write("[INIT] INIT DONE : UI_STATE -> INIT DONE");
    ui_state = UI_STATE_INIT_DONE;
}


////*********************************************  MAP IMAGE 관련   ***************************************************////
QString Supervisor::getMapname(){
    return pmap->map_name;
}
QString Supervisor::getMappath(){
    return pmap->map_path;
}
QString Supervisor::getServerMappath(){
    return QDir::homePath() + "/maps/"+server->server_map_name;
}
QString Supervisor::getServerMapname(){
    return server->server_map_name;
}
int Supervisor::getMapWidth(){
    return pmap->width;
}
int Supervisor::getMapHeight(){
    return pmap->height;
}
float Supervisor::getGridWidth(){
//    qDebug() << pmap->gridwidth;
    return pmap->gridwidth;
}
QVector<int> Supervisor::getOrigin(){
    QVector<int> temp;
    temp.push_back(pmap->origin[0]);
    temp.push_back(pmap->origin[1]);
    return temp;
}

////*********************************************  PATROL 관련   ***************************************************////
QString Supervisor::getPatrolFileName(){
    if(patrol.filename == ""){
        return patrol.filename;
    }else{
        QFile *file  = new QFile(patrol.filename);
        if(file->open(QIODevice::ReadOnly)){

            QStringList namelist = patrol.filename.split("/");
            QStringList name = namelist[namelist.size()-1].split(".");
            return name[0];
        }else{
            return "";
        }
    }
}
void Supervisor::makePatrol(){
    plog->write("[USER INPUT] Make New Patrol");
    setSetting("PATROL/curfile","");
    patrol.path.clear();
    patrol.filename = "";
}
void Supervisor::loadPatrolFile(QString path){
    QStringList list1 = path.split("/");
    QStringList list = list1[list1.size()-1].split(".");
    if(list.size() == 1){
        path = QDir::homePath()+"/patrols/" + list1[list1.size()-1] + ".ini";
    }else{
        path = QDir::homePath()+"/patrols/" + list1[list1.size()-1];
    }
    plog->write("[USER INPUT] Load Patrol : "+path);
    QSettings patrols(path, QSettings::IniFormat);
    patrol.path.clear();
    patrol.filename = path;
    ST_PATROL temp;
    patrols.beginGroup("PATH");
    int num = patrols.value("num").toInt();
    patrol.mode = patrols.value("mode").toInt();
    for(int i=0; i<num; i++){
        temp.type = patrols.value("type_"+QString::number(i)).toString();
        temp.location = patrols.value("location_"+QString::number(i)).toString();
        temp.pose.x = patrols.value("x_"+QString::number(i)).toFloat();
        temp.pose.y = patrols.value("y_"+QString::number(i)).toFloat();
        temp.pose.th = patrols.value("th_"+QString::number(i)).toFloat();
        patrol.path.push_back(temp);
    }
    patrols.endGroup();
    setSetting("PATROL/curfile",path);
}
void Supervisor::savePatrolFile(QString path){
    QStringList list1 = path.split("/");
    QStringList list = list1[list1.size()-1].split(".");
    if(list.size() == 1){
        path = QDir::homePath()+"/patrols/" + list1[list1.size()-1] + ".ini";
    }else{
        path = QDir::homePath()+"/patrols/" + list1[list1.size()-1];
    }
    plog->write("[USER INPUT] Save Patrol : "+path);
    QSettings patrols(path, QSettings::IniFormat);
    patrols.clear();
    for(int i=0; i<patrol.path.size(); i++){
        patrols.setValue("PATH/type_"+QString::number(i),patrol.path[i].type);
        patrols.setValue("PATH/location_"+QString::number(i),patrol.path[i].location);
        patrols.setValue("PATH/x_"+QString::number(i),QString::number(patrol.path[i].pose.x));
        patrols.setValue("PATH/y_"+QString::number(i),QString::number(patrol.path[i].pose.y));
        patrols.setValue("PATH/th_"+QString::number(i),QString::number(patrol.path[i].pose.th));
    }
    patrols.setValue("PATH/num",patrol.path.size());
    patrols.setValue("PATH/mode",QString::number(patrol.mode));

    setSetting("PATROL/curfile",path);
}
void Supervisor::addPatrol(QString type, QString location, float x, float y, float th){
    ST_PATROL temp;

    temp.type = type;
    temp.location = location;
    qDebug() << type << location;

    if(temp.location == "MANUAL"){
        ST_FPOINT temp1 = canvasTomap(x,y);
        temp.pose.x = temp1.x;
        temp.pose.y = temp1.y;
        temp.pose.th = th;
        patrol.path.push_back(temp);
        plog->write("[USER INPUT] Add Patrol Pose : "+QString().sprintf("%f, %f, %f",temp.pose.x, temp.pose.y, temp.pose.th));
    }else{
        for(int i=0; i<pmap->vecLocation.size(); i++){
            if(pmap->vecLocation[i].name == temp.location){
                temp.pose.x = pmap->vecLocation[i].pose.x;
                temp.pose.y = pmap->vecLocation[i].pose.y;
                temp.pose.th = pmap->vecLocation[i].pose.th;
                patrol.path.push_back(temp);
                plog->write("[USER INPUT] Add Patrol Location : "+location);
                break;
            }
        }
    }
}
void Supervisor::removePatrol(int num){
    clear_all();
    if(num > -1 && num < patrol.path.size()){
        patrol.path.remove(num);
        plog->write("[USER INPUT] Remove Patrol : "+QString::number(num));
    }
}
void Supervisor::movePatrolUp(int num){
    if(num > 1 && num < patrol.path.size()){
        ST_PATROL temp = patrol.path[num];
        patrol.path.remove(num);
        patrol.path.insert(num-1,temp);
        plog->write("[USER INPUT] Move Up Patrol : "+QString::number(num));
    }
}
void Supervisor::movePatrolDown(int num){
    if(num > 0 && num < patrol.path.size()-1){
        ST_PATROL temp = patrol.path[num];
        patrol.path.remove(num);
        patrol.path.insert(num+1,temp);
        plog->write("[USER INPUT] Move Down Patrol : "+QString::number(num));
    }
}
int Supervisor::getPatrolMode(){
    return patrol.mode;
}
void Supervisor::setPatrolMode(int mode){
    patrol.mode = mode;
    plog->write("[USER INPUT] SET Patrol Mode : "+QString::number(mode));
    QMetaObject::invokeMethod(mMain, "updatepatrol");
}
int Supervisor::getPatrolNum(){
    return patrol.path.size();
}
QString Supervisor::getPatrolType(int num){
    if(num > -1 && num < patrol.path.size()){
        return patrol.path[num].type;
    }else{
        return "";
    }
}
QString Supervisor::getPatrolLocation(int num){
    if(num > -1 && num < patrol.path.size()){
        return patrol.path[num].location;
    }else{
        return "";
    }
}
float Supervisor::getPatrolX(int num){
    if(num > -1 && num < patrol.path.size()){
        ST_POSE temp = setAxis(patrol.path[num].pose);
        return temp.x;
    }else{
        return 0;
    }
}
float Supervisor::getPatrolY(int num){
    if(num > -1 && num < patrol.path.size()){
        ST_POSE temp = setAxis(patrol.path[num].pose);
        return temp.y;
    }else{
        return 0;
    }
}
float Supervisor::getPatrolTH(int num){
    if(num > -1 && num < patrol.path.size()){
        ST_POSE temp = setAxis(patrol.path[num].pose);
        return temp.th;
    }else{
        return 0;
    }
}

void Supervisor::startRecordPath(){

}
void Supervisor::startcurPath(){

}
void Supervisor::stopcurPath(){

}
void Supervisor::pausecurPath(){

}

void Supervisor::runRotateTables(){
    plog->write("[USER INPUT] START ROTATE TABLES");
    ui_cmd = UI_CMD_TABLE_PATROL;
    state_rotate_tables = 1;
}
void Supervisor::stopRotateTables(){
    plog->write("[USER INPUT] STOP ROTATE TABLES");
    ui_cmd = UI_CMD_PATROL_STOP;
}
void Supervisor::startServingTest(){
    plog->write("[USER INPUT] START PATROL SERVING");
    ui_cmd = UI_CMD_MOVE_TABLE;
    flag_patrol_serving = true;
}
void Supervisor::stopServingTest(){
    plog->write("[USER INPUT] STOP PATROL SERVING");
    flag_patrol_serving = false;
    moveStop();
}

//// *********************************** SLOTS *********************************** ////
void Supervisor::server_cmd_setini(){
    readSetting();
}
void Supervisor::server_get_map(){
    readSetting(server->server_map_name);
    QMetaObject::invokeMethod(mMain, "loadmap_server_success");
}
void Supervisor::path_changed(){
    QMetaObject::invokeMethod(mMain, "updatepath");
}
void Supervisor::camera_update(){
    QMetaObject::invokeMethod(mMain, "updatecamera");
}
void Supervisor::mapping_update(){
    QMetaObject::invokeMethod(mMain, "updatemapping");
}
void Supervisor::objecting_update(){
    QMetaObject::invokeMethod(mMain, "updateobjecting");
}
void Supervisor::server_cmd_pause(){
    plog->write("[SERVER] PAUSE");
    lcm->movePause();
    QMetaObject::invokeMethod(mMain, "pausedcheck");
}
void Supervisor::server_cmd_resume(){
    plog->write("[SERVER] RESUME");
    lcm->moveResume();
    QMetaObject::invokeMethod(mMain, "pausedcheck");
}
void Supervisor::server_cmd_newtarget(){
    plog->write("[SERVER] NEW TARGET !!" + QString().sprintf("%f, %f, %f",probot->targetPose.x, probot->targetPose.y, probot->targetPose.th));
    if(ui_state == UI_STATE_PATROLLING)
        state_rotate_tables = 4;
    lcm->moveTo(probot->targetPose.x, probot->targetPose.y, probot->targetPose.th);
}
void Supervisor::server_cmd_newcall(){
    ui_cmd = UI_CMD_MOVE_CALLING;
//    QMetaObject::invokeMethod(mMain,"newcall");
}


//// *********************************** TIMER *********************************** ////
void Supervisor::onTimer(){
    // QML 오브젝트 매칭
    if(mMain == nullptr && object != nullptr){
        setObject(object);
        setWindow(qobject_cast<QQuickWindow*>(object));
    }

    static int count_pass = 0;
    // usb 파일 확인
    if(usb_check){
        if(usb_check_count++ > 15){
            usb_check = false;
        }else{
            std::string user = getenv("USER");
            std::string path = "/media/" + user;
            QDir directory(path.c_str());
            QStringList FilesList = directory.entryList();
            usb_map_list.clear();
            for(int i=0; i<FilesList.size(); i++){
                std::string path1 = path + "/";
                QString path_usb = path1.c_str() + FilesList[i];
                QDir directory1(path_usb);
                QStringList FilesList2 = directory1.entryList();
                for(int j=0; j<FilesList2.size(); j++){
                    if(FilesList2[j].left(7) == "raw_map"){
                        usb_map_list.push_back(path_usb +  "/" + FilesList2[j]);
                    }else if(FilesList2[j].left(4) == "map_"){
                        usb_map_list.push_back(path_usb + "/" + FilesList2[j]);
                    }
                }
            }

            if(usb_map_list.size() > 0){
                qDebug() << usb_map_list;
                usb_check = false;
                usb_check_count = 0;
            }
        }
    }
    // 스케줄러 변수 초기화
    static int prev_error = -1;
    static int prev_state = -1;
    static int prev_running_state = -1;
    static int prev_motor_state = -1;
    static int prev_local_state = -1;

    static int state_count = 0;

    if(lcm->isconnect){
        if(ui_state != UI_STATE_NONE){
            state_count = 0;
            if(probot->status_charge == 1){
                if(ui_state != UI_STATE_CHARGING){
                    plog->write("[LCM] Charging Start -> UI_STATE = UI_STATE_CHARGING");
                    ui_state = UI_STATE_CHARGING;
                    QMetaObject::invokeMethod(mMain, "docharge");
                }
            }else if(probot->motor_state == MOTOR_NOT_READY){
                if(prev_motor_state != probot->motor_state){
                    plog->write("[LCM] MOTOR NOT READY -> UI_STATE = UI_STATE_MOVEFAIL");
                    if(ui_state != UI_STATE_MOVEFAIL){
                        ui_state = UI_STATE_MOVEFAIL;
                    }
                }
            }else if(probot->localization_state == LOCAL_NOT_READY){
                if(prev_local_state != probot->localization_state){
                    plog->write("[LCM] LOCAL NOT READY -> UI_STATE = UI_STATE_MOVEFAIL");
                    if(ui_state != UI_STATE_MOVEFAIL){
                        ui_state = UI_STATE_MOVEFAIL;
                    }
                }
            }else if(probot->localization_state == LOCAL_FAILED){
                if(prev_local_state != probot->localization_state){
                    plog->write("[LCM] LOCAL FAILED -> UI_STATE = UI_STATE_MOVEFAIL");
                    if(ui_state != UI_STATE_MOVEFAIL){
                        ui_state = UI_STATE_MOVEFAIL;
                    }
                }
            }else if(probot->running_state == ROBOT_MOVING_NOT_READY){
                if(prev_running_state != probot->running_state){
                    if(ui_state != UI_STATE_MOVEFAIL){
                        plog->write("[LCM] RUNNING NOT READY -> UI_STATE = UI_STATE_MOVEFAIL");
                        ui_state = UI_STATE_MOVEFAIL;
                    }
                }
            }else if(probot->running_state == ROBOT_MOVING_WAIT){
                plog->write("[SCHEDULER] ROBOT ERROR : EXCUSE ME");
                QMetaObject::invokeMethod(mMain, "excuseme");
            }else if(probot->motor_state == MOTOR_READY && probot->localization_state == LOCAL_READY){
                if(ui_state == UI_STATE_INIT_DONE){
                    plog->write("[LCM] INIT ALL DONE -> UI_STATE = UI_STATE_READY");
                    ui_state = UI_STATE_READY;
                }
            }
        }else{
            if(probot->motor_state == MOTOR_READY && probot->localization_state == LOCAL_READY){
                if(state_count++ > 10){
                    plog->write("[LCM] INIT ALL DONE? -> UI_STATE = UI_STATE_READY");
                    ui_state = UI_STATE_READY;
                    state_count = 0;
                }
            }
        }
    }else{
        // 로봇연결이 끊어졌는데 ui_state가 NONE이 아니면
        if(ui_state != UI_STATE_NONE){
            plog->write("[LCM] DISCONNECT -> UI_STATE = NONE");
            ui_state = UI_STATE_NONE;
            QMetaObject::invokeMethod(mMain, "stateinit");
        }
    }


    switch(ui_state){
    case UI_STATE_NONE:{
        if(probot->running_state == ROBOT_MOVING_PAUSED){
            lcm->moveStop();
        }
        break;
    }
    case UI_STATE_INIT_DONE:{
        ui_cmd = UI_CMD_NONE;
        break;
    }
    case UI_STATE_READY:{
        if(ui_cmd == UI_CMD_MOVE_TABLE){
            plog->write("[SUPERVISOR] UI_STATE = SERVING");
            ui_state = UI_STATE_SERVING;
            ui_cmd = UI_CMD_NONE;
        }else if(ui_cmd == UI_CMD_MOVE_CHARGE){
            plog->write("[SUPERVISOR] UI_STATE = GO CHARGE");
            ui_state = UI_STATE_GO_CHARGE;
            ui_cmd = UI_CMD_NONE;
        }else if(ui_cmd == UI_CMD_MOVE_WAIT){
            plog->write("[SUPERVISOR] UI_STATE = GO HOME");
            ui_state = UI_STATE_GO_HOME;
            ui_cmd = UI_CMD_NONE;
        }else if(ui_cmd == UI_CMD_TABLE_PATROL){
            plog->write("[SUPERVISOR] UI_STATE = PATROLLING");
            ui_state = UI_STATE_PATROLLING;
            ui_cmd = UI_CMD_NONE;
        }else if(ui_cmd == UI_CMD_MOVE_CALLING){
            plog->write("[SUPERVISOR] UI_STATE = CALLING");
            ui_state = UI_STATE_CALLING;
            probot->call_moving_count = 0;
            ui_cmd = UI_CMD_NONE;
        }
        break;
    }
    case UI_STATE_CHARGING:{
        flag_patrol_serving = false;
        if(probot->status_charge == 0){
            ui_state = UI_STATE_NONE;
        }
        break;
    }
    case UI_STATE_GO_HOME:{
        flag_patrol_serving = false;
        if(probot->running_state == ROBOT_MOVING_READY){
            if(isaccepted){
                ui_cmd = UI_CMD_NONE;
                if(probot->type == "SERVING"){
                    QMetaObject::invokeMethod(mMain, "waitkitchen");
                    ui_state = UI_STATE_READY;
                }else{
                    QMetaObject::invokeMethod(mMain, "clearkitchen");
                    ui_state = UI_STATE_READY;
                }
                isaccepted = false;
            }else{
                lcm->moveTo("Resting_0");
            }
        }else if(probot->running_state == ROBOT_MOVING_MOVING){
            // moving
            if(!isaccepted){
                isaccepted = true;
                QMetaObject::invokeMethod(mMain, "movelocation");
            }
        }
        break;
    }
    case UI_STATE_GO_CHARGE:{
        flag_patrol_serving = false;
        if(probot->running_state == ROBOT_MOVING_READY){
            if(isaccepted){
                ui_cmd = UI_CMD_NONE;
                isaccepted = false;
                ui_state = UI_STATE_CHARGING;
                QMetaObject::invokeMethod(mMain, "docharge");
            }else{
                lcm->moveTo("Charging_0");
            }
        }else if(probot->running_state == ROBOT_MOVING_MOVING){
            // moving
            if(!isaccepted){
                isaccepted = true;
                QMetaObject::invokeMethod(mMain, "movelocation");
            }
        }
        break;
    }
    case UI_STATE_SERVING:{
        if(probot->running_state == ROBOT_MOVING_READY){
            //Check Done Signal
            if(isaccepted){
                count_pass = 0;
                ui_state = UI_STATE_PICKUP;
                int curNum = 0;
                probot->pickupTrays.clear();
                for(int i=0; i<setting.tray_num; i++){
                    if(probot->trays[i] == curNum){
                        probot->trays[i] = 0;
                        if(curNum != 0)
                            probot->pickupTrays.push_back(i+1);
                    }else if(curNum == 0){
                        curNum = probot->trays[i];
                        probot->pickupTrays.push_back(i+1);
                        probot->trays[i] = 0;
                    }
                }
                plog->write("[SCHEDULER] SERVING : PICK UP (Table"+QString::number(curNum)+")");
                QMetaObject::invokeMethod(mMain, "showpickup");
                isaccepted = false;
            }else{
                // move start
                static int timer_cnt = 0;
                if(flag_patrol_serving){
                    //시연용 가라모션
                    static int table_num_last = 0;
                    if(timer_cnt%5 == 0){
                        int temp = qrand();
                        qDebug() << "First temp = " << temp << setting.table_num << temp%(setting.table_num);
                        while(table_num_last == temp%(setting.table_num)){
                            temp = qrand();
                            qDebug() << "Next temp = " << temp << temp%(setting.table_num);
                        }
                        int table_num = temp%(setting.table_num);
                        qDebug() << "Move To " << "Serving_"+QString().sprintf("%d",table_num);
                        lcm->moveTo("Serving_"+QString().sprintf("%d",table_num));
                        table_num_last = table_num;
                    }
                }else{
                    bool serveDone = true;
                    if(timer_cnt%5==0){
                        for(int i=0; i<setting.tray_num; i++){
                            if(probot->trays[i] != 0){
                                plog->write("[SCHEDULER] SERVING : MOVE TO (Table"+QString::number(probot->trays[i])+")");
                                lcm->moveTo("Serving_"+QString().sprintf("%d",probot->trays[i]-1));
                                serveDone = false;
                                break;
                            }
                        }
                        if(serveDone){
                            // move done -> move to wait
                            plog->write("[SCHEDULER] SERVING : SERVE DONE");
                            ui_state = UI_STATE_GO_HOME;
                        }
                    }
                }
                timer_cnt++;
            }
        }else if(probot->running_state == ROBOT_MOVING_MOVING){
            // moving
            if(!isaccepted){
                isaccepted = true;
                plog->write("[SCHEDULER] SERVING : MOVE START");
                QMetaObject::invokeMethod(mMain, "movelocation");
            }
        }
        break;
    }
    case UI_STATE_CALLING:{
        flag_patrol_serving = false;
        if(probot->running_state == ROBOT_MOVING_READY){
            if(isaccepted){//도착
                plog->write("[SCHEDULER] CALLING MOVE ARRIVED "+call_list[0]);
                ui_state = UI_STATE_PICKUP;
                call_list.pop_front();
                probot->call_moving_count++;
                QMetaObject::invokeMethod(mMain, "showpickup");
                isaccepted = false;
            }else{//출발
                static int timer_cnt = 0;
                bool moveDone = false;

                if(timer_cnt%5==0){
                    //최대 이동 횟수 초과 시 -> 대기장소로 이동
                    if(probot->call_moving_count > probot->max_moving_count){
                        plog->write("[SCHEDULER] CALLING MOVE DONE(MAX MOVING)");
                        moveDone = true;
                    }

                    //call_list 비어있으면 -> 대기장소로 이동(혹은 패트롤 재시작)
                    if(call_list.size() == 0){
                        plog->write("[SCHEDULER] CALLING MOVE DONE(NO LIST)");
                        moveDone = true;
                    }

                    if(moveDone){
                        ui_state = UI_STATE_GO_HOME;
                        probot->call_moving_count = 0;
                    }else{
                        //call_list에서 타겟 지정 후 move
                        QString cur_target = getCallName(call_list[0]);
                        plog->write("[SCHEDULER] CALLING MOVE TO "+cur_target);
                        lcm->moveTo(cur_target);
                    }
                }
                timer_cnt++;
            }
        }else if(probot->running_state == ROBOT_MOVING_MOVING){
            // moving
            if(!isaccepted){
                isaccepted = true;
                plog->write("[SCHEDULER] CALLING : MOVE START");
                QMetaObject::invokeMethod(mMain, "movelocation");
            }
        }
        break;
    }
    case UI_STATE_CLEAR:{
        break;
    }
    case UI_STATE_PICKUP:{
        if(probot->running_state == ROBOT_MOVING_PAUSED){
            lcm->moveResume();
        }
        if(flag_patrol_serving){
            count_pass++;
            if(count_pass > 30){
                ui_state = UI_STATE_SERVING;
                ui_cmd = UI_CMD_NONE;
            }
        }
        if(ui_cmd == UI_CMD_PICKUP_CONFIRM){
            if(probot->type == "SERVING"){
                ui_state = UI_STATE_SERVING;
                ui_cmd = UI_CMD_NONE;
            }else{
                ui_state = UI_STATE_CALLING;
                ui_cmd = UI_CMD_NONE;
            }
        }
        break;
    }
    case UI_STATE_PATROLLING:{
        // 테스트용 테이블 로테이션
            if(ui_cmd == UI_CMD_TABLE_PATROL){
                state_rotate_tables = 1;
                ui_cmd = UI_CMD_NONE;
            }else if(ui_cmd == UI_CMD_PATROL_STOP){
                ui_cmd = UI_CMD_NONE;
                if(state_rotate_tables != 0){
                    ui_state = UI_STATE_NONE;
                    lcm->moveStop();
                    state_rotate_tables = 0;
                }
            }
            static int table_num_last = 0;
            switch(state_rotate_tables){
            case 1:
            {//Start
                if(probot->running_state == ROBOT_MOVING_READY){
                    ui_state = UI_STATE_PATROLLING;
                    int table_num = qrand()%5;
                    while(table_num_last == table_num){
                        table_num = qrand()%5;
                    }
                    qDebug() << "Move To " << "Serving_"+QString().sprintf("%d",table_num);
                    lcm->moveTo("Serving_"+QString().sprintf("%d",table_num));
                    state_rotate_tables = 2;
                    table_num_last = table_num;
                }
                break;
            }
            case 2:
            {//Wait State Change
                static int timer_cnt = 0;
                if(probot->running_state == ROBOT_MOVING_MOVING){
                    qDebug() << "Moving Start";
                    state_rotate_tables = 3;
                }else{
                    if(timer_cnt%10==0){
                        lcm->moveTo("Serving_"+QString().sprintf("%d",table_num_last));
                    }
                }
                break;
            }
            case 3:
            {
                if(probot->running_state == ROBOT_MOVING_READY){
                    //move done
                    qDebug() << "Move Done!!";
                    state_rotate_tables = 1;
                }
                break;
            }
            case 4:
            {//server new target
                if(probot->running_state == ROBOT_MOVING_READY){
                    state_rotate_tables = 5;
                }//confirm

                break;
            }
            case 5:{
                if(probot->running_state == ROBOT_MOVING_MOVING){
                    qDebug() << "Moving Start";
                    state_rotate_tables = 3;
                }
                break;
            }
        }
        break;
    }
    case UI_STATE_MOVEFAIL:{
        flag_patrol_serving = false;
        if(prev_motor_state != probot->motor_state){
            //UI에 movefail 페이지 표시
            flag_patrol_serving = false;
            QMetaObject::invokeMethod(mMain, "movefail");
            if(probot->motor_state == MOTOR_NOT_READY){
                plog->write("[SCHEDULER] ROBOT ERROR :ROBOT_INIT_NOT_READY");
            }
        }else if(prev_local_state != probot->localization_state){
            //UI에 movefail 페이지 표시
            QMetaObject::invokeMethod(mMain, "movefail");
            if(probot->localization_state == LOCAL_NOT_READY){
                plog->write("[SCHEDULER] ROBOT ERROR : LOCAL NOT READY");

            }else if(probot->localization_state == LOCAL_FAILED){
                plog->write("[SCHEDULER] ROBOT ERROR : ROBOT_INIT_LOCAL_FAILED");

            }
        }else{
            //UI에 movefail 페이지 표시
            QMetaObject::invokeMethod(mMain, "movefail");
            if(probot->motor_state == MOTOR_READY && probot->localization_state == LOCAL_READY && isaccepted){
                plog->write("[SCHEDULER] ROBOT ERROR : NO PATH");
                isaccepted = false;
            }
        }
        break;
    }
    }

    prev_state = ui_state;
    prev_running_state = probot->running_state;
    prev_motor_state = probot->motor_state;
    prev_local_state = probot->localization_state;

//    // 로봇 상태가 에러가 아니면 에러 초기화
//    if(probot->state != ROBOT_STATE_ERROR)
//        cur_error = ROBOT_ERROR_NONE;
//    static int count_test = 0;
//    qDebug() << count_test++;
}








