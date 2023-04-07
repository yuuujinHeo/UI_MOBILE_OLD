#ifndef MAPVIEW_H
#define MAPVIEW_H

#include <QPainter>
#include <QObject>
#include <QPixmap>
#include <QQuickPaintedItem>

class PixmapContainer : public QObject
{
    Q_OBJECT
public:
    explicit PixmapContainer(QObject *parent = 0);
    QPixmap pixmap;
};

class MapView : public QQuickPaintedItem
{
    Q_OBJECT
public:
    MapView(QQuickItem *parent = Q_NULLPTR);
    Q_INVOKABLE void setMap(QObject *pixmapContainer);
    Q_INVOKABLE void setTravel(QList<int> canvas);
protected:
    virtual void paint(QPainter *painter) Q_DECL_OVERRIDE;

private:
    PixmapContainer m_pixmapContainer;
};


#endif // MAPVIEW_H
