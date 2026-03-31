#ifndef FILESYSTEMWINDOW_H
#define FILESYSTEMWINDOW_H

#include <QMainWindow>
#include <QTabWidget>
#include <QGraphicsView>
#include <QGraphicsScene>
#include <QTextEdit>
#include <QVBoxLayout>

class FileSystemWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit FileSystemWindow(QWidget *parent = nullptr);
    ~FileSystemWindow();

private:
    void setupLayout();
    void drawDiskMap();
    void drawLayers();

    QTabWidget *tabs;
    QGraphicsView *diskView;
    QGraphicsScene *diskScene;
    
    QGraphicsView *layersView;
    QGraphicsScene *layersScene;

    QTextEdit *explanationArea;
};

#endif