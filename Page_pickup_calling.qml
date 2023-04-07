import QtQuick 2.12
import QtQuick.Controls 2.12
import "."
import io.qt.Supervisor 1.0
import QtMultimedia 5.12

Item {
    id: page_pickup_calling
    objectName: "page_pickup_calling"
    width: 1280
    height: 800

    property int type: 0

    function init(){
        if(type == 0){//부르셨나요?
            target_pos2.visible = false;
        }else if(type == 1){//다 드신 그릇은
            target_pos2.visible = true;
        }
        text_mention.visible = true;
        target_pos.visible = true;
        btn_confirm.visible = true;
        voice_pickup.play();
        text_hello.visible = false;
        timer_hello.stop();
    }

    Rectangle{
        id: rect_background
        anchors.fill: parent
        color: "#282828"
    }
    Image{
        id: image_robot
        source: {
            if(type==0){
                "image/robot_callme.png"
            }else if(type == 1){
                "image/robot_clear.png"
            }
        }
        width: {
            if(type==0){
                221
            }else if(type == 1){
                257
            }
        }
        height: {
            if(type==0){
                334
            }else if(type == 1){
                457
            }
        }
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 200
    }
    Column{
        id: column_pickup
        anchors.left: image_robot.right
        anchors.leftMargin: 100
        anchors.verticalCenter: image_robot.verticalCenter

        Text{
            id: target_pos
            text: {
                if(type == 0){
                    "고객님, 부르셨나요?"
                }else if(type == 1){
                    "<font color=\"#12d27c\">다 드신 그릇</font> 은"
                }
            }
            font.pixelSize: 60
            font.family: font_noto_b.name
            color: "white"
        }
        Text{
            id: target_pos2
            visible:type==1?true:false
            text: "저에게 전달해 주세요."
            font.pixelSize: 60
            font.family: font_noto_b.name
            color: "white"
        }
        Rectangle{
            color:"transparent"
            width: parent.width
            height: {
                if(type == 0){
                    10
                }else if(type == 1){
                    40
                }
            }
        }
        Text{
            id: text_mention
            text:  {
                if(type == 0){
                    "이용이 끝나시면 <font color=\"#12d27c\">확인버튼</font>을 눌러주세요."
                }else if(type == 1){
                    "완료 후 아래 <font color=\"#12d27c\">확인버튼</font>을 눌러주세요."
                }
            }
            font.pixelSize: 40
            font.family: font_noto_b.name
            color: "white"
        }
        Rectangle{
            color:"transparent"
            width: parent.width
            height: {
                if(type == 0){
                    60
                }else if(type == 1){
                    40
                }
            }
        }
        Image{
            id: btn_confirm
            source:"icon/btn_confirm.png"
            anchors.horizontalCenter: parent.horizontalCenter
            width: 250
            height: 90
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    console.log("UI : CONFIRM");
                    voice_pickup.stop();
                    voice_thanks.play();
                    text_mention.visible = false;
                    target_pos.visible = false;
                    target_pos2.visible = false;
                    btn_confirm.visible = false;
                    text_hello.visible = true;
                    timer_hello.start();
                }
            }
        }

    }
    Text{
        id: text_hello
        text:"감사합니다."
        visible: false
        font.pixelSize: 50
        font.family: font_noto_b.name
        color: "white"
        anchors.left: image_robot.right
        anchors.leftMargin: 100
        anchors.verticalCenter: image_robot.verticalCenter
    }
    Audio{
        id: voice_pickup
        autoPlay: false
        volume: parseInt(supervisor.getSetting("ROBOT_SW","volume_voice"))/100
        source: "bgm/voice_pickup_calling.mp3"
    }
    Audio{
        id: voice_thanks
        autoPlay: false
        volume: parseInt(supervisor.getSetting("ROBOT_SW","volume_voice"))/100
        source: "bgm/voice_thanks.mp3"
    }

    Timer{
        id: timer_hello
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            supervisor.confirmPickup();
            console.log("UI : MOVE NEXT");
        }
    }
}
