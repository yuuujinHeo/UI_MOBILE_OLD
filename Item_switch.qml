import QtQuick 2.0
import "."
import io.qt.Supervisor 1.0

Item {
    id: item_switch
    property int width_back: 6
    property int width_head: 5
    property int width_head2: 40
    property int width_dist: 15
    width: width_back*2 + width_head*2 + width_head2
    height: width_head2*2 +width_back*2 + width_head*4 + width_dist
    property bool onoff: false
    property bool touchEnabled: false
    onOnoffChanged: {
        if(onoff){
            head.y = width_back;
        }else{
            head.y = width_back + width_head*2 + width_head2 + width_dist;
        }
        if(onoff && background.color != "#12d27c"){
            background.color = "#12d27c";
        }else if(!onoff && background.color != "#525252"){
            background.color = "#525252";
        }

        if(onoff && onoff_text.text != "ON"){
            onoff_text.text = "ON";
        }else if(!onoff && onoff_text.text != "OFF"){
            onoff_text.text = "OFF";
        }
    }
    Rectangle{
        id: background
        anchors.fill: parent
        radius: 40
        color: "#525252"
        MouseArea{
            anchors.fill: parent
            enabled: touchEnabled
            onClicked: {
                if(onoff){
                    print("click 1: onoff -> off");
                    onoff = false;
                }else{
                    print("click 1: onoff -> on");
                    onoff = true;
                }
            }
        }
        Rectangle{
            id: head
            width: width_head*2 + width_head2
            height: width
            radius: width
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
            y: width_head*2 + width_head2 + width_dist
            Behavior on y{
                SpringAnimation{
                    duration: 500
                    spring: 1
                    damping: 0.2
                }
            }

            Rectangle{
                width: width_head2
                height: width_head2
                radius: width_head2
                anchors.centerIn: parent
                color: background.color
                Text{
                    id: onoff_text
                    anchors.centerIn: parent
                    text: "OFF"
                    color: "white"
                    font.family: font_noto_b.name
                    font.bold: true
                    font.pixelSize: 14
                }
            }


            MouseArea{
                anchors.fill: parent
                enabled: touchEnabled
                property var firstY;
                property var width_dis: 0
                onPressed: {
                    firstY = mouseY;
                    width_dis = 0;
//                    title_text.visible = false;
                }
                onPositionChanged: {
                    width_dis = mouseY-firstY;
                    if(head.y + width_dis < width_back){
                        head.y = width_back;
                    }else if(head.y + width_dis > width_back + width_head*2 + width_head2 + width_dist){
                        head.y = width_back + width_head*2 + width_head2 + width_dist;
                    }else{
                        head.y = head.y + width_dis;
                    }

                    if(width_dis > 0){
                        if(background.color != "#525252"){
                            background.color = "#525252";
                        }
                        if(onoff_text.text != "OFF"){
                            onoff_text.text = "OFF";
                        }
                    }else{
                        if(background.color != "#12d27c"){
                            background.color = "#12d27c";
                        }
                        if(onoff_text.text != "ON"){
                            onoff_text.text = "ON";
                        }
                    }
                }
                onReleased: {
                    if(width_dis>0){
                        onoff = false;
                        print("drag: onoff -> off");
                        head.y = width_back + width_head*2 + width_head2 + width_dist;
                    }else if(width_dis<0){
                        onoff = true;
                        print("drag : onoff -> on");
                        head.y = width_back;
                    }else if(width_dis == 0){
                        if(onoff){
                            print("click : onoff -> off");
                            onoff = false;
                        }else{
                            print("click : onoff -> on");
                            onoff = true;
                        }
                    }
//                    title_text.visible = show_title;
                }
            }
        }
    }
}
