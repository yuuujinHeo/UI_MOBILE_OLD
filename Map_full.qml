import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "."
import io.qt.Supervisor 1.0
import io.qt.MapView 1.0
Item {
    id: map_full
    objectName: "map_full"
    width: 1000
    height: 1000
    onWidthChanged: {
        if(robot_following){
            var newx = width/2 - robot_x*newscale;
            var newy = height/2 - robot_y*newscale;

            if(newx > 0){
                mapview.x = 0;
            }else if(newx < - map_width*newscale + width){
                mapview.x = - map_width*newscale + width
            }else{
                mapview.x = newx;
            }

            if(newy  > 0){
                mapview.y = 0;
            }else if(newy < - map_height*newscale + height){
                mapview.y = - map_height*newscale + height
            }else{
                mapview.y = newy;
            }
            print(newx, newy, mapview.x, mapview.y)
        }
    }

    //불러올 맵 폴더 이름
    property string map_name: ""

    //불러올 맵 파일 모드(RAW, EDITED, MINIMAP, MAPPING, OBJECTING)
    property string map_mode: "EDITED"
    onMap_modeChanged: {
        print("MAP_MODE : "+map_mode);
    }

    //그리기 기능
    property bool show_object: false
    property bool show_location: false
    property bool show_lidar: false
    property bool show_robot: false
    property bool show_path: false
    property bool show_icon_only: false
    property bool show_objecting: false

    property bool show_connection: false
    property bool show_buttons: false

    property int obj_sequence: 0

    //SLAM 상태(map load되고 localization도 된 상태면 true)
    property bool is_slam_running: false

    //특수 기능
    property bool robot_following: false

    //0(location patrol) 1:(path patrol)
    property int patrol_mode: 0

    //Annotation State (None, Drawing, Object, Location, Travelline)
    property string state_annotation: "NONE"

    Component.onCompleted: {
//        loadmap();
    }

    onRobot_followingChanged: {
        if(robot_following){
            robot_x = (supervisor.getRobotx()/grid_size + origin_x)*newscale;
            robot_y = (supervisor.getRoboty()/grid_size + origin_y)*newscale;
            var newx = width/2 - robot_x*newscale;
            var newy = height/2 - robot_y*newscale;

            if(newx > 0){
                mapview.x = 0;
                print("???")
            }else if(newx < - map_width*newscale + width){
                mapview.x = - map_width*newscale + width
            }else{
                mapview.x = newx;
            }

            if(newy  > 0){
                mapview.y = 0;
            }else if(newy < - map_height*newscale + height){
                mapview.y = - map_height*newscale + height
            }else{
                mapview.y = newy;
            }
        }
    }
    onRobot_xChanged: {
        if(robot_following){
            var newx = width/2 - robot_x;
            if(newx > 0){
                mapview.x = 0;
            }else if(newx < - map_width*newscale + width){
                mapview.x = - map_width*newscale + width
            }else{
                mapview.x = newx;
            }
        }
    }
    onRobot_yChanged: {
        if(robot_following){
            var newy = height/2 - robot_y;
            if(newy  > 0){
                mapview.y = 0;
            }else if(newy < - map_height*newscale + height){
                mapview.y = - map_height*newscale + height
            }else{
                mapview.y = newy;
            }
        }
    }

    //굳이 필요?/*
//    Behavior on robot_x{
//        NumberAnimation{
//            duration: 200
//        }
//    }
//    Behavior on robot_y{
//        NumberAnimation{
//            duration: 200
//        }
//    }
//    Behavior on robot_th{
//        NumberAnimation{
//            duration: 200
//        }
//    }*/

    //맵 불러오기
    function loadmap(name,type){
        grid_size = supervisor.getGridWidth();
        supervisor.writelog("[QML MAP] LoadMap "+objectName+": "+name+" (mode = "+type+")");
        if(typeof(name) !== 'undefined'){
            map_name = name;
            if(typeof(type) !== 'undefined'){
                map_mode = type;
            }
            if(map_mode == "MINIMAP"){
                mapview.setMap(supervisor.getMinimap(name));
            }else if(map_mode === "RAW"){
                mapview.setMap(supervisor.getRawMap(name));
            }else if(map_mode === "EDITED"){
                mapview.setMap(supervisor.getMap(name));
            }else if(map_mode === "T_RAW"){
                print("kk");
                mapview.setMap(supervisor.getCostMap(name));
                travelview.setMap(supervisor.getTravelRawMap(name));
            }else if(map_mode === "T_EDIT"){
                mapview.setMap(supervisor.getCostMap(name));
                travelview.setMap(supervisor.getTravelMap(name));
            }else{
                supervisor.writelog("[QML MAP] LoadMap Failed : Map mode is "+map_mode);
            }
            setfullscreen();
        }else{
            supervisor.writelog("[QML MAP] LoadMap Failed : Map name is undefined");
            map_name = "";
        }
        //캔버스에 맵을 그림
        clear_canvas();
        update_canvas();
    }

    //맵 불러오기(매핑 중)
    function loadmapping(){
        mapview.setMap(supervisor.getMapping())
    }

    //맵 불러오기(매핑 중)
    function loadobjecting(){
        print("objecting")
        objectview.setMap(supervisor.getObjecting())
    }
    function loadobjectingpng(){
        print("objectingpng")
        objectview.setMap(supervisor.getObjectMap(supervisor.getMapname()))
    }


    //맵 사이즈를 전체 화면에 맞춰서 축소
    function setfullscreen(){
        newscale = width/map_width;
        print(width, map_width, newscale)
    }

    function update_canvas(){
        clear_canvas();
        if(state_annotation == "DRAWING" || state_annotation == "TRAVELLINE"){
            draw_canvas_lines(true);
            clear_canvas_temp();
        }
        draw_canvas_current();
        draw_canvas_object();
        draw_canvas_new_object();
        draw_canvas_location();
        draw_canvas_location_icon();
        draw_canvas_location_temp();
        draw_canvas_patrol_location();
    }

    function clear_canvas(){
        if(canvas_map.available){
            var ctx = canvas_map.getContext('2d');
            ctx.clearRect(0,0,canvas_map.width,canvas_map.height);
            canvas_map.requestPaint();
        }

        clear_canvas_location();
        clear_canvas_object();

        if(canvas_map_margin.available){
            ctx = canvas_map_margin.getContext('2d');
            ctx.clearRect(0,0,canvas_map_margin.width,canvas_map_margin.height);
            canvas_map_margin.requestPaint();
        }

        if(canvas_map_cur.available){
            ctx = canvas_map_cur.getContext('2d');
            ctx.clearRect(0,0,canvas_map_cur.width,canvas_map_cur.height);
            canvas_map_cur.requestPaint();
        }

    }

    function update_annotation(){
        supervisor.clear_all();
        location_num = supervisor.getLocationNum();
        origin_x = supervisor.getOrigin()[0];
        origin_y = supervisor.getOrigin()[1];
        grid_size = supervisor.getGridWidth();
        object_num = supervisor.getObjectNum();
        print(origin_x, origin_y, grid_size, object_num, location_num)
    }

    function rotate_map(angle){
        supervisor.setRotateAngle(angle);
        canvas_map.rotation = angle;
        print("ROTATE MAP : " ,angle);
        if(map_mode == "RAW"){
            mapview.setMap(supervisor.getRawMap(map_name));
        }else if(map_mode == "EDITED"){
            mapview.setMap(supervisor.getMap(map_name));
        }
    }

    //Annotation State (0: state, 1: load/edit, 2: object, 3: location, 4: travel line)
    //////========================================================================================Map Image Variable
    property var grid_size: supervisor.getSetting("ROBOT_SW","grid_size");
    property int origin_x: supervisor.getOrigin()[0];//500
    property int origin_y: supervisor.getOrigin()[1];//500
    property var robot_radius: supervisor.getRobotRadius() + 0.02
    property var map_width: supervisor.getMapWidth()
    property var map_height: supervisor.getMapHeight()

    //////========================================================================================Annotation Tool
    //Tool Num (MOVE, BRUSH, ADD_OBJECT, ADD_POINT, EDIT_POINT, ADD_LOCATION, EDIT_LOCATION, ADD_LINE, SLAM_INIT, ADD_PATROL_LOCATION)
    property string tool: "MOVE"
    property var brush_size: 10
    property color brush_color: "black"

    onToolChanged: {
        obj_sequence = 0;
    }

    function reset_canvas(){
        supervisor.clear_all();
        grid_size = supervisor.getSetting("ROBOT_SW","grid_size");
        new_slam_init = false;
        select_object= -1
        select_object_point= -1
        select_location= -1
        select_patrol= -1
        select_line= -1
        select_travel_line= -1
        select_location_show= -1
        new_location= false
        new_loc_available= false
        new_object= false
        update_annotation();
        update_canvas();
    }

    property int location_num: supervisor.getLocationNum();
    property var location_types
    property var location_x
    property var location_y
    property var location_th

    property int path_num: supervisor.getPathNum();
    property var path_x
    property var path_y
    property var path_th

    property int object_num: supervisor.getObjectNum();

    property bool new_slam_init: false
    property var init_x: origin_x;
    property var init_y: origin_y;
    property var init_th:0;

    property var robot_x: supervisor.getRobotx()/grid_size + origin_x;
    property var robot_y: supervisor.getRoboty()/grid_size + origin_y;
    property var robot_th:-supervisor.getRobotth()-Math.PI/2;

    property int select_object: -1
    property int select_object_point: -1
    property int select_location: -1
    property int select_patrol: -1
    property int select_line: -1
    property int select_travel_line: -1
    property int select_location_show: -1

    property bool new_travel_line: false
    property bool new_line_point1: false
    property bool new_line_point2: false
    property int new_line_x1;
    property int new_line_x2;
    property int new_line_y1;
    property int new_line_y2;

    property bool new_location: false
    property bool new_loc_available: false
    property var new_loc_x;
    property var new_loc_y;
    property var new_loc_th;

    property bool new_object: false
    property int new_obj_x1;
    property int new_obj_y1;
    property int new_obj_x2;
    property int new_obj_y2;
    property int new_obj_x1_orin;
    property int new_obj_y1_orin;
    property int new_obj_x2_orin;
    property int new_obj_y2_orin;
    property int new_obj_posx;
    property int new_obj_posy;

    //////========================================================================================Canvas Tool
    property bool refreshMap: true
    property bool rotateMap: false


    property var prevscale: 1
    property var newscale: 1
    Behavior on newscale{
        NumberAnimation{
            duration: 100
        }
    }
    onNewscaleChanged: {
        grid_size = supervisor.getSetting("ROBOT_SW","grid_size");
        var xscale = (area_wheel.mouseX - mapview.x)/mapview.width;
        var yscale = (area_wheel.mouseY - mapview.y)/mapview.height;

        mapview.width = map_width*newscale
        mapview.height = map_height*newscale

        if(robot_following){
            robot_x = (supervisor.getRobotx()/grid_size + origin_x)*newscale;
            robot_y = (supervisor.getRoboty()/grid_size + origin_y)*newscale;
            var newx = -width/2 + robot_x;//*newscale;
            var newy = -height/2 + robot_y;//*newscale;
//            print(supervisor.getRobotx(), newscale, robot_x, mapview.width, newscale, newx);

//            if(newx > 0){
//                mapview.x = 0;
//                print("??")
//            }else if(newx < - map_width*newscale + width){
//                mapview.x = - map_width*newscale + width
//            }else{
//                mapview.x = newx;
//            }

//            if(newy  > 0){
//                mapview.y = 0;
//            }else if(newy < - map_height*newscale + height){
//                mapview.y = - map_height*newscale + height
//            }else{
//                mapview.y = newy;
//            }
//            print(newx, newy, mapview.x, mapview.y)




//            var newx = -width/2 + (supervisor.getRobotx()/grid_size + origin_x)*newscale;
//            var newy = -height/2 + (supervisor.getRoboty()/grid_size + origin_y)*newscale;
        }else{
            var newx = - mapview.x + map_width*(newscale-prevscale)*xscale;
            var newy = - mapview.y + map_height*(newscale-prevscale)*yscale;
        }

//        print(supervisor.getRobotx()/grid_size + origin_x, (supervisor.getRobotx()/grid_size + origin_x)*newscale, newscale, mapview.centerx, mapview.x, xscale, newx)
        mapview.x = -newx;
        mapview.y = -newy;
        prevscale = newscale;

//        print(robot_x,robot_y, mapview.x, canvas_map_cur.x)

        update_canvas();
//        if(newscale > 0.9 && newscale < 1.1){
//            print("re drawing1");
//            update_canvas();
//        }
//        if(newscale > 1.9 && newscale < 2.1){
//            print("re drawing2");
//            update_canvas();
//        }
//        if(newscale > 2.9 && newscale < 3.1){
//            print("re drawing3");
//            update_canvas();
//        }
//        if(newscale > 3.9 && newscale < 4.1){
//            print("re drawing4");
//            update_canvas();
//        }
//        if(newscale > 4.9 && newscale < 5.1){
//            print("re drawing5");
//            update_canvas();
//        }
    }

    //Annotation State (None, Drawing, Object, Location, Travelline)
    onState_annotationChanged: {
        tool = "MOVE";
        travelview.visible = false;
        obj_sequence = 0;
        grid_size = supervisor.getSetting("ROBOT_SW","grid_size");
        if(state_annotation == "NONE"){
            robot_following = false;
        }else if(state_annotation == "DRAWING"){
            robot_following = false;
        }else if(state_annotation == "OBJECTING"){
            show_object = true;
            show_location = true;
            show_robot = true;
            show_objecting = true;
//            robot_following = false;
            show_buttons = true;
            show_lidar = true;
            robot_following = true;
        }else if(state_annotation == "OBJECT"){
            show_object = true;
            show_location = true;
            show_objecting = true;
//            robot_following = false;
            show_buttons = true;
        }else if(state_annotation == "LOCATION"){
            show_object = true;
            show_robot = true;
            show_location = true;
            show_buttons = true;
            show_lidar = true;
            robot_following = true;
            find_map_walls();
        }else if(state_annotation == "SAVE"){
            show_location = true;
            show_object = true;
            robot_following = false;
            show_buttons = false;
            show_robot = true;
            setfullscreen();
//            show_travelline = true;
        }else if(state_annotation == "TRAVELLINE"){
            travelview.visible = true;
            robot_following = false;
            show_location = true;
            loadmap(supervisor.getMapname(),"T_RAW")
        }

        update_canvas();
    }

    function brushchanged(){
        brushview.visible = true;
    }
    function brushdisappear(){
        brushview.visible = false;
    }

    //////========================================================================================Main Canvas
    Rectangle{
        id: rect_map
        anchors.fill: parent
        width: parent.width
        height: parent.height
        clip: true
        color: "black"

        MapView{
            id: mapview
            width: map_width
            height: map_height
            property var centerx: 0
            property var centery: 0
            property var startx: 0
            property var starty: 0
            property var startScale: 0
//            property var newx: 0
//            onNewxChanged: {
//                x = newx;
//            }

            onXChanged: {
                if(x > 0){
                    x = 0;
                }else if(x < - map_width*newscale + rect_map.width){
                    x = - map_width*newscale + rect_map.width
                }
                print(map_width, map_height);
//                print("x : "+x);
            }
            onYChanged: {
                if(y > 0){
                    y = 0;
                }else if(x < - map_height*newscale + rect_map.height){
                    y = - map_height*newscale + rect_map.height
                }
//                print("y : "+y);
            }

        }

        MapView{
            id: travelview
            width: map_width
            height: map_height
            visible: state_annotation==="TRAVELLINE"
            x: mapview.x + (mapview.width - width)/2
            y: mapview.y + (mapview.height - height)/2
            scale: newscale
        }
        MapView{
            id: objectview
            width: map_width
            height: map_height
            visible: (state_annotation==="OBJECT" || state_annotation==="OBJECTING")&& show_objecting
            x: mapview.x + (mapview.width - width)/2
            y: mapview.y + (mapview.height - height)/2
            scale: newscale
        }

        Canvas{
            id: canvas_map
            width: map_width
            height: map_height
            visible: state_annotation==="TRAVELLINE"?false:true
            x: mapview.x + (mapview.width - width)/2
            y: mapview.y + (mapview.height - height)/2
            scale: newscale
            property var lineWidth: brush_size
            //drawing 용
            property real lastX
            property real lastY
            property var lineX
            property var lineY
        }


        Canvas{
            id: canvas_map_margin
            width: map_width
            height: map_height
            x: mapview.x
            y: mapview.y
            scale: newscale
        }

        Canvas{
            id: canvas_object
            visible: show_object
            width: mapview.width
            height: mapview.height
            opacity: 0.7
            x: mapview.x + (mapview.width - width)/2
            y: mapview.y + (mapview.height - height)/2
//            scale: newscale
        }

//        Canvas{
//            id: canvas_location
//            visible: show_location
//            width: map_width
//            height: map_height
//            x: mapview.x + (mapview.width - width)/2
//            y: mapview.y + (mapview.height - height)/2
//            scale: newscale
//        }
        Canvas{
            id: canvas_location
            visible: show_location
            width: mapview.width
            height: mapview.height
            x: mapview.x + (mapview.width - width)/2
            y: mapview.y + (mapview.height - height)/2
//            scale: newscale
        }

        Canvas{
            id: canvas_map_cur
            width: mapview.width
            height: mapview.height
            x: mapview.x + (mapview.width - width)/2
            y: mapview.y + (mapview.height - height)/2
//            scale: newscale
        }

        Canvas{
            id: canvas_map_temp
            width: map_width
            height: map_height
            opacity: 0.7
            visible: state_annotation==="TRAVELLINE"
            x: mapview.x + (mapview.width - width)/2
            y: mapview.y + (mapview.height - height)/2
            scale: newscale
            property var lineWidth: brush_size
            //drawing 용
            property real lastX
            property real lastY
            property var lineX
            property var lineY
        }
//        MouseArea{
//            id: area_wheel
//            anchors.fill: mapview
//            hoverEnabled: true
//            onWheel: {
//                var ctx = canvas_map.getContext('2d');
//                var new_scale;
//                wheel.accepted = false;
//                 mapview.centerx = mouseX*(map_width/width);
//                 mapview.centery = mouseY*(map_height/height);

//                print(mouseX, mouseY, map_width, width, mapview.centerx)
//                if(wheel.angleDelta.y > 0){
//                    new_scale = newscale + 0.1;
//                    if(new_scale > 5){
//                        newscale = 5;
//                    }else{
//                        newscale = new_scale;
//                    }
//                }else{
//                    new_scale = newscale - 0.1;
//                    if(rect_map.width > new_scale*map_width){
//                        newscale = rect_map.width/map_width;
////                        /*print*/(rect_map.width, map_width)
//                    }else{
//                        newscale = new_scale;
//                    }
//                }
//            }
//        }
        MouseArea{
            id: area_wheel
            anchors.fill: parent
            hoverEnabled: true
            onWheel: {
                var ctx = canvas_map.getContext('2d');
                var new_scale;
                wheel.accepted = false;
                mapview.centerx = mouseX;//((mouseX*map_width*newscale/width)-(mapview.x))/newscale;
                mapview.centery = mouseY;//((mouseY*map_height*newscale/height)-(mapview.y))/newscale;

//                print(mouseX, mouseY, map_width, width, mapview.centerx)
                if(wheel.angleDelta.y > 0){
                    new_scale = newscale + 0.1;
                    if(new_scale > 5){
                        newscale = 5;
                    }else{
                        newscale = new_scale;
                    }
                }else{
                    new_scale = newscale - 0.1;
                    if(rect_map.width > new_scale*map_width){
                        newscale = rect_map.width/map_width;
//                        /*print*/(rect_map.width, map_width)
                    }else{
                        newscale = new_scale;
                    }
                }
            }
        }


        MultiPointTouchArea{
            id: area_map
            anchors.fill: mapview
            minimumTouchPoints: 1
            maximumTouchPoints: 2
            property var startViewX: 0
            property var startViewY: 0
            property var dmoveX : 0;
            property var dmoveY : 0;
            property var startX : 0;
            property var startY : 0;
            property var startDist : 0;
            property var point_x1: 0;
            property var point_x2: 0;
            property var point_y1: 0;
            property var point_y2: 0;
            property bool is_update: false
            property bool double_touch: false
            touchPoints: [TouchPoint{id:point1},TouchPoint{id:point2}]
            onPressed: {
                if(point1.pressed){
                    point_x1 = point1.x*(map_width/width);
                    point_y1 = point1.y*(map_height/height);
                }

                if(point1.pressed && point2.pressed){
                    point_x2 = point2.x*(map_width/width);
                    point_y2 = point2.y*(map_height/height);
                    double_touch = true;
                }
                if(tool == "MOVE"){//move
                    if(point1.pressed && point2.pressed){
                        mapview.centerx = (point_x1+point_x2)/2;
                        mapview.centery = (point_y1+point_y2)/2;
                        mapview.startx = mapview.x;
                        mapview.starty = mapview.y;
                        mapview.startScale = newscale;
                        var dx = Math.abs(point_x1-point_x2);
                        var dy = Math.abs(point_y1-point_y2);
                        var dist = Math.sqrt(dx*dx + dy*dy);
                        area_map.startDist = dist;
//                        /*print*/("PRESS : ",mapview.centerx, mapview.centery, newscale);
                    }else if(point1.pressed){
                        area_map.startX = point1.x;
                        area_map.startY = point1.y;
                    }else if(point2.pressed){
                        area_map.startX = point2.x;
                        area_map.startY = point2.y;
                    }
                }else if(tool == "BRUSH" || tool == "ERASE"){//draw
                    canvas_map.lastX = point_x1;
                    canvas_map.lastY = point_y1;
                    canvas_map_temp.lastX = point_x1;
                    canvas_map_temp.lastY = point_y1;
                    supervisor.startLine(brush_color, canvas_map.lineWidth);
                    supervisor.setLine(point_x1,point_y1);
                }else if(tool == "EDIT_POINT"){
                    select_object_point = supervisor.getObjPointNum(select_object, point_x1, point_y1);

                }else if(tool == "EDIT_OBJECT"){
                    select_object_point = supervisor.getObjPointNum(select_object, point_x1, point_y1);

                }else if(tool == "ADD_LOCATION"){
                    new_location = true;
                    new_loc_available = false;
                    new_loc_x = point_x1;
                    new_loc_y = point_y1;
                    new_loc_th = 0;
                }else if(tool == "ADD_PATROL_LOCATION"){
                    new_location = true;
                    new_loc_available = false;
                    new_loc_x = point_x1;
                    new_loc_y = point_y1;
                    new_loc_th = 0;
                }else if(tool == "EDIT_LOCATION"){
                    supervisor.moveLocationPoint(select_location, point_x1, point_y1, 0);
                }else if(tool == "SLAM_INIT"){
                    new_slam_init = true;
                    init_x = point_x1;
                    init_y = point_y1;
                    init_th = 0;
                }else if(tool == "ADD_OBJECT"){
                    supervisor.clearObjectPoints();
                    if(obj_sequence == 0){
                        new_object = true;
                        new_obj_x1 = point_x1;
                        new_obj_y1 = point_y1;
                        new_obj_x2 = point_x1;
                        new_obj_y2 = point_y1;
                    }else if(obj_sequence){
                        new_obj_posx = point_x1;
                        new_obj_posy = point_y1;
                        new_obj_x1_orin = new_obj_x1;
                        new_obj_y1_orin = new_obj_y1;
                        new_obj_x2_orin = new_obj_x2;
                        new_obj_y2_orin = new_obj_y2;
                    }

                }else if(tool == "ADD_POINT"){
                    new_object = true;
                }
            }

            onReleased: {
                if(point1.pressed){
                    point_x1 = point1.x*(map_width/width);
                    point_y1 = point1.y*(map_height/height);
                }
                if(point2.pressed){
                    point_x2 = point2.x*(map_width/width);
                    point_y2 = point2.y*(map_height/height);
                }
                if(!point1.pressed&&!point2.pressed){
                    double_touch = false;
                    if(tool == "BRUSH" || tool == "ERASE"){
                        supervisor.stopLine();
                        if(state_annotation === "TRAVELLINE"){
                            set_travel_draw();
                        }
                    }else if(tool == "ADD_POINT"){//add point
                        supervisor.addObjectPoint(point_x1, point_y1);
                        loader_menu.item.check_object_size();
                    }else if(tool == "EDIT_POINT"){
                        select_object_point = -1;
                        supervisor.setObjPose();
                    }else if(tool == "EDIT_OBJECT"){
                        select_object_point = -1;
                        supervisor.setObjPose();
                    }else if(tool == "ADD_PATROL_LOCATION"){
                        if(!is_Col_loc(new_loc_x,new_loc_y)){
                            popup_add_patrol_1.open();
                        }
                    }else if(tool == "EDIT_LOCATION"){
                        updatelocationcollision();
                        tool = "NONE";
                    }else if(tool == "SLAM_INIT"){
                        supervisor.setInitPos(init_x,init_y, init_th);
                        supervisor.slam_setInit();
                    }else if(tool == "ADD_LINE"){
                        if(state_annotation == "TRAVELLINE"){
                            if(new_line_point1){
                                new_line_x2 = point_x1;
                                new_line_y2 = point_y1;
                                new_line_point2 = true;
                            }else{
                                new_line_point1 = true;
                                new_line_x1 = point_x1;
                                new_line_y1 = point_y1;
                            }
//                                canvas_travelline.requestPaint();
                        }else{
                            tool = "NONE";
                        }
                    }else if(tool == "ADD_OBJECT"){
                        print("addObjectPoint"+new_obj_x1,new_obj_x2);
                        supervisor.addObjectPoint(new_obj_x1,new_obj_y1);
                        supervisor.addObjectPoint(new_obj_x1,new_obj_y2);
                        supervisor.addObjectPoint(new_obj_x2,new_obj_y2);
                        supervisor.addObjectPoint(new_obj_x2,new_obj_y1);
                        loader_menu.item.check_object_size();
                        if(obj_sequence == 0){
                            obj_sequence = 1;
                        }else if(obj_sequence == 1){
                            obj_sequence = 2;
                        }else if(obj_sequence == 2){

                        }
                    }else{
                        if(state_annotation == "OBJECT"){
                            select_object = supervisor.getObjNum(point_x1,point_y1);
                            loader_menu.item.setcur(select_object);
                            update_canvas();
                        }else if(state_annotation == "LOCATION"){
                            select_location = supervisor.getLocNum(point_x1,point_y1);
                            loader_menu.item.setcur(select_location);
                            update_canvas();
                        }else if(state_annotation == "TRAVELLINE"){
//                            select_line = supervisor.getTlineNum(point_x1, point_y1)/2;
//                            loader_menu.item.setcur(select_line);
//                                canvas_travelline.requestPaint();
                        }
                    }
                }
            }
            onTouchUpdated:{
                if(point1.pressed){
                    point_x1 = point1.x*(map_width/width);
                    point_y1 = point1.y*(map_height/height);
                }
                if(point2.pressed){
                    point_x2 = point2.x*(map_width/width);
                    point_y2 = point2.y*(map_height/height);
                }
                if(tool == "MOVE"){
                    robot_following = false;
                    if(point1.pressed&&point2.pressed){

                        var dx = Math.abs(point1.x - point2.x)
                        var dy = Math.abs(point1.y - point2.y)
                        var dist = Math.sqrt(dx*dx + dy*dy);//*width/map_width;
                        var dscale = (dist)/startDist;

                        if(dscale > 5){
                            newscale = 5;
                        }else if(rect_map.width > dscale*map_width){
                            newscale = rect_map.width/map_width;
                        }else{
                            newscale = dscale;
                        }

                    }else if(!double_touch){
                        if(point1.pressed || point2.pressed){
                            dmoveX = point1.x - area_map.startX;
                            dmoveY = point1.y - area_map.startY;

                            var newx = mapview.x + dmoveX;
                            var newy = mapview.y + dmoveY;

                            if(newx > 0){
                                mapview.x = 0;
                            }else if(newx < - map_width*newscale + rect_map.width){
                                mapview.x = - map_width*newscale + rect_map.width
                            }else{
                                mapview.x = newx;
                            }
                            if(newy  > 0){
                                mapview.y = 0;
                            }else if(newy < - map_height*newscale + rect_map.height){
                                mapview.y = - map_height*newscale + rect_map.height
                            }else{
                                mapview.y = newy;
                            }
                        }


                    }
                }else if(tool == "BRUSH" || tool == "ERASE"){
                    draw_canvas_lines(false);
                    draw_canvas_temp();
                }else if(tool == "EDIT_POINT"){
                    if(select_object_point != -1){
                        supervisor.editObject(select_object,select_object_point,point_x1, point_y1);
                    }
                    clear_canvas_object();
                    draw_canvas_object();
                }else if(tool == "EDIT_OBJECT"){
                    if(select_object_point != -1){
                        supervisor.editObject(select_object, select_object_point, point_x1, point_y1);
                    }
                    clear_canvas_object();
                    draw_canvas_object();
                }else if(tool == "ADD_LOCATION"){
                    if(point_y1-new_loc_y == 0){
                        new_loc_th = 0;
                    }else{
                        new_loc_th = Math.atan2(-(point_x1-new_loc_x),-(point_y1-new_loc_y));
                    }
//                    print("update : "+new_loc_th);
                    clear_canvas_location();
                    draw_canvas_location();
                    draw_canvas_location_icon();
                    draw_canvas_location_temp();
                }else if(tool == "ADD_PATROL_LOCATION"){
                    if(point_y1-new_loc_y == 0){
                        new_loc_th = 0;
                    }else{
                        new_loc_th = Math.atan2(-(point_x1-new_loc_x),-(point_y1-new_loc_y));
                    }
                    clear_canvas_location();
                    draw_canvas_location();
                    draw_canvas_location_icon();
                    draw_canvas_location_temp();
                }else if(tool == "EDIT_LOCATION"){
                    var new_th;
                    var cur_x = supervisor.getLocationx(select_location)/grid_size + origin_x;
                    var cur_y = supervisor.getLocationy(select_location)/grid_size + origin_y;
                    if(point_y1-cur_y == 0){
                        new_th= 0;
                    }else{
                        new_th = Math.atan2(-(point_x1-cur_x),-(point_y1-cur_y));
                    }
                    supervisor.moveLocationPoint(select_location, cur_x,cur_y, new_th);
                    clear_canvas_location();
                    draw_canvas_location();
                    draw_canvas_location_icon();
                    draw_canvas_location_temp();
                }else if(tool == "SLAM_INIT"){
                    if(point_y1-init_y == 0){
                        init_th = 0;
                    }else{
                        init_th = Math.atan2(-(point_x1-init_x),-(point_y1-init_y));
                    }
                    clear_canvas_location();
                    draw_canvas_location();
                    draw_canvas_location_icon();
                    draw_canvas_location_temp();
                }else if(tool == "ADD_OBJECT"){
                    if(point1.pressed){
                        if(obj_sequence == 0){
                            print("0");
                            new_obj_x2 = point_x1
                            new_obj_y2 = point_y1
                        }else if(obj_sequence == 1){
                            print("1 : ",point_x1,new_obj_posx);
                            new_obj_x1 = new_obj_x1_orin + point_x1-new_obj_posx;
                            new_obj_y1 = new_obj_y1_orin + point_y1-new_obj_posy;
                            new_obj_x2 = new_obj_x2_orin + point_x1-new_obj_posx;
                            new_obj_y2 = new_obj_y2_orin + point_y1-new_obj_posy;
                        }else if(obj_sequence == 2){
                            print("2");
                            new_obj_x2 = new_obj_x2_orin + point_x1-new_obj_posx;
                            new_obj_y2 = new_obj_y2_orin + point_y1-new_obj_posy;
                        }
                        clear_canvas_object();
                        draw_canvas_object();
                        draw_canvas_new_object();
                    }

                }
            }
        }

        Rectangle{
            id: btn_robot_following
            width: 40
            height: 40
            radius: 40
            visible: show_buttons
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 5
            color: robot_following?"#12d27c":"#e8e8e8"
            Image{
                anchors.centerIn: parent
                source: "icon/icon_cur.png"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    robot_following = true;
                }
            }
        }

        Rectangle{
            id: btn_show_lidar
            width: 40
            height: 40
            radius: 40
            visible: show_buttons
            anchors.top: btn_robot_following.bottom
            anchors.topMargin: 5
            anchors.left: parent.left
            anchors.leftMargin: 5
            color: show_lidar?"#12d27c":"#e8e8e8"
            Image{
                anchors.centerIn: parent
                source: "icon/icon_lidar.png"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(show_lidar){
                        show_lidar = false;
                    }else{
                        show_lidar = true;
                    }
                }
            }
        }

        Rectangle{
            id: btn_show_objecting
            width: 40
            height: 40
            radius: 40
            visible: show_buttons && (state_annotation === "OBJECT" || state_annotation === "OBJECTING")
            anchors.top: btn_show_lidar.bottom
            anchors.topMargin: 5
            anchors.left: parent.left
            anchors.leftMargin: 5
            color: show_objecting?"#12d27c":"#e8e8e8"
            Image{
                anchors.centerIn: parent
                source: show_objecting?"icon/icon_obj_yes.png":"icon/icon_obj_no.png"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(show_objecting){
                        show_objecting = false;
                    }else{
                        show_objecting = true;
                    }
                }
            }
        }
        Rectangle{
            id: btn_show_object
            width: 40
            height: 40
            radius: 40
            visible: show_buttons && (state_annotation !== "OBJECT" && state_annotation !== "OBJECTING")
            anchors.top: btn_show_lidar.bottom
            anchors.topMargin: 5
            anchors.left: parent.left
            anchors.leftMargin: 5
            color: show_object?"#12d27c":"#e8e8e8"
            Image{
                anchors.centerIn: parent
                source: show_object?"icon/icon_obj_yes.png":"icon/icon_obj_no.png"
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(show_object){
                        show_object = false;
                    }else{
                        show_object = true;
                    }
                }
            }
        }
        //브러시 사이즈 조절할 때 보여주는 원
        Rectangle{
            id: brushview
            visible: false
            width: (brush_size+1)*newscale
            height: (brush_size+1)*newscale
            radius: (brush_size+1)*newscale
            border.width: 1
            border.color: "black"
            anchors.centerIn: parent
        }
        //슬램 활성화 안될 때 보여주는 안내창
        Rectangle{
            id: rect_notice
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300
            height: 60
            y: -10
            radius: 5
            color: color_red
            function show_connect(){
                show_ani.start();
            }
            function unshow_connect(){
                unshow_ani.start();
            }
            NumberAnimation{
                id: show_ani
                target: parent
                property: "y"
                from: -height
                to: 0
                duration: 500
                onStarted: {
                    parent.visible = true;
                }
                onFinished: {

                }
            }
            NumberAnimation{
                id: unshow_ani
                target: parent
                property: "y"
                from: 0
                to: -height
                duration: 500
                onStarted: {
                }
                onFinished: {
                    parent.visible = false;
                }
            }
            visible: false
            onVisibleChanged: {
                if(visible){
                    show_ani.start();
                }
            }
            property string msg: ""
            property bool show_icon: false
            Row{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 5
                spacing: 10
                Image{
                    width: 30
                    height: 30
                    visible: rect_notice.show_icon
                    anchors.verticalCenter: parent.verticalCenter
                    source: "icon/icon_warning.png"
                    ColorOverlay{
                        source: parent
                        anchors.fill: parent
                        color: "white"
                    }
                }
                Text{
                    text: rect_notice.msg
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: font_noto_b.name
                    font.pixelSize: 20
                    color: "white"
                }
            }
        }
    }
    //////========================================================================================Sub Canvas
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

    Image{
        id: image_charging_selected
        visible: false
//        width: 13
//        height: 13
//        sourceSize.width: 13
//        sourceSize.height: 13
        source: "icon/icon_charge_1.png"
        ColorOverlay{
            source: parent
            anchors.fill: parent
            color: "#83B8F9"
        }
    }
    Image{
        id: image_charging
        visible: false
//        width: 13
//        height: 13
//        sourceSize.width: 13
//        sourceSize.height: 13
        source: "icon/icon_charge_2.png"
    }
    Image{
        id: image_resting_selected
        visible: false
//        width: 13
//        height: 13
//        sourceSize.width: 13
//        sourceSize.height: 13
        source: "icon/icon_home_1.png"
        ColorOverlay{
            source: parent
            anchors.fill: parent
            color: "#83B8F9"
        }
    }
    Image{
        id: image_resting
        visible: false
//        width: 13
//        height: 13
//        sourceSize.width: 13
//        sourceSize.height: 13
        source: "icon/icon_home_2.png"
    }

    Column{
        id: scale_bar
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottomMargin: 10
        spacing: -5
        Row{
            Rectangle{
                width: 3
                height: 10
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle{
                anchors.verticalCenter: parent.verticalCenter
                width: (1/supervisor.getGridWidth())*newscale
                height: 3
                color: "white"
            }
            Rectangle{
                width: 3
                height: 10
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text{
            anchors.horizontalCenter: parent.horizontalCenter
            text: "1m"
            font.family: font_noto_r.name
            font.pixelSize: 10
            color: "white"
        }
    }

    Rectangle{
        anchors.bottom: parent.bottom
        anchors.right: parent.right

    }


    //////========================================================================================Timer
    Timer{
        id: update_checker
        interval: 1000
        repeat: false
        onTriggered: {
            updatelocationcollision();
        }
    }

    //최초 실행 후 맵 파일을 받아올 수 있을 때까지 1회 수행
    Timer{
        id: timer_loadmap
        running: true
        repeat: true
        interval: 500
        onTriggered: {
            //맵을 로딩할 수 있을 때
            if(supervisor.isloadMap()){

                //맵 정보 받아옴(경로, 이름)
                map_name = supervisor.getMapname();
                loadmap(map_name);

                //타이머 종료
                timer_loadmap.stop();
                supervisor.writelog("[QML] Load Map(AUTO) : "+map_name);
            }
        }
    }

    //로봇 연결되면 주기적 수행
    Timer{
        id: update_map
        running: show_robot
        repeat: true
        interval: 500
        onTriggered: {
            if(supervisor.getLCMConnection()){
                is_slam_running = supervisor.is_slam_running();
                robot_x = (supervisor.getRobotx()/grid_size + origin_x)*newscale;
                robot_y = (supervisor.getRoboty()/grid_size + origin_y)*newscale;
                robot_th = -supervisor.getRobotth()-Math.PI/2;
                path_num = supervisor.getPathNum();
                draw_canvas_current();

                if(show_connection){
                    if(supervisor.getMappingflag()){
                        rect_notice.visible = true;
                        rect_notice.msg =  "맵 생성 중";
                        rect_notice.color = color_navy;
                        rect_notice.show_icon = false;
                    }else if(supervisor.getObjectingflag()){
                        rect_notice.visible = true;
                        rect_notice.msg =  "오브젝트 생성 중";
                        rect_notice.color = color_navy;
                        rect_notice.show_icon = false;
                    }else if(supervisor.getLocalizationState()===1){
                        rect_notice.visible = true;
                        rect_notice.msg =  "위치 초기화 중";
                        rect_notice.color = color_navy;
                        rect_notice.show_icon = false;
                    }else if(!is_slam_running && map_mode != "MAPPING"){
                        rect_notice.visible = true;
                        rect_notice.msg =  "주행 활성화 안됨";
                        rect_notice.color = color_red;
                        rect_notice.show_icon = true;
                    }else{
                        rect_notice.visible = false;
                    }
                }else{
                    rect_notice.visible = false;
                }
            }else{
                rect_notice.visible = true;
                rect_notice.msg =  "로봇 연결 안됨";
                rect_notice.color = color_red;
                rect_notice.show_icon = true;
            }

        }
    }

    //////========================================================================================Variable update function
    function init_mode(){
        tool = "MOVE";
        select_object = -1;
        select_object_point = -1;
        select_location = -1;
        select_patrol = -1;

        new_location = false;
        new_loc_available = false;
        new_object = false;

        supervisor.clearObjectPoints();

        show_connection = true;

        show_buttons = false;
        show_lidar = false;
        show_location = false;
        show_object = false;
        show_path = false;
        show_robot = false;
        show_objecting = false;
        clear_margin();
        clear_canvas();
        update_canvas();
    }

    function update_path(){
        canvas_map_cur.requestPaint();
    }
    function update_margin(){
        update_checker.start();
        canvas_map_margin.requestPaint();
    }
    function clear_margin(){
        canvas_map_margin.requestPaint();
    }

    //////========================================================================================Annotation function
    function find_map_walls(){
        supervisor.clearMarginObj();
        var ctx1 = canvas_object.getContext('2d');
        var map_data1 = ctx1.getImageData(0,0,map_width, map_height);
        for(var x=0; x< map_data1.data.length; x=x+4){
            if(map_data1.data[x+3] > 0){
                supervisor.setMarginPoint(Math.abs(x/4));
            }
        }
    }

    //margin 업데이트 1초 뒤, location collision 업데이트
    function updatelocationcollision(){
        loader_menu.item.update();
    }

    function is_Col_loc(x,y){
        if(map_name != ""){
            var ctx1 = canvas_map_margin.getContext('2d');
            var ctx_robot = canvas_robot.getContext('2d');

            var map_data = supervisor.getMapData(map_name);
            var map_data1 = ctx1.getImageData(0,0,map_width,map_height);
            var robot_data = ctx_robot.getImageData(0,0,canvas_robot.width,canvas_robot.height);

            for(var i=0; i<robot_data.data.length; i=i+4){
                if(robot_data.data[i+3] > 0){
                    var robot_x = Math.floor((i/4)%canvas_robot.width + x - canvas_robot.width/2);
                    var robot_y = Math.floor((i/4)/canvas_robot.width + y - canvas_robot.width/2);
                    var pixel_num = robot_y*canvas_map.width + robot_x;
                    if(map_data[pixel_num] == 0 || map_data[pixel_num] > 100){
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

    function save_patrol(is_edit){
        var ctx = canvas_map.getContext('2d');

        var data = ctx.getImageData(0,0,map_width, map_height);
        var array = [];
        for(var i=0; i<data.data.length; i=i+4){
            if(data.data[i+3] > 0){
                if(data.data[i] > 0){
                    array.push(255);
                }else{
                    array.push(100);
                }
            }else{
                array.push(0);
            }

        }
        supervisor.saveTravel(is_edit,array);
    }

    function save_map(name){
        newscale = 1;

        var ctx = canvas_map.getContext('2d');
        var data = ctx.getImageData(0,0,map_width,map_height);
        var array= [];
        var array_alpha= [];

        for(var i=0; i<data.data.length; i=i+4){
            array.push(data.data[i]);
            array_alpha.push(data.data[i+3]);
        }
        print(map_width, map_height, data.data.length);
        supervisor.saveMap(map_mode,map_name,name,array,array_alpha);
    }

    //////========================================================================================Canvas drawing function
    function draw_canvas_lines(refresh){
        if(canvas_map.available){
            var ctx = canvas_map.getContext('2d');
            if(refresh){
//                print("Refresh Canvas Map Lines");
                ctx.clearRect(0,0,canvas_map.width,canvas_map.height);
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
            }else{
                if(tool == "BRUSH" || tool == "ERASE"){
                    ctx.lineWidth = canvas_map.lineWidth
                    ctx.strokeStyle = brush_color
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.moveTo(canvas_map.lastX, canvas_map.lastY)
                    if(point1.pressed){
                        canvas_map.lastX = area_map.point_x1
                        canvas_map.lastY = area_map.point_y1
                    }
                    supervisor.setLine(canvas_map.lastX,canvas_map.lastY);
                    ctx.lineTo(canvas_map.lastX, canvas_map.lastY)
                    ctx.stroke()
                }

            }

            canvas_map.requestPaint();
        }
    }
    function draw_canvas_temp(){
        var ctx = canvas_map_temp.getContext('2d');
        if(state_annotation === "TRAVELLINE"){
            if(tool == "BRUSH" || tool == "ERASE"){
                ctx.lineWidth = canvas_map_temp.lineWidth
                ctx.strokeStyle = color_dark_navy
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.moveTo(canvas_map_temp.lastX, canvas_map_temp.lastY)
                if(point1.pressed){
                    canvas_map_temp.lastX = area_map.point_x1
                    canvas_map_temp.lastY = area_map.point_y1
                }
                ctx.lineTo(canvas_map_temp.lastX, canvas_map_temp.lastY)
                ctx.stroke()
            }
        }else{
            clear_canvas_temp();
        }

        canvas_map_temp.requestPaint();

    }
    function clear_canvas_temp(){
        print("clear")
        var ctx = canvas_map_temp.getContext('2d');
        ctx.clearRect(0,0,canvas_map_temp.width,canvas_map_temp.height);

    }

    function clear_canvas_location(){
        if(canvas_location.available){
            var ctx = canvas_location.getContext('2d');
            ctx.clearRect(0,0,canvas_location.width, canvas_location.height);
            canvas_location.requestPaint();
        }
    }

    function clear_canvas_object(){
        if(canvas_object.available){
            var ctx = canvas_object.getContext('2d');
            ctx.clearRect(0,0,canvas_object.width, canvas_object.height);
            canvas_object.requestPaint();
        }
    }

    function draw_canvas_location_icon(){
        if(canvas_location.available){
            var ctx = canvas_location.getContext('2d');
            location_num = supervisor.getLocationNum();
            for(var i=0; i<location_num; i++){
                var loc_type = supervisor.getLocationTypes(i);
                var loc_x = (supervisor.getLocationx(i)/grid_size + origin_x)*newscale;;
                var loc_y = (supervisor.getLocationy(i)/grid_size + origin_y)*newscale;;
                var loc_th = supervisor.getLocationth(i);
                var radiusrobot = robot_radius*newscale;
                var icon_size = 13*newscale;
                if(loc_type.slice(0,4) == "Char"){
                    if(select_location == i){
                        ctx.fillStyle = "#7f7f7f";
                        ctx.strokeStyle = "#83B8F9";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.arc(loc_x,loc_y, radiusrobot/grid_size, -loc_th-Math.PI/2, -loc_th-Math.PI/2+2*Math.PI, true);
                        ctx.fill()
                        ctx.stroke()

                        var distance = (radiusrobot/grid_size)*1.8;
                        var distance2 = distance*0.8;
                        var th_dist = Math.PI/8;
                        var x = loc_x-distance*Math.sin(loc_th);
                        var y = loc_y-distance*Math.cos(loc_th);
                        var x1 = loc_x-distance2*Math.sin(loc_th-th_dist);
                        var y1 = loc_y-distance2*Math.cos(loc_th-th_dist);
                        var x2 = loc_x-distance2*Math.sin(loc_th+th_dist);
                        var y2 = loc_y-distance2*Math.cos(loc_th+th_dist);

                        ctx.beginPath();
                        ctx.moveTo(x,y);
                        ctx.lineTo(x1,y1);
                        ctx.moveTo(x,y);
                        ctx.lineTo(x2,y2);
                        ctx.stroke()
                        ctx.drawImage(image_charging_selected,loc_x - icon_size/2,loc_y - icon_size/2, icon_size, icon_size);

                    }else{
                        ctx.fillStyle = "#7f7f7f";
                        ctx.strokeStyle = "white";
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.arc(loc_x,loc_y,radiusrobot/grid_size, -loc_th-Math.PI/2, -loc_th-Math.PI/2+2*Math.PI, true);
                        ctx.fill()
                        ctx.stroke()
                        ctx.drawImage(image_charging,loc_x - icon_size/2,loc_y - icon_size/2, icon_size,icon_size);
                    }
                }else if(loc_type.slice(0,4) == "Rest"){
                    if(select_location === i){
                        ctx.fillStyle = "#7f7f7f";
                        ctx.strokeStyle = "#83B8F9";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.arc(loc_x,loc_y,radiusrobot/grid_size, -loc_th-Math.PI/2, -loc_th-Math.PI/2+2*Math.PI, true);
                        ctx.fill()
                        ctx.stroke()
                        var distance = (radiusrobot/grid_size)*1.8;
                        var distance2 = distance*0.8;
                        var th_dist = Math.PI/8;
                        var x = loc_x-distance*Math.sin(loc_th);
                        var y = loc_y-distance*Math.cos(loc_th);
                        var x1 = loc_x-distance2*Math.sin(loc_th-th_dist);
                        var y1 = loc_y-distance2*Math.cos(loc_th-th_dist);
                        var x2 = loc_x-distance2*Math.sin(loc_th+th_dist);
                        var y2 = loc_y-distance2*Math.cos(loc_th+th_dist);

                        ctx.beginPath();
                        ctx.moveTo(x,y);
                        ctx.lineTo(x1,y1);
                        ctx.moveTo(x,y);
                        ctx.lineTo(x2,y2);
                        ctx.stroke()
                        ctx.drawImage(image_resting_selected,loc_x - icon_size/2,loc_y - icon_size/2, icon_size, icon_size);
                    }else{
                        ctx.fillStyle = "#7f7f7f";
                        ctx.strokeStyle = "white";
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.arc(loc_x,loc_y,radiusrobot/grid_size, -loc_th-Math.PI/2, -loc_th-Math.PI/2+2*Math.PI, true);
                        ctx.fill()
                        ctx.stroke()
                        ctx.drawImage(image_resting,loc_x - icon_size/2,loc_y - icon_size/2, icon_size, icon_size);
                    }

                }
            }
            canvas_location.requestPaint();
        }
    }

    function draw_canvas_location(){
        if(canvas_location.available && !show_icon_only){
            var ctx = canvas_location.getContext('2d');
            location_num = supervisor.getLocationNum();

            for(var i=0; i<location_num; i++){
                var loc_type = supervisor.getLocationTypes(i);
                var loc_x = (supervisor.getLocationx(i)/grid_size +origin_x)*newscale;
                var loc_y = (supervisor.getLocationy(i)/grid_size +origin_y)*newscale;
                var loc_th = supervisor.getLocationth(i);//+Math.PI/2;
                var radiusrobot = robot_radius*newscale;

                if(select_location == i){
                    ctx.strokeStyle = "#83B8F9";
                    ctx.fillStyle = "#FFD9FF";
                    ctx.lineWidth = 2;
                }else{
                    ctx.strokeStyle = "white";
                    ctx.lineWidth = 2;
                    ctx.fillStyle = "#83B8F9";
                }

                ctx.beginPath();
                ctx.arc(loc_x,loc_y,radiusrobot/grid_size, -loc_th-Math.PI/2, -loc_th-Math.PI/2+2*Math.PI, true);
                ctx.fill()
                ctx.stroke()

                var distance = (radiusrobot/grid_size)*1.8;
                var distance2 = distance*0.8;
                var th_dist = Math.PI/8;
                var x = loc_x-distance*Math.sin(loc_th);
                var y = loc_y-distance*Math.cos(loc_th);
                var x1 = loc_x-distance2*Math.sin(loc_th-th_dist);
                var y1 = loc_y-distance2*Math.cos(loc_th-th_dist);
                var x2 = loc_x-distance2*Math.sin(loc_th+th_dist);
                var y2 = loc_y-distance2*Math.cos(loc_th+th_dist);

                if(select_location == i){
                    ctx.strokeStyle = "#83B8F9";
                }else{
                    ctx.strokeStyle = "#83B8F9";
                }

                ctx.beginPath();
                ctx.moveTo(x,y);
                ctx.lineTo(x1,y1);
                ctx.moveTo(x,y);
                ctx.lineTo(x2,y2);
                ctx.stroke()
            }
            canvas_location.requestPaint();
        }

    }

    function draw_canvas_patrol_location(){
        if(canvas_location.available && !show_icon_only){
            var ctx = canvas_location.getContext('2d');
            var patrol_num = supervisor.getPatrolNum();

            for(var i=0; i<patrol_num; i++){
                var loc_type = supervisor.getPatrolType(i);
                var loc_name = supervisor.getPatrolLocation(i);
                var loc_x = (supervisor.getPatrolX(i)/grid_size+origin_x)*newscale;
                var loc_y = (supervisor.getPatrolY(i)/grid_size+origin_y)*newscale;
                var loc_th = -supervisor.getPatrolTH(i)-Math.PI/2;
                var radiusrobot = robot_radius*newscale;

                if(select_patrol === i){
                    ctx.lineWidth = 3;
                    if(loc_type === "START"){
                        ctx.fillStyle = "#12d27c";
                    }else{
                        ctx.fillStyle = "#FFD9FF";
                    }
                    ctx.strokeStyle = "#83B8F9";
                }else{
                    ctx.strokeStyle = "white";
                    ctx.lineWidth = 2;
                    if(loc_type === "START"){
                        ctx.fillStyle = "#12d27c";
                    }else{
                        ctx.fillStyle = "#83B8F9";
                    }
                }
                ctx.beginPath();
                ctx.arc(loc_x,loc_y,radiusrobot/grid_size, -loc_th-Math.PI/2, -loc_th-Math.PI/2+2*Math.PI, true);
                ctx.fill()
                ctx.stroke()

                if(select_patrol === i){
                    ctx.font="bold 15px sans-serif";
                    ctx.fillStyle = "yellow"
                }else{
                    ctx.font="bold 15px sans-serif";
                    ctx.fillStyle = "white"
                }

                if(i===0){
                    ctx.fillText("S",loc_x - 5,loc_y + 5);
                }else{
                    ctx.fillText(Number(i),loc_x - 5,loc_y + 5);
                }

                if(select_patrol === i){
                    var distance = (radiusrobot/grid_size)*1.8;
                    var distance2 = distance*0.8;
                    var th_dist = Math.PI/8;
                    var x = loc_x-distance*Math.sin(loc_th);
                    var y = loc_y-distance*Math.cos(loc_th);
                    var x1 = loc_x-distance2*Math.sin(loc_th-th_dist);
                    var y1 = loc_y-distance2*Math.cos(loc_th-th_dist);
                    var x2 = loc_x-distance2*Math.sin(loc_th+th_dist);
                    var y2 = loc_y-distance2*Math.cos(loc_th+th_dist);

                    ctx.strokeStyle = "yellow";
                    ctx.beginPath();
                    ctx.moveTo(x,y);
                    ctx.lineTo(x1,y1);
                    ctx.moveTo(x,y);
                    ctx.lineTo(x2,y2);
                    ctx.stroke()
                }
            }

            if(select_location_show > -1){
                //새로 추가될 location 보여주기(임시)
                var loc_type = supervisor.getLocationTypes(select_location_show);
                var loc_x = supervisor.getLocationx(select_location_show)/grid_size +origin_x;
                var loc_y = supervisor.getLocationy(select_location_show)/grid_size +origin_y;
                var loc_th = -supervisor.getLocationth(select_location_show)-Math.PI/2;

                ctx.strokeStyle = "white";
                ctx.lineWidth = 2;
                ctx.fillStyle = "#FFD9FF";
                ctx.beginPath();
                ctx.arc(loc_x,loc_y,radiusrobot/grid_size, 0,2*Math.PI, true);
                ctx.fill()
                ctx.stroke()

                var distance = (radiusrobot/grid_size)*1.8;
                var distance2 = distance*0.8;
                var th_dist = Math.PI/8;
                var x = loc_x+distance*Math.cos(-loc_th-Math.PI/2);
                var y = loc_y+distance*Math.sin(-loc_th-Math.PI/2);
                var x1 = loc_x+distance2*Math.cos(-loc_th-Math.PI/2-th_dist);
                var y1 = loc_y+distance2*Math.sin(-loc_th-Math.PI/2-th_dist);
                var x2 = loc_x+distance2*Math.cos(-loc_th-Math.PI/2+th_dist);
                var y2 = loc_y+distance2*Math.sin(-loc_th-Math.PI/2+th_dist);

                if(select_location == i){
                    ctx.strokeStyle = "#FFD9FF";
                }else{
                    ctx.strokeStyle = "#FFD9FF";
                }
                ctx.beginPath();
                ctx.moveTo(x,y);
                ctx.lineTo(x1,y1);
                ctx.moveTo(x,y);
                ctx.lineTo(x2,y2);
                ctx.stroke()
            }
            canvas_location.requestPaint();
        }

    }

    function draw_canvas_location_temp(){
        if(canvas_location.available){
            var ctx = canvas_location.getContext('2d');
            ctx.strokeStyle = "white";
            ctx.fillStyle = "yellow";
            ctx.lineWidth = 2;
            var robotradius = robot_radius*newscale;

            if(new_location){
                ctx.beginPath();
                ctx.arc(new_loc_x*newscale,new_loc_y*newscale,robotradius/grid_size, -new_loc_th-Math.PI/2, -new_loc_th-Math.PI/2+2*Math.PI, true);
                ctx.fill()
                ctx.stroke()

                var distance = (robotradius/grid_size)*2.2;
                var distance2 = distance*0.7;
                var th_dist = Math.PI/6;
                var x = new_loc_x*newscale-distance*Math.sin(new_loc_th);
                var y = new_loc_y*newscale-distance*Math.cos(new_loc_th);
                var x1 = new_loc_x*newscale-distance2*Math.sin(new_loc_th-th_dist);
                var y1 = new_loc_y*newscale-distance2*Math.cos(new_loc_th-th_dist);
                var x2 = new_loc_x*newscale-distance2*Math.sin(new_loc_th+th_dist);
                var y2 = new_loc_y*newscale-distance2*Math.cos(new_loc_th+th_dist);

                ctx.beginPath();
                ctx.moveTo(x,y);
                ctx.lineTo(x1,y1);
                ctx.lineTo(x2,y2);
                ctx.closePath();

                ctx.fill()
            }
            if(new_slam_init){
                ctx.beginPath();
                ctx.arc(init_x*newscale,init_y*newscale,robotradius/grid_size, -init_th-Math.PI/2, -init_th-Math.PI/2+2*Math.PI, true);
                ctx.fill()
                ctx.stroke()
                print(init_x*newscale,init_y*newscale,robotradius,grid_size,init_th);

                var distance = (robotradius/grid_size)*2.2;
                var distance2 = distance*0.7;
                var th_dist = Math.PI/6;
                var x = init_x*newscale-distance*Math.sin(init_th);
                var y = init_y*newscale-distance*Math.cos(init_th);
                var x1 = init_x*newscale-distance2*Math.sin(init_th-th_dist);
                var y1 = init_y*newscale-distance2*Math.cos(init_th-th_dist);
                var x2 = init_x*newscale-distance2*Math.sin(init_th+th_dist);
                var y2 = init_y*newscale-distance2*Math.cos(init_th+th_dist);

                ctx.beginPath();
                ctx.moveTo(x,y);
                ctx.lineTo(x1,y1);
                ctx.lineTo(x2,y2);
                ctx.closePath();

                ctx.fill()
            }
            canvas_location.requestPaint();
        }

    }

    function draw_canvas_new_object(){
        if(canvas_object.available && new_object){
            var ctx = canvas_object.getContext('2d');

            if(tool == "ADD_OBJECT"){
                ctx.lineCap = "round";
                ctx.strokeStyle = "yellow";
                ctx.fillStyle = "steelblue";
                ctx.lineWidth = 3;

                ctx.beginPath();
                ctx.moveTo(new_obj_x1*newscale,new_obj_y1*newscale);
                ctx.rect(new_obj_x1*newscale,new_obj_y1*newscale, (new_obj_x2-new_obj_x1)*newscale, (new_obj_y2 - new_obj_y1)*newscale);
                ctx.closePath();
                ctx.stroke();
                ctx.fill();

                ctx.lineWidth = 1;
                ctx.strokeStyle = "blue";
                ctx.fillStyle = "blue";

                ctx.beginPath();
                ctx.moveTo(new_obj_x1*newscale,new_obj_y1*newscale);
                ctx.arc(new_obj_x1*newscale,new_obj_y1*newscale,2,0, Math.PI*2);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(new_obj_x1*newscale,new_obj_y2*newscale);
                ctx.arc(new_obj_x1*newscale,new_obj_y2*newscale,2,0, Math.PI*2);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(new_obj_x2*newscale,new_obj_y1*newscale);
                ctx.arc(new_obj_x2*newscale,new_obj_y1*newscale,2,0, Math.PI*2);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(new_obj_x2*newscale,new_obj_y2*newscale);
                ctx.arc(new_obj_x2*newscale,new_obj_y2*newscale,2,0, Math.PI*2);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
            }else if(tool == "ADD_POINT"){
                var point_num = supervisor.getTempObjectSize();
                if(point_num > 0){
                    ctx.lineCap = "round";
                    ctx.strokeStyle = "yellow";
                    ctx.fillStyle = "steelblue";
                    ctx.lineWidth = 3;
                    var point_x = (supervisor.getTempObjectX(0)/grid_size + origin_x)*newscale;
                    var point_y = (supervisor.getTempObjectY(0)/grid_size + origin_y)*newscale;
                    var point_x0 = point_x;
                    var point_y0 = point_y;

                    if(point_num > 2){
                        ctx.beginPath();
                        ctx.moveTo(point_x,point_y);
                        for(var i=1; i<point_num; i++){
                            point_x = (supervisor.getTempObjectX(i)/grid_size + origin_x)*newscale;
                            point_y = (supervisor.getTempObjectY(i)/grid_size + origin_y)*newscale;
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
                        point_x = (supervisor.getTempObjectX(1)/grid_size + origin_x)*newscale;
                        point_y = (supervisor.getTempObjectY(1)/grid_size + origin_y)*newscale;
                        ctx.lineTo(point_x,point_y)
                        ctx.stroke();
                    }

                    ctx.lineWidth = 1;
                    ctx.strokeStyle = "blue";
                    ctx.fillStyle = "blue";
                    point_x = (supervisor.getTempObjectX(0)/grid_size + origin_x)*newscale;
                    point_y = (supervisor.getTempObjectY(0)/grid_size + origin_y)*newscale;
                    for(i=0; i<point_num; i++){
                        ctx.beginPath();
                        point_x = (supervisor.getTempObjectX(i)/grid_size + origin_x)*newscale;
                        point_y = (supervisor.getTempObjectY(i)/grid_size + origin_y)*newscale;
                        ctx.moveTo(point_x,point_y);
                        ctx.arc(point_x,point_y,2,0, Math.PI*2);
                        ctx.closePath();
                        ctx.fill();
                        ctx.stroke();
                    }
                }
            }

            canvas_object.requestPaint();
        }
    }

    function draw_canvas_object(){
        if(canvas_object.available){
            var ctx = canvas_object.getContext('2d');
            object_num = supervisor.getObjectNum();
            ctx.lineWidth = 1;
            ctx.lineCap = "round";
            ctx.strokeStyle = "white";
            for(var i=0; i<object_num; i++){
                var obj_type = supervisor.getObjectName(i);
                var obj_size = supervisor.getObjectPointSize(i);
                var obj_x = (supervisor.getObjectX(i,0)/grid_size +origin_x)*newscale;
                var obj_y = (supervisor.getObjectY(i,0)/grid_size +origin_y)*newscale;
                var obj_x0 = obj_x;
                var obj_y0 = obj_y;

                if(select_object == i){
                    ctx.strokeStyle = "#83B8F9";
                    ctx.fillStyle = "#FFD9FF";
                    ctx.lineWidth = 3;
                }else{
                    if(obj_type.slice(0,5) === "Table"){
                        ctx.strokeStyle = "white";
                        ctx.fillStyle = "#56AA72";
                        ctx.lineWidth = 1;
                    }else if(obj_type.slice(0,5) === "Chair"){
                        ctx.strokeStyle = "white";
                        ctx.fillStyle = "#727272";
                        ctx.lineWidth = 1;
                    }else if(obj_type.slice(0,4) === "Wall"){
                        ctx.strokeStyle = "white";
                        ctx.fillStyle = "white";
                        ctx.lineWidth = 1;
                    }else{
                        ctx.strokeStyle = "red";
                        ctx.fillStyle = "red";
                        ctx.lineWidth = 1;
                    }
                }

                ctx.beginPath();
                ctx.moveTo(obj_x,obj_y);
                for(var j=1; j<obj_size; j++){
                    var obj_x_new = (supervisor.getObjectX(i,j)/grid_size + origin_x)*newscale;
                    var obj_y_new = (supervisor.getObjectY(i,j)/grid_size + origin_y)*newscale;
    //                print(obj_x,obj_y,obj_x_new,obj_y_new);
                    if(Math.abs(obj_x - obj_x_new) > 2 || Math.abs(obj_y - obj_y_new) > 2){
                        obj_x = obj_x_new;
                        obj_y = obj_y_new;
                        ctx.lineTo(obj_x,obj_y);
                    }
                }
                ctx.lineTo(obj_x0,obj_y0);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                if(state_annotation == "OBJECT"){
                    ctx.lineWidth = 1;
                    if(select_object == i){
                        ctx.strokeStyle = "#83B8F9";
                        ctx.fillStyle = "#83B8F9";
                        for(j=0; j<obj_size; j++){
                            ctx.beginPath();
                            obj_x = (supervisor.getObjectX(i,j)/grid_size +origin_x)*newscale;
                            obj_y = (supervisor.getObjectY(i,j)/grid_size +origin_y)*newscale;
                            ctx.moveTo(obj_x,obj_y);
                            if(select_object == i){
                                ctx.arc(obj_x,obj_y,4,0, Math.PI*2);
                            }else{
                                ctx.arc(obj_x,obj_y,2,0, Math.PI*2);
                            }

                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();
                        }
                    }else{
//                        ctx.strokeStyle = "white";
//                        ctx.fillStyle = "white";
                    }

                }
            }
            canvas_object.requestPaint();
        }

    }


    function draw_canvas_current(){
        if(canvas_map_cur.available){
            var ctx = canvas_map_cur.getContext('2d');
//            ctx.fillStyle = "white"
//            ctx.fillRect(0,0,canvas_map_cur.width,canvas_map_cur.height);
            ctx.clearRect(0,0,canvas_map_cur.width,canvas_map_cur.height);
            if(show_robot && (supervisor.is_slam_running() || map_mode === "MAPPING")){
                robot_x = (supervisor.getRobotx()/grid_size + origin_x)*newscale;
                robot_y = (supervisor.getRoboty()/grid_size + origin_y)*newscale;
                robot_th = -supervisor.getRobotth()-Math.PI/2;
                var robotradius = robot_radius*newscale

//                print(robot_th);
                ctx.strokeStyle = "white";
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.arc(robot_x,robot_y,robotradius/grid_size, robot_th, robot_th+2*Math.PI, true);
                ctx.fillStyle = "red";
                ctx.fill()
                ctx.stroke()

                var distance = (robotradius/grid_size)*2.2;
                var distance2 = distance*0.7;
                var th_dist = Math.PI/6;
                var x = robot_x+distance*Math.cos(robot_th);
                var y = robot_y+distance*Math.sin(robot_th);
                var x1 = robot_x+distance2*Math.cos(robot_th-th_dist);
                var y1 = robot_y+distance2*Math.sin(robot_th-th_dist);
                var x2 = robot_x+distance2*Math.cos(robot_th+th_dist);
                var y2 = robot_y+distance2*Math.sin(robot_th+th_dist);

                ctx.beginPath();
                ctx.moveTo(x,y);
                ctx.lineTo(x1,y1);
                ctx.lineTo(x2,y2);
                ctx.closePath();

                ctx.fillStyle = "red";
                ctx.fill()
            }
            //lidar
            if(show_lidar){
                ctx.lineWidth = 0.5;
                ctx.strokeStyle = "red";
                ctx.fillStyle = "red";
                robot_x = (supervisor.getRobotx()/grid_size + origin_x)*newscale;
                robot_y = (supervisor.getRoboty()/grid_size + origin_y)*newscale;
                robot_th = -supervisor.getRobotth()-Math.PI/2;
//                print("REDRAW, "+robot_x,canvas_map_cur.width,canvas_map_cur.x)
                for(var i=0; i<360; i++){
                    var data = (supervisor.getLidar(i)/grid_size)*newscale;
                    if(data > 0.01){
                        ctx.beginPath();
                        var lidar_x = robot_x + data*Math.cos((-Math.PI*i)/180 + robot_th);
                        var lidar_y = robot_y  + data*Math.sin((-Math.PI*i)/180 + robot_th);
                        ctx.moveTo(lidar_x, lidar_y);
                        ctx.arc(lidar_x,lidar_y,newscale,0,Math.PI*2);
                        ctx.closePath();
                        ctx.fill();
                        ctx.stroke();
                    }
                }
            }
            //path
            if(show_path){
                //Global path!
                path_num = supervisor.getPathNum();
//                print("show path"+path_num);
                path_x = robot_x;
                path_y = robot_y;
                path_th = robot_th;
                ctx.lineWidth = 2;
                for(var i=0; i<path_num; i++){
                    var path_x_before = path_x;
                    var path_y_before = path_y;
                    var path_th_before = path_th;
                    path_x = (supervisor.getPathx(i)/grid_size+origin_x)*newscale;
                    path_y = (supervisor.getPathy(i)/grid_size+origin_y)*newscale;
                    path_th = -supervisor.getPathth(i)-Math.PI/2;

                    ctx.strokeStyle = "#FFD9FF";
                    ctx.fillStyle = "#05C9FF";
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    if(i>0){
                        ctx.moveTo(path_x_before,path_y_before);
                        ctx.lineTo(path_x,path_y);
                        ctx.stroke()
                    }
                }
                //target pose
                if(path_num > 0){
                    ctx.beginPath();
                    ctx.arc(path_x,path_y,robotradius/grid_size, -path_th-Math.PI/2, -path_th-Math.PI/2+2*Math.PI, true);
                    ctx.fill()
                    ctx.stroke()

                    var distance = (robotradius/grid_size)*1.8;
                    var distance2 = distance*0.8;
                    var th_dist = Math.PI/8;
                    var x = path_x+distance*Math.cos(-path_th-Math.PI/2);
                    var y = path_y+distance*Math.sin(-path_th-Math.PI/2);
                    var x1 = path_x+distance2*Math.cos(-path_th-Math.PI/2-th_dist);
                    var y1 = path_y+distance2*Math.sin(-path_th-Math.PI/2-th_dist);
                    var x2 = path_x+distance2*Math.cos(-path_th-Math.PI/2+th_dist);
                    var y2 = path_y+distance2*Math.sin(-path_th-Math.PI/2+th_dist);

                    ctx.beginPath();
                    ctx.moveTo(x,y);
                    ctx.lineTo(x1,y1);
                    ctx.moveTo(x,y);
                    ctx.lineTo(x2,y2);
                    ctx.stroke()
                }

                //Local path!
                ctx.lineWidth = 1;
                ctx.strokeStyle = "#05C9FF";
                ctx.fillStyle = "#05C9FF";
                if(path_num != 0){
                    var localpath_num = supervisor.getLocalPathNum();
//                    print("local num : ",localpath_num);
                    for(var i=0; i<localpath_num; i++){
                        ctx.beginPath();
                        var local_x = (supervisor.getLocalPathx(i)/grid_size +origin_x)*newscale;
                        var local_y = (supervisor.getLocalPathy(i)/grid_size +origin_y)*newscale;
                        ctx.moveTo(local_x,local_y);
                        ctx.arc(local_x,local_y,2,0, Math.PI*2);
                        ctx.closePath();
                        ctx.fill();
                        ctx.stroke();
                    }
                }
            }
            canvas_map_cur.requestPaint();
        }
    }

    function draw_canvas_margin(){
        if(canvas_map_margin.available){
            var ctx = canvas_map_margin.getContext('2d');

            var map_data = supervisor.getMapData(map_name);
            var margin_obj = supervisor.getMarginObj();

            ctx.lineWidth = 0;
            ctx.lineCap = "round"
            ctx.strokeStyle = "#E7584D";
            ctx.fillStyle = "#E7584D";
            for(var i=0; i<margin_obj.length; i++){
                var point_x = (margin_obj[i])%map_width;
                var point_y = Math.floor((margin_obj[i])/map_width);
                ctx.beginPath();
                ctx.moveTo(point_x,point_y);
                ctx.arc(point_x,point_y,1,0,Math.PI*2);
                ctx.fill();
                ctx.stroke();
            }

            ctx.fillStyle = "#d0d0d0";
            ctx.strokeStyle = "#d0d0d0";
            for(var x=0; x< map_data.length; x++){
                if(map_data[x] > 100){
                    ctx.beginPath();
                    ctx.moveTo((x)%map_width,Math.floor((x)/map_width));
                    ctx.arc((x)%map_width,Math.floor((x)/map_width),0.5,0,Math.PI*2);
                    ctx.fill();
                    ctx.stroke();
                }
            }
            update_checker.start();
        }
    }

    function set_travel_draw(){
        var ctx = canvas_map.getContext('2d');

        var data = ctx.getImageData(0,0,map_width, map_height);
        var array = [];
        clear_canvas_temp();
        for(var i=0; i<data.data.length; i=i+4){
            if(data.data[i+3] > 0){
                if(data.data[i] > 0){
                    array.push(255);
                }else{
                    array.push(100);
                }
            }else{
                array.push(0);
            }

        }
        travelview.setMap(supervisor.getTravel(array));
    }
}

