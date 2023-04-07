import QtQuick 2.12
import QtGraphicalEffects 1.0


Item {
    id: item_jog
    objectName: "item_jog"
    width: joystick.width
    height: joystick.height

    property bool bold: false

    property real angle : 0//mousearea.angle
    property real distance : 0

    property bool show_arrow: true

    property bool pressed: mousearea.pressed
    property int update_cnt: 0

    property bool verticalOnly : false
    property bool horizontalOnly : false
    property real mouseX2 : verticalOnly ? width * 0.5 : point.x
    property real mouseY2 : horizontalOnly ? height * 0.5 : point.y
    property real fingerAngle : Math.atan2(mouseX2, mouseY2)
    property int mcx : mouseX2 - width * 0.5
    property int mcy : mouseY2 - height * 0.5
    property bool fingerInBounds : fingerDistance2 < distanceBound2
    property real fingerDistance2 : mcx * mcx + mcy * mcy
    property real distanceBound : width * 0.5 - thumb.width * 0.5
    property real distanceBound2 : distanceBound * distanceBound
    property double signal_x : (mouseX2 - joystick.width/2) / distanceBound
    property double signal_y : -(mouseY2 - joystick.height/2) / distanceBound

    Image {
        id: joystick
        x: 0
        y: 0
        source: "icon/joystick_back.png"
    }

    Image{
        id: image_joy_up
        source: "icon/joy_up.png"
        visible: show_arrow&&verticalOnly?true:false
        width: 13
        height: 8
        anchors.horizontalCenter: joystick.horizontalCenter
        anchors.bottom: joystick.top
        anchors.bottomMargin: 8
    }
    ColorOverlay{
        visible: image_joy_up.visible && bold
        anchors.fill: image_joy_up
        source: image_joy_up
        color: "#585858"
    }

    Image{
        id: image_joy_down
        source: "icon/joy_down.png"
        visible: show_arrow&&verticalOnly?true:false
        width: 13
        height: 8
        anchors.horizontalCenter: joystick.horizontalCenter
        anchors.top: joystick.bottom
        anchors.topMargin: 8
    }
    ColorOverlay{
        visible: image_joy_down.visible && bold
        anchors.fill: image_joy_down
        source: image_joy_down
        color: "#585858"
    }
    Image{
        id: image_joy_left
        source: "icon/joy_left.png"
        visible: show_arrow&&horizontalOnly?true:false
        width: 8
        height: 13
        anchors.verticalCenter: joystick.verticalCenter
        anchors.right: joystick.left
        anchors.rightMargin: 8
    }
    ColorOverlay{
        visible: image_joy_left.visible && bold
        anchors.fill: image_joy_left
        source: image_joy_left
        color: "#585858"
    }
    Image{
        id: image_joy_right
        source: "icon/joy_right.png"
        visible: show_arrow&&horizontalOnly?true:false
        width: 8
        height: 13
        anchors.verticalCenter: joystick.verticalCenter
        anchors.left: joystick.right
        anchors.leftMargin: 8
    }
    ColorOverlay{
        visible: image_joy_right.visible && bold
        anchors.fill: image_joy_right
        source: image_joy_right
        color: "#585858"
    }

    ParallelAnimation {
        id: returnAnimation
        NumberAnimation { target: thumb.anchors; property: "horizontalCenterOffset";
            to: 0; duration: 200; easing.type: Easing.OutSine }
        NumberAnimation { target: thumb.anchors; property: "verticalCenterOffset";
            to: 0; duration: 200; easing.type: Easing.OutSine }
    }



    function remote_input(re_x, re_y){
        returnAnimation.stop();
        update_cnt++;
        if(verticalOnly){
            mcy = (width/2)*re_x/32767;
            mcx = 0;
        }else if(horizontalOnly){
            mcx = (width/2)*re_y/32767;
            mcy = 0;
        }
        if (fingerInBounds) {
            thumb.anchors.horizontalCenterOffset = mcx
            thumb.anchors.verticalCenterOffset = mcy
        } else {
            angle = Math.atan2(mcy, mcx)
            thumb.anchors.horizontalCenterOffset = Math.cos(angle) * distanceBound
            thumb.anchors.verticalCenterOffset = Math.sin(angle) * distanceBound
        }
    }
    function remote_stop(){
        print("remote stop");
        mcx = 0
        mcy = 0
        update_cnt = 0;
        returnAnimation.restart();
    }

    MultiPointTouchArea {
        id: mousearea
        anchors.fill: parent
        minimumTouchPoints: 1
        maximumTouchPoints: 1
        touchPoints: TouchPoint{id: point}
        onPressed: {
            print("pressed")
            update_cnt = 0;
            returnAnimation.stop();
        }
        onReleased: {
            print("release")
            update_cnt = 0;
            parent.pressed = false;
            returnAnimation.restart()
        }
        onTouchUpdated: {
            if(pressed){
                update_cnt++;
                print(point.x,point.y)

                mouseX2 = verticalOnly ? width * 0.5 : point.x
                mouseY2 = horizontalOnly ? height * 0.5 : point.y
                fingerAngle = Math.atan2(mouseX2, mouseY2)
                fingerInBounds = fingerDistance2 < distanceBound2
                mcx =mouseX2 - width * 0.5
                mcy =mouseY2 - height * 0.5

                fingerDistance2 = mcx * mcx + mcy * mcy

                distanceBound = width * 0.5 - thumb.width * 0.5
                distanceBound2 = distanceBound * distanceBound
                signal_x = (mouseX2 - joystick.width/2) / distanceBound
                signal_y = -(mouseY2 - joystick.height/2) / distanceBound

                if (fingerInBounds) {
                    thumb.anchors.horizontalCenterOffset = mcx
                    thumb.anchors.verticalCenterOffset = mcy
                } else {
                    angle = Math.atan2(mcy, mcx)
                    thumb.anchors.horizontalCenterOffset = Math.cos(angle) * distanceBound
                    thumb.anchors.verticalCenterOffset = Math.sin(angle) * distanceBound
                }

                // Fire the signal to indicate the joystick has moved
                angle = Math.atan2(signal_y, signal_x)
    //            print(mcx, signal_x, signal_y,  fingerDistance2, distanceBound, angle);

            }
        }
    }

    Image {
        id: thumb
        source: "icon/joystick_thumb.png"
        anchors.centerIn: parent
    }
}
