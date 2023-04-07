import QtQuick 2.12
import QtQuick.Shapes 1.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.2
import Qt.labs.platform 1.0 as Platform
import QtQuick.Shapes 1.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.12
import "."
import io.qt.Supervisor 1.0

Item {
    id: page_movefail
    objectName: "page_movefail"
    width: 1280
    height: 800
    property bool joystick_connection: false
    property var joy_axis_left_ud: 0
    property var joy_axis_right_rl: 0

    function setNotice(num){
        notice_num = num;
    }

    //0: no path /1: local fail /2: emergency /3: user stop /4: motor error
    property int notice_num: 0
    onNotice_numChanged: {
        if(notice_num === 0){
            text.text = "목적지로 이동하는데 실패하였습니다.\비상스위치 버튼을 누르고 로봇을 수동으로 이동시켜주세요."
        }else if(notice_num === 1){
            text.text = "로봇의 초기화가 필요합니다.\n 위치초기화를 다시 수행해주세요."
        }else if(notice_num === 2){
            text.text = "비상스위치가 눌렸습니다.\n 로봇을 수동으로 이동시켜주세요."
        }else if(notice_num === 3){
            text.text = "사용자에 의해 정지되었습니다."
        }else if(notice_num === 4){
            text.text = "목적지로 이동하는데 실패하였습니다.\n 비상스위치 버튼을 누르고 로봇을 수동으로 이동시켜주세요."
        }
    }

    property bool select_localmode: false
    onSelect_localmodeChanged: {
        map.init_mode();
        map.show_buttons = true;
        map.show_connection = true;
        map.robot_following = true;
        map.show_lidar = true;
        map.show_path = true;
        map.show_object = true;
        if(select_localmode)
            map.show_location = true;
        map.show_robot = true;
    }

    Component.onCompleted: {
        init();
    }

    function init(){
        supervisor.writelog("[QML] MOVEFAIL PAGE init")
        notice_num = 0;
        statusbar.visible = true;
        notice.y = 0;
        area_swipe.enabled = true;
        map.init_mode();
        map.show_buttons = true;
        map.show_connection = true;
        map.robot_following = true;
        map.show_lidar = true;
        map.show_path = true;
        map.show_object = true;
        if(select_localmode)
            map.show_location = true;
        map.show_robot = true;
    }

    SequentialAnimation{
        id: ani_swipe
        running: true;
        loops: Animation.Infinite
        ParallelAnimation{
            NumberAnimation{target: image_swipe; property: "opacity"; to:1; duration: 1000; easing.type: Easing.OutCubic}
            NumberAnimation{target: image_swipe; property: "anchors.bottomMargin"; to:80; from: 40; duration: 1000; easing.type: Easing.OutCubic}
        }
        ParallelAnimation{
            NumberAnimation{target: image_swipe; property: "opacity"; to:0.2; duration: 600; easing.type: Easing.OutCubic}
            NumberAnimation{target: image_swipe; property: "anchors.bottomMargin"; to:40; duration: 600; easing.type: Easing.OutCubic}
        }
    }


    Item{
        id: manual
        width: 1280
        height: 800
        anchors.top: notice.bottom

        Rectangle{
            anchors.fill: parent
            color:"#282828"
        }
        Rectangle{
            id: rect_state
            height: parent.height
            width: parent.width - rect_menu1.width - map.width
            anchors.top: parent.top
            anchors.topMargin: statusbar.height
            color: color_dark_navy
            Column{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 50
                spacing: 30
                Rectangle{
                    id: btn_reset
                    width: 90
                    height: 80
                    radius: 5
                    enabled: false
                    color: enabled?"white":color_gray
                    Column{
                        anchors.centerIn: parent
                        spacing: 5
                        Image{
                            source: "icon/icon_run.png"
                            sourceSize.width: 40
                            sourceSize.height: 40
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text{
                            text: "다시 시작"
                            color:btn_reset.enabled?"black":"white"
                            font.family: font_noto_r.name
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    DropShadow{
                        anchors.fill: parent
                        radius: 5
                        color: color_navy
                        source: parent
                        visible:btn_reset.enabled?true:false
                        z: -1
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                            supervisor.writelog("[USER INPUT] MOVEFAIL PAGE : RESTART")
                            supervisor.moveStop();
                        }
                    }
                }
                Rectangle{
                    width: 90
                    height: 80
                    radius: 5
                    border.width: select_localmode?3:0
                    border.color: color_green
                    Column{
                        anchors.centerIn: parent
                        spacing: 5
                        Image{
                            source: "image/image_localization.png"
                            sourceSize.width: 40
                            sourceSize.height: 40
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text{
                            font.pixelSize: 15
                            text: "Localization"
                            font.family: font_noto_r.name
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    DropShadow{
                        anchors.fill: parent
                        radius: 3
                        color: color_navy
                        source: parent
                        z: -1
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                            if(select_localmode){
                                supervisor.writelog("[USER INPUT] MOVEFAIL PAGE : LOCALIZATION STOP")
                                select_localmode = false;
                            }else{
                                supervisor.writelog("[USER INPUT] MOVEFAIL PAGE : LOCALIZATION START")
                                select_localmode = true;
                            }
                        }
                    }
                }
                Rectangle{
                    width: 90
                    height: 80
                    radius: 5
                    Column{
                        anchors.centerIn: parent
                        spacing: 5
                        Image{
                            source: "icon/icon_power.png"
                            sourceSize.width: 40
                            sourceSize.height: 40
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text{
                            text: "SLAM 재부팅"
                            font.family: font_noto_r.name
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    DropShadow{
                        anchors.fill: parent
                        z: -1
                        radius: 5
                        color: color_navy
                        source: parent
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                            supervisor.writelog("[USER INPUT] MOVEFAIL PAGE : RESTART SLAM")
                            supervisor.restartSLAM();
                        }
                    }
                }
            }
        }
        Rectangle{
            id: rect_menu1
            width: 400
            height: parent.height - statusbar.height
            anchors.left: rect_state.right
            anchors.topMargin: statusbar.height
            anchors.top: parent.top
            color: "#f4f4f4"
            visible: select_localmode?false:true
            Column{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                spacing: 30
                Rectangle{
                    width: rect_menu1.width
                    height: 80
                    color: color_dark_navy
                    Text{
                        id: text_obs
                        anchors.centerIn : parent
                        font.family: font_noto_b.name
                        font.pixelSize: 30
                        color: "white"
                        text:""
                    }
                }
                Rectangle{
                    id: rect_annot_box
                    width: rect_menu1.width*0.9
                    height: 120
                    radius: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#e8e8e8"
                    Row{
                        anchors.centerIn: parent
                        spacing: 30
                        Rectangle{
                            id: state_manual
                            width: 100
                            height: 80
                            radius: 10
                            color: "white"
                            enabled: supervisor.getEmoStatus()
                            border.color:color_green
                            border.width: enabled?3:0
                            Column{
                                spacing: 3
                                anchors.centerIn: parent
                                Image{
                                    source: "icon/image_emergency.png"
                                    Component.onCompleted: {
                                        if(sourceSize.width > 30)
                                            sourceSize.width = 30

                                        if(sourceSize.height > 30)
                                            sourceSize.height = 30
                                    }
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    ColorOverlay{
                                        id: emo_light
                                        anchors.fill: parent
                                        source: parent
                                        color: color_green
                                        visible: state_manual.enabled
                                    }
                                }
                                Text{
                                    font.family: font_noto_r.name
                                    font.pixelSize: 12
                                    text: "비상스위치 눌림"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                        Rectangle{
                            id: state_obs
                            width: 100
                            height: 80
                            radius: 10
                            color: "white"
                            enabled: supervisor.getObsState()
                            border.color:color_red
                            border.width: enabled?3:0
                            Column{
                                anchors.centerIn: parent
                                spacing: 3
                                Image{
                                    source: "icon/icon_obs.png"
                                    Component.onCompleted: {
                                        if(sourceSize.width > 30)
                                            sourceSize.width = 30

                                        if(sourceSize.height > 30)
                                            sourceSize.height = 30
                                    }
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text{
                                    font.family: font_noto_r.name
                                    font.pixelSize: 12
                                    text: "장애물 걸림"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
                Grid{
                    id: grid_status
                    rows: 20
                    columns: 3
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    property var led_size: 15
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "충전 중"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle{
                        id: rect_charging
                        width: parent.led_size
                        height: width
                        radius: width
                        color: color_light_gray
                        border.width:1
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "비상스위치"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle{
                        id: rect_emo
                        width: parent.led_size
                        height: width
                        radius: width
                        color: color_light_gray
                        border.width:1
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "모터 전원"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle{
                        id: rect_power
                        width: parent.led_size
                        height: width
                        radius: width
                        color: color_light_gray
                        border.width:1
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "원격스위치"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle{
                        id: rect_remote
                        width: parent.led_size
                        height: width
                        radius: width
                        color: color_light_gray
                        border.width:1
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "배터리"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle{
                        color: "transparent"
                        width: parent.led_size*2 + 30
                        height: parent.led_size
                        Row{
                            spacing: 30
                            Text{
                                id: text_battery_in
                                font.pixelSize: 12
                                text: "0V"
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text{
                                id: text_battery_out
                                font.pixelSize: 12
                                text: "0V"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "전류"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        id: text_current
                        font.pixelSize: 12
                        text: "0A"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "전력"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        id: text_power
                        font.pixelSize: 12
                        text: "0W"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "전력(Total)"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        id: text_power_total
                        font.pixelSize: 12
                        text: "0W"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "모터 연결상태"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        width: 30
                        text: ":"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle{
                        color: "transparent"
                        width: parent.led_size*2 + 30
                        height: parent.led_size
                        Row{
                            spacing: 30
                            Rectangle{
                                id: rect_motor_con1
                                width: grid_status.led_size
                                height: width
                                radius: width
                                color: color_light_gray
                                border.width:1
                            }
                            Rectangle{
                                id: rect_motor_con2
                                width: grid_status.led_size
                                height: width
                                radius: width
                                color: color_light_gray
                                border.width:1
                            }
                        }
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "모터 상태 0"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        id: text_motor_stat1
                        color: "white"
                        font.pixelSize: 10
                        font.family: font_noto_r.name
                    }

                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "모터 상태 1"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text{
                        id: text_motor_stat2
                        color: "white"
                        font.pixelSize: 10
                        font.family: font_noto_r.name
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: "모터 온도"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text{
                        font.family: font_noto_r.name
                        font.pixelSize: 12
                        text: ":"
                        width: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Rectangle{
                        color: "transparent"
                        width: parent.led_size*2 + 30
                        height: parent.led_size
                        Row{
                            anchors.centerIn: parent
                            spacing: 30
                            Text{
                                id: text_motor_temp1
                                font.pixelSize: 13
                                text: "0"
                                font.family: font_noto_r.name
                            }
                            Text{
                                id: text_motor_temp2
                                font.pixelSize: 13
                                text: "0"
                                font.family: font_noto_r.name
                            }
                        }
                    }
                }
            }
        }
        Timer{
            id: timer_check_localization
            running: false
            repeat: true
            interval: 500
            onTriggered:{
                if(supervisor.is_slam_running()){
                    supervisor.writelog("[QML] CHECK LOCALIZATION : STARTED")
                    btn_auto_init.running = false;
                    timer_check_localization.stop();
                }else if(supervisor.getLocalizationState() === 0 || supervisor.getLocalizationState() === 3){
                    supervisor.writelog("[QML] CHECK LOCALIZATION : FAILED OR NOT READY "+Number(supervisor.getLocalizationState()));
                    timer_check_localization.stop();
                    btn_auto_init.running = false;
                }
            }
        }

        Rectangle{
            id: rect_menu2
            width: 400
            height: parent.height - statusbar.height
            anchors.left: rect_state.right
            anchors.topMargin: statusbar.height
            anchors.top: parent.top
            visible: select_localmode?true:false
            color: "#f4f4f4"
            Column{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                spacing: 30
                Rectangle{
                    width: rect_menu1.width
                    height: 80
                    color: color_dark_navy
                    Text{
                        anchors.centerIn : parent
                        font.family: font_noto_b.name
                        font.pixelSize: 30
                        color: "white"
                        text:"위치 초기화"
                    }
                }
                Rectangle{
                    width: rect_menu1.width*0.9
                    height: 120
                    radius: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#e8e8e8"
                    Row{
                        anchors.centerIn: parent
                        spacing: 30
                        Item_button{
                            id: btn_move
                            width: 80
                            shadow_color: color_gray
                            highlight: map.tool=="MOVE"
                            icon: "icon/icon_move.png"
                            name: "이동"
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    map.tool = "MOVE";
                                }
                            }
                        }
                        Item_button{
                            width: 80
                            shadow_color: color_gray
                            highlight: map.tool=="SLAM_INIT"
                            icon: "icon/icon_point.png"
                            name: "수동 초기화"
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    supervisor.writelog("[USER INPUT] MOVEFAIL PAGE : LOCALIZATION MANUAL")
                                    map.tool = "SLAM_INIT";
                                    map.new_slam_init = true;
                                    if(supervisor.getGridWidth() > 0){
                                        map.init_x = supervisor.getlastRobotx()/supervisor.getGridWidth() + supervisor.getOrigin()[0];
                                        map.init_y = supervisor.getlastRoboty()/supervisor.getGridWidth() + supervisor.getOrigin()[1];
                                        map.init_th  = supervisor.getlastRobotth();// - Math.PI/2;
                                        supervisor.setInitPos(map.init_x,map.init_y,map.init_th);
                                    }
                                    map.update_canvas();
                                }
                            }
                        }
                        Item_button{
                            id: btn_auto_init
                            width: 78
                            shadow_color: color_gray
                            icon:"icon/icon_auto_init.png"
                            name:"자동 초기화"
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    supervisor.writelog("[USER INPUT] MOVEFAIL PAGE : LOCALIZATION AUTO")
                                    if(supervisor.getLocalizationState() !== 1){
                                        btn_auto_init.running = true;
                                        supervisor.slam_autoInit();
                                        timer_check_localization.start();
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Rectangle{
                width: parent.width*0.9
                height: 200
                radius: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 50
                anchors.horizontalCenter: parent.horizontalCenter
                Column{
                    anchors.centerIn: parent
                    spacing: 10
                    Text{
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "* 안 내 사 항 *"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: font_noto_b.name
                        color: color_red
                    }
                    Grid{
                        rows: 6
                        columns: 2
                        Text{
                            text: "1."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "비상스위치가 눌려있다면 풀어주세요."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "2."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "자동 초기화 버튼을 눌러 초기화를 시작합니다. (약 3-5초 소요)"
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "3."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "라이다 데이터가 맵과 일치하는 지 확인해주세요."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "4."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "일치하지 않는다면 수동 초기화 버튼을 누르세요."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "5."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "맵 상에서 로봇의 현재 위치와 방향대로 표시해주세요."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "6."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                        Text{
                            text: "라이다가 맵과 일치하는 지 확인해주세요."
                            font.pixelSize: 13
                            font.family: font_noto_r.name
                            color: color_red
                        }
                    }
                }
            }
        }

        Map_full{
            id: map
            objectName: "MOVEFAIL"
            width: 740
            height: width
            show_robot: true
            show_path: true
            robot_following: true
            show_lidar: true
            show_buttons: true
            show_connection: true
            show_location: true
            show_object: true
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: statusbar.height
        }
    }
    Item{
        id: notice
        width: 1280
        height: 800
        Behavior on y{
            NumberAnimation{
                duration: 500;
                easing.type: Easing.OutCubic
            }
        }
        Rectangle{
            anchors.fill: parent
            color:"#282828"
        }
        Image{
            id: icon_warn
            source: "icon/image_emergency_push.png"
//            width: 130
//            height: 130
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 200
        }
        Text{
            id: text
            text:"목적지로 이동하는데 실패하였습니다.\n비상스위치 버튼을 누르고 로봇을 수동으로 이동시켜주세요."
            anchors.top: icon_warn.bottom
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.family: font_noto_b.name
            font.pixelSize: 40
            color: "white"
        }
        Image{
            id: image_swipe
            source: "icon/joy_up.png"
            width: 60
            height: 40
            visible: area_swipe.enabled
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text{
            text: "위로 올리시면 메뉴가 나옵니다."
            font.family: font_noto_r.name
            color: "#e8e8e8"
            visible: image_swipe.visible
            opacity: image_swipe.opacity
            anchors.verticalCenter: image_swipe.verticalCenter
            anchors.left: image_swipe.right
            anchors.leftMargin: 10
        }
    }
    MouseArea{
        id: area_swipe
        anchors.fill: parent
        enabled: false
        property var firstX;
        property var firstY;
        onPressed: {
            firstX = mouseX;
            firstY = mouseY;
        }
        onReleased: {
            if(firstY - mouseY > 100){
                supervisor.writelog("[USER INPUT] SWIPE MOVEFAIL PAGE TO DOWN "+Number(firstY - mouseY).toFixed(0))
                notice.y = -800;
                area_swipe.enabled = false;
//                timer_get_joy.start();
            }else{
                supervisor.writelog("[USER INPUT] SWIPE MOVEFAIL PAGE TO UP "+Number(firstY - mouseY).toFixed(0))
                notice.y = 0;
            }
        }
        onPositionChanged: {
            if(firstY - mouseY > 0){
                notice.y =  mouseY - firstY;
            }
        }
    }

    Audio{
        id: voice_obs_close
        autoPlay: false
        volume: parseInt(supervisor.getSetting("ROBOT_SW","volume_voice"))/100
        source: "bgm/voice_obs_too_close.mp3"
    }

    Timer{
        id: timer_update
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            //0: no path /1: local fail /2: emergency /3: user stop /4: motor error
            if(notice_num === 0){
                if(supervisor.getEmoStatus()){
                    if(notice.y === 0)
                        area_swipe.enabled = true;
                }else{
                    area_swipe.enabled = false;
                }
            }else if(notice_num === 1){
                if(notice.y === 0)
                    area_swipe.enabled = true;
            }else if(notice_num === 2){
                if(notice.y === 0)
                    area_swipe.enabled = true;
            }else if(notice_num === 3){
                if(notice.y === 0)
                    area_swipe.enabled = true;
            }else if(notice_num === 4){
                if(supervisor.getEmoStatus()){
                    if(notice.y === 0)
                        area_swipe.enabled = true;
                }else{
                    area_swipe.enabled = false;
                }
            }

            if(supervisor.getEmoStatus()){
                rect_emo.color = color_green;
                state_manual.enabled = true;
            }else{
                state_manual.enabled = false;
                rect_emo.color = color_light_gray;
            }

            if(supervisor.getObsState()){
                state_obs.enabled = true;
            }else{
                state_obs.enabled = false;
            }

            if(supervisor.getEmoStatus() === 0 && supervisor.getObsState() === 0){
                btn_reset.enabled = true;
            }else{
                btn_reset.enabled = false;
            }

            if(supervisor.getRemoteStatus()){
                rect_remote.color = color_green;
            }else{
                rect_remote.color = color_light_gray;
            }
            if(supervisor.getPowerStatus()){
                rect_power.color = color_green;
            }else{
                rect_power.color = color_light_gray;
            }
            if(supervisor.getChargeStatus()){
                rect_charging.color = color_green;
            }else{
                rect_charging.color = color_light_gray;
            }
            if(supervisor.getMotorConnection(0)){
                rect_motor_con1.color = color_green;
            }else{
                rect_motor_con1.color = color_red;
            }

            if(supervisor.getMotorConnection(1)){
                rect_motor_con2.color = color_green;
            }else{
                rect_motor_con2.color = color_red;
            }
            if(supervisor.getMotorStatus(0)===0){
                text_motor_stat1.color = color_light_gray;
                text_motor_stat1.text = supervisor.getMotorStatusStr(0);
            }else if(supervisor.getMotorStatus(0)===1){
                text_motor_stat1.color = color_green;
                text_motor_stat1.text = supervisor.getMotorStatusStr(0);
            }else{
                text_motor_stat1.color = color_red;
                text_motor_stat1.text = supervisor.getMotorStatusStr(0);
            }
            if(supervisor.getMotorStatus(1)===0){
                text_motor_stat2.color = color_light_gray;
                text_motor_stat2.text = supervisor.getMotorStatusStr(1);
            }else if(supervisor.getMotorStatus(1)===1){
                text_motor_stat2.color = color_green;
                text_motor_stat2.text = supervisor.getMotorStatusStr(1);
            }else{
                text_motor_stat2.color = color_red;
                text_motor_stat2.text = supervisor.getMotorStatusStr(1);
            }

            if(supervisor.getMotorTemperature(0) > supervisor.getMotorWarningTemperature()){
                text_motor_temp1.color = color_red;
            }else{
                text_motor_temp1.color = "black";
            }
            if(supervisor.getMotorTemperature(1) > supervisor.getMotorWarningTemperature()){
                text_motor_temp2.color = color_red;
            }else{
                text_motor_temp2.color = "black";
            }

            text_motor_temp1.text = supervisor.getMotorTemperature(0).toFixed(0).toString();
            text_motor_temp2.text = supervisor.getMotorTemperature(1).toFixed(0).toString();

            text_battery_in.text = supervisor.getBatteryIn().toFixed(1).toString() + "V";
            text_battery_out.text = supervisor.getBatteryOut().toFixed(1).toString() + "V";
            text_current.text = supervisor.getBatteryCurrent().toFixed(1).toString() + "A";

            text_power.text = supervisor.getPower(0).toFixed(0).toString() + "W";
            text_power_total.text = supervisor.getPowerTotal(1).toFixed(0).toString() + "W";

        }

    }
}
