//#ifndef RB_JOYSTICK_H
//#define RB_JOYSTICK_H

//#include <QObject>
//#include <fcntl.h>
//#include <unistd.h>
//#include <QTimer>
//#include <sys/ioctl.h>
//#include <QThread>
//#include <linux/joystick.h>
//#include <QString>

//typedef enum{JAXIS_LJOG_RL = 0, JAXIS_LJOG_UD, JAXIS_RJOG_RL, JAXIS_RJOG_UD, JAXIS_ARW_RL, JAXIS_ARW_UD} JOY_AXIS_SEQ;
//typedef enum{JBTN_X = 0, JBTN_A, JBTN_B, JBTN_Y, JBTN_LB, JBTN_RB, JBTN_LT, JBTN_RT, JBTN_BACK, JBTN_START, JBTN_LJOG, JBTN_RJOG} JOY_BTN_SEQ;

//float calc_joy(float in);

//class RBJoystick : public QObject
//{
//    Q_OBJECT
//public:
//    RBJoystick();
//    ~RBJoystick();

//    int		ConnectJoy(const QString _devName = "/dev/input/js0");
//    int     DisconnectJoy();

//    int*    GetAxis()               {return JoyAxis;}
//    char*   GetButton()             {return JoyButton;}

//    int		JoyAxis[8];
//    char	JoyButton[12];
//    char	JoyButton_pre[12];

//    int     State;

//    int		connection;
//    int		fdJoy;

//    int     m_manufacturerID;
//    int     m_productID;

//private slots:
//    void updatejoy();
//private:
//    int		isTerminated;
//    QString	devName;
//    struct js_event JoyEvent;
//    QTimer *timer;
//    unsigned long	JoyThraedHandler;
//};

//#endif // RB_JOYSTICK_H
