#ifndef BUFFERCACHEWIDGET_H
#define BUFFERCACHEWIDGET_H

#include <QWidget>
#include <QTableWidget>
#include <QVBoxLayout>
#include <QLabel>
#include <QTimer>
#include <sqlite3.h>

struct BufferInfo {
    int blockno;
    int status; // 0: Free, 1: Locked, 2: Dirty
    int last_update_tick;
};

class BufferCacheWidget : public QWidget {
    Q_OBJECT
public:
    explicit BufferCacheWidget(QWidget *parent = nullptr);
    void updateFromDB(); // دالة لجلب البيانات من SQLite

private:
    QTableWidget *bufferTable;
    QLabel *statsLabel;
    int hits = 0;
    int misses = 0;
    
    void setupUI();
};

#endif