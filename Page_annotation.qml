import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.2
import Qt.labs.platform 1.0
import QtGraphicalEffects 1.0
import "."
import io.qt.Supervisor 1.0
import QtMultimedia 5.12

Item {
    id: page_annotation
    objectName: "page_annotation"
    width: 1280
    height: 800

    //Tool Num (0: move, 1: drawing, 2: addPoint, 3: editPoint, 4: addLocation, 5: editLocation, 6: addTravelLine)
    property int tool_num: 0
    //Annotation State (0: state, 1: load/edit, 2: object, 3: location, 4: travel line)
    property int anot_state: 0
    property string image_name: "map_rotated"
    property string image_source: "file://" + applicationDirPath + "/image/" + image_name + ".png"
    property bool loadImage: false
    property var brush_size: 10

    property bool refreshMap: false
    property bool flag_margin: false

    property var grid_size: 0.02
    property int origin_x: 500
    property int origin_y: 500
    property var robot_radius: supervisor.getRobotRadius()

    property int select_object: -1
    property int select_object_point: -1
    property int select_location: -1
    property int select_line: -1
    property int select_travel_line: -1

    property int location_num: supervisor.getLocationNum();
    property int path_num: supervisor.getPathNum();
    property int object_num: supervisor.getObjectNum();
    property var location_types
    property var location_x
    property var location_y
    property var location_th
    property var robot_x: supervisor.getRobotx()/grid_size;
    property var robot_y: supervisor.getRoboty()/grid_size;
    property var robot_th:-supervisor.getRobotth()-Math.PI/2;

    Component.onCompleted: {
        var ob_num = supervisor.getObjectNum();
        list_object.model.clear();
        for(var i=0; i<ob_num; i++){
            list_object.model.append({"name":supervisor.getObjectName(i)});
        }

        var loc_num = supervisor.getLocationNum();
        list_location.model.clear();
        for(i=0; i<loc_num; i++){
            list_location.model.append({"name":supervisor.getLocationTypes(i),"iscol":false});
        }


        var travel_num = supervisor.getTlineSize();
        list_travel_line.model.clear();
        for(i=0; i<travel_num; i++){
            list_travel_line.model.append({"name":supervisor.getTlineName(i)});
        }
        select_travel_line = 0;



        var line_num = supervisor.getTlineSize(select_travel_line);
        list_line.model.clear();
        for(i=0; i<line_num; i=i+2){
            list_line.model.append({"name":"line_" + Number(i/2)});
        }

        updatecanvas();

    }

    function loadmap(path){
        image_map.source = path;
        image_map.isload = true;
        refreshMap = true;
        updatemap();
        updatecanvas();
    }

    function init(){
        while(stackview_menu.currentItem.objectName != "menu_init"){
            stackview_menu.pop();
        }
        anot_state = 0;
        tool_num = 0;
        refreshMap = true;
        updatecanvas();
    }

    function updateobject(){
        var ob_num = supervisor.getObjectNum();
        list_object.model.clear();
        for(var i=0; i<ob_num; i++){
            list_object.model.append({"name":supervisor.getObjectName(i)});
        }
        list_object.currentIndex = ob_num-1;
    }
    function updatelocation(){
        var loc_num = supervisor.getLocationNum();
        list_location.model.clear();
        for(var i=0; i<loc_num; i++){
            list_location.model.append({"name":supervisor.getLocationTypes(i),"iscol":false});
        }
        list_location.currentIndex = loc_num-1;
    }
    function updatecanvas(){
        canvas_map.requestPaint();
        canvas_object.requestPaint();
        canvas_location.requestPaint();
        canvas_map_margin.requestPaint();
        canvas_map_cur.requestPaint();
        canvas_travelline.requestPaint();
    }
    function updatelocationcollision(){
        for(var i=0; i<list_location.model.count; i++){
            if(is_Col_loc(supervisor.getLocationx(i)/grid_size + origin_x,supervisor.getLocationy(i)/grid_size + origin_y)){
                list_location.model.get(i).iscol = true;
            }else{
                list_location.model.get(i).iscol = false;
            }
        }
    }
    function updatetravelline(){
        var travel_num = supervisor.getTlineSize();
        list_travel_line.model.clear();
        for(var i=0; i<travel_num; i++){
            list_travel_line.model.append({"name":supervisor.getTlineName(i)});
        }

        var line_num = supervisor.getTlineSize(select_travel_line);
        print(line_num);
        list_line.model.clear();
        for(i=0; i<line_num; i=i+2){
            list_line.model.append({"name":"line_" + Number(i/2)});
        }
        list_line.currentIndex = line_num-1;
    }
    function updatelistline(){
        var line_num = supervisor.getTlineSize(select_travel_line);
        print(line_num);
        list_line.model.clear();
        for(var i=0; i<line_num; i=i+2){
            list_line.model.append({"name":"line_" + Number(i/2)});
        }
    }

    //Menu===================================================================
    Rectangle{
        id: rect_menus
        width: parent.width - rect_map.width
        height: 100
        color: "gray"

        Row{
            spacing: 25
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            Repeater{
                model: ["edit","back"]
                Rectangle{
                    width: 60
                    height: 60
                    color: "gray"
                    radius: 10
                    border.color: "white"
                    border.width: 3
                    Text{
                        anchors.centerIn: parent
                        text: modelData
                    }
                    MouseArea{
                        anchors.fill:parent
                        onClicked:{
                            if(modelData == "edit"){
                                anot_state = 1;
                                updatecanvas();
                                stackview_menu.push(menu_load_edit);
                            }else if(modelData == "back"){
                                anot_state = 0;
                                updatecanvas();
                                stackview.pop();
                                if(stackview.currentItem.objectName == "page_init")
                                    pinit.check_timer();
                            }
                        }
                    }
                }
            }
        }

        Text{
            anchors.right: parent.right
            anchors.bottom: parent.verticalCenter
            text: Number(-grid_size*(point1.y - origin_y))
        }
        Text{
            anchors.right: parent.right
            anchors.top: parent.verticalCenter
            text: Number(-grid_size*(point1.x - origin_x))
        }


    }

    //Annotation Menu========================================================
    Rectangle{
        id: rect_anot_menus
        width: rect_menus.width
        height: parent.height - rect_menus.height
        anchors.top: rect_menus.bottom
        color: "gray"
        property int menu_height: 40
        StackView{
            id: stackview_menu
            anchors.fill: parent
            initialItem: menu_state
        }
    }

    //Annotation Menu ITEM===================================================
    Item{
        id: menu_state
        objectName: "menu_init"
        width: parent.width
        height: parent.height
        visible: false
        Rectangle{
            anchors.fill: parent
            color: "white"
            Column{
                anchors.top: parent.top
                anchors.topMargin: 25
                spacing: 25
                Rectangle{
                    y: 20
                    width: menu_state.width
                    height: rect_anot_menus.menu_height
                    color: "yellow"
                    radius: 10
                    Text{
                        id: text_name
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 15
                        text: "Map : "
                    }
                }
                Rectangle{
                    width: menu_state.width
                    height: rect_anot_menus.menu_height
                    color: "yellow"
                    radius: 10

                }
                Rectangle{
                    width: menu_state.width
                    height: rect_anot_menus.menu_height
                    color: "yellow"
                    radius: 10

                }
                Rectangle{
                    width: menu_state.width
                    height: rect_anot_menus.menu_height
                    color: "yellow"
                    radius: 10

                }
            }

        }
    }
    Item{
        id: menu_load_edit
        width: parent.width
        height: parent.height
        visible: false
        Rectangle{
            width: parent.width
            height: parent.height
            anchors.fill: parent
            color: "white"
            Text{
                id: text_main_1
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 20
                text: "Step 1. Map annotation and edit location"
            }

            //map load
            Rectangle{
                id: text_cur_name
                anchors.top: text_main_1.bottom
                anchors.topMargin: 30
                width: parent.width
                height: rect_anot_menus.menu_height
                color: "yellow"
                radius: 10
                Text{
                    id: text_name2
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 15
                    text: " Current Map : "
                }
                Text{
                    id: text_name3
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 15
                    text: "/image/"+image_name + ".png";
                }
            }
            Rectangle{
                id: btn_load_map
                width: parent.width/2
                height: 60
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: text_cur_name.bottom
                anchors.topMargin: 30

                radius: 10
                border.width: 2
                border.color: "gray"

                Text{
                    anchors.centerIn: parent
                    text: "Load"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        fileload.open();
                    }
                }
            }


            //draw Menu
            Row{
                id: menubar_drawing
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: btn_load_map.bottom
                anchors.topMargin: 30
                spacing: 25
                Repeater{
                    model: ["move","draw","clear","undo","redo"]
                    Rectangle{
                        id: btn
                        width: 60
                        height: 60
                        color: {
                            if(tool_num == 0){
                                if(modelData == "move"){
                                    "blue"
                                }else{
                                    "gray"
                                }
                            }else if(tool_num == 1){
                                if(modelData == "draw"){
                                    "blue"
                                }else{
                                    "gray"
                                }
                            }else{
                                "gray"
                            }
                        }
                        radius: 10
                        Image{
                            anchors.centerIn:  parent
                            antialiasing: true
                            mipmap: true
                            scale: {(height>width?parent.width/height:parent.width/width)*0.8}
                            source:{
                                if(modelData == "move"){
                                    "./build/icon/icon_touch.png"
                                }else if(modelData == "draw"){
                                    "./build/icon/icon_save.png"
                                }else if(modelData == "clear"){
                                    "./build/icon/icon_clear.png"
                                }else if(modelData == "undo"){
                                    "./build/icon/icon_undo.png"
                                }else if(modelData == "redo"){
                                    "./build/icon/icon_redo.png"
                                }
                            }
                        }
                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                if(modelData == "move"){
                                    tool_num = 0;
                                }else if(modelData == "draw"){
                                    tool_num = 1;
                                }else if(modelData == "clear"){
                                    supervisor.clear_all();
                                    refreshMap = true;
                                    canvas_map.requestPaint();
                                }else if(modelData == "undo"){
                                    supervisor.undo();
                                    refreshMap = true;
                                    canvas_map.requestPaint();
                                }else if(modelData == "redo"){
                                    supervisor.redo();
                                    refreshMap = true;
                                    canvas_map.requestPaint();
                                }
                            }
                        }
                    }
                }
            }

            Row{
                id: colorbar
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: menubar_drawing.bottom
                anchors.topMargin: 30
                spacing: 25
                property color paintColor: "black"
                Repeater{
                    model: ["black", "#262626", "white"]
                    Rectangle {
                        id: red
                        width: 60
                        height: 60
                        color: modelData
                        border.color: "gray"
                        border.width: 2
                        radius: 60

                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                colorbar.paintColor = color
                                tool_num = 1;
                            }
                        }
                    }
                }
            }

            Slider {
                id: slider_brush
                x: 300
                y: 330
                value: 15
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: colorbar.bottom
                anchors.topMargin: 20
                width: parent.width/1.5
                height: 30
                from: 0.1
                to : 50
//                orientation: Qt.Vertical
                onValueChanged: {
                    brush_size = value;
                    canvas_map.lineWidth = brush_size;
                    print("slider : " +brush_size);
                }
                onPressedChanged: {
                    if(slider_brush.pressed){
                        brushview.visible = true;
                    }else{
                        brushview.visible =false;
                    }
                }
            }



            //prev, next button
            Rectangle{
                id: btn_prev_1
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Previous"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        anot_state = 0;
                        tool_num = 0;
                        stackview_menu.pop();
                        updatecanvas();
                    }
                }
            }
            Rectangle{
                id: btn_next_1
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Next"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        //save temp Image
                        canvas_map.save("image/map_edited.png");
                        image_name = "map_edited";
                        image_source = "file://" + applicationDirPath + "/image/" + image_name + ".png";
                        supervisor.clear_all();
                        anot_state = 2;
                        tool_num = 0;
                        stackview_menu.push(menu_object);
                        updatecanvas();
                    }
                }
            }
        }
    }
    Item{
        id: menu_object
        width: parent.width
        height: parent.height
        visible: false
        Rectangle{
            anchors.fill: parent
            color: "white"
            Text{
                id: text_main_2
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 20
                text: "Step 2. Add Object"
            }
            Row{
                id: menubar_object
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: text_main_2.bottom
                anchors.topMargin: 30
                spacing: 25
                Repeater{
                    model: ["move","add","clear","undo","redo"]
                    Rectangle{
                        id: btn2
                        width: 60
                        height: 60
                        color: {
                            if(tool_num == 0){
                                if(modelData == "move"){
                                    "blue"
                                }else{
                                    "gray"
                                }
                            }else if(tool_num == 2){
                                if(modelData == "add"){
                                    "blue"
                                }else{
                                    "gray"
                                }
                            }else{
                                "gray"
                            }
                        }
                        radius: 10
                        Image{
                            anchors.centerIn:  parent
                            antialiasing: true
                            mipmap: true
                            scale: {(height>width?parent.width/height:parent.width/width)*0.8}
                            source:{
                                if(modelData == "move"){
                                    "./build/icon/icon_touch.png"
                                }else if(modelData == "add"){
                                    "./build/icon/icon_save.png"
                                }else if(modelData == "clear"){
                                    "./build/icon/icon_clear.png"
                                }else if(modelData == "undo"){
                                    "./build/icon/icon_undo.png"
                                }else if(modelData == "redo"){
                                    "./build/icon/icon_redo.png"
                                }
                            }
                        }
                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                if(modelData == "move"){
                                    tool_num = 0;
                                }else if(modelData == "add"){
                                    tool_num = 2;
                                }else if(modelData == "clear"){
                                    supervisor.clearObjectPoints();
                                    canvas_object.requestPaint();
                                }else if(modelData == "undo"){
                                    supervisor.removeObjectPointLast();
                                    canvas_object.requestPaint();
                                }else if(modelData == "redo"){
                                }
                            }
                        }
                    }
                }
            }

            //List Object
            Component {
                id: objectCompo
                Item {
                    width: 250; height: 30
                    Text {
                        anchors.centerIn: parent
                        text: name
                    }
                    Rectangle//리스트의 구분선
                    {
                        id:line
                        width:parent.width
                        anchors.bottom:parent.bottom//현재 객체의 아래 기준점을 부모객체의 아래로 잡아주어서 위치가 아래로가게 설정
                        height:1
                        color:"black"
                    }
                    MouseArea{
                        id:area_compo
                        anchors.fill:parent
                        onClicked: {
                            select_object = supervisor.getObjNum(name);
                            print("select object = "+select_object);
                            list_object.currentIndex = index;
                            canvas_object.requestPaint();
                        }
                    }
                }
            }
            ListView {
                id: list_object
                width: 250
                height: 400
                anchors.top: menubar_object.bottom
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 30
                clip: true
                model: ListModel{}
                delegate: objectCompo
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                focus: true
            }

            Column{
                id: menubar_object2
                anchors.verticalCenter: list_object.verticalCenter
                anchors.left: list_object.right
                anchors.leftMargin: 40
                spacing: 30
                Repeater{
                    model: ["add","edit","remove"]
                    Rectangle{
                        id: btn3
                        width: 60
                        height: 60
                        color: "gray"
                        radius: 10
                        Image{
                            anchors.centerIn:  parent
                            antialiasing: true
                            mipmap: true
                            scale: {(height>width?parent.width/height:parent.width/width)*0.8}
                            source:{
                                if(modelData == "edit"){
                                    "./build/icon/icon_touch.png"
                                }else if(modelData == "remove"){
                                    "./build/icon/icon_save.png"
                                }else if(modelData == "add"){
                                    "./build/icon/icon_save.png"
                                }
                            }
                        }
                        Text{
                            anchors.centerIn: parent
                            text: modelData
                        }

                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                if(modelData == "edit"){
                                    tool_num = 3;
                                }else if(modelData == "remove"){
                                    supervisor.removeObject(list_object.model.get(list_object.currentIndex).name);
                                    canvas_object.requestPaint();
                                }else if(modelData == "add"){
                                    popup_add_object.open();
                                }
                            }
                        }
                    }
                }
            }

            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Previous"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        anot_state = 1;
                        tool_num = 0;
                        stackview_menu.pop();
                        updatecanvas();
                    }
                }
            }
            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Next"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
//                        supervisor.clear_all();
                        anot_state = 3;
                        tool_num = 0;
                        find_map_walls();
                        updatecanvas();
                        stackview_menu.push(menu_location);
                    }
                }
            }
        }
    }
    Item{
        id: menu_location
        width: parent.width
        height: parent.height
        visible: false
        Rectangle{
            anchors.fill: parent
            color: "white"
            Text{
                id: text_main_3
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 20
                text: "Step 3. Set Margin"
            }
            Slider{
                id: slider_margin
                anchors.top: text_main_3.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 50
                from: 0
                to: 1
                value: supervisor.getMargin()
                onValueChanged: {
                    canvas_map_margin.requestPaint();
                    update_checker.restart();
                }
            }
            Text{
                id: text_margin
                anchors.top: slider_margin.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 20
                text: "Margin [m] = " + slider_margin.value
            }

            //List Object
            Component {
                id: locationCompo
                Item {
                    width: 250; height: 30
                    Text {
                        id: text_loc
                        anchors.centerIn: parent
                        text: name
                        font.bold: iscol
                        color: iscol?"red":"black"
                    }
                    Rectangle//리스트의 구분선
                    {
                        id:line
                        width:parent.width
                        anchors.bottom:parent.bottom//현재 객체의 아래 기준점을 부모객체의 아래로 잡아주어서 위치가 아래로가게 설정
                        height:1
                        color:"black"
                    }
                    MouseArea{
                        id:area_compo
                        anchors.fill:parent
                        onClicked: {
                            select_location = supervisor.getLocNum(name);
                            print("select location = "+select_location);
                            list_location.currentIndex = index;
                            canvas_location.requestPaint();
                        }
                    }
                }
            }
            ListView {
                id: list_location
                width: 250
                height: 400
                anchors.top: text_margin.bottom
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 30
                clip: true
                model: ListModel{}
                delegate: locationCompo
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                focus: true
            }

            Column{
                id: menubar_location
                anchors.verticalCenter: list_location.verticalCenter
                anchors.left: list_location.right
                anchors.leftMargin: 40
                spacing: 30
                Repeater{
                    model: ["move","add","edit","remove"]
                    Rectangle{
                        id: btn4
                        width: 60
                        height: 60
                        color: {
                            if(tool_num == 4 && modelData == "add")
                                "blue"
                            else if(tool_num == 5 && modelData == "edit")
                                "blue"
                            else
                                "gray"


                        }
                        radius: 10
                        Image{
                            anchors.centerIn:  parent
                            antialiasing: true
                            mipmap: true
                            scale: {(height>width?parent.width/height:parent.width/width)*0.8}
                            source:{
                                if(modelData == "edit"){
                                    "./build/icon/icon_touch.png"
                                }else if(modelData == "remove"){
                                    "./build/icon/icon_save.png"
                                }else if(modelData == "add"){
                                    "./build/icon/icon_save.png"
                                }else if(modelData == "move"){
                                    "./build/icon/icon_save.png"
                                }
                            }
                        }
                        Text{
                            anchors.centerIn: parent
                            text: modelData
                        }
                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                if(modelData == "edit"){
                                    tool_num = 5;
                                }else if(modelData == "remove"){
                                    if(list_location.currentIndex > 0){
                                        supervisor.removeLocation(list_location.model.get(list_location.currentIndex).name);
                                        select_location = -1;
                                        canvas_location.requestPaint();
                                    }
                                }else if(modelData == "add"){
                                    if(tool_num == 4){
                                        if(canvas_location.new_loc_available){
                                            popup_add_location.open();
                                        }else{

                                        }
                                    }else{
                                        tool_num = 4;
                                    }
                                }else if(modelData == "move"){
                                    tool_num = 0;
                                }
                            }
                        }
                    }
                }
            }

            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Previous"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        anot_state = 2;
                        tool_num = 0;
                        stackview_menu.pop();
                        updatecanvas();
                    }
                }
            }
            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Next"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        tool_num = 0;
                        anot_state = 4;
                        updatecanvas();
                        stackview_menu.push(menu_travelline);
                    }
                }
            }
        }
    }
    Item{
        id: menu_travelline
        width: parent.width
        height: parent.height
        visible: false
        Rectangle{
            anchors.fill: parent
            color: "white"
            Text{
                id: text_main_4
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 20
                text: "Step 4. Travel Line"
            }



            //List Object
            Component {
                id: lineCompo
                Item {
                    width: 250; height: 30
                    Text {
                        anchors.centerIn: parent
                        text: name
                    }
                    Rectangle//리스트의 구분선
                    {
                        id:line
                        width:parent.width
                        anchors.bottom:parent.bottom//현재 객체의 아래 기준점을 부모객체의 아래로 잡아주어서 위치가 아래로가게 설정
                        height:1
                        color:"black"
                    }
                    MouseArea{
                        id:area_compo
                        anchors.fill:parent
                        onClicked: {
                            select_line = index;
                            print("select line = "+select_line);
                            list_line.currentIndex = index;
                            canvas_travelline.requestPaint();
                        }
                    }
                }
            }
            Component {
                id: travellineCompo
                Item {
                    width: 250; height: 30
                    Text {
                        anchors.centerIn: parent
                        text: name
                    }
                    Rectangle//리스트의 구분선
                    {
                        id:line
                        width:parent.width
                        anchors.bottom:parent.bottom//현재 객체의 아래 기준점을 부모객체의 아래로 잡아주어서 위치가 아래로가게 설정
                        height:1
                        color:"black"
                    }
                    MouseArea{
                        id:area_compo
                        anchors.fill:parent
                        onClicked: {
                            select_travel_line = index;
                            print("select travel line = "+select_travel_line);
                            list_travel_line.currentIndex = index;
                            updatelistline();
                            canvas_travelline.requestPaint();
                        }
                    }
                }
            }
            ListView{
                id: list_travel_line
                width: 250
                height: 100
                anchors.top: text_main_4.bottom
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 30
                clip: true
                model: ListModel{}
                delegate: travellineCompo
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                focus: true
            }

            ListView {
                id: list_line
                width: 250
                height: 200
                anchors.top: list_travel_line.bottom
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 30
                clip: true
                model: ListModel{}
                delegate: lineCompo
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                focus: true
            }

            Column{
                id: menubar_line
                anchors.verticalCenter: list_line.verticalCenter
                anchors.left: list_line.right
                anchors.leftMargin: 40
                spacing: 30
                Repeater{
                    model: ["add","remove"]
                    Rectangle{
                        id: btn5
                        width: 60
                        height: 60
                        color: {
                            if(tool_num == 6 && modelData == "add")
                                "blue"
                            else
                                "gray"
                        }
                        radius: 10
                        Image{
                            anchors.centerIn:  parent
                            antialiasing: true
                            mipmap: true
                            scale: {(height>width?parent.width/height:parent.width/width)*0.8}
                            source:{
                                if(modelData == "remove"){
                                    "./build/icon/icon_save.png"
                                }else if(modelData == "add"){
                                    "./build/icon/icon_save.png"
                                }
                            }
                        }
                        Text{
                            anchors.centerIn: parent
                            text: modelData
                        }

                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                if(modelData == "remove"){
                                    supervisor.removeTline(0,list_line.currentIndex);
                                    canvas_travelline.requestPaint();
                                }else if(modelData == "add"){
                                    if(tool_num == 6){
                                        if(canvas_travelline.ispoint1 && canvas_travelline.ispoint2){
                                            supervisor.addTline(0,canvas_travelline.x1,canvas_travelline.y1,canvas_travelline.x2,canvas_travelline.y2);
                                        }
                                        //cancel
                                        canvas_travelline.ispoint1 = false;
                                        canvas_travelline.ispoint2 = false;
                                        tool_num = 0;

                                    }else{
                                        tool_num = 6;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Previous"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        anot_state = 3;
                        tool_num = 0;
                        stackview_menu.pop();
                        updatecanvas();
                    }
                }
            }
            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Next"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        tool_num = 0;
                        anot_state = 5;
                        updatecanvas();
                        stackview_menu.push(menu_save);
                    }
                }
            }
        }
    }
    Item{
        id: menu_save
        width: parent.width
        height: parent.height
        visible: false
        Rectangle{
            anchors.fill: parent
            color: "white"
            Text{
                id: text_main_5
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 20
                text: "Save"
            }
            //현재 어노테이션 상태 체크 화면

            //저장
            Rectangle{
                id: btn_save_meta
                width: 100
                height: 60
                anchors.top: text_main_5.bottom
                anchors.topMargin: 50
                anchors.right: parent.horizontalCenter
                anchors.rightMargin: 30
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Meta 저장"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        filesavemeta.open();
                    }
                }
            }
            Rectangle{
                id:btn_save_annot
                width: 100
                height: 60
                anchors.top: text_main_5.bottom
                anchors.topMargin: 50
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 30
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Annot 저장"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        filesaveannot.open();
                    }
                }
            }
            //서버에 전송
            Rectangle{
                width: 100
                height: 60
                anchors.top: btn_save_annot.bottom
                anchors.topMargin: 50
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "서버에 전송"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        supervisor.sendMaptoServer();
                    }
                }
            }

            //뒤로가기
            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Previous"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        anot_state = 4;
                        tool_num = 0;
                        stackview_menu.pop();
                        updatecanvas();
                    }
                }
            }
            Rectangle{
                width: parent.width/2
                height: 60
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                radius: 10
                border.width: 2
                border.color: "gray"
                Text{
                    anchors.centerIn: parent
                    text: "Confirm"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked:{
                        init();
                    }
                }
            }
        }
    }

    //Map Canvas ===========================================================
    function find_map_walls(){
        print("find map walls");
        supervisor.clearMarginObj();

        var ctx = canvas_map.getContext('2d');
        var map_data = ctx.getImageData(0,0,image_map.width, image_map.height);

        for(var x=0; x< map_data.data.length; x=x+4){
            if(map_data.data[x] > 100){
                supervisor.setMarginPoint(Math.abs(x/4));
            }
        }


        var ctx1 = canvas_object.getContext('2d');
        var map_data1 = ctx1.getImageData(0,0,image_map.width, image_map.height);

        for(x=0; x< map_data1.data.length; x=x+4){
            if(map_data1.data[x+3] > 0){
                supervisor.setMarginPoint(Math.abs(x/4));
            }
        }

//        supervisor.setMarginObj();
    }
    function is_Col_loc(x,y){
        if(image_map.isload){

            var ctx = canvas_map.getContext('2d');
            var ctx1 = canvas_map_margin.getContext('2d');
            var ctx_robot = canvas_robot.getContext('2d');
            var map_data = ctx.getImageData(0,0,image_map.width, image_map.height)
            var map_data1 = ctx1.getImageData(0,0,image_map.width,image_map.height);
            var robot_data = ctx_robot.getImageData(0,0,canvas_robot.width,canvas_robot.height);
            for(var i=0; i<robot_data.data.length; i=i+4){
                if(robot_data.data[i+3] > 0){
                    var robot_x = Math.floor((i/4)%canvas_robot.width + x - canvas_robot.width/2);
                    var robot_y = Math.floor((i/4)/canvas_robot.width + y - canvas_robot.width/2);
                    var pixel_num = robot_y*canvas_map.width + robot_x;
                    if(map_data.data[pixel_num*4] == 0 || map_data.data[pixel_num*4] > 100){
                        //collision walls
                        return true;
                    }else if(map_data1.data[pixel_num*4+3] > 0){
                        //collision to margin
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function draw_canvas_lines(){
        var ctx = canvas_map.getContext('2d');
        for(var i=0; i<supervisor.getCanvasSize(); i++){
            ctx.lineWidth = supervisor.getLineWidth(i);
            ctx.strokeStyle = supervisor.getLineColor(i);
            ctx.lineCap = "round"
            ctx.beginPath()
            canvas_map.lineX = supervisor.getLineX(i);
            canvas_map.lineY = supervisor.getLineY(i);
            for(var j=0;j<canvas_map.lineX.length-1;j++){
                ctx.moveTo(canvas_map.lineX[j], canvas_map.lineY[j])
                ctx.lineTo(canvas_map.lineX[j+1], canvas_map.lineY[j+1])
            }
            ctx.stroke()
        }
    }
    function draw_canvas_map(){
        var ctx = canvas_map.getContext('2d');
        ctx.drawImage(image_map,0,0,image_map.width,image_map.height);
    }
    function draw_canvas_location(){
        var ctx = canvas_location.getContext('2d');
        location_num = supervisor.getLocationNum();
        for(var i=0; i<location_num; i++){
            var loc_type = supervisor.getLocationTypes(i);
            var loc_x = supervisor.getLocationx(i)/grid_size;
            var loc_y = supervisor.getLocationy(i)/grid_size;
            var loc_th = -supervisor.getLocationth(i)-Math.PI/2;

//                        console.log(loc_type,loc_x,loc_y,loc_th);

            if(select_location == i){
                ctx.lineWidth = 3;
                ctx.strokeStyle = "yellow";
            }else{
                ctx.lineWidth = 1;
                if(loc_type.slice(0,4) == "Char"){
                    ctx.strokeStyle = "green";
                }else if(loc_type.slice(0,4) == "Rest"){
                    ctx.strokeStyle = "white";
                }else if(loc_type.slice(0,4) == "Patr"){
                    ctx.strokeStyle = "blue";
                }else if(loc_type.slice(0,4) == "Tabl"){
                    ctx.strokeStyle = "gray";
                }
            }

            ctx.beginPath();
            ctx.moveTo(loc_x+origin_x,loc_y+origin_y);
            ctx.arc(loc_x+origin_x,loc_y+origin_y,robot_radius/grid_size, loc_th, loc_th+2*Math.PI, true);
            ctx.moveTo(loc_x+origin_x,loc_y+origin_y);
            ctx.stroke()
        }
    }
    function draw_canvas_location_temp(){
        if(canvas_location.isnewLoc){
            var ctx = canvas_location.getContext('2d');
            ctx.lineWidth = 3;
            if(is_Col_loc(canvas_location.new_loc_x,canvas_location.new_loc_y)){
                ctx.strokeStyle = "red";
                canvas_location.new_loc_available = false;
            }else{
                ctx.strokeStyle = "yellow";
                canvas_location.new_loc_available = true;
            }
            ctx.beginPath();
            ctx.moveTo(canvas_location.new_loc_x,canvas_location.new_loc_y);
            ctx.arc(canvas_location.new_loc_x,canvas_location.new_loc_y,robot_radius/grid_size, -canvas_location.new_loc_th-Math.PI/2, -canvas_location.new_loc_th-Math.PI/2+2*Math.PI, true);
            ctx.moveTo(canvas_location.new_loc_x,canvas_location.new_loc_y);
            ctx.stroke()
        }
    }

    function draw_canvas_object(){
        var ctx = canvas_object.getContext('2d');
        object_num = supervisor.getObjectNum();
        ctx.lineWidth = 1;
        ctx.lineCap = "round";
        ctx.strokeStyle = "white";
        for(var i=0; i<object_num; i++){
            var obj_type = supervisor.getObjectName(i);
            var obj_size = supervisor.getObjectPointSize(i);
            var obj_x = supervisor.getObjectX(i,0)/grid_size +origin_x;
            var obj_y = supervisor.getObjectY(i,0)/grid_size +origin_y;
            var obj_x0 = obj_x;
            var obj_y0 = obj_y;

            if(select_object == i){
                ctx.strokeStyle = "yellow";
                ctx.fillStyle = "steelblue";
                ctx.lineWidth = 3;
            }else{
                ctx.strokeStyle = "blue";
                ctx.fillStyle = "steelblue";
                ctx.lineWidth = 1;
            }

            ctx.beginPath();
            ctx.moveTo(obj_x,obj_y);
            for(var j=1; j<obj_size; j++){
                obj_x = supervisor.getObjectX(i,j)/grid_size + origin_x;
                obj_y = supervisor.getObjectY(i,j)/grid_size + origin_y;
                ctx.lineTo(obj_x,obj_y);
            }
            ctx.lineTo(obj_x0,obj_y0);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            ctx.lineWidth = 1;
            ctx.strokeStyle = "red";
            ctx.fillStyle = "red";
            for(j=0; j<obj_size; j++){
                ctx.beginPath();
                obj_x = supervisor.getObjectX(i,j)/grid_size +origin_x;
                obj_y = supervisor.getObjectY(i,j)/grid_size +origin_y;
                ctx.moveTo(obj_x,obj_y);
                ctx.arc(obj_x,obj_y,2,0, Math.PI*2);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
            }
        }
    }
    function draw_canvas_cur_pose(){
        var ctx = canvas_map_cur.getContext('2d');
        robot_x = supervisor.getRobotx()/grid_size;
        robot_y = supervisor.getRoboty()/grid_size;
        robot_th = -supervisor.getRobotth()-Math.PI/2;
//                    print(robot_x,robot_y,robot_th);
        ctx.strokeStyle = "cyan";
        ctx.beginPath();
        ctx.moveTo(robot_x+origin_x,robot_y+origin_y);
        ctx.arc(robot_x+origin_x,robot_y+origin_y,robot_radius/grid_size, robot_th, robot_th+2*Math.PI, true);
        ctx.stroke()
        ctx.fillStyle = "black";
        ctx.fill()
        ctx.moveTo(robot_x+origin_x,robot_y+origin_y);
        ctx.lineTo(robot_x+origin_x,robot_y+origin_y)
        ctx.stroke()
    }
    function draw_canvas_new_object(){
        var ctx = canvas_object.getContext('2d');
        var point_num = supervisor.getTempObjectSize();
        if(point_num > 0){
            ctx.lineCap = "round";
            ctx.strokeStyle = "yellow";
            ctx.fillStyle = "steelblue";
            ctx.lineWidth = 3;
            var point_x = supervisor.getTempObjectX(0)/grid_size + origin_x;
            var point_y = supervisor.getTempObjectY(0)/grid_size + origin_y;
            var point_x0 = point_x;
            var point_y0 = point_y;

            if(point_num > 2){
                ctx.beginPath();
                ctx.moveTo(point_x,point_y);
                for(var i=1; i<point_num; i++){
                    point_x = supervisor.getTempObjectX(i)/grid_size + origin_x;
                    point_y = supervisor.getTempObjectY(i)/grid_size + origin_y;
                    ctx.lineTo(point_x,point_y);
                }
                if(point_num > 2){
                    ctx.lineTo(point_x0,point_y0);
                }
                ctx.fill();
                ctx.stroke();
            }else if(point_num > 1){
                ctx.beginPath()
                ctx.moveTo(point_x,point_y)
                point_x = supervisor.getTempObjectX(1)/grid_size + origin_x;
                point_y = supervisor.getTempObjectY(1)/grid_size + origin_y;
                ctx.lineTo(point_x,point_y)
                ctx.stroke();
            }

            ctx.lineWidth = 1;
            ctx.strokeStyle = "red";
            ctx.fillStyle = "red";
            point_x = supervisor.getTempObjectX(0)/grid_size + origin_x;
            point_y = supervisor.getTempObjectY(0)/grid_size + origin_y;
            for(i=0; i<point_num; i++){
                ctx.beginPath();
                point_x = supervisor.getTempObjectX(i)/grid_size + origin_x;
                point_y = supervisor.getTempObjectY(i)/grid_size + origin_y;
                ctx.moveTo(point_x,point_y);
                ctx.arc(point_x,point_y,2,0, Math.PI*2);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
            }
        }

    }

    function draw_canvas_margin(){
        var ctx1 = canvas_map.getContext('2d');
        var map_data = ctx1.getImageData(0,0,image_map.width, image_map.height);

        var ctx = canvas_map_margin.getContext('2d');
        var margin_obj = supervisor.getMarginObj();

        ctx.lineWidth = 0;
        ctx.lineCap = "round"
        ctx.strokeStyle = "cyan";
        ctx.fillStyle = "cyan";
        for(var i=0; i<margin_obj.length; i++){
            var point_x = (margin_obj[i])%image_map.width;
            var point_y = Math.floor((margin_obj[i])/image_map.width);
            ctx.beginPath();
            ctx.moveTo(point_x,point_y);
            ctx.arc(point_x,point_y,slider_margin.value/grid_size,0,Math.PI*2);
            ctx.fill();
            ctx.stroke();
        }

        ctx.fillStyle = "red";
        ctx.strokeStyle = "red";
        for(var x=0; x< map_data.data.length; x=x+4){
            if(map_data.data[x] > 100){
                ctx.beginPath();
                ctx.moveTo((x/4)%image_map.width,Math.floor((x/4)/image_map.width));
                ctx.arc((x/4)%image_map.width,Math.floor((x/4)/image_map.width),0.5,0,Math.PI*2);
                ctx.fill();
                ctx.stroke();
            }
        }

        flag_margin = true;
    }

    function draw_canvas_travelline(){
        var ctx = canvas_travelline.getContext('2d');

        ctx.lineCap = "round";

        var tline_num = supervisor.getTlineSize();
        print(tline_num);
        for(var i=0; i<tline_num; i++){
            var linenum = supervisor.getTlineSize(i);
            for(var j=0; j<linenum; j=j+2){

                if(select_travel_line == i && select_line == j/2){
                    ctx.lineWidth = 5;
                    ctx.strokeStyle = "yellow";
                }else{
                    ctx.lineWidth = 3;
                    ctx.strokeStyle = "red";
                }

                var linex = supervisor.getTlineX(i,j)/grid_size + origin_x;
                var liney = supervisor.getTlineY(i,j)/grid_size + origin_y;
                ctx.beginPath();
                ctx.moveTo(linex,liney);
                print(linex,liney);
                linex = supervisor.getTlineX(i,j+1)/grid_size + origin_x;
                liney = supervisor.getTlineY(i,j+1)/grid_size + origin_y;
                ctx.lineTo(linex,liney);
                print(linex,liney);
                ctx.stroke();
            }
        }

        if(canvas_travelline.ispoint1 && canvas_travelline.ispoint2){
            ctx.strokeStyle = "red";
            ctx.beginPath();
            ctx.moveTo(canvas_travelline.x1,canvas_travelline.y1);
            ctx.lineTo(canvas_travelline.x2, canvas_travelline.y2);
            ctx.stroke();
        }

        if(canvas_travelline.ispoint1){
            ctx.fillStyle = "yellow";
            ctx.strokeStyle = "yellow";
            ctx.beginPath();
            ctx.moveTo(canvas_travelline.x1,canvas_travelline.y1);
            ctx.arc(canvas_travelline.x1,canvas_travelline.y1,2,0,Math.PI*2);
            ctx.fill();
            ctx.stroke();
        }
        if(canvas_travelline.ispoint2){
            ctx.fillStyle = "yellow";
            ctx.strokeStyle = "yellow";
            ctx.beginPath();
            ctx.moveTo(canvas_travelline.x2,canvas_travelline.y2);
            ctx.arc(canvas_travelline.x2,canvas_travelline.y2,2,0,Math.PI*2);
            ctx.fill();
            ctx.stroke();
        }


    }

    Canvas{
        id: canvas_robot
        visible: false
        width: (robot_radius/grid_size)*2
        height: (robot_radius/grid_size)*2
        onPaint: {
            var ctx = getContext('2d');
            ctx.clearRect(0,0,width,height);
            ctx.lineWidth = 1;
            ctx.fillStyle = "yellow";
            ctx.strokeStyle = "yellow";
            ctx.beginPath();
            ctx.moveTo(width/2,width/2);
            ctx.arc(width/2,width/2,robot_radius/grid_size, 0, 2*Math.PI, true);
            ctx.moveTo(width/2,width/2);
            ctx.fill()
            ctx.stroke()
        }
    }

    Rectangle{
        id: rect_map
        width: 800
        height: 800
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right;

        Canvas{
            id: canvas_map
            width: image_map.width
            height: image_map.height
            antialiasing: true
            property color color: colorbar.paintColor
            property var lineWidth: brush_size

            property real lastX
            property real lastY
            property var lineX
            property var lineY

            Behavior on scale{
                NumberAnimation{
                    duration: 300
                }
            }
            Behavior on x{
                NumberAnimation{
                    duration: 100
                }
            }
            Behavior on y{
                NumberAnimation{
                    duration: 100
                }
            }

            onXChanged: {
                if(canvas_map.x  > canvas_map.width*(canvas_map.scale - 1)/2){
                    canvas_map.x = canvas_map.width*(canvas_map.scale - 1)/2
                }else if(canvas_map.x < -(canvas_map.width*(canvas_map.scale - 1)/2 + canvas_map.width - rect_map.width)){
                    canvas_map.x = -(canvas_map.width*(canvas_map.scale - 1)/2 + canvas_map.width - rect_map.width)
                }
                requestPaint();
            }
            onYChanged: {
                if(canvas_map.y  > canvas_map.height*(canvas_map.scale - 1)/2){
                    canvas_map.y = canvas_map.height*(canvas_map.scale - 1)/2
                }else if(canvas_map.y < -(canvas_map.height*(canvas_map.scale - 1)/2 + canvas_map.height - rect_map.height)){
                    canvas_map.y = -(canvas_map.height*(canvas_map.scale - 1)/2 + canvas_map.height - rect_map.height)
                }
                requestPaint();
            }
            onScaleChanged: {
                if(canvas_map.x  > canvas_map.width*(canvas_map.scale - 1)/2){
                    canvas_map.x = canvas_map.width*(canvas_map.scale - 1)/2
                }else if(canvas_map.x < -(canvas_map.width*(canvas_map.scale - 1)/2 + canvas_map.width - rect_map.width)){
                    canvas_map.x = -(canvas_map.width*(canvas_map.scale - 1)/2 + canvas_map.width - rect_map.width)
                }

                if(canvas_map.y  > canvas_map.height*(canvas_map.scale - 1)/2){
                    canvas_map.y = canvas_map.height*(canvas_map.scale - 1)/2
                }else if(canvas_map.y < -(canvas_map.height*(canvas_map.scale - 1)/2 + canvas_map.height - rect_map.height)){
                    canvas_map.y = -(canvas_map.height*(canvas_map.scale - 1)/2 + canvas_map.height - rect_map.height)
                }
            }

            onPaint:{
                var ctx = canvas_map.getContext('2d');

                if(image_map.isload){

                    if(refreshMap){
                        refreshMap = false;
                        ctx.clearRect(0,0,canvas_map.width, canvas_map.height);
                        draw_canvas_map();
                        if(anot_state == 1){
                            draw_canvas_lines();
                        }else if(anot_state == 3){
                        }
                    }

                    // Draw new object
                    if(tool_num == 1){
                        ctx.lineWidth = canvas_map.lineWidth
                        ctx.strokeStyle = canvas_map.color
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.moveTo(lastX, lastY)
                        if(point1.pressed){
                            lastX = point1.x
                            lastY = point1.y
                        }
                        supervisor.setLine(lastX,lastY);
                        ctx.lineTo(lastX, lastY)
                        ctx.stroke()
                    }else{
    //                    if(anot_state == 1){ //draw
    //                        draw_canvas_lines();
    //                    }
                    }
                }

            }
        }

        Canvas{
            id: canvas_map_margin
            width: image_map.width
            height: image_map.height
            antialiasing: true
            x: canvas_map.x
            y: canvas_map.y
            scale: canvas_map.scale
            onPaint: {
                var ctx = canvas_map_margin.getContext('2d');
                if(image_map.isload){
                    ctx.clearRect(0,0,canvas_map_margin.width,canvas_map_margin.height);
                    if(anot_state == 3 || anot_state == 4){
                        flag_margin = false;
                        draw_canvas_margin();
                    }
                }
            }
        }

        Canvas{
            id: canvas_object
            width: canvas_map.width
            height: canvas_map.height
            x: canvas_map.x
            y: canvas_map.y
            scale: canvas_map.scale
            antialiasing: true
            onPaint:{
                var ctx = getContext("2d");
                if(image_map.isload){
                    ctx.clearRect(0,0,canvas_object.width,canvas_object.height);

                    // Draw canvas
                    if(anot_state != 1){
                        draw_canvas_new_object();
                        draw_canvas_object();
                    }
                }
            }
        }

        Canvas{
            id: canvas_location
            width: canvas_map.width
            height: canvas_map.height
            x: canvas_map.x
            y: canvas_map.y
            scale: canvas_map.scale
            antialiasing: true

            property bool isnewLoc: false
            property var new_loc_x;
            property var new_loc_y;
            property var new_loc_th;
            property bool new_loc_available: false
            onPaint:{
                var ctx = getContext("2d");
                if(image_map.isload){

                    ctx.clearRect(0,0,canvas_location.width,canvas_location.height);

                    if(anot_state == 0 || anot_state == 3){
                        draw_canvas_location();
                        draw_canvas_location_temp();
                    }
                }
            }
        }

        Canvas{
            id: canvas_travelline
            width: canvas_map.width
            height: canvas_map.height
            x: canvas_map.x
            y: canvas_map.y
            scale: canvas_map.scale
            antialiasing: true

            property bool ispoint1: false
            property bool ispoint2: false
            property int x1
            property int y1
            property int x2
            property int y2
            onPaint:{
                var ctx = getContext('2d');
                if(image_map.isload){

                    ctx.clearRect(0,0,canvas_travelline.width, canvas_travelline.height);
                    if(anot_state == 4){
                        draw_canvas_travelline();
                    }
                }
            }

        }

        Canvas{
            id: canvas_map_cur
            width: canvas_map.width
            height: canvas_map.height
            x: canvas_map.x
            y: canvas_map.y
            scale: canvas_map.scale
            antialiasing: true
            onPaint:{
                var ctx = getContext("2d");
                if(image_map.isload){
                    ctx.clearRect(0,0,canvas_map_cur.width,canvas_map_cur.height);

                    // Draw new object
                    if(anot_state == 0 || anot_state == 3){ //show current
                        draw_canvas_cur_pose();
                    }
                }

            }

            MultiPointTouchArea{
                id: area_map
                anchors.fill: parent
                minimumTouchPoints: 1
                maximumTouchPoints: 2
                property var gesture: "none"
                property var dmoveX : 0;
                property var dmoveY : 0;
                property var startX : 0;
                property var startY : 0;
                property var startDist : 0;
                touchPoints: [TouchPoint{id:point1},TouchPoint{id:point2}]

                onPressed: {
                    if(tool_num == 0){//move
                        gesture = "drag";
                        if(point1.pressed && point2.pressed){
                            var dx = Math.abs(point1.x-point2.x);
                            var dy = Math.abs(point1.y-point2.y);
                            var dist = Math.sqrt(dx*dx + dy*dy);
                            area_map.startX = (point1.x+point2.x)/2;
                            area_map.startY = (point1.y+point2.y)/2;
                            area_map.startDist = dist;
                        }else if(point1.pressed){
                            area_map.startX = point1.x;
                            area_map.startY = point1.y;
                        }
                    }else if(tool_num == 1){//draw
                        gesture = "draw";
                        print("gesture -> draw")
                        canvas_map.lastX = point1.x;
                        canvas_map.lastY = point1.y;
                        supervisor.startLine(canvas_map.color, canvas_map.lineWidth);
                        supervisor.setLine(point1.x,point1.y);
                    }else if(tool_num == 2){//add point

                    }else if(tool_num == 3){
                        select_object_point = supervisor.getObjPointNum(select_object, point1.x, point1.y);

                    }else if(tool_num == 4){
                        canvas_location.isnewLoc = true;
                        canvas_location.new_loc_available = false;
                        canvas_location.new_loc_x = point1.x;
                        canvas_location.new_loc_y = point1.y;
                        canvas_location.new_loc_th = 0;
                    }else if(tool_num == 5){
                        supervisor.moveLocationPoint(select_location, point1.x, point1.y, 0);
                    }
                }

                onReleased: {
                    if(!point1.pressed&&!point2.pressed){
                        if(tool_num == 1){
//                            touchpoint.visible = false;
                            supervisor.stopLine();
                        }else if(tool_num == 2){//add point
                            print(point1.x, point1.y);
                            supervisor.addObjectPoint(point1.x, point1.y);
                        }else if(tool_num == 3){
                            select_object_point = -1;
                            supervisor.setObjPose();
                        }else if(tool_num == 4){

                        }else if(tool_num == 5){
                            updatelocationcollision();
                            tool_num = 0;
                        }else if(tool_num == 6){
                            if(anot_state == 4){
                                if(canvas_travelline.ispoint1){
                                    canvas_travelline.x2 = point1.x;
                                    canvas_travelline.y2 = point1.y;
                                    canvas_travelline.ispoint2 = true;
                                }else{
                                    canvas_travelline.ispoint1 = true;
                                    canvas_travelline.x1 = point1.x;
                                    canvas_travelline.y1 = point1.y;
                                }
                                canvas_travelline.requestPaint();
                            }else{
                                tool_num = 0;
                            }
                        }else{
                            if(anot_state == 2){
                                select_object = supervisor.getObjNum(point1.x,point1.y);
                                list_object.currentIndex = select_object;
                                canvas_object.requestPaint();
                            }else if(anot_state == 3){
                                select_location = supervisor.getLocNum(point1.x,point1.y);
                                list_location.currentIndex = select_location;
                                canvas_location.requestPaint();
                            }else if(anot_state == 4){
                                select_line = supervisor.getTlineNum(point1.x, point1.y)/2;
                                print(select_line);
                                list_line.currentIndex = select_line;
                                canvas_travelline.requestPaint();
                            }
                        }

                        gesture = "none"
                    }
                }
                onTouchUpdated:{
//                    var ctx = canvas_map.getContext('2d');
                    if(tool_num == 0){
                        if(point1.pressed&&point2.pressed){
                            var dx = Math.abs(point1.x-point2.x);
                            var dy = Math.abs(point1.y-point2.y);
                            var mx = (point1.x+point2.x)/2;
                            var my = (point1.y+point2.y)/2;
                            var dist = Math.sqrt(dx*dx + dy*dy);
                            var dscale = (dist)/startDist;
                            var new_scale = canvas_map.scale*dscale;

                            if(new_scale > 5)   new_scale = 5;
                            else if(new_scale < 1) new_scale = 1;

                            print("drag",mx,my,dist,new_scale,canvas_map.scale);
                            dmoveX = (mx - startX);
                            dmoveY = (my - startY);

                            if(canvas_map.x + dmoveX > canvas_map.width*(new_scale - 1)/2){

                            }else if(canvas_map.x +dmoveX < -(canvas_map.width*(new_scale - 1)/2 + canvas_map.width - rect_map.width)){

                            }else{
                                canvas_map.scale = new_scale;
                                canvas_map.x += dmoveX;
                            }
                            if(canvas_map + dmoveY > canvas_map.height*(new_scale - 1)/2){

                            }else if(canvas_map.y + dmoveY < -(canvas_map.height*(new_scale - 1)/2 + canvas_map.height - rect_map.height)){

                            }else{
                                canvas_map.scale = new_scale;
                                canvas_map.y += dmoveY;
                            }
                        }else{
                            dmoveX = (point1.x - startX)*canvas_map.scale;
                            dmoveY = (point1.y - startY)*canvas_map.scale;

                            if(canvas_map.x + dmoveX > canvas_map.width*(canvas_map.scale - 1)/2){

                            }else if(canvas_map.x +dmoveX < -(canvas_map.width*(canvas_map.scale - 1)/2 + canvas_map.width - rect_map.width)){

                            }else{
                                canvas_map.x += dmoveX;
                            }
                            if(canvas_map.y + dmoveY > canvas_map.height*(canvas_map.scale - 1)/2){

                            }else if(canvas_map.y + dmoveY < -(canvas_map.height*(canvas_map.scale - 1)/2 + canvas_map.height - rect_map.height)){

                            }else{
                                canvas_map.y += dmoveY;
                            }
                        }
                    }else if(tool_num == 1){
                        canvas_map.requestPaint()
                    }else if(tool_num == 3){
                        if(select_object_point != -1){
                            supervisor.moveObjectPoint(select_object,select_object_point,point1.x, point1.y);
                        }
                    }else if(tool_num == 4){
                        if(point1.y-canvas_location.new_loc_y == 0){
                            canvas_location.new_loc_th = 0;
                        }else{
                            canvas_location.new_loc_th = Math.atan2(-(point1.x-canvas_location.new_loc_x),-(point1.y-canvas_location.new_loc_y));
                        }
                        canvas_location.requestPaint();
                    }else if(tool_num == 5){
                        var new_th;
                        var cur_x = supervisor.getLocationx(select_location)/grid_size + origin_x;
                        var cur_y = supervisor.getLocationy(select_location)/grid_size + origin_y;
                        if(point1.y-cur_y == 0){
                            new_th= 0;
                        }else{
                            new_th = Math.atan2(-(point1.x-cur_x),-(point1.y-cur_y));
                        }
                        supervisor.moveLocationPoint(select_location, cur_x,cur_y, new_th);
                        canvas_location.requestPaint();
                    }
                }
            }
        }

    }

    Rectangle{
        id: brushview
        visible: false
        width: (brush_size+1)*canvas_map.scale
        height: (brush_size+1)*canvas_map.scale
        radius: (brush_size+1)*canvas_map.scale
        border.width: 1
        border.color: "black"
        anchors.centerIn: rect_map
//        x: rect_map.x/2 - brush_size/2
//        y: rect_map.y/2 - brush_size/2
    }




    //Map Image================================================================
    Image{
        id: image_map
        property bool isload: false
        visible: false
        cache: false
    }

    function updatemap(){
        supervisor.clear_all();
        location_num = supervisor.getLocationNum();
        origin_x = supervisor.getOrigin()[0];
        origin_y = supervisor.getOrigin()[1];
        grid_size = supervisor.getGridWidth();
        object_num = supervisor.getObjectNum();
        draw_canvas_map();
        canvas_map.requestPaint();
    }


    //Timer=====================================================================
//    Timer{
//        id: timer_loadmap
//        interval: 1000
//        running: true
//        triggeredOnStart: true
//        repeat: true
//        onTriggered: {
//            if(!loadImage){
//                if(supervisor.getMapExist()){
//                    loadImage = true;
//                    print("image source = " + image_source);
//                    supervisor.clear_all();
//                    location_num = supervisor.getLocationNum();
//                    origin_x = supervisor.getOrigin()[0];
//                    origin_y = supervisor.getOrigin()[1];
//                    grid_size = supervisor.getGridWidth();
//                    object_num = supervisor.getObjectNum();
//                    draw_canvas_map();
//                    canvas_map.requestPaint();
//                    timer_loadmap.stop();
//                }
//            }
//        }
//    }

    Timer{
        id: update_checker
        interval: 1000
        running: flag_margin
        repeat: false
        onTriggered: {
            updatelocationcollision();
            flag_margin = false;
        }
    }


    //Dialog(Popup) ================================================================
    FileDialog{
        id: fileload
        folder: "file:"+applicationDirPath+"/image"
        property variant pathlist
        property string path : ""
        nameFilters: ["*.png"]
        onAccepted: {
            print(fileload.file.toString());
            pathlist = fileload.file.toString().split("/");
            path = "./build/image/" + pathlist[9];
            image_source = fileload.file.toString();//path
            image_name = pathlist[9].split(".")[0];
            print(image_source)
            var ctx = canvas_map.getContext('2d');
            print("image source = " + image_source);
            ctx.drawImage(image_map,0,0,image_map.width,image_map.height);
            canvas_map.requestPaint();

        }
    }
    FileDialog{
        id: filesaveannot
//        fileMode: FileDialog.SaveFile
        property variant pathlist
        property string path : ""
        folder: "file:"+applicationDirPath+"/setting"
        onAccepted: {
            print(filesaveannot.file.toString())
            supervisor.saveAnnotation(filesaveannot.file.toString());
        }
    }
    FileDialog{
        id: filesavemeta
//        fileMode: FileDialog.SaveFile
        property variant pathlist
        property string path : ""
        folder: "file:"+applicationDirPath+"/setting"
        onAccepted: {
            print(filesavemeta.file.toString())

            supervisor.saveMetaData(filesavemeta.file.toString());
        }
    }

    Popup{
        id: popup_add_object
//        visible: false
        width: 400
        height: 300
        anchors.centerIn: parent
        background: Rectangle{
            anchors.fill:parent
            color: "white"
        }

        Text{
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Add Object"
            font.pixelSize: 20
            font.bold: true
        }
        TextField{
            id: textfield_name
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100
            width: 200
            height: 60
            placeholderText: "(obj_name)"
            font.pointSize: 20
        }
        Rectangle{
            id: btn_add_object_confirm
            width: 60
            height: 50
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: 20
            color: "gray"
            Text{
                anchors.centerIn: parent
                text: "확인"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(textfield_name.text == ""){
                        textfield_name.color = "red";
                    }else{
                        supervisor.addObject(textfield_name.text);
                        canvas_object.requestPaint();
                        tool_num = 0;
                        popup_add_object.close();
                    }
                }
            }
        }
        Rectangle{
            id: btn_add_object_cancel
            width: 60
            height: 50
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: 20
            color: "gray"
            Text{
                anchors.centerIn: parent
                text: "취소"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
//                    popup_add_object.visible = false;
                    popup_add_object.close();
                }
            }
        }
    }

    Popup{
        id: popup_add_location
//        visible: false
        width: 400
        height: 300
        anchors.centerIn: parent
        background: Rectangle{
            anchors.fill:parent
            color: "white"
        }

        Text{
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Add Location"
            font.pixelSize: 20
            font.bold: true
        }
        TextField{
            id: textfield_name2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100
            width: 200
            height: 60
            placeholderText: "(loc_name)"
            font.pointSize: 20
        }
        Rectangle{
            id: btn_add_loc_confirm
            width: 60
            height: 50
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: 20
            color: "gray"
            Text{
                anchors.centerIn: parent
                text: "확인"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(textfield_name2.text == ""){
                        textfield_name2.color = "red";
                    }else{
                        supervisor.addLocation(textfield_name2.text, canvas_location.new_loc_x, canvas_location.new_loc_y, canvas_location.new_loc_th);
                        tool_num = 0;
                        canvas_location.isnewLoc = false;
                        canvas_location.new_loc_x = 0;
                        canvas_location.new_loc_y = 0;
                        canvas_location.new_loc_th = 0;
                        canvas_location.new_loc_available = false;
                        popup_add_location.close();
                        canvas_location.requestPaint();
                    }
                }
            }
        }
        Rectangle{
            id: btn_add_loc_cancel
            width: 60
            height: 50
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: 20
            color: "gray"
            Text{
                anchors.centerIn: parent
                text: "취소"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    popup_add_location.close();
                }
            }
        }
    }

    Popup{
        id: popup_add_travelline
        width: 400
        height: 300
        anchors.centerIn: parent
        background: Rectangle{
            anchors.fill:parent
            color: "white"
        }

        Text{
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Add Location"
            font.pixelSize: 20
            font.bold: true
        }
        TextField{
            id: textfield_name3
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100
            width: 200
            height: 60
            placeholderText: "(line_name)"
            font.pointSize: 20
        }
        Rectangle{
            id: btn_add_line_confirm
            width: 60
            height: 50
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: 20
            color: "gray"
            Text{
                anchors.centerIn: parent
                text: "확인"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(textfield_name3.text == ""){
                        textfield_name3.color = "red";
                    }else if(canvas_travelline.isnewline){
                        supervisor.addTline(textfield_name3.text, canvas_travelline.x1, canvas_travelline.y1, canvas_travelline.x2, canvas_travelline.y2);
                        canvas_travelline.isnewline = false;
                        canvas_travelline.x1 = 0;
                        canvas_travelline.x2 = 0;
                        canvas_travelline.y1 = 0;
                        canvas_travelline.y2 = 0;
                        tool_num = 0;
                        popup_add_travelline.close();
                        canvas_location.requestPaint();
                    }else{
                        popup_add_travelline.close();
                    }
                }
            }
        }
        Rectangle{
            id: btn_add_line_cancel
            width: 60
            height: 50
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: 20
            color: "gray"
            Text{
                anchors.centerIn: parent
                text: "취소"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    popup_add_travelline.close();
                }
            }
        }
    }
}
