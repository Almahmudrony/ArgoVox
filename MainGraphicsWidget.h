#ifndef MAINGRAPHICSWIDGET_H
#define MAINGRAPHICSWIDGET_H

#include <QGLWidget>
#include <QtGui>
#include "View.h"
#include "Camera.h"
#include "TileManager.h"
#include "Grid.h"
#include "GBuffer.h"
#include "LightBuffer.h"
#include "VoxelGrid.h"
#include "GlossyBuffer.h"
#include "IndirectBuffer.h"
#include "ColorBuffer.h"
#include "BlurBuffer.h"

class MainGraphicsWidget : public QGLWidget
{
    Q_OBJECT

private:
    int fps;
	View *view;
	Camera *camera;
	TileManager *tileManager;
	Grid *myGrid;
	
	GBuffer *m_gBuffer;
	LightBuffer *m_lightBuffer;
	GlossyBuffer *m_glossyBuffer;
	IndirectBuffer *m_indirectBuffer;
	BlurBuffer *m_blurBuffer;
	FinalBuffer *m_finalBuffer;

	void forwardRender();
	void deferredRender();
	void voxelRender();


protected:
    void initializeGL();
    void resizeGL(int width, int height);
	void paintGL() {update(fps); render();}
	void keyPressEvent (QKeyEvent *event);
	void keyReleaseEvent (QKeyEvent *event);
    void mousePressEvent(QMouseEvent *event);
	void mouseReleaseEvent(QMouseEvent *event);
    void mouseMoveEvent(QMouseEvent *event);
	void wheelEvent(QWheelEvent *event);	

public:
	MainGraphicsWidget(QGLFormat fmt, QWidget *parent = 0);

    void update(float fps);
	void render();
};

#endif