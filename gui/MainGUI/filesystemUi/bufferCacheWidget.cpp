#include "bufferCacheWidget.h"
#include <QHeaderView>

BufferCacheWidget::BufferCacheWidget(QWidget *parent) : QWidget(parent) {
    setupUI();
    
    // تيمر لتحديث الواجهة كل ثانية من قاعدة البيانات
    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &BufferCacheWidget::updateFromDB);
    timer->start(1000);
}

void BufferCacheWidget::setupUI() {
    QVBoxLayout *layout = new QVBoxLayout(this);

    statsLabel = new QLabel("Cache Stats: Hits: 0 | Misses: 0", this);
    statsLabel->setStyleSheet("font-weight: bold; font-size: 14px; color: #2c3e50;");
    layout->addWidget(statsLabel);

    bufferTable = new QTableWidget(5, 6, this); // 5*6 = 30 buffers
    bufferTable->horizontalHeader()->hide();
    bufferTable->verticalHeader()->hide();
    bufferTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    
    // جعل المربعات متساوية الحجم
    for(int i=0; i<6; i++) bufferTable->setColumnWidth(i, 100);
    for(int i=0; i<5; i++) bufferTable->setRowHeight(i, 80);


    layout->addWidget(bufferTable);
}

void BufferCacheWidget::updateFromDB() {
    sqlite3 *db;
    if (sqlite3_open("/mnt/c/Users/ASUS/rubaa/events.db", &db) != SQLITE_OK) return;

    const char *query = "SELECT type, blockno FROM fs_events ORDER BY id DESC LIMIT 30";
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(db, query, -1, &stmt, nullptr) == SQLITE_OK) {
        int row = 0, col = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            int type = sqlite3_column_int(stmt, 0);
            int bno = sqlite3_column_int(stmt, 1);

            QTableWidgetItem *item = new QTableWidgetItem(QString("Block: %1").arg(bno));
            item->setTextAlignment(Qt::AlignCenter);

            // تلوين البلوك بناءً على الحدث
            if (type == 6) { // HIT
                item->setBackground(Qt::green);
                hits++;
            } else if (type == 7) { // MISS
                item->setBackground(Qt::yellow);
                misses++;
            } else { // RELEASE
                item->setBackground(Qt::lightGray);
            }

            bufferTable->setItem(row, col, item);
            col++; if(col > 5) { col = 0; row++; }
        }
    }
    
    statsLabel->setText(QString("Cache Stats: Hits: %1 | Misses: %2").arg(hits/10).arg(misses/10));
    sqlite3_finalize(stmt);
    sqlite3_close(db);
}