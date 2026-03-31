#include "mainwindow.h"
#include "schedulerWindow.h" // تأكدي من تضمين الملف الصحيح
#include <QVBoxLayout>
#include <QGridLayout>
#include <QPushButton>
#include <QLabel>

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    QWidget *central = new QWidget(this);
    setCentralWidget(central);
    QVBoxLayout *mainLayout = new QVBoxLayout(central);

    titleLabel = new QLabel("xv6 Educational Dashboard", this);
    titleLabel->setAlignment(Qt::AlignCenter);
    titleLabel->setStyleSheet("font-size: 22pt; font-weight: bold; color: #2c3e50; margin: 25px;");
    mainLayout->addWidget(titleLabel);

    QGridLayout *grid = new QGridLayout();
    
    btnScheduler = new QPushButton("📊 CPU Scheduling", this);
    btnPageTable = new QPushButton("🧠 Memory (Page Tables)", this);
    btnFileSystem = new QPushButton("📁 File System Explorer", this);
    btnSyscall   = new QPushButton("📞 System Calls Lab", this);

    // ستايل احترافي موحد
    QString btnStyle = "QPushButton { background-color: #3498db; color: white; border-radius: 15px; min-height: 100px; font-size: 18px; font-weight: bold; border: 2px solid #2980b9; } "
                       "QPushButton:hover { background-color: #2ecc71; border: 2px solid #27ae60; }";
    
    btnScheduler->setStyleSheet(btnStyle);
    btnPageTable->setStyleSheet(btnStyle);
    btnFileSystem->setStyleSheet(btnStyle);
    btnSyscall->setStyleSheet(btnStyle);

    grid->addWidget(btnScheduler, 0, 0);
    grid->addWidget(btnPageTable, 0, 1);
    grid->addWidget(btnFileSystem, 1, 0);
    grid->addWidget(btnSyscall, 1, 1);

    mainLayout->addLayout(grid);
    mainLayout->addStretch();

    connect(btnScheduler, &QPushButton::clicked, this, &MainWindow::onSchedulerClicked);
    
    setWindowTitle("xv6 OS Educational GUI v2.0");
    resize(700, 550);
}

void MainWindow::onSchedulerClicked() {
    SchedulerWindow *schedWin = new SchedulerWindow();
    schedWin->setAttribute(Qt::WA_DeleteOnClose);
    schedWin->show();
}

// باقي الدوال تبقى فارغة حالياً
void MainWindow::onPageTableClicked() {}
void MainWindow::onFileSystemClicked() {}
void MainWindow::onSyscallClicked() {}

MainWindow::~MainWindow() {}