#include "schedulerWindow.h"
#include <QTableWidgetItem>
#include <QHeaderView>
#include <QSqlError>
#include <QVBoxLayout>
#include <QSqlQuery>

SchedulerWindow::SchedulerWindow(QWidget *parent) : QMainWindow(parent) {
    setupUi(); // الآن سيجد المترجم تعريفها بالأسفل
    
    // ربط قاعدة البيانات
    db = QSqlDatabase::addDatabase("QSQLITE", "scheduler_connection");
    db.setDatabaseName("/mnt/c/Users/ASUS/rubaa/events.db");

    refreshTimer = new QTimer(this);
    connect(refreshTimer, &QTimer::timeout, this, &SchedulerWindow::updateTable);
    refreshTimer->start(1000);

    setWindowTitle("xv6 CPU Scheduler - Live Monitor");
    resize(800, 500);
}

// هذه الدالة كانت ناقصة وهي المسؤولة عن بناء شكل الجدول
void SchedulerWindow::setupUi() {
    auto *central = new QWidget(this);
    setCentralWidget(central);
    auto *layout = new QVBoxLayout(central);

    schedTable = new QTableWidget(this);
    schedTable->setColumnCount(3); 
    schedTable->setHorizontalHeaderLabels({"Process (Name/PID)", "Current State", "System Ticks"});
    
    schedTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
    schedTable->setAlternatingRowColors(true);
    schedTable->setStyleSheet("QHeaderView::section { background-color: #2c3e50; color: white; font-weight: bold; }");

    layout->addWidget(schedTable);
}

// هذه الدالة المسؤولة عن تحديث البيانات من القاعدة
void SchedulerWindow::updateTable() {
    if (!db.isOpen() && !db.open()) return;

    schedTable->setRowCount(0);
    QSqlQuery query("SELECT pid, state, tick, name FROM events ORDER BY id DESC LIMIT 20", db);

    QStringList states = {"UNUSED", "USED", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE"};

    while (query.next()) {
        int row = schedTable->rowCount();
        schedTable->insertRow(row);

        int pid = query.value(0).toInt();
        int stateIdx = query.value(1).toInt();
        int tick = query.value(2).toInt();
        QString name = query.value(3).toString();

        QString stateStr = (stateIdx >= 0 && stateIdx < 6) ? states[stateIdx] : "UNKNOWN";

        schedTable->setItem(row, 0, new QTableWidgetItem(QString("%1 (PID: %2)").arg(name).arg(pid)));
        
        auto *stateItem = new QTableWidgetItem(stateStr);
        if(stateStr == "RUNNING") stateItem->setBackground(Qt::green);
        else if(stateStr == "SLEEPING") stateItem->setBackground(Qt::yellow);
        
        schedTable->setItem(row, 1, stateItem);
        schedTable->setItem(row, 2, new QTableWidgetItem(QString::number(tick)));
    }
}

// الـ Destructor الذي كان يسبب خطأ undefined reference
SchedulerWindow::~SchedulerWindow() {
    if(db.isOpen()) db.close();
}