#include "mainwindow.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QGridLayout>
#include <QLabel>
#include <QPushButton>
#include <QUrl>
#include <QVBoxLayout>
#include <QWidget>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), titleLabel(nullptr), btnScheduler(nullptr),
      btnPageTable(nullptr), btnFileSystem(nullptr), btnSyscall(nullptr) {

  QWidget *central = new QWidget(this);
  setCentralWidget(central);

  titleLabel = new QLabel("xv6 Educational GUI", this);
  titleLabel->setAlignment(Qt::AlignCenter);
  QFont f = titleLabel->font();
  f.setPointSize(18);
  f.setBold(true);
  titleLabel->setFont(f);

  btnScheduler = new QPushButton("Scheduling", this);
  btnPageTable = new QPushButton("Page Tables", this);
  btnFileSystem = new QPushButton("File System", this);
  btnSyscall = new QPushButton("Syscalls", this);

  connect(btnScheduler, &QPushButton::clicked, this,
          &MainWindow::onSchedulerClicked);
  connect(btnPageTable, &QPushButton::clicked, this,
          &MainWindow::onPageTableClicked);
  connect(btnFileSystem, &QPushButton::clicked, this,
          &MainWindow::onFileSystemClicked);
  connect(btnSyscall, &QPushButton::clicked, this,
          &MainWindow::onSyscallClicked);

  QGridLayout *grid = new QGridLayout;
  grid->addWidget(btnScheduler, 0, 0);
  grid->addWidget(btnPageTable, 0, 1);
  grid->addWidget(btnFileSystem, 1, 0);
  grid->addWidget(btnSyscall, 1, 1);

  QVBoxLayout *mainLayout = new QVBoxLayout;
  mainLayout->addWidget(titleLabel);
  mainLayout->addSpacing(20);
  mainLayout->addLayout(grid);
  mainLayout->addStretch();

  central->setLayout(mainLayout);

  setWindowTitle("xv6 Educational Main GUI");
  resize(500, 300);
}

MainWindow::~MainWindow() {}

void MainWindow::openModuleFolder(const QString &relativePath) {
  QString baseDir = QCoreApplication::applicationDirPath();
  QDir dir(baseDir);

  dir.cdUp();

  QString targetPath = dir.absoluteFilePath(relativePath);

  QDesktopServices::openUrl(QUrl::fromLocalFile(targetPath));
}

void MainWindow::onSchedulerClicked() { openModuleFolder("SchedulerUI"); }

void MainWindow::onPageTableClicked() { openModuleFolder("PageTableUI"); }

void MainWindow::onFileSystemClicked() { openModuleFolder("FileSystemUI"); }

void MainWindow::onSyscallClicked() { openModuleFolder("SyscallUI"); }
