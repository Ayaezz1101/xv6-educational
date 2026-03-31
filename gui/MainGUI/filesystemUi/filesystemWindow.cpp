#include "filesystemWindow.h"
#include <QGraphicsRectItem>
#include <QGraphicsTextItem>
#include <QBrush>
#include <QPen>
// في FileSystemWindow.cpp
#include "bufferCacheWidget.h"


FileSystemWindow::FileSystemWindow(QWidget *parent) : QMainWindow(parent) {
    setupLayout();
    drawLayers();   // رسم الطبقات السبعة
    drawDiskMap();  // رسم خريطة القرص
    
    setWindowTitle("xv6 File System Education Tool");
    resize(900, 700);
}

void FileSystemWindow::setupLayout() {
    QWidget *central = new QWidget(this);
    setCentralWidget(central);
    QVBoxLayout *layout = new QVBoxLayout(central);

    tabs = new QTabWidget(this);

    // 1. تبويب الطبقات (Seven Layers)
    layersScene = new QGraphicsScene(this);
    layersView = new QGraphicsView(layersScene, this);
    tabs->addTab(layersView, "1. File System Layers (The Pipeline)");

    // 2. تبويب خريطة القرص (Disk Layout)
    diskScene = new QGraphicsScene(this);
    diskView = new QGraphicsView(diskScene, this);
    tabs->addTab(diskView, "2. Physical Disk Map");

    explanationArea = new QTextEdit(this);
    explanationArea->setReadOnly(true);
    explanationArea->setFixedHeight(150);
    explanationArea->setHtml("<b style='color:blue;'>How it works:</b><br>"
                             "When a process calls <i>read()</i>, the request travels from the top layer "
                             "(File Descriptor) down to the bottom layer (Disk).");

    layout->addWidget(tabs);
    layout->addWidget(explanationArea);
    // داخل setupLayout:
    BufferCacheWidget *bufWidget = new BufferCacheWidget(this);
    tabs->addTab(bufWidget, "3. Buffer Cache Monitor");
}

void FileSystemWindow::drawLayers() {
    layersScene->clear();
    QStringList layers = {
        "7. File Descriptor (System Call Interface)",
        "6. Pathname (Resolving /a/b/c)",
        "5. Directory (Name to Inode)",
        "4. Inode (File Metadata)",
        "3. Logging (Crash Recovery)",
        "2. Buffer Cache (Memory Speed)",
        "1. Disk (Virtio Driver)"
    };

    int y = 0;
    for(const QString& name : layers) {
        // رسم مربع الطبقة
        auto rect = layersScene->addRect(0, y, 400, 50, QPen(Qt::black), QBrush(QColor(200, 230, 255)));
        
        // إضافة النص
        auto text = layersScene->addText(name);
        text->setPos(10, y + 10);
        
        // رسم سهم لأسفل (إلا في الطبقة الأخيرة)
        if (name != layers.last()) {
            layersScene->addLine(200, y + 50, 200, y + 70, QPen(Qt::black, 2));
        }
        y += 70;
    }
}

void FileSystemWindow::drawDiskMap() {
    diskScene->clear();
    // البيانات المأخوذة من كتاب xv6 (Figure 8.2)
    struct DiskSection { QString name; int blocks; QColor color; };
    QList<DiskSection> sections = {
        {"Boot", 1, Qt::darkGray},
        {"Super", 1, Qt::cyan},
        {"Log", 30, Qt::yellow},
        {"Inodes", 50, Qt::green},
        {"Bitmap", 1, Qt::magenta},
        {"Data", 100, Qt::blue}
    };

    int x = 0;
    for(const auto& sec : sections) {
        int width = sec.blocks * 5; // تكبير العرض ليتناسب مع الشاشة
        if(width < 60) width = 60;   // حد أدنى للعرض لظهور النص
        
        diskScene->addRect(x, 0, width, 100, QPen(Qt::black), QBrush(sec.color));
        auto text = diskScene->addText(sec.name);
        text->setPos(x + 5, 40);
        x += width + 5;
    }
    
}
FileSystemWindow::~FileSystemWindow() { }