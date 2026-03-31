#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

class QPushButton;
class QLabel;

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();
private slots:
    void onSchedulerClicked();
    void onPageTableClicked();
    void onFileSystemClicked();
    void onSyscallClicked();

private:
    QLabel *titleLabel;
    QPushButton *btnScheduler;
    QPushButton *btnPageTable;
    QPushButton *btnFileSystem;
    QPushButton *btnSyscall;
};

#endif