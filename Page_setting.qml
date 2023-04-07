import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import "."
import io.qt.Supervisor 1.0

import QtMultimedia 5.12
Item {
    id: page_setting
    objectName: "page_setting"
    width: 1280
    height: 800

    property int select_category: 1
    property string platform_name: supervisor.getRobotName()
    property string debug_platform_name: ""
    property bool is_debug: false
    function update_camera(){
        if(popup_camera.opened)
            popup_camera.update();
    }

    function set_category(num){
        select_category = num;
    }

    function set_call_done(){
//        init();
        model_callbell.clear();
        for(var i=0; i<combo_call_num.currentIndex; i++){
            model_callbell.append({name:supervisor.getSetting("CALLING","call_"+Number(i))});
        }
        popup_change_call.close();
    }

    Tool_Keyboard{
        id: keyboard
    }
    Rectangle{
        width: parent.width
        height: parent.height-statusbar.height
        anchors.bottom: parent.bottom
        color: "#f4f4f4"
        //카테고리 바
        Row{
            spacing: 5
            Rectangle{
                width: 250
                height: 40
                color: "#323744"
                Text{
                    anchors.centerIn: parent
                    font.family: font_noto_r.name
                    color: "white"
                    text: "설정"
                    font.pixelSize: 20
                }
            }
            Rectangle{
                id: rect_category_1
                width: 240
                height: 40
                color: "#647087"
                Text{
                    anchors.centerIn: parent
                    font.family: font_noto_r.name
                    color: "white"
                    text: "로봇"
                    font.pixelSize: 20
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                       select_category = 1;
                    }
                }
                Rectangle{
                    width: parent.width
                    height: 7
                    visible: select_category==1?true:false
                    color: "#12d27c"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                }
            }
            Rectangle{
                id: rect_category_2
                width: 240
                height: 40
                color: "#647087"
                Text{
                    anchors.centerIn: parent
                    font.family: font_noto_r.name
                    color: "white"
                    text: "맵"
                    font.pixelSize: 20
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                       select_category = 2;
                    }
                }
                Rectangle{
                    width: parent.width
                    height: 7
                    visible: select_category==2?true:false
                    color: "#12d27c"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                }
            }
            Rectangle{
                id: rect_category_3
                width: 264
                height: 40
                color: "#647087"
                Text{
                    anchors.centerIn: parent
                    font.family: font_noto_r.name
                    color: "white"
                    text: "주행"
                    font.pixelSize: 20
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                       select_category = 3;
                    }
                }
                Rectangle{
                    width: parent.width
                    height: 7
                    visible: select_category==3?true:false
                    color: "#12d27c"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                }
            }
            Rectangle{
                id: rect_category_4
                width: 240
                height: 40
                color: "#647087"
                Text{
                    anchors.centerIn: parent
                    font.family: font_noto_r.name
                    color: "white"
                    text: "모터"
                    font.pixelSize: 20
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                       select_category = 4;
                    }
                }
                Rectangle{
                    width: parent.width
                    height: 7
                    visible: select_category==4?true:false
                    color: "#12d27c"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                }
            }
        }

        Flickable{
            id: area_setting_robot
            visible: select_category==1?true:false
            width: 880
            anchors.left: parent.left
            anchors.leftMargin: 100
            anchors.top: parent.top
            anchors.topMargin: 120
            height: parent.height - 200
            contentHeight: column_setting.height
            clip: true
            ScrollBar.vertical: ScrollBar{
                width: 20
                anchors.right: parent.right
                policy: ScrollBar.AlwaysOn
            }
            Column{
                id:column_setting
                width: parent.width
                spacing:25
                Rectangle{
                    id: set_robot_1
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"플랫폼 이름(*영문)"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: platform_name
                                anchors.fill: parent
                                text:supervisor.getSetting("ROBOT_HW","model");
                                onFocusChanged: {
                                    keyboard.owner = platform_name;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_robot_1_serial
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"플랫폼 넘버(중복 주의)"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_platform_serial
                                anchors.fill: parent
                                model:[0,1,2,3,4,5,6,7,8,9,10]
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_robot_2
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"플랫폼 타입"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_platform_type
                                anchors.fill: parent
                                model:["서빙용","호출용"]
                            }
                        }
                    }
                }

                Rectangle{
                    id: set_robot_3
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"이동 속도"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            id: rr
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_velocity
                                        anchors.centerIn: parent
                                        text: slider_vxy.value.toFixed(2)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_vxy
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0
                                    to: 1
                                    value: supervisor.getVelocity()
                                }
                            }

                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"음악 볼륨"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            id: tt
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Image{
                                    id: ttet1
                                    source: "icon/icon_mute.png"
                                    anchors.verticalCenter: parent.verticalCenter
                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            if(slider_volume_bgm.value == 0){
                                                slider_volume_bgm.value  = Number(supervisor.getSetting("ROBOT_SW","volume_bgm"));
                                            }else{
                                                slider_volume_bgm.value  = 0;
                                            }

                                        }
                                    }
                                }
                                Slider{
                                    anchors.verticalCenter: parent.verticalCenter
                                    id: slider_volume_bgm
//                                    anchors.centerIn: parent
                                    width: tt.width*0.7
                                    height: 40
                                    from: 0
                                    to: 100
                                    value: supervisor.getSetting("ROBOT_SW","volume_bgm")
                                }

                                Image{
                                    id: ttet
                                    source: "icon/icon_test_play.png"
                                    anchors.verticalCenter: parent.verticalCenter
                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            if(bgm_test.isplaying){
                                                bgm_test.stop();
                                                ttet.source = "icon/icon_test_play.png";
                                            }else{
                                                bgm_test.play();
                                                ttet.source = "icon/icon_test_stop.png";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Audio{
                    id: voice_test
                    autoPlay: false
                    volume: slider_volume_voice.value/100
                    source: "bgm/voice_start_serving.mp3"
                }
                Audio{
                    id: bgm_test
                    property bool isplaying: false
                    autoPlay: false
                    volume: slider_volume_bgm.value/100
                    source: "bgm/song.mp3"
                    onPlaying: {
                        isplaying = true;
                    }
                    onStopped: {
                        isplaying = false;
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"음성 볼륨"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }

                        Rectangle{
                            id: te
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Image{
                                    id: ttet12
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: "icon/icon_mute.png"
                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            if(slider_volume_voice.value == 0){
                                                slider_volume_voice.value  = Number(supervisor.getSetting("ROBOT_SW","volume_voice"));
                                            }else{
                                                slider_volume_voice.value  = 0;
                                            }
                                        }
                                    }
                                }
                                Slider{
                                    anchors.verticalCenter: parent.verticalCenter
                                    id: slider_volume_voice
                                    width: te.width*0.7
                                    height: 40
                                    from: 0
                                    to: 100
                                    value: supervisor.getSetting("ROBOT_SW","volume_voice")
                                }
                                Image{
                                    id: ttet14
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: "icon/icon_test_play.png"
                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            print("test play")
                                            voice_test.play();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle{
                    id: set_robot_6
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"서버 명령 사용"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_use_servercmd
                                anchors.fill: parent
                                model:["사용 안함","사용"]
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"로봇 반지름 반경"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: radius
                                anchors.fill: parent
                                text:supervisor.getSetting("ROBOT_HW","radius");
                                onFocusChanged: {
                                    keyboard.owner = radius;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"UI 명령 활성"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_use_uicmd
                                anchors.fill: parent
                                model:["비활성화","활성화"]
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"초기화"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Rectangle{
                                anchors.centerIn: parent
                                width: 300
                                height: 40
                                color: "black"
                                Text{
                                    anchors.centerIn: parent
                                    color: "white"
                                    font.family: font_noto_r.name
                                    font.pixelSize: 15
                                    text: "공용폴더 덮어씌우기"
                                }
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        popup_reset.open();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Flickable{
            id: area_setting_map
            visible: select_category==2?true:false
            width: 880
            anchors.left: parent.left
            anchors.leftMargin: 100
            anchors.top: parent.top
            anchors.topMargin: 120
            height: parent.height - 200
            contentHeight: column_setting2.height
            clip: true
            ScrollBar.vertical: ScrollBar{
                width: 20
                anchors.right: parent.right
                policy: ScrollBar.AlwaysOn
            }
            Column{
                id:column_setting2
                width: parent.width
                spacing:25
                Rectangle{
                    id: set_map_0
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"현재 설정된 맵"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 30
                                anchors.centerIn: parent
                                TextField{
                                    id: map_name
                                    height: parent.height
                                    width: 300
                                    text:supervisor.getMapname();
                                    onFocusChanged: {
                                        keyboard.owner = map_name;
                                        if(focus){
                                            keyboard.open();
                                        }else{
                                            keyboard.close();
                                        }
                                    }
                                }
                                Rectangle{
                                    width: 100
                                    height: 40
                                    radius: 5
                                    color: "black"
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text{
                                        font.family: font_noto_r.name
                                        color: "white"
                                        anchors.centerIn: parent
                                        text: "변경"
                                    }
                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            popup_maplist.open();
                                            init();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"맵 크기"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: map_size
                                anchors.fill: parent
                                text:supervisor.getSetting("ROBOT_SW","map_size");
                                onFocusChanged: {
                                    keyboard.owner = map_size;
                                    if(focus){
                                        keyboard.open();
                                        map_size.selectAll();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"맵 단위 크기"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: grid_size
                                anchors.fill: parent
                                text:supervisor.getSetting("ROBOT_SW","grid_size");
                                onFocusChanged: {
                                    keyboard.owner = grid_size;
                                    if(focus){
                                        keyboard.open();
                                        grid_size.selectAll();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_map_4
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"테이블 개수"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_table_num
                                anchors.fill: parent
                                model:30
//                                model:[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]

                            }
                        }
                    }
                }
                Rectangle{
                    id: set_map_3
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"트레이 개수"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_tray_num
                                anchors.fill: parent
                                model:[1,2,3,4,5]
                            }
                        }
                    }

                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"최대 호출 횟수"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_call_max
                                anchors.fill: parent
                                model:[1,2,3,4,5]
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"호출벨 개수"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_call_num
                                anchors.fill: parent
                                model:20
                                onCurrentIndexChanged: {
                                    model_callbell.clear();
                                    for(var i=0; i<combo_call_num.currentIndex; i++){
                                        model_callbell.append({name:supervisor.getSetting("CALLING","call_"+Number(i))});
                                    }
                                }
                            }
                        }
                    }

                }
                Repeater{
                    model: ListModel{id:model_callbell}//combo_call_num.currentIndex
                    Rectangle{
                        width: 840
                        height: 40
                        Row{
                            anchors.fill: parent
                            Rectangle{
                                width: 350
                                height: parent.height
                                Text{
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 50
                                    font.family: font_noto_r.name
                                    text:"호출벨 "+Number(index)
                                    font.pixelSize: 20
                                }
                            }
                            Rectangle{
                                width: 1
                                height: parent.height
                                color: "#d0d0d0"
                            }
                            Rectangle{
                                width: parent.width - 351
                                height: parent.height
                                Row{
                                    anchors.centerIn: parent
                                    spacing: 20
                                    TextField{
                                        id: call_id
                                        width: 300
                                        height: parent.height
                                        text: name//supervisor.getSetting("CALLING","call_"+Number(index))
                                    }
                                    Rectangle{
                                        width: 100
                                        height: 40
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "black"
                                        radius: 5
                                        Text{
                                            anchors.centerIn: parent
                                            text: "변경"
                                            font.family: font_noto_r.name
                                            font.pixelSize: 10
                                            color: "white"
                                        }
                                        MouseArea{
                                            anchors.fill: parent
                                            onClicked: {
                                                popup_change_call.callid = index
                                                popup_change_call.open();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Flickable{
            id: area_setting_slam
            visible: select_category==3?true:false
            width: 880
            anchors.left: parent.left
            anchors.leftMargin: 100
            anchors.top: parent.top
            anchors.topMargin: 120
            height: parent.height - 200
            contentHeight: column_setting3.height
            clip: true
            ScrollBar.vertical: ScrollBar{
                width: 20
                anchors.right: parent.right
                policy: ScrollBar.AlwaysOn
            }
            Column{
                id:column_setting3
                width: parent.width
                spacing:25
                Rectangle{
                    id: set_slam_0
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"실행 시 자동 초기화"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_autoinit
                                anchors.fill: parent
                                model:["사용안함","사용"]
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"대기 후 경로재탐색"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_avoid
                                anchors.fill: parent
                                model:["사용안함","사용"]
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_slam_1
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"baudrate"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_baudrate
                                anchors.fill: parent
                                model:[115200,256000]
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_slam_2
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"mask"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_mask
                                        anchors.centerIn: parent
                                        text: slider_mask.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_mask
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0
                                    to: 15.0
                                    value: 10.0
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_slam_3
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"max_range"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_max_range
                                        anchors.centerIn: parent
                                        text: slider_max_range.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_max_range
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 10.0
                                    to: 50.0
                                    value: 40.0
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_slam_4
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"offset_x"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: offset_x
                                anchors.fill: parent
                                text:supervisor.getSetting("SENSOR","offset_x");
                                onFocusChanged: {
                                    keyboard.owner = offset_x;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_slam_5
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"offset_y"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: offset_y
                                anchors.fill: parent
                                text:supervisor.getSetting("SENSOR","offset_y");
                                onFocusChanged: {
                                    keyboard.owner = offset_y;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_slam_6
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"left_camera"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: left_camera
                                height: parent.height
                                anchors.left: parent.left
                                anchors.right: btn_view_cam.left
                                text:supervisor.getSetting("SENSOR","left_camera");
                                readOnly: true
                            }
                            Rectangle{
                                id: btn_view_cam
                                width: 100
                                height: parent.height
                                anchors.right: parent.right
                                radius: 5
                                color: "#d0d0d0"
                                Text{
                                    anchors.centerIn: parent
                                    text: "viewer"
                                    font.pixelSize: 15
                                    font.family: font_noto_r.name

                                }
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        popup_camera.open();

                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_slam_7
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"right_camera"
                                font.pixelSize: 20
                            }
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {

                                }
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: right_camera
                                height: parent.height
                                anchors.left: parent.left
                                anchors.right: btn_view_camr.left
                                text:supervisor.getSetting("SENSOR","right_camera");
                                readOnly: true
                            }
                            Rectangle{
                                id: btn_view_camr
                                width: 100
                                height: parent.height
                                anchors.right: parent.right
                                radius: 5
                                color: "#d0d0d0"
                                Text{
                                    anchors.centerIn: parent
                                    text: "viewer"
                                    font.pixelSize: 15
                                    font.family: font_noto_r.name
                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            popup_camera.open();

                                        }
                                    }

                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"k_curve"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_k_curve
                                        anchors.centerIn: parent
                                        text: slider_k_curve.value.toFixed(3)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_k_curve
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0.001
                                    to: 0.01
                                    value: 0.005
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"k_v"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_k_v
                                        anchors.centerIn: parent
                                        text: slider_k_v.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_k_v
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0.1
                                    to: 2.0
                                    value: 0.7
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"k_w"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_k_w
                                        anchors.centerIn: parent
                                        text: slider_k_w.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_k_w
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 1.0
                                    to: 3.0
                                    value: 2.5
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_pivot"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_limit_pivot
                                        anchors.centerIn: parent
                                        text: slider_limit_pivot.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_limit_pivot
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 5.0
                                    to: 90.0
                                    value: 45.0
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_v"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_limit_v
                                        anchors.centerIn: parent
                                        text: slider_limit_v.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_limit_v
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0.1
                                    to: 2.0
                                    value: 1.0
                                }
                            }
                        }
                    }
                }

                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_v_acc"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_limit_v_acc
                                        anchors.centerIn: parent
                                        text: slider_limit_v_acc.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_limit_v_acc
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0.1
                                    to: 2.0
                                    value: 1.0
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_w"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_limit_w
                                        anchors.centerIn: parent
                                        text: slider_limit_w.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_limit_w
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 5.0
                                    to: 120.0
                                    value: 120.0
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_w_acc"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_limit_w_acc
                                        anchors.centerIn: parent
                                        text: slider_limit_w_acc.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_limit_w_acc
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 5.0
                                    to: 360.0
                                    value: 360.0
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_manual_v"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_limit_manual_v
                                        anchors.centerIn: parent
                                        text: slider_limit_manual_v.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_limit_manual_v
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0.1
                                    to: 2.0
                                    value: 0.3
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_manual_w"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_limit_manual_w
                                        anchors.centerIn: parent
                                        text: slider_limit_manual_w.value.toFixed(1)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_limit_manual_w
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 5.0
                                    to: 120.0
                                    value: 120.0
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"look_ahead_dist"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            Row{
                                spacing: 10
                                anchors.centerIn: parent
                                Rectangle{
                                    width: rr.width*0.1
                                    height: 40
                                    Text{
                                        id: text_look_ahead_dist
                                        anchors.centerIn: parent
                                        text: slider_look_ahead_dist.value.toFixed(2)
                                        font.pixelSize: 15
                                        font.family: font_noto_r.name
                                    }
                                }
                                Slider{
                                    id: slider_look_ahead_dist
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.width*0.8
                                    height: 40
                                    from: 0.3
                                    to: 1.0
                                    value: 0.45
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"wheel_base"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: wheel_base
                                anchors.fill: parent
                                text:supervisor.getSetting("ROBOT","wheel_base");
                                onFocusChanged: {
                                    keyboard.owner = wheel_base;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"wheel_radius"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: wheel_radius
                                anchors.fill: parent
                                text:supervisor.getSetting("ROBOT","wheel_radius");
                                onFocusChanged: {
                                    keyboard.owner = wheel_radius;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }





            }
        }

        Flickable{
            id: area_setting_motor
            visible: select_category==4?true:false
            width: 880
            anchors.left: parent.left
            anchors.leftMargin: 100
            anchors.top: parent.top
            anchors.topMargin: 120
            height: parent.height - 200
            contentHeight: column_setting4.height
            clip: true
            ScrollBar.vertical: ScrollBar{
                width: 20
                anchors.right: parent.right
                policy: ScrollBar.AlwaysOn
            }
            Column{
                id:column_setting4
                width: parent.width
                spacing:25
                Rectangle{
                    id: set_motor_1
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"모터 연결상태"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            id: rect_connection_0
                            width: (parent.width - 351)/2
                            height: parent.height
                            color: supervisor.getMotorConnection(0)?color_green:color_red
                            Text{
                                id: text_connection_0
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:supervisor.getMotorConnection(0)?"모터 0번 연결됨":"모터 0번 연결안됨"
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            id: rect_connection_1
                            width: (parent.width - 351)/2
                            height: parent.height
                            color: supervisor.getMotorConnection(1)?color_green:color_red
                            Text{
                                id: text_connection_1
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:supervisor.getMotorConnection(1)?"모터 1번 연결됨":"모터 1번 연결안됨"
                                font.pixelSize: 15
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"모터 상태"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: (parent.width - 351)/2
                            height: parent.height
                            Text{
                                id: text_status_0
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"모터 0 : "+supervisor.getMotorStatus(0).toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/2
                            height: parent.height
                            Text{
                                id: text_status_1
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"모터 1 : "+supervisor.getMotorStatus(1).toString()
                                font.pixelSize: 15
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"모터 온도"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: (parent.width - 351)/2
                            height: parent.height
                            Text{
                                id: text_temp_0
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"모터 0 : "+supervisor.getMotorTemperature(0).toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/2
                            height: parent.height
                            Text{
                                id: text_temp_1
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"모터 1 : "+supervisor.getMotorTemperature(1).toString()
                                font.pixelSize: 15
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"상태값"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: (parent.width - 351)/4
                            height: parent.height
                            Text{
                                id: text_status_charging
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Charging : "+supervisor.getChargeStatus().toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/4
                            height: parent.height
                            Text{
                                id: text_status_power
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Power : "+supervisor.getPowerStatus().toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/4
                            height: parent.height
                            Text{
                                id: text_status_emo
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Emo : "+supervisor.getEmoStatus().toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/4
                            height: parent.height
                            Text{
                                id: text_status_remote
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Remote : "+supervisor.getRemoteStatus().toString()
                                font.pixelSize: 15
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"배터리"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: (parent.width - 351)/3
                            height: parent.height
                            Text{
                                id: text_battery_in
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"In : "+supervisor.getBatteryIn().toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/3
                            height: parent.height
                            Text{
                                id: text_battery_out
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Out : "+supervisor.getBatteryOut().toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/3
                            height: parent.height
                            Text{
                                id: text_battery_current
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Current : "+supervisor.getBatteryCurrent().toString()
                                font.pixelSize: 15
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"Power"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: (parent.width - 351)/2
                            height: parent.height
                            Text{
                                id: text_power
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Power : "+supervisor.getPower().toString()
                                font.pixelSize: 15
                            }
                        }
                        Rectangle{
                            width: (parent.width - 351)/2
                            height: parent.height
                            Text{
                                id: text_power_total
                                anchors.centerIn: parent
                                font.family: font_noto_r.name
                                text:"Total : "+supervisor.getPowerTotal().toString()
                                font.pixelSize: 15
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"모터 방향"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_wheel_dir
                                anchors.fill: parent
                                model: [-1,1]
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"left_id"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_left_id
                                anchors.fill: parent
                                model:[0,1]
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"right_id"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            ComboBox{
                                id: combo_right_id
                                anchors.fill: parent
                                model:[0,1]
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"gear_ratio"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: gear_ratio
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","gear_ratio");
                                onFocusChanged: {
                                    keyboard.owner = gear_ratio;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_motor_2
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"k_p"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: k_p
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","k_p");
                                onFocusChanged: {
                                    keyboard.owner = k_p;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_motor_3
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"k_i"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: k_i
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","k_i");
                                onFocusChanged: {
                                    keyboard.owner = k_i;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: set_motor_4
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"k_d"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: k_d
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","k_d");
                                onFocusChanged: {
                                    keyboard.owner = k_d;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_v"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: limit_v
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","limit_v");
                                onFocusChanged: {
                                    keyboard.owner = limit_v;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_v_acc"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: limit_v_acc
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","limit_v_acc");
                                onFocusChanged: {
                                    keyboard.owner = limit_v_acc;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_w"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: limit_w
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","limit_w");
                                onFocusChanged: {
                                    keyboard.owner = limit_w;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: 840
                    height: 40
                    Row{
                        anchors.fill: parent
                        Rectangle{
                            width: 350
                            height: parent.height
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font.family: font_noto_r.name
                                text:"limit_w_acc"
                                font.pixelSize: 20
                            }
                        }
                        Rectangle{
                            width: 1
                            height: parent.height
                            color: "#d0d0d0"
                        }
                        Rectangle{
                            width: parent.width - 351
                            height: parent.height
                            TextField{
                                id: limit_w_acc
                                anchors.fill: parent
                                text: supervisor.getSetting("MOTOR","limit_w_acc");
                                onFocusChanged: {
                                    keyboard.owner = limit_w_acc;
                                    if(focus){
                                        keyboard.open();
                                    }else{
                                        keyboard.close();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle{
            id: btn_menu
            width: 120
            height: width
            anchors.right: parent.right
            anchors.rightMargin: 50
            anchors.top: parent.top
            anchors.topMargin: 50
            color: "transparent"
            radius: 30
            Behavior on width{
                NumberAnimation{
                    duration: 500;
                }
            }
            Image{
                id: image_btn_menu
                source:"icon/btn_reset2.png"
                scale: 1-(120-parent.width)/120
                anchors.centerIn: parent
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    supervisor.writelog("[USER INPUT] SETTING PAGE -> BACKPAGE");
                    backPage();
                }
            }
        }

        Column{
            anchors.bottom: area_setting_robot.bottom
            anchors.right: parent.right
            anchors.rightMargin: (parent.width - area_setting_robot.width - area_setting_robot.x - btn_default.width)/2
            spacing: 30
            Rectangle{
                id: btn_update
                width: 180
                height: 60
                radius: 10
                color:"transparent"
                border.width: 1
                border.color: "#7e7e7e"
                Text{
                    anchors.centerIn: parent
                    text: "Program Update"
                    font.family: font_noto_r.name
                    font.pixelSize: 20
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        supervisor.writelog("[USER INPUT] SETTING PAGE -> PROGRAM UPDATE");
                        popup_update.open();
                    }
                }
            }
            Rectangle{
                id: btn_reset_slam
                width: 180
                height: 60
                radius: 10
                color:"transparent"
                border.width: 1
                border.color: "#7e7e7e"
                Text{
                    anchors.centerIn: parent
                    text: "SLAM restart"
                    font.family: font_noto_r.name
                    font.pixelSize: 20
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        supervisor.writelog("[USER INPUT] SETTING PAGE -> RESTART SLAM");
                        supervisor.restartSLAM();
                    }
                }
            }
            Rectangle{
                id: btn_default
                width: 180
                height: 60
                radius: 10
                color:"transparent"
                border.width: 1
                border.color: "#7e7e7e"
                Text{
                    anchors.centerIn: parent
                    text: "초기화"
                    font.family: font_noto_r.name
                    font.pixelSize: 25
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        supervisor.writelog("[USER INPUT] SETTING PAGE -> RESET DEFAULT");
                        init();
                    }
                }
            }
            Rectangle{
                id: btn_confirm
                width: 180
                height: 60
                radius: 10
                color: "#12d27c"
                border.width: 1
                border.color: "#12d27c"
                Text{
                    anchors.centerIn: parent
                    text: "Confirm"
                    font.family: font_noto_r.name
                    font.pixelSize: 25
                    color: "white"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        supervisor.writelog("[USER INPUT] SETTING PAGE -> SETTING CHANGE");
                        supervisor.setSetting("ROBOT_HW/model",platform_name.text);
                        supervisor.setSetting("ROBOT_HW/serial_num",combo_platform_serial.currentText);
                        supervisor.setSetting("ROBOT_HW/radius",radius.text);
                        supervisor.setSetting("ROBOT_HW/tray_num",combo_tray_num.currentText);

                        if(combo_platform_type.currentIndex == 0){
                            supervisor.setSetting("ROBOT_HW/type","SERVING");
                        }else if(combo_platform_type.currentIndex == 1){
                            supervisor.setSetting("ROBOT_HW/type","CALLING");
                        }

                        supervisor.setSetting("ROBOT_HW/wheel_base",wheel_base.text);
                        supervisor.setSetting("ROBOT_HW/wheel_radius",wheel_radius.text);

                        supervisor.setSetting("ROBOT_SW/k_curve",text_k_curve.text);
                        supervisor.setSetting("ROBOT_SW/k_v",text_k_v.text);
                        supervisor.setSetting("ROBOT_SW/k_w",text_k_w.text);
                        supervisor.setSetting("ROBOT_SW/limit_pivot",text_limit_pivot.text);
                        supervisor.setSetting("ROBOT_SW/limit_v",text_limit_v.text);
                        supervisor.setSetting("ROBOT_SW/limit_w",text_limit_w.text);
                        supervisor.setSetting("ROBOT_SW/limit_v_acc",text_limit_v_acc.text);
                        supervisor.setSetting("ROBOT_SW/limit_w_acc",text_limit_w_acc.text);

                        supervisor.setSetting("ROBOT_SW/limit_manual_v",text_limit_manual_v.text);
                        supervisor.setSetting("ROBOT_SW/limit_manual_w",text_limit_manual_w.text);
                        supervisor.setSetting("ROBOT_SW/look_ahead_dist",text_look_ahead_dist.text);

                        supervisor.setSetting("ROBOT_SW/grid_size",grid_size.text);

                        supervisor.setSetting("ROBOT_SW/map_size",map_size.text);

                        supervisor.setSetting("ROBOT_SW/volume_bgm",slider_volume_bgm.value.toFixed(0));
                        supervisor.setSetting("ROBOT_SW/volume_voice",slider_volume_voice.value.toFixed(0));

                        if(combo_use_uicmd.currentIndex == 0)
                            supervisor.setSetting("ROBOT_SW/use_uicmd","false");
                        else
                            supervisor.setSetting("ROBOT_SW/use_uicmd","true");

                        if(combo_use_servercmd.currentIndex == 0)
                            supervisor.setSetting("SERVER/use_servercmd","false");
                        else
                            supervisor.setSetting("SERVER/use_servercmd","true");


                        supervisor.setSetting("ROBOT_SW/velocity",text_velocity.text);

                        if(combo_autoinit.currentIndex == 0)
                            supervisor.setSetting("ROBOT_SW/use_autoinit","false");
                        else
                            supervisor.setSetting("ROBOT_SW/use_autoinit","true");

                        if(combo_avoid.currentIndex == 0)
                            supervisor.setSetting("ROBOT_SW/use_avoid","false");
                        else
                            supervisor.setSetting("ROBOT_SW/use_avoid","true");

                        supervisor.setSetting("SENSOR/baudrate",combo_baudrate.currentText);
                        supervisor.setSetting("SENSOR/mask",text_mask.text);
                        supervisor.setSetting("SENSOR/max_range",text_max_range.text);
                        supervisor.setSetting("SENSOR/offset_x",offset_x.text);
                        supervisor.setSetting("SENSOR/offset_y",offset_y.text);
                        supervisor.setSetting("SENSOR/right_camera",right_camera.text);
                        supervisor.setSetting("SENSOR/left_camera",left_camera.text);


                        supervisor.setSetting("MOTOR/gear_ratio",gear_ratio.text);
                        supervisor.setSetting("MOTOR/k_d",k_d.text);
                        supervisor.setSetting("MOTOR/k_i",k_i.text);
                        supervisor.setSetting("MOTOR/k_p",k_p.text);

                        supervisor.setSetting("MOTOR/limit_v",limit_v.text);
                        supervisor.setSetting("MOTOR/limit_v_acc",limit_v_acc.text);
                        supervisor.setSetting("MOTOR/limit_w",limit_w.text);
                        supervisor.setSetting("MOTOR/limit_w_acc",limit_w_acc.text);

                        supervisor.setSetting("MOTOR/left_id",combo_left_id.currentText);
                        supervisor.setSetting("MOTOR/right_id",combo_right_id.currentText);
                        supervisor.setSetting("MOTOR/wheel_dir",combo_wheel_dir.currentText);
                        supervisor.setTableNum(combo_table_num.currentIndex);

                        supervisor.setSetting("CALLING/call_num",combo_call_num.currentText);
                        supervisor.setSetting("CALLING/call_maximum",combo_call_max.currentText);

                        supervisor.readSetting();
                        supervisor.restartSLAM();
                        init();
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        init();
    }

    function init(){
        supervisor.writelog("[QML] SETTING PAGE init");
        platform_name.text = supervisor.getSetting("ROBOT_HW","model");
        combo_platform_serial.currentIndex = parseInt(supervisor.getSetting("ROBOT_HW","serial_num"))
        radius.text = supervisor.getSetting("ROBOT_HW","radius");

        combo_tray_num.currentIndex = supervisor.getSetting("ROBOT_HW","tray_num")-1;

        if(supervisor.getSetting("ROBOT_HW","type") === "SERVING"){
            combo_platform_type.currentIndex = 0;
        }else{
            combo_platform_type.currentIndex = 1;
        }
        wheel_base.text = supervisor.getSetting("ROBOT_HW","wheel_base");
        wheel_radius.text = supervisor.getSetting("ROBOT_HW","wheel_radius");

        map_name.text = supervisor.getMapname();
        grid_size.text = supervisor.getSetting("ROBOT_SW","grid_size");
        map_size.text = supervisor.getSetting("ROBOT_SW","map_size");

        slider_k_curve.value = parseFloat(supervisor.getSetting("ROBOT_SW","k_curve"));
        slider_k_v.value = parseFloat(supervisor.getSetting("ROBOT_SW","k_v"));
        slider_k_w.value = parseFloat(supervisor.getSetting("ROBOT_SW","k_w"));
        slider_limit_pivot.value = parseFloat(supervisor.getSetting("ROBOT_SW","limit_pivot"));
        slider_limit_manual_v.value = parseFloat(supervisor.getSetting("ROBOT_SW","limit_manual_v"));
        slider_limit_manual_w.value = parseFloat(supervisor.getSetting("ROBOT_SW","limit_manual_w"));
        slider_limit_v.value = parseFloat(supervisor.getSetting("ROBOT_SW","limit_v"));
        slider_limit_w.value = parseFloat(supervisor.getSetting("ROBOT_SW","limit_w"));
        slider_limit_v_acc.value = parseFloat(supervisor.getSetting("ROBOT_SW","limit_v_acc"));
        slider_limit_w_acc.value = parseFloat(supervisor.getSetting("ROBOT_SW","limit_w_acc"));
        slider_look_ahead_dist.value = parseFloat(supervisor.getSetting("ROBOT_SW","look_ahead_dist"));

        slider_volume_bgm.value = Number(supervisor.getSetting("ROBOT_SW","volume_bgm"));
        slider_volume_voice.value = Number(supervisor.getSetting("ROBOT_SW","volume_voice"));

        if(supervisor.getSetting("SERVER","use_servercmd") === "true"){
            combo_use_servercmd.currentIndex = 1;
        }else{
            combo_use_servercmd.currentIndex = 0;
        }
        if(supervisor.getSetting("ROBOT_SW","use_uicmd") === "true"){
            combo_use_uicmd.currentIndex = 1;
        }else{
            combo_use_uicmd.currentIndex = 0;
        }

        slider_vxy.value = parseFloat(supervisor.getSetting("ROBOT_SW","velocity"));
        combo_table_num.currentIndex = supervisor.getTableNum();

        gear_ratio.text = supervisor.getSetting("MOTOR","gear_ratio");
        k_d.text = supervisor.getSetting("MOTOR","k_d");
        k_i.text = supervisor.getSetting("MOTOR","k_i");
        k_p.text = supervisor.getSetting("MOTOR","k_p");

        limit_v.text = supervisor.getSetting("MOTOR","limit_v");
        limit_v_acc.text = supervisor.getSetting("MOTOR","limit_v_acc");
        limit_w.text = supervisor.getSetting("MOTOR","limit_w");
        limit_w_acc.text = supervisor.getSetting("MOTOR","limit_w_acc");

        combo_left_id.currentIndex = parseInt(supervisor.getSetting("MOTOR","left_id"));
        combo_right_id.currentIndex = parseInt(supervisor.getSetting("MOTOR","right_id"));

        if(supervisor.getSetting("MOTOR","wheel_dir") === "-1"){
            combo_wheel_dir.currentIndex = 0;
        }else{
            combo_wheel_dir.currentIndex = 1;
        }

        if(supervisor.getSetting("ROBOT_SW","use_autoinit") === "true"){
            combo_autoinit.currentIndex = 1;
        }else{
            combo_autoinit.currentIndex = 0;
        }

        if(supervisor.getSetting("ROBOT_SW","use_avoid") === "true"){
            combo_avoid.currentIndex = 1;
        }else{
            combo_avoid.currentIndex = 0;
        }

        if(supervisor.getSetting("SENSOR","baudrate") === "115200"){
            combo_baudrate.currentIndex = 0;
        }else if(supervisor.getSetting("SENSOR","baudrate") === "256000"){
            combo_baudrate.currentIndex = 1;
        }

        combo_call_max.currentIndex = parseInt(supervisor.getSetting("CALLING","call_maximum"))-1;
        combo_call_num.currentIndex = parseInt(supervisor.getSetting("CALLING","call_num"));

        model_callbell.clear();
        for(var i=0; i<combo_call_num.currentIndex; i++){
            model_callbell.append({name:supervisor.getSetting("CALLING","call_"+Number(i))});
        }



        slider_mask.value = parseFloat(supervisor.getSetting("SENSOR","mask"));
        slider_max_range.value = parseFloat(supervisor.getSetting("SENSOR","max_range"));
        offset_x.text = supervisor.getSetting("SENSOR","offset_x");
        offset_y.text = supervisor.getSetting("SENSOR","offset_y");
        right_camera.text = supervisor.getSetting("SENSOR","right_camera");
        left_camera.text = supervisor.getSetting("SENSOR","left_camera");
    }

    Timer{
        running: true
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if(supervisor.getMotorConnection(0)){
                rect_connection_0.color = color_green;
                text_connection_0.text = "모터 0번 연결됨"
            }else{
                rect_connection_0.color = color_red;
                text_connection_0.text = "모터 0번 연결안됨"
            }
            if(supervisor.getMotorConnection(1)){
                rect_connection_1.color = color_green;
                text_connection_1.text = "모터 1번 연결됨"
            }else{
                rect_connection_1.color = color_red;
                text_connection_1.text = "모터 1번 연결안됨"
            }
            text_status_0.text = "모터 0 : " + supervisor.getMotorStatus(0).toString();
            text_status_1.text = "모터 1 : " + supervisor.getMotorStatus(1).toString();

            text_temp_0.text = "모터 0 : " + supervisor.getMotorTemperature(0).toString();
            text_temp_1.text = "모터 1 : " + supervisor.getMotorTemperature(1).toString();

            text_status_charging.text = "Charge : " + supervisor.getChargeStatus().toString();
            text_status_power.text = "Power : " + supervisor.getPowerStatus().toString();
            text_status_emo.text = "Emo : " + supervisor.getEmoStatus().toString();
            text_status_remote.text = "Remote : " + supervisor.getRemoteStatus().toString();

            text_battery_in.text = "In : " + supervisor.getBatteryIn().toFixed(1).toString();
            text_battery_out.text = "Out : " + supervisor.getBatteryOut().toFixed(1).toString();
            text_battery_current.text = "Current : " + supervisor.getBatteryCurrent().toFixed(1).toString();

            text_power.text = "Power : " + supervisor.getPower().toString();
            text_power_total.text = "Total : " + supervisor.getPowerTotal().toString();

        }
    }

    Popup{
        id: popup_change_call
        width: 400
        height: 300
        anchors.centerIn: parent
        leftPadding: 0
        topPadding: 0
        bottomPadding: 0
        rightPadding: 0
        property var callid: 0
        onOpened: {
//            timer_popup_call.start();
            supervisor.setCallbell(callid);
        }
        onClosed: {
            supervisor.setCallbell(-1);
//            timer_popup_call.stop();
        }

        Rectangle{
            anchors.fill: parent
            Text{
                anchors.centerIn: parent
                text: "변경하실 호출벨을 눌러주세요."
                font.family: font_noto_r.name
                font.pixelSize: 25
            }
        }
        Timer{
            id: timer_popup_call
            interval: 300
            running: false
            repeat: true
            onTriggered: {
                print("hello " + Number(popup_change_call.callid))
            }
        }
    }

    Popup{
        id: popup_reset
        width: 400
        height: 300
        anchors.centerIn: parent
        leftPadding: 0
        topPadding: 0
        bottomPadding: 0
        rightPadding: 0
        Rectangle{
            anchors.fill: parent
            Column{
                anchors.centerIn: parent
                spacing: 20
                Text{
                    text: "정말 덮어씌우시겠습니까?"
                    font.family: font_noto_b.name
                    font.pixelSize: 20

                }
                Rectangle{
                    width: 100
                    height: 50
                    border.width: 1
                    radius: 5
                    Text{
                        anchors.centerIn: parent
                        text: "확인"
                        font.family: font_noto_r.name
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked:{
                            supervisor.writelog("[USER INPUT] RESET HOME FOLDERS")
                            supervisor.resetHomeFolders();
                            popup_reset.close();
                        }
                    }
                }
            }
        }
    }

    Popup{
        id: popup_update
        width: 600
        height: 400
        anchors.centerIn: parent

        onOpened: {
            //버전 체크
            if(supervisor.isNewVersion()){
                supervisor.writelog("[USER INPUT] UPDATE PROGRAM -> ALREADY NEW VERSION")
                //버전이 이미 최신임
                rect_lastest.visible = true;
                rect_need_update.visible = false;
                text_version.text = supervisor.getLocalVersionDate()
            }else{
                supervisor.writelog("[USER INPUT] UPDATE PROGRAM -> CHECK NEW VERSION")
                //새로운 버전 확인됨
                rect_lastest.visible = false;
                rect_need_update.visible = true;
                text_version1.text = "현재 : " + supervisor.getLocalVersionDate()
                text_version2.text = "최신 : " + supervisor.getServerVersionDate()
            }
        }

        Rectangle{
            id: rect_lastest
            anchors.fill: parent
            radius: 5
            Text{
                id: text_1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 50
                font.family: font_noto_r.name
                font.pixelSize: 20
                text:"프로그램이 이미 최신입니다."
            }
            Text{
                id: text_version
                anchors.centerIn: parent
                anchors.topMargin: 50
                font.family: font_noto_r.name
                font.pixelSize: 20
                text:supervisor.getLocalVersionDate()
            }

            Rectangle{
                width: 180
                height: 60
                radius: 10
                color: "#12d27c"
                border.width: 1
                border.color: "#12d27c"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30
                Text{
                    anchors.centerIn: parent
                    text: "확인"
                    font.family: font_noto_r.name
                    font.pixelSize: 25
                    color: "white"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        popup_update.close();
                    }
                }
            }
        }
        Rectangle{
            id: rect_need_update
            anchors.fill: parent
            radius: 5
            Text{
                id: text_11
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 50
                font.family: font_noto_r.name
                font.pixelSize: 20
                text:"새로운 버전이 확인되었습니다. 업데이트하시겠습니까?"
            }
            Column{
                anchors.centerIn: parent
                Text{
                    id: text_version1
                    font.family: font_noto_r.name
                    font.pixelSize: 20
                    text:"현재 : "+supervisor.getLocalVersionDate()
                }
                Text{
                    id: text_version2
                    font.family: font_noto_r.name
                    font.pixelSize: 20
                    text:"최신 : "+supervisor.getServerVersionDate()
                }
            }
            Row{
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20

                Rectangle{
                    width: 180
                    height: 60
                    radius: 10
                    color:"transparent"
                    border.width: 1
                    border.color: "#7e7e7e"
                    Text{
                        anchors.centerIn: parent
                        text: "취소"
                        font.family: font_noto_r.name
                        font.pixelSize: 25
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                            popup_update.close();
                        }
                    }
                }
                Rectangle{
                    width: 180
                    height: 60
                    radius: 10
                    color: "#12d27c"
                    border.width: 1
                    border.color: "#12d27c"
                    Text{
                        anchors.centerIn: parent
                        text: "확인"
                        font.family: font_noto_r.name
                        font.pixelSize: 25
                        color: "white"
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                            supervisor.writelog("[USER INPUT] UPDATE PROGRAM -> UPDATE START")
                            supervisor.pullGit();
                            popup_update.close();
                        }
                    }
                }
            }
        }

    }
    Popup{
        id: popup_camera
        width: parent.width
        height: parent.height
        background: Rectangle{
            opacity: 0.8
            color: "#282828"
        }

        property bool is_load: false

        onOpened: {
            timer_load.start();
        }
        onClosed: {
            timer_load.stop();
        }

        function update(){
            timer_load.stop();
            //카메라 대수에 따라 UI 업데이트
            if(supervisor.getCameraNum() > 1){
                text_camera_1.text = supervisor.getCameraSerial(0);
                text_camera_2.text = supervisor.getCameraSerial(1);
                popup_camera.is_load = true;
            }else if(supervisor.getCameraNum() === 1){
                text_camera_1.text = supervisor.getCameraSerial(0);
                popup_camera.is_load = true;
            }else{
                text_camera_1.text = supervisor.getLeftCamera();
                text_camera_2.text = supervisor.getRightCamera();
            }

            if(popup_camera.is_load){
                //지정된 왼쪽카메라 확인
//                if(supervisor.getLeftCamera() === supervisor.getCameraSerial(0)){
//                    mousearea_1.is_left = true;
//                    mousearea_2.is_left = false;

//                    ani_1.to = popup_camera.pos_left;
//                    ani_2.to = popup_camera.pos_right;
//                    ani_camera.restart();
//                }
//                if(supervisor.getRightCamera() === supervisor.getCameraSerial(0)){
//                    mousearea_1.is_left = false;
//                    mousearea_2.is_left = true;
//                    ani_1.to = popup_camera.pos_right;
//                    ani_2.to = popup_camera.pos_left;
//                    ani_camera.restart();
//                }

                if(supervisor.getCameraNum() > 1){
                    if(mousearea_1.is_left && supervisor.getLeftCamera() === supervisor.getCameraSerial(0)){
                        cam_info_1.set = true;
                    }
                    if(mousearea_2.is_left && supervisor.getLeftCamera() === supervisor.getCameraSerial(1)){
                        cam_info_2.set = true;
                    }
                    if(!mousearea_1.is_left && supervisor.getRightCamera() === supervisor.getCameraSerial(0)){
                        cam_info_1.set = true;
                    }
                    if(!mousearea_2.is_left && supervisor.getRightCamera() === supervisor.getCameraSerial(1)){
                        cam_info_2.set = true;
                    }
                }

                canvas_camera_1.requestPaint();
                canvas_camera_2.requestPaint();
            }else{
                cam_info_1.set = false;
                cam_info_2.set = false;
            }

            timer_load.start();
        }

        Timer{
            id: timer_load
            interval: 500
            repeat: true
            onTriggered:{
                //카메라 정보 요청
                supervisor.requestCamera();

            }
        }

        property var pos_left: rect_remain.width/4 - cam_info_1.width/2
        property var pos_right: rect_remain.width*3/4 - cam_info_1.width/2
        Rectangle{
            anchors.centerIn: parent
            width: 800
            height: 800
            Rectangle{
                id: rect_title
                width: parent.width
                height: 100
                color: "#323744"
                Text{
                    anchors.centerIn: parent
                    color: "white"
                    font.family: font_noto_r.name
                    font.pixelSize: 20
                    text: "카메라 정보를 확인한 후, 위치를 지정하여주세요."
                }
            }
            Rectangle{
                id: rect_remain
                width: parent.width
                height: parent.height - rect_title.height
                anchors.top: rect_title.bottom

                Rectangle{
                    id: rect_black_left
                    width: rect_remain.width/2
                    height: 500
                    color: "#282828"
                    Text{
                        id: text_left
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        text: "Left"
                        font.family: font_noto_b.name
                        font.pixelSize: 20
                        color: "white"
                    }
                }
                Rectangle{
                    id: rect_black_right
                    width: rect_remain.width/2
                    anchors.left: rect_black_left.right
                    height: 500
                    color: "#282828"
                    Text{
                        id: text_right
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        text: "Right"
                        font.family: font_noto_b.name
                        font.pixelSize: 20
                        color: "white"
                    }
                }

                ParallelAnimation{
                    id: ani_camera;
                    SpringAnimation{
                        id:ani_1
                        target:cam_info_1
                        property:"x"
                        duration:500
                        spring: 2
                        damping: 0.2
                    }
                    SpringAnimation{
                        id:ani_2
                        target:cam_info_2
                        property:"x"
                        duration:500
                        spring: 2
                        damping: 0.2
                    }
                }

                Rectangle{
                    id: cam_info_1
                    width: 350
                    height: 400
                    color: "transparent"
                    property bool set:false
                    z: mousearea_1.pressed?2:1
                    x: parent.width/4 - width/2
                    y: 60

                    Rectangle{
                        id: rect_cam_1
                        clip: true
                        width: parent.width
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        Canvas{
                            id: canvas_camera_1
                            width: 212
                            height: 120
                            scale: parent.width/212
                            anchors.centerIn: parent
                            onPaint:{
                                var ctx = getContext('2d');

                                if(supervisor.getCameraNum() > 0){
                                    var image_data = supervisor.getCamera(0);

                                    if(image_data.length > 0){

                                        ctx.clearRect(0,0,width,height);
                                        var temp_image = ctx.createImageData(width,height);

                                        for(var i=0; i<image_data.length; i++){
                                            temp_image.data[4*i+0] = image_data[i];
                                            temp_image.data[4*i+1] = image_data[i];
                                            temp_image.data[4*i+2] = image_data[i];
                                            temp_image.data[4*i+3] = 255;
                                        }
                                        ctx.drawImage(temp_image,0,0,width,height);

                                    }
                                }
                            }
                        }

                    }

                    Rectangle{
                        anchors.top: rect_cam_1.bottom
                        width: parent.width
                        height: 50
                        radius: 5
                        color: cam_info_1.set?"#12d27c":"#d0d0d0"
                        Row{
                            spacing: 10
                            anchors.centerIn: parent
                            Text{
                                text: "Serial : "
                                font.family: font_noto_r.name

                            }
                            Text{
                                id: text_camera_1
                                text: {
                                    if(supervisor.getCameraNum() > 0){
                                        supervisor.getCameraSerial(0);
                                    }else{
                                        ""
                                    }
                                }
                                font.family: font_noto_r.name

                            }
                        }
                    }

                    MouseArea{
                        id:mousearea_1
                        anchors.fill: parent
                        property var firstX;
                        property var firstY;
                        property bool is_left: true
                        propagateComposedEvents: true
                        preventStealing: false

                        onPressed:{
                            firstX = mouseX;
                            firstY = mouseY;
                        }
                        onReleased: {
                            if(is_left){
                                ani_1.from = cam_info_1.x;
                                ani_1.to = popup_camera.pos_left;

                                ani_2.from = cam_info_2.x;
                                ani_2.to = popup_camera.pos_right;

                                print("LEFT ",ani_1.to, ani_2.to);
                                ani_camera.restart();
                            }else{
                                ani_1.from = cam_info_1.x;
                                ani_1.to = popup_camera.pos_right;
                                ani_2.from = cam_info_2.x;
                                ani_2.to = popup_camera.pos_left;
                                print("RIGHT ",ani_1.to, ani_2.to);
                                ani_camera.restart();
                            }
                        }
                        onPositionChanged: {
                            cam_info_1.x += mouseX - firstX;
                            if(mouseX - firstX > 0){
                                is_left = false;
                            }else{
                                is_left = true;
                            }
                        }
                    }
                }
                Rectangle{
                    id: cam_info_2
                    width: 350
                    height: 400
                    color: "transparent"
                    property bool set: false
                    z: mousearea_2.pressed?2:1
                    x: parent.width*3/4 - width/2
                    y: 60
                    Rectangle{
                        id: rect_cam_2
                        clip: true
                        width: parent.width
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        Canvas{
                            id: canvas_camera_2
                            width: 212
                            height: 120
                            scale: parent.width/212
                            anchors.centerIn: parent
                            onPaint:{
                                var ctx = getContext('2d');

                                if(supervisor.getCameraNum() > 1){
                                    var image_data = supervisor.getCamera(1);
                                    if(image_data.length > 0){
                                        ctx.clearRect(0,0,width,height);
                                        var temp_image = ctx.createImageData(width,height);
                                        for(var i=0; i<image_data.length; i++){
                                            temp_image.data[4*i+0] = image_data[i];
                                            temp_image.data[4*i+1] = image_data[i];
                                            temp_image.data[4*i+2] = image_data[i];
                                            temp_image.data[4*i+3] = 255;
                                        }
                                        ctx.drawImage(temp_image,0,0,width,height);
                                    }
                                }
                            }
                        }

                    }

                    Rectangle{
                        anchors.top: rect_cam_2.bottom
                        width: parent.width
                        height: 50
                        radius: 5
                        color: cam_info_2.set?"#12d27c":"#d0d0d0"
                        Row{
                            spacing: 10
                            anchors.centerIn: parent
                            Text{
                                text: "Serial : "
                                font.family: font_noto_r.name

                            }
                            Text{
                                id: text_camera_2
                                text: {
                                    if(supervisor.getCameraNum() > 1){
                                        supervisor.getCameraSerial(1);
                                    }else{
                                        ""
                                    }
                                }
                                font.family: font_noto_r.name

                            }
                        }
                    }

                    MouseArea{
                        id:mousearea_2
                        anchors.fill: parent
                        property var firstX;
                        property var firstY;
                        property bool is_left: true
                        propagateComposedEvents: true
                        preventStealing: false

                        onPressed:{
                            firstX = mouseX;
                            firstY = mouseY;
                        }
                        onReleased: {
                            if(!is_left){
                                ani_1.from = cam_info_1.x;
                                ani_1.to = popup_camera.pos_left;

                                ani_2.from = cam_info_2.x;
                                ani_2.to = popup_camera.pos_right;

                                ani_camera.restart();

                            }else{
                                ani_1.from = cam_info_1.x;
                                ani_1.to = popup_camera.pos_right;
                                ani_2.from = cam_info_2.x;
                                ani_2.to = popup_camera.pos_left;
                                ani_camera.restart();
                            }
                        }
                        onPositionChanged: {
                            cam_info_2.x += mouseX - firstX;
                            if(mouseX - firstX > 0){
                                is_left = false;
                            }else{
                                is_left = true;
                            }
                        }
                    }
                }

                Rectangle{
                    width: rect_remain.width
                    height: rect_remain.height - rect_black_left.height
                    anchors.top: rect_black_left.bottom
                    Row{
                        spacing: 50
                        anchors.centerIn: parent
                        Rectangle{
                            width: 180
                            height: 60
                            radius: 10
                            color: enabled?"#12d27c":"#e9e9e9"
                            border.width: enabled?1:0
                            border.color: "#12d27c"
                            enabled: popup_camera.is_load
                            Text{
                                anchors.centerIn: parent
                                text: "확인"
                                font.family: font_noto_r.name
                                font.pixelSize: 25
                                color: "white"
                            }
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    if(mousearea_1.is_left){
                                        supervisor.writelog("[USER INPUT] SETTING PAGE : CAMERA LEFT ("+text_camera_1.text+")")
                                        print("1 : ",text_camera_1.text,text_camera_2.text);
                                        supervisor.setCamera(text_camera_1.text,text_camera_2.text);
                                    }else{
                                        supervisor.writelog("[USER INPUT] SETTING PAGE : CAMERA LEFT ("+text_camera_2.text+")")

                                        print("2 : ",text_camera_2.text,text_camera_1.text);
                                        supervisor.setCamera(text_camera_2.text,text_camera_1.text);
                                    }
                                    supervisor.readSetting();
                                    init();
                                    popup_camera.close();
                                }
                            }
                        }
                        Rectangle{
                            width: 180
                            height: 60
                            radius: 10
                            color:"transparent"
                            border.width: 1
                            border.color: "#7e7e7e"
                            Text{
                                anchors.centerIn: parent
                                text: "취소"
                                font.family: font_noto_r.name
                                font.pixelSize: 25
                            }
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    popup_camera.close();
                                }
                            }
                        }
                        Rectangle{
                            width: 180
                            height: 60
                            radius: 10
                            color:popup_camera.is_load?"transparent":"#12d27c"
                            border.width: 1
                            border.color: "#7e7e7e"
                            Text{
                                anchors.centerIn: parent
                                text: "사진 요청"
                                font.family: font_noto_r.name
                                font.pixelSize: 25
                            }
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    supervisor.writelog("[USER INPUT] SETTING PAGE : CAMERA REQUEST")
//                                    supervisor.requestCamera();
                                    timer_load.start();
                                }
                            }
                        }
                    }
                }

            }
        }
    }

    Popup{
        id: popup_password

    }

    Popup_map_list{
        id: popup_maplist
    }
}
