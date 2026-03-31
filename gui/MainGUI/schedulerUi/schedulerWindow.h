#ifndef SCHEDULERWINDOW_H
#define SCHEDULERWINDOW_H

#include <QMainWindow>
#include <QTableWidget>
#include <QTimer>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QVBoxLayout>

class SchedulerWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit SchedulerWindow(QWidget *parent = nullptr);
    ~SchedulerWindow();

private slots:
    void updateTable();

private:
    void setupUi();
    QTableWidget *schedTable;
    QTimer *refreshTimer;
    QSqlDatabase db; // إضافة هذا السطر
};

#endif