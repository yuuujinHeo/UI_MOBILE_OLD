#include "MapView.h"

PixmapContainer::PixmapContainer(QObject *parent){
}

MapView::MapView(QQuickItem *parent):
    QQuickPaintedItem(parent)
{
}

void MapView::setMap(QObject *pixmapContainer){
    PixmapContainer *pc = qobject_cast<PixmapContainer*>(pixmapContainer);
    Q_ASSERT(pc);
    m_pixmapContainer.pixmap = pc->pixmap;
    update();
}

void MapView::setTravel(QList<int> canvas){
    qDebug() << canvas.size();

}

void MapView::paint(QPainter *painter){
    qDebug() << width() << height();
    painter->drawPixmap(0,0,width(),height(),m_pixmapContainer.pixmap);
}
