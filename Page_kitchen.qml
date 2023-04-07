import QtQuick 2.12
import QtQuick.Controls 2.12
import "."
import io.qt.Supervisor 1.0
Item {
    id: page_kitchen
    objectName: "page_kitchen"
    width: 1280
    height: 800

    Component.onCompleted: {
        init();
        if(supervisor.getRobotType() === "CALLING"){
            ready_call = false;
            popup_question.visible = true;
        }
    }
    function init(){
        table_num = supervisor.getTableNum();
        tray_num = supervisor.getTrayNum();
        table_col_num = supervisor.getTableColNum();
        traymodel.clear();
        robot_type = supervisor.getRobotType();
        for(var i=0; i<tray_num; i++){
            traymodel.append({x:0,y:0,tray_num:i+1,set_table:0,color:"white"});
        }

        if(robot_type == "CALLING"){
            if(pbefore != pmenu)
                popup_question.visible = true;


            model_call.clear();
            for(var i=0; i<supervisor.getCallSize(); i++){
                model_call.append({name:supervisor.getCallName(supervisor.getCall(i))})
            }


//            supervisor.loadPatrolFile(supervisor.getPatrolFileName());
//            var num=supervisor.getPatrolNum();

//            repeat_patrol.model.clear();
//            repeat_patrol.model.append({type:0,name:"Start"});

//            for(var i=0; i<num; i++){
//                repeat_patrol.model.append({type:2,name:""});
//                print(supervisor.getPatrolLocation(i));
//                if(supervisor.getPatrolLocation(i) == ""){
//                    var text="x:"+supervisor.getPatrolX(i)+", y:"+supervisor.getPatrolY(i)+", th:"+supervisor.getPatrolTH(i);
//                    repeat_patrol.model.append({type:1,name:text});
//                    print(text);
//                }else{
//                    repeat_patrol.model.append({type:1,name:supervisor.getPatrolLocation(i)});
//                }
//            }
        }
        statusbar.visible = true;
    }
    Timer{
        running: true
        repeat: true
        interval: 500
        onTriggered: {
            robot_type = supervisor.getRobotType();
            if(robot_type == "CALLING"){
                model_call.clear();
                for(var i=0; i<supervisor.getCallSize(); i++){
                    model_call.append({name:supervisor.getCallName(supervisor.getCall(i))})
                }

                if(supervisor.getCallSize() > 0 && ready_call){
                    supervisor.server_cmd_newcall();
                }
            }

        }
    }

    property int tray_num: 3
    property int table_num: 5
    property int table_col_num: 1

    property int tray_width: 400
    property int tray_height: 80
    property int spacing_tray : 10

    property int cur_table_num: 0
    property bool flag_moving: false

    property int rect_size: 70
    property int traybox_margin: 150

    property int cur_table: 0
    property bool go_wait: false
    property bool go_charge: false
    property bool go_patrol: false
    property bool ready_call: false

    Rectangle{
        anchors.fill : parent
        color: "#f4f4f4"
    }

    ListModel{
        id: traymodel
        ListElement{
            x: 0
            y: 0
            tray_num: 1
            set_table: 0
            color: "white"
        }
    }
    ListModel{
        id: patrolmodel
    }

    Image{
        id: image_head
        anchors.horizontalCenter: robot_type=="SERVING"?rect_tray_box.horizontalCenter:rect_calling_box.horizontalCenter
        anchors.bottom: rect_tray_box.top
        anchors.bottomMargin: 10

        width: 90*1.5
        height: 50*1.5
        source:{
            if(robot_type=="SERVING"){
                "image/robot_head.png"
            }else{
                if(ready_call){
                    "image/robot_head.png"
                }else{
                    "image/robot_head_sleep.png"
                }
            }
        }
    }

    Rectangle{
        id: rect_tray_box
        visible: robot_type=="SERVING"?true:false
        width: 500
        height: tray_num*tray_height + (tray_num - 1)*spacing_tray + 50
        color: "#e8e8e8"
        radius: 30
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: rect_table_box.right
        anchors.leftMargin: (rect_menu_box.x-rect_table_box.width - width)/2
        Column{
            id: column_tray
            anchors.centerIn: parent
            spacing: 20
            Repeater{
                id: repeat_tray
                model: traymodel
                Rectangle{
                    id: rect_tray
                    width: tray_width
                    height: tray_height
                    color: "transparent"
                    radius:50
                    border.color: "#d0d0d0"
                    border.width: 1
                    onYChanged: {
                        model.y = y;
                    }

                    SequentialAnimation{
                        id: ani_tray
                        running: false
                        ParallelAnimation{
                            NumberAnimation{target:rect_tray_fill; property:"scale"; from:1;to:1.2;duration:300;}
                            NumberAnimation{target:rect_tray_fill; property:"scale"; from:1.2;to:1;duration:300;}
                        }
                    }
                    Rectangle{
                        id: rect_tray_fill
                        width: tray_width
                        height: tray_height
                        radius:50
                        color: model.color
                        border.color: model.color
                        border.width: 1
                        onColorChanged: {
                            if(color != "#0000ff"){
                                ani_tray.start()
                            }
                        }
                    }
                    Text{
                        id: text_cancel
                        font.family: font_noto_r.name
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        color: "#525252"
                        visible: false
                        text:"cancel"
                    }
                    MouseArea{
                        id: tray_mousearea
                        anchors.fill: parent
                        property var firstX;
                        property var width_dis: 0
                        onPressed: {
                            firstX = mouseX;
                            width_dis = 0;
                        }
                        onReleased: {
                            if(width_dis > 50){
                                model.set_table = 0;
                                model.color =  "white"
                                cur_table = 0;
                            }else{
                                if(cur_table != 0){
                                    model.set_table = cur_table;
                                    model.color =  "#12d27c"
                                }

                            }
                            rect_tray_fill.width = rect_tray.width;
                            text_cancel.visible = false;
                            width_dis = 0;
                        }
                        onPositionChanged: {
                            count_resting = 0;
                            width_dis = firstX-mouseX;

                            if(width_dis < 0)
                                width_dis = 0;

                            if(model.set_table !== 0){
                                if(width_dis > 50){
                                    text_cancel.visible = true;
                                }else{
                                    text_cancel.visible = false;
                                }
                                rect_tray_fill.width = rect_tray.width - width_dis
                            }

                        }
                    }
                    Text{
                        id: textTray
                        anchors.centerIn: parent
                        font.family: font_noto_r.name
                        font.pixelSize: (model.set_table===0)?25:30
                        font.bold: (model.set_table===0)?false:true
                        color: (model.set_table===0)?"#d0d0d0":"white"
                        text: (model.set_table===0)?"Tray "+Number(model.tray_num):Number(model.set_table)
                    }
                }
            }
        }
    }

    Rectangle{
        id: rect_table_box
        visible: robot_type=="SERVING"?true:false
        width: (table_col_num)*100 - 20 + 160
        height: parent.height - statusbar.height
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: statusbar.height
        color: "#282828"
        onWidthChanged: {
            margin_name = rect_table_box.width
        }

        Text{
            id: text_tables
            color:"white"
            font.bold: true
            font.family: font_noto_b.name
            text: "테이블 번호"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            font.pixelSize: 30
        }
        SwipeView{
            id: swipeview_tables
            width: parent.width
            currentIndex: 0
            clip: true
            anchors.top: text_tables.bottom
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 100
            Repeater{
                id: page_table
                model: Math.ceil((table_num/(table_col_num*5)))

                onModelChanged: {
                    swipeview_tables.currentIndex = 0;
                }
                Item{
                    property int pageNum: index
                    Grid{
                        rows: 5
                        columns: table_num-(table_col_num*5*(pageNum+1))>0?table_col_num:((table_num-(table_col_num*5*pageNum))/5 + 1).toFixed(0)
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        flow: Grid.TopToBottom
                        Repeater{
                            id: column_table
                            model: table_num-(table_col_num*5*pageNum)>(table_col_num*5)?table_col_num*5:table_num-(table_col_num*5*pageNum)
                            Rectangle{
                                id: rect_table
                                width:80
                                height:80
                                radius:80
                                color: ((table_col_num*5*pageNum)+index+1 == cur_table)?"#12d27c":"#d0d0d0"
                                Rectangle{
                                    width:68
                                    height:68
                                    radius:68
                                    color: "#f4f4f4"
                                    anchors.centerIn: parent
                                    Text{
                                        anchors.centerIn: parent
                                        text: (table_col_num*5*pageNum)+index+1
                                        color: supervisor.isExistLocation((table_col_num*5*pageNum)+index)?"#525252":color_red
                                        font.family: font_noto_r.name
                                        font.pixelSize: 25
                                    }
                                }
                                MouseArea{
                                    anchors.fill:parent
                                    onClicked: {
                                        count_resting = 0;
                                        if(cur_table == (table_col_num*5*pageNum)+index+1){
                                            cur_table = 0;
                                        }else{
                                            if(supervisor.isExistLocation((table_col_num*5*pageNum)+index)){
                                                cur_table = (table_col_num*5*pageNum)+index+1;
                                            }else{

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
        PageIndicator{
            id: indicator_tables1
            count: swipeview_tables.count
            currentIndex: swipeview_tables.currentIndex
            anchors.bottom: swipeview_tables.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            delegate: Rectangle{
                implicitWidth: 15
                implicitHeight: 15
                radius: width
                color: index===swipeview_tables.currentIndex?"#12d27c":"#525252"
                Behavior on color{
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
        }
        Rectangle{
            id: btn_lock
            color: "transparent"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            width: 50
            radius: 50
            height: 50
            visible: table_num>5?true:false
            Image{
                anchors.fill: parent
                source: "icon/btn_lock.png"
            }
            MouseArea{
                anchors.fill: parent
                onPressAndHold: {
                    count_resting = 0;
                    supervisor.writelog("[USER INPUT] TABLE NUM CHANGED DONE : "+Number(table_col_num));
                    btn_lock.visible = false;
                    btns_table.visible = true;
                }
            }
        }
        Row{
            id: btns_table
            visible: false
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Rectangle{
                id: btn_minus
                color: "#282828"
                width: 40
                height: 40
                radius: 40
                enabled: table_num>5?true:false
                border.color: "#e8e8e8"
                border.width: 1
                Text{
                    anchors.centerIn: parent
                    text:"-"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: font_noto_b.name
                    font.pixelSize: 40
                    color: "#e8e8e8"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        count_resting = 0;
                        if(table_col_num > 1)
                            supervisor.setTableColNum(--table_col_num);
                    }
                }
            }
            Rectangle{
                id: btn_plus
                color: "#282828"
                width: 40
                height: 40
                radius: 40
                enabled: table_num>table_col_num*5?true:false
                border.color: "#e8e8e8"
                border.width: 1
                Text{
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text:"+"
                    font.family: font_noto_b.name
                    font.pixelSize: 40
                    color: "#e8e8e8"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        count_resting = 0;
                        if(table_col_num < 3)
                            supervisor.setTableColNum(++table_col_num);
                    }
                }
            }
            Rectangle{
                id: btn_confirm_tables
                color: "#282828"
                width: 40
                height: 40
                radius: 40
                border.color: "#e8e8e8"
                border.width: 1
                Image{
                    anchors.fill: parent
                    source: "icon/btn_yes.png"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        count_resting = 0;
                        supervisor.writelog("[USER INPUT] TABLE NUM CHANGED");
                        btn_lock.visible = true;
                        btns_table.visible = false;
                    }
                }
            }

        }

    }

    Rectangle{
        id: rect_go
        width: 300
        visible: robot_type=="SERVING"?true:false
        height: 100
        radius: 100
        anchors.horizontalCenter: rect_tray_box.horizontalCenter
        anchors.top: rect_tray_box.bottom
        anchors.topMargin: 40
        color: "#24a9f7"
        Text{
            id: text_go
            anchors.centerIn: parent
            text: "서빙 시작"
            font.family: font_noto_r.name
            font.pixelSize: 35
            font.bold: true
            color: "white"
        }
        MouseArea{
            id: btn_go
            anchors.fill: parent
            onClicked: {
                count_resting = 0;
                print("serving start button");
                cur_table = 0;
                for(var i=0; i<tray_num; i++){
                    supervisor.setTray(i,traymodel.get(i).set_table);
                }
            }
        }
    }
//    Rectangle{
//        id: rect_patrol_box
//        visible: robot_type=="CALLING"?true:false
//        width: (table_num/5).toFixed(0)*100 - 20 + 160
//        height: parent.height - statusbar.height
//        anchors.left: parent.left
//        anchors.top: parent.top
//        anchors.topMargin: statusbar.height
//        color: "#282828"
//        onWidthChanged: {
//            margin_name = rect_table_box.width
//        }

//        Text{
//            id: text_patrol
//            color:"white"
//            font.bold: true
//            font.family: font_noto_b.name
//            text: "로봇 이동경로"
//            anchors.horizontalCenter: parent.horizontalCenter
//            anchors.top: parent.top
//            anchors.topMargin: 40
//            font.pixelSize: 30
//        }

//        Flickable{
//            width: 180
//            height: parent.height - y - 100
//            contentHeight: column_patrol.height
//            anchors.horizontalCenter: parent.horizontalCenter
//            anchors.top: text_patrol.bottom
//            anchors.topMargin: 50
//            clip: true
//            Column{
//                id: column_patrol
//                anchors.centerIn: parent
//                Repeater{
//                    id: repeat_patrol
//                    model: patrolmodel
//                    Rectangle{
//                        width: 179
//                        height: 44
//                        color: "transparent"
//                        Rectangle{
//                            enabled: patrolmodel.get(index).type===2?false:true
//                            visible:patrolmodel.get(index).type===2?false:true
//                            anchors.fill: parent
//                            color:{
//                                if(patrolmodel.get(index).type == 0){
//                                    "#282828"
//                                }else{
//                                    "#d0d0d0"
//                                }
//                            }
//                            radius: 10
//                            border.width: 4
//                            border.color: "#d0d0d0"
//                            Text{
//                                anchors.centerIn: parent
//                                color:patrolmodel.get(index).type===0?"#d0d0d0":"#282828"
//                                text:patrolmodel.get(index).name
//                                font.family: font_noto_r.name
//                                font.pixelSize: 20
//                            }
//                        }
//                        Image{
//                            visible:patrolmodel.get(index).type===2?true:false
//                            anchors.centerIn: parent
//                            width: 22
//                            height: 13
//                            source: "icon/patrol_down.png"
//                        }
//                    }
//                }
//            }

//        }

//    }
    Rectangle{
        id: rect_calling_list
        visible: robot_type=="CALLING"?true:false
        width: (table_num/5).toFixed(0)*100 - 20 + 160
        height: parent.height - statusbar.height
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: statusbar.height
        color: "#282828"
        onWidthChanged: {
            margin_name = rect_table_box.width
        }

        Text{
            id: text_patrol
            color:"white"
            font.bold: true
            font.family: font_noto_b.name
            text: "호출 리스트"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            font.pixelSize: 30
        }

        Flickable{
            width: 180
            height: parent.height - y - 100
            contentHeight: column_call.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: text_patrol.bottom
            anchors.topMargin: 50
            clip: true
            Column{
                id: column_call
                spacing: 10
                Repeater{
                    model: ListModel{id:model_call}
                    Column{
                        spacing: 10
                        Image{
                            visible:index > 0?true:false
                            width: 22
                            height: 13
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: "icon/patrol_down.png"
                        }
                        Rectangle{
                            width: 170
                            height: 44
                            color: color_dark_black
                            radius: 10
                            border.width: 4
                            border.color: color_gray
                            Text{
                                anchors.centerIn: parent
                                color:color_gray
                                text:name
                                font.family: font_noto_r.name
                                font.pixelSize: 20
                            }
                            MouseArea{
                                anchors.fill: parent
                                onDoubleClicked: {
                                    supervisor.removeCall(index);
                                }
                            }
                        }
                    }


                }
            }
        }
    }

    Rectangle{
        id: rect_calling_box
        visible: robot_type=="CALLING"?true:false
        width: 500
        height: tray_num*tray_height + (tray_num - 1)*spacing_tray + 50
        color: "#e8e8e8"
        radius: 30
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
//        anchors.left: rect_table_box.right
//        anchors.leftMargin: traybox_margin
        Text{
            id: text_calling_box
            color:"white"
            font.bold: true
            font.family: font_noto_b.name
            text: ready_call?"호출 대기 중":"비활성화 됨"
            anchors.centerIn: parent
            font.pixelSize: 50
        }
    }


//    Rectangle{
//        id: rect_go_patrol
//        width: 300
//        visible: robot_type=="CALLING"?true:false
//        height: 100
//        radius: 100
//        anchors.horizontalCenter: rect_calling_box.horizontalCenter
//        anchors.top: rect_calling_box.bottom
//        anchors.topMargin: 40
//        color: "#24a9f7"
//        Text{
//            id: text_go2
//            anchors.centerIn: parent
//            text: "패트롤 시작"
//            font.family: font_noto_r.name
//            font.pixelSize: 35
//            font.bold: true
//            color: "white"
//        }
//        MouseArea{
//            id: btn_go2
//            anchors.fill: parent
//            onClicked: {
//                count_resting = 0;
//                go_patrol = true;
//                popup_question.visible = true;
//                print("patrol start button");
//            }
//        }
//    }

    Rectangle{
        id: rect_calling_enable
        width: 300
        visible: robot_type=="CALLING"?true:false
        height: 100
        radius: 100
        anchors.horizontalCenter: rect_calling_box.horizontalCenter
        anchors.top: rect_calling_box.bottom
        anchors.topMargin: 40
        color: "#24a9f7"
        Text{
            id: text_enable
            anchors.centerIn: parent
            text: ready_call?"비활성화":"활성화"
            font.family: font_noto_r.name
            font.pixelSize: 35
            font.bold: true
            color: "white"
        }
        MouseArea{
            anchors.fill: parent
            onClicked: {
                count_resting = 0;
                if(ready_call){
                    ready_call = false;
                }else{
                    ready_call = true;
                }
            }
        }
    }

    property var size_menu: 100
    Rectangle{
        id: rect_menu_box
        width: 120
        height: width*3
        anchors.right: parent.right
        anchors.rightMargin: 50
        anchors.top: parent.top
        anchors.topMargin: statusbar.height + 50
        color: "white"
        radius: 30
        Column{
            spacing: 10
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle{
                id: btn_menu
                width: size_menu
                height: size_menu
                color: "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                Image{
                    source:"icon/btn_menu.png"
                    anchors.centerIn: parent
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                            count_resting = 0;
                            cur_table = 0;
                            loadPage(pmenu);
                        }
                    }
                }
            }
            Rectangle{// 구분바
                width: rect_menu_box.width
                height: 3
                color: "#f4f4f4"
            }
            Rectangle{
                id: btn_charge
                width: size_menu
                height: size_menu
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle{
                    width: size_menu
                    height: image_charge.height+text_charge.height
                    anchors.centerIn: parent
                    Image{
                        id: image_charge
                        scale: 1.2
                        source:"icon/btn_charge.png"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text{
                        id: text_charge
                        text:"충전위치로"
                        font.family: font_noto_r.name
                        font.pixelSize: 15
                        color: "#525252"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: image_charge.bottom
                        anchors.topMargin: 10
                    }
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        count_resting = 0;
                        cur_table = 0;
                        go_charge = true;
                        popup_question.visible = true;
                    }
                }
            }
            Rectangle{// 구분바
                width: rect_menu_box.width
                height: 3
                color: "#f4f4f4"
            }
            Rectangle{
                width: size_menu
                height: size_menu
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle{
                    width: size_menu
                    height: image_wait.height+text_wait.height
                    anchors.centerIn: parent
                    Image{
                        id: image_wait
                        scale: 1.3
                        source:"icon/btn_wait.png"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text{
                        id: text_wait
                        text:"대기위치로"
                        font.family: font_noto_r.name
                        font.pixelSize: 15
                        color: "#525252"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: image_wait.bottom
                        anchors.topMargin: 10
                    }
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        count_resting = 0;
                        cur_table = 0;
                        go_wait = true;
                        popup_question.visible = true;
                    }
                }
            }
        }
    }

    Item{
        id: popup_question
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        visible: false
        Rectangle{
            anchors.fill: parent
            color: "#282828"
            opacity: 0.8
        }
        Image{
            id: image_location
            source:"image/image_location.png"
            width: 160
            height: 160
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 200
        }
        Text{
            id: text_quest
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:image_location.bottom
            anchors.topMargin: 30
            font.family: font_noto_b.name
            font.pixelSize: 40
            color: "#12d27c"
            text: {
                if(go_wait){
                    "대기 장소로 이동<font color=\"white\">하시겠습니까?</font>"
                }else if(go_charge){
                    "충전기로 이동<font color=\"white\">하시겠습니까?</font>"
                }else if(go_patrol){
                    "패트롤을 시작 <font color=\"white\">하시겠습니까?</font>"
                }else if(robot_type == "CALLING"){
                    "트레이를 모두 비우고<font color=\"white\"> 확인 버튼을 눌러주세요.</font>"
                }else{
                    ""
                }
            }
        }
        Rectangle{
            id: btn_no
            width: 250
            height: 90
            radius: 20
            visible: !go_charge&&!go_wait&&!go_patrol
            color: "#d0d0d0"
            anchors.top: text_quest.bottom
            anchors.topMargin: 50
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: 20
            Image{
                id: image_no
                source: "icon/btn_no.png"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
            }
            Text{
                id:text_nono
                text:"전부 취소"
                font.family: font_noto_b.name
                font.pixelSize: 30
                color:"#282828"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: image_no.right
                anchors.leftMargin : (parent.width - image_no.x - image_no.width)/2 - text_nono.width/2
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    supervisor.removeCallAll();
                    ready_call = false;
                    count_resting = 0;
                    go_wait = false;
                    go_charge = false;
                    go_patrol = false;
                    popup_question.visible = false;
                }
            }
        }

        Rectangle{
            id: btn_confirm
            width: 250
            height: 90
            radius: 20
            visible: !go_charge&&!go_wait&&!go_patrol
            color: "#d0d0d0"
            anchors.top: text_quest.bottom
            anchors.topMargin: 50
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: 20
//            anchors.horizontalCenter: parent.horizontalCenter
            Image{
                id: image_confirm
                source: "icon/btn_yes.png"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
            }
            Text{
                id:text_confirm
                text:"확인"
                font.family: font_noto_b.name
                font.pixelSize: 30
                color:"#282828"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: image_confirm.right
                anchors.leftMargin : (parent.width - image_confirm.x - image_confirm.width)/2 - text_confirm.width/2
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    count_resting = 0;
                    if(go_wait){
                        supervisor.moveToWait();
                    }else if(go_charge){
                        supervisor.moveToCharge();
                    }else if(go_patrol){

                    }else{

                    }
                    go_wait = false;
                    go_charge = false;
                    go_patrol = false;
                    ready_call = true;
                    popup_question.visible = false;
                }
            }
        }
        Rectangle{
            width: 250
            height: 90
            radius: 20
            visible: go_charge||go_wait||go_patrol
            color: "#d0d0d0"
            anchors.top: text_quest.bottom
            anchors.topMargin: 50
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: 20
            Image{
                id: image_nonono
                source: "icon/btn_no.png"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
            }
            Text{
                text:"아니오"
                font.family: font_noto_b.name
                font.pixelSize: 30
                color:"#282828"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: image_nonono.right
                anchors.leftMargin : (parent.width - image_nonono.x - image_nonono.width)/2 - width/2
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    count_resting = 0;
                    go_wait = false;
                    go_charge = false;
                    go_patrol = false;
                    popup_question.visible = false;
                }
            }
        }
        Rectangle{
            id: btn_yes
            width: 250
            height: 90
            radius: 20
            visible: go_charge||go_wait||go_patrol
            color: "#d0d0d0"
            anchors.top: text_quest.bottom
            anchors.topMargin: 50
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: 20
            Rectangle{
                color:"white"
                width: 240
                height: 80
                radius: 19
                anchors.centerIn: parent
            }
            Image{
                id: image_yes
                source: "icon/btn_yes.png"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
            }
            Text{
                text:"네"
                font.family: font_noto_b.name
                font.pixelSize: 30
                color:"#282828"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: image_yes.right
                anchors.leftMargin : (parent.width - image_yes.x - image_yes.width)/2 - width/2
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    count_resting = 0;
                    if(go_wait){
                        supervisor.moveToWait();
                    }else if(go_charge){
                        supervisor.moveToCharge();
                    }else if(go_patrol){
                        print("patrol start command");
                    }else if(robot_type == "CALLING"){
                    }
                    go_wait = false;
                    go_charge = false;
                    go_patrol = false;
                    popup_question.visible = false;
                }
            }
        }
    }

}
