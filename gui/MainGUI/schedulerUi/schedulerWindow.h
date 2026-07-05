#ifndef SCHEDULERWINDOW_H
#define SCHEDULERWINDOW_H

#include <QMainWindow>
#include <QTabWidget>
#include <QTableWidget>
#include <QTextEdit>
#include <QComboBox>
#include <QPushButton>
#include <QTimer>
#include <QSqlDatabase>
#include <QWidget>
#include <QProcess>
#include <QLabel>

class SchedulerWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit SchedulerWindow(QWidget *parent = nullptr);
    ~SchedulerWindow();

private slots:
    void refreshAll();
    void loadTimeline();
    void updateLiveEvents();
    void explainSelectedTimelineRow();

    void startLiveCapture();
    void stopLiveCapture();
    void rebuildIntervals();

    void onIngestorStarted();
    void onIngestorFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onBuilderFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    void setupDatabase();
    void setupUi();

    void setupSummaryTab();
    void setupTimelineTab();
    void setupLiveTab();

    void loadSchedulerInfo();
    void loadProcessSummary();
    void loadCpuSummary();
    void loadFilters();

    bool tableExists(const QString &tableName);
    bool hasAnyEvents();

    QString stateToString(int state) const;
    QString offReasonToString(const QVariant &reasonVar) const;
    void showDbError(const QString &context);
    void updateStatusLabel(const QString &text, const QString &color = "#2c3e50");

private:
    QString connectionName;
    QSqlDatabase db;
    QTimer *refreshTimer;

    QTabWidget *tabs;

    QWidget *summaryTab;
    QTextEdit *infoBox;
    QTableWidget *processTable;
    QTableWidget *cpuTable;
    QPushButton *summaryRefreshButton;

    QWidget *timelineTab;
    QComboBox *pidFilter;
    QComboBox *cpuFilter;
    QPushButton *timelineRefreshButton;
    QTableWidget *timelineTable;
    QTextEdit *timelineExplanationBox;

    QWidget *liveTab;
    QTableWidget *liveTable;
    QPushButton *liveRefreshButton;

    QPushButton *startCaptureButton;
    QPushButton *stopCaptureButton;
    QPushButton *rebuildButton;
    QLabel *statusLabel;

    QProcess *ingestorProcess;
    QProcess *builderProcess;
};

#endif