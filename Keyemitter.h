#ifndef KEYEMITTER_H
#define KEYEMITTER_H
#include <QObject>
#include <QDebug>
#include <QCoreApplication>
#include <QKeyEvent>
class KeyEmitter : public QObject
{
    Q_OBJECT
public:
    KeyEmitter(QObject* parent=nullptr) : QObject(parent) {}
    Q_INVOKABLE void keyPressed(QObject* tf, Qt::Key k) {
        QKeyEvent keyPressEvent = QKeyEvent(QEvent::Type::KeyPress, k, Qt::NoModifier, QKeySequence(k).toString());
        if(k == Qt::Key_Space){
            keyPressEvent = QKeyEvent(QEvent::Type::KeyPress, k, Qt::NoModifier, " ");
        }
        QCoreApplication::sendEvent(tf, &keyPressEvent);
    }
    Q_INVOKABLE void keyPressed(QObject* tf, QString k) {
        QKeyEvent keyPressEvent = QKeyEvent(QEvent::Type::KeyPress, QKeySequence(k).count(), Qt::NoModifier, k);
        QCoreApplication::sendEvent(tf, &keyPressEvent);
    }
};
#endif // KEYEMITTER_H

