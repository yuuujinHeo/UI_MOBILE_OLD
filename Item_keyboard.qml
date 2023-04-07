import QtQuick 2.12

Item {
    id: item_keyboard
    objectName: "item_keyboard"

    width: btn_size*3+btn_dist*2
    height:btn_size*2+btn_dist
    property string color_default: "#f4f4f4"
    property string color_pushed: "#12d27c"

    property int btn_size: 70
    property int btn_dist: 8

    property bool pressed_up: false
    property bool pressed_down: false
    property bool pressed_left: false
    property bool pressed_right: false

    function clear(){
        if(!pressed_down && !pressed_up){
            supervisor.joyMoveXY(0);
        }

        if(!pressed_left && !pressed_right){
            supervisor.joyMoveR(0);
        }
    }

    onPressed_upChanged: {
        if(pressed_up){
            supervisor.joyMoveXY(1);
            pressed_down = false;
        }else{
            clear();
        }
    }
    onPressed_downChanged: {
        if(pressed_down){
            supervisor.joyMoveXY(-1);
            pressed_up = false;
        }else{
            clear();
        }
    }
    onPressed_leftChanged: {
        if(pressed_left){
            supervisor.joyMoveR(1);
            pressed_right = false;
        }else{
            clear();
        }
    }
    onPressed_rightChanged: {
        if(pressed_right){
            supervisor.joyMoveR(-1);
            pressed_left = false;
        }else{
            clear();
        }
    }



    Rectangle{
        id: btn_up
        width: btn_size
        height: btn_size
        radius: btn_size/10
        color: pressed_up?color_pushed:color_default
        border.color: "#282828"
        border.width: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        Image{
            source: "icon/keyboard_up.png"
            anchors.centerIn: parent
        }
        MultiPointTouchArea{
            anchors.fill: parent
            onPressed: {
                pressed_up = true;
            }
            onReleased: {
                pressed_up = false;
            }
        }
    }
    Rectangle{
        id: btn_down
        width: btn_size
        height: btn_size
        radius: btn_size/10
        color: pressed_down?color_pushed:color_default
        border.color: "#282828"
        border.width: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: btn_dist
        anchors.top: btn_up.bottom
        Image{
            source: "icon/keyboard_down.png"
            anchors.centerIn: parent
        }
        MultiPointTouchArea{
            anchors.fill: parent
            onPressed: {
                pressed_down = true;
            }
            onReleased: {
                pressed_down = false;
            }
        }
    }
    Rectangle{
        id: btn_left
        width: btn_size
        height: btn_size
        radius: btn_size/10
        color: pressed_left?color_pushed:color_default
        border.color: "#282828"
        border.width: 2
        anchors.right: btn_down.left
        anchors.rightMargin: btn_dist
        anchors.top: btn_up.bottom
        anchors.topMargin: btn_dist
        Image{
            source: "icon/keyboard_left.png"
            anchors.centerIn: parent
        }
        MultiPointTouchArea{
            anchors.fill: parent
            onPressed: {
                pressed_left = true;
            }
            onReleased: {
                pressed_left = false;
            }
        }
    }
    Rectangle{
        id: btn_right
        width: btn_size
        height: btn_size
        radius: btn_size/10
        color: pressed_right?color_pushed:color_default
        border.color: "#282828"
        border.width: 2
        anchors.left: btn_down.right
        anchors.leftMargin: btn_dist
        anchors.top: btn_up.bottom
        anchors.topMargin: btn_dist
        Image{
            source: "icon/keyboard_right.png"
            anchors.centerIn: parent
        }
        MultiPointTouchArea{
            anchors.fill: parent
            onPressed: {
                pressed_right = true;
            }
            onReleased: {
                pressed_right = false;
            }
        }
    }
}
