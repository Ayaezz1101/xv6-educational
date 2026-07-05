#include "schedulerWindow.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFormLayout>
#include <QGroupBox>
#include <QHeaderView>
#include <QLabel>
#include <QMessageBox>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QColor>
#include <QUuid>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QTimer>
#include <QPushButton>
#include <QTabWidget>
#include <QTextEdit>
#include <QTableWidget>
#include <QComboBox>
#include <QAbstractItemView>

static const QString DB_PATH = "events.db";
static const QString INGEST_SCRIPT = "ingest_from_stream.py";
static const QString BUILD_SCRIPT = "build_intervals.py";

static QString findProjectRoot()
{
    QDir dir(QCoreApplication::applicationDirPath());

    // اصعد عدة مستويات وابحث عن السكربتات/قاعدة البيانات
    for (int i = 0; i < 8; ++i) {
        bool hasIngest = QFileInfo::exists(dir.filePath(INGEST_SCRIPT));
        bool hasBuild = QFileInfo::exists(dir.filePath(BUILD_SCRIPT));

        if (hasIngest && hasBuild) {
            return dir.absolutePath();
        }

        if (!dir.cdUp()) {
            break;
        }
    }

    // fallback: مكان تشغيل التطبيق
    return QCoreApplication::applicationDirPath();
}

static QString resolvePythonBinary()
{
    QDir root(findProjectRoot());

    QString venvPython = root.filePath(".venv/bin/python");
    if (QFileInfo::exists(venvPython)) {
        return venvPython;
    }

    return "python3";
}

static QString resolveDbPath()
{
    QDir root(findProjectRoot());
    return root.filePath(DB_PATH);
}

static QString resolveScriptPath(const QString &scriptName)
{
    QDir root(findProjectRoot());
    return root.filePath(scriptName);
}

SchedulerWindow::SchedulerWindow(QWidget *parent)
    : QMainWindow(parent),
      refreshTimer(nullptr),
      tabs(nullptr),
      summaryTab(nullptr),
      infoBox(nullptr),
      processTable(nullptr),
      cpuTable(nullptr),
      summaryRefreshButton(nullptr),
      timelineTab(nullptr),
      pidFilter(nullptr),
      cpuFilter(nullptr),
      timelineRefreshButton(nullptr),
      timelineTable(nullptr),
      timelineExplanationBox(nullptr),
      liveTab(nullptr),
      liveTable(nullptr),
      liveRefreshButton(nullptr),
      startCaptureButton(nullptr),
      stopCaptureButton(nullptr),
      rebuildButton(nullptr),
      statusLabel(nullptr),
      ingestorProcess(new QProcess(this)),
      builderProcess(new QProcess(this))
{
    connectionName = "scheduler_connection_" + QUuid::createUuid().toString();

    setupDatabase();
    setupUi();

    connect(ingestorProcess, &QProcess::started,
            this, &SchedulerWindow::onIngestorStarted);

    connect(ingestorProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this,
            &SchedulerWindow::onIngestorFinished);

    connect(builderProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this,
            &SchedulerWindow::onBuilderFinished);

    refreshTimer = new QTimer(this);
    connect(refreshTimer, &QTimer::timeout, this, &SchedulerWindow::updateLiveEvents);
    refreshTimer->start(1500);

    setWindowTitle("xv6 CPU Scheduler Explorer");
    resize(1200, 800);

    refreshAll();
}

SchedulerWindow::~SchedulerWindow() {
    if (refreshTimer) {
        refreshTimer->stop();
    }

    if (ingestorProcess && ingestorProcess->state() != QProcess::NotRunning) {
        ingestorProcess->terminate();
        ingestorProcess->waitForFinished(1500);
        if (ingestorProcess->state() != QProcess::NotRunning) {
            ingestorProcess->kill();
        }
    }

    if (builderProcess && builderProcess->state() != QProcess::NotRunning) {
        builderProcess->terminate();
        builderProcess->waitForFinished(1000);
        if (builderProcess->state() != QProcess::NotRunning) {
            builderProcess->kill();
        }
    }

    if (db.isOpen()) {
        db.close();
    }

    QSqlDatabase::removeDatabase(connectionName);
}

void SchedulerWindow::setupDatabase() {
    db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
    db.setDatabaseName(resolveDbPath());

    if (!db.open()) {
        showDbError("Opening scheduler database");
    }
}

void SchedulerWindow::setupUi() {
    QWidget *central = new QWidget(this);
    setCentralWidget(central);

    QVBoxLayout *mainLayout = new QVBoxLayout(central);

    QHBoxLayout *topBar = new QHBoxLayout();

    startCaptureButton = new QPushButton("Start Live Capture", this);
    stopCaptureButton = new QPushButton("Stop Live Capture", this);
    rebuildButton = new QPushButton("Rebuild Intervals", this);
    QPushButton *reloadAllButton = new QPushButton("Reload Database", this);

    startCaptureButton->setStyleSheet(
        "QPushButton { background-color: #27ae60; color: white; font-weight: bold; padding: 8px; border-radius: 8px; }"
        "QPushButton:hover { background-color: #1f8b4d; }"
    );

    stopCaptureButton->setStyleSheet(
        "QPushButton { background-color: #c0392b; color: white; font-weight: bold; padding: 8px; border-radius: 8px; }"
        "QPushButton:hover { background-color: #992d22; }"
    );

    rebuildButton->setStyleSheet(
        "QPushButton { background-color: #8e44ad; color: white; font-weight: bold; padding: 8px; border-radius: 8px; }"
        "QPushButton:hover { background-color: #6c3483; }"
    );

    reloadAllButton->setStyleSheet(
        "QPushButton { background-color: #3498db; color: white; font-weight: bold; padding: 8px; border-radius: 8px; }"
        "QPushButton:hover { background-color: #2980b9; }"
    );

    statusLabel = new QLabel("Ready", this);
    statusLabel->setStyleSheet("font-weight: bold; color: #2c3e50; padding-left: 8px;");

    topBar->addWidget(startCaptureButton);
    topBar->addWidget(stopCaptureButton);
    topBar->addWidget(rebuildButton);
    topBar->addWidget(reloadAllButton);
    topBar->addStretch();
    topBar->addWidget(statusLabel);

    connect(startCaptureButton, &QPushButton::clicked, this, &SchedulerWindow::startLiveCapture);
    connect(stopCaptureButton, &QPushButton::clicked, this, &SchedulerWindow::stopLiveCapture);
    connect(rebuildButton, &QPushButton::clicked, this, &SchedulerWindow::rebuildIntervals);
    connect(reloadAllButton, &QPushButton::clicked, this, &SchedulerWindow::refreshAll);

    tabs = new QTabWidget(this);

    setupSummaryTab();
    setupTimelineTab();
    setupLiveTab();

    tabs->addTab(summaryTab, "Summary");
    tabs->addTab(timelineTab, "Timeline");
    tabs->addTab(liveTab, "Live Events");

    mainLayout->addLayout(topBar);
    mainLayout->addWidget(tabs);
}

void SchedulerWindow::setupSummaryTab() {
    summaryTab = new QWidget(this);
    QVBoxLayout *layout = new QVBoxLayout(summaryTab);

    summaryRefreshButton = new QPushButton("Refresh Summary", this);
    connect(summaryRefreshButton, &QPushButton::clicked, this, &SchedulerWindow::refreshAll);

    infoBox = new QTextEdit(this);
    infoBox->setReadOnly(true);
    infoBox->setMinimumHeight(170);

    processTable = new QTableWidget(this);
    processTable->setColumnCount(4);
    processTable->setHorizontalHeaderLabels({"PID", "Runs", "Total Runtime", "Avg Slice"});
    processTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
    processTable->setAlternatingRowColors(true);
    processTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    processTable->setSelectionBehavior(QAbstractItemView::SelectRows);

    cpuTable = new QTableWidget(this);
    cpuTable->setColumnCount(4);
    cpuTable->setHorizontalHeaderLabels({"CPU", "Slices", "Busy Time", "Avg Duration"});
    cpuTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
    cpuTable->setAlternatingRowColors(true);
    cpuTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    cpuTable->setSelectionBehavior(QAbstractItemView::SelectRows);

    QLabel *procLabel = new QLabel("Process Summary", this);
    procLabel->setStyleSheet("font-weight: bold; font-size: 14px;");
    QLabel *cpuLabel = new QLabel("CPU Summary", this);
    cpuLabel->setStyleSheet("font-weight: bold; font-size: 14px;");

    layout->addWidget(summaryRefreshButton);
    layout->addWidget(infoBox);
    layout->addWidget(procLabel);
    layout->addWidget(processTable, 1);
    layout->addWidget(cpuLabel);
    layout->addWidget(cpuTable, 1);
}

void SchedulerWindow::setupTimelineTab() {
    timelineTab = new QWidget(this);
    QVBoxLayout *layout = new QVBoxLayout(timelineTab);

    QGroupBox *filtersBox = new QGroupBox("Filters", this);
    QFormLayout *filtersLayout = new QFormLayout(filtersBox);

    pidFilter = new QComboBox(this);
    cpuFilter = new QComboBox(this);

    timelineRefreshButton = new QPushButton("Refresh Timeline", this);
    connect(timelineRefreshButton, &QPushButton::clicked, this, &SchedulerWindow::loadTimeline);

    filtersLayout->addRow("PID", pidFilter);
    filtersLayout->addRow("CPU", cpuFilter);
    filtersLayout->addRow(timelineRefreshButton);

    timelineTable = new QTableWidget(this);
    timelineTable->setColumnCount(9);
    timelineTable->setHorizontalHeaderLabels({
        "PID", "CPU", "Seq Start", "Seq End",
        "Tick Start", "Tick End", "Duration",
        "Off Reason", "Closed Implicitly"
    });
    timelineTable->horizontalHeader()->setSectionResizeMode(QHeaderView::ResizeToContents);
    timelineTable->horizontalHeader()->setStretchLastSection(true);
    timelineTable->setAlternatingRowColors(true);
    timelineTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    timelineTable->setSelectionBehavior(QAbstractItemView::SelectRows);

    connect(timelineTable, &QTableWidget::itemSelectionChanged,
            this, &SchedulerWindow::explainSelectedTimelineRow);

    timelineExplanationBox = new QTextEdit(this);
    timelineExplanationBox->setReadOnly(true);
    timelineExplanationBox->setMinimumHeight(170);

    layout->addWidget(filtersBox);
    layout->addWidget(timelineTable, 1);
    layout->addWidget(timelineExplanationBox);
}

void SchedulerWindow::setupLiveTab() {
    liveTab = new QWidget(this);
    QVBoxLayout *layout = new QVBoxLayout(liveTab);

    liveRefreshButton = new QPushButton("Refresh Live Events", this);
    connect(liveRefreshButton, &QPushButton::clicked, this, &SchedulerWindow::updateLiveEvents);

    liveTable = new QTableWidget(this);
    liveTable->setColumnCount(8);
    liveTable->setHorizontalHeaderLabels({
        "Seq", "Tick", "CPU", "PID", "Name", "State", "Type", "Reason"
    });
    liveTable->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
    liveTable->setAlternatingRowColors(true);
    liveTable->setEditTriggers(QAbstractItemView::NoEditTriggers);
    liveTable->setSelectionBehavior(QAbstractItemView::SelectRows);

    layout->addWidget(liveRefreshButton);
    layout->addWidget(liveTable);
}

bool SchedulerWindow::tableExists(const QString &tableName) {
    if (!db.isOpen() && !db.open()) {
        return false;
    }

    return db.tables().contains(tableName);
}

bool SchedulerWindow::hasAnyEvents() {
    if (!tableExists("events")) {
        return false;
    }

    QSqlQuery query(db);
    query.prepare("SELECT COUNT(*) FROM events");

    if (!query.exec()) {
        return false;
    }

    if (query.next()) {
        return query.value(0).toInt() > 0;
    }

    return false;
}

void SchedulerWindow::refreshAll() {
    if (!db.isOpen() && !db.open()) {
        showDbError("Re-opening database");
        return;
    }

    if (!tableExists("events")) {
        infoBox->setHtml(
            "<h3 style='color:#c0392b;'>No scheduler data yet</h3>"
            "The database exists, but the <code>events</code> table was not found.<br><br>"
            "Use <b>Start Live Capture</b> first to create the schema and collect trace events."
        );

        processTable->setRowCount(0);
        cpuTable->setRowCount(0);
        timelineTable->setRowCount(0);
        liveTable->setRowCount(0);
        timelineExplanationBox->setPlainText("No trace data available yet.");

        pidFilter->clear();
        cpuFilter->clear();
        pidFilter->addItem("All PIDs", QVariant());
        cpuFilter->addItem("All CPUs", QVariant());

        updateStatusLabel("No events table yet - start live capture first", "#c0392b");
        return;
    }

    if (!hasAnyEvents()) {
        infoBox->setHtml(
            "<h3 style='color:#d35400;'>Database is ready but empty</h3>"
            "The <code>events</code> table exists, but there are no scheduler events yet.<br><br>"
            "Start live capture, then stop it to rebuild intervals automatically."
        );

        processTable->setRowCount(0);
        cpuTable->setRowCount(0);
        timelineTable->setRowCount(0);
        liveTable->setRowCount(0);
        timelineExplanationBox->setPlainText("No events recorded yet.");

        pidFilter->clear();
        cpuFilter->clear();
        pidFilter->addItem("All PIDs", QVariant());
        cpuFilter->addItem("All CPUs", QVariant());

        updateStatusLabel("Database empty - waiting for live capture", "#d35400");
        return;
    }

    loadSchedulerInfo();
    loadProcessSummary();
    loadCpuSummary();
    loadFilters();
    loadTimeline();
    updateLiveEvents();

    updateStatusLabel("Scheduler data loaded", "#27ae60");
}

void SchedulerWindow::loadSchedulerInfo() {
    infoBox->clear();

    QSqlQuery query(db);
    query.prepare(R"(
        SELECT
            scheduler,
            cpus,
            time_slice,
            MIN(seq) AS first_seq,
            MAX(seq) AS last_seq
        FROM events
        WHERE type = 'SCHED_INFO'
        GROUP BY scheduler, cpus, time_slice
        ORDER BY first_seq ASC
        LIMIT 1
    )");

    if (!query.exec()) {
        showDbError("Loading scheduler info");
        return;
    }

    if (query.next()) {
        const QString scheduler = query.value("scheduler").toString();
        const int cpus = query.value("cpus").toInt();
        const int timeSlice = query.value("time_slice").toInt();
        const int firstSeq = query.value("first_seq").toInt();
        const int lastSeq = query.value("last_seq").toInt();

        QString text;
        text += "<h3 style='color:#2c3e50;'>Scheduler Overview</h3>";
        text += QString("<b>Scheduler:</b> %1<br>").arg(scheduler);
        text += QString("<b>CPU count:</b> %1<br>").arg(cpus);
        text += QString("<b>Time slice:</b> %1<br>").arg(timeSlice);

        if (firstSeq == lastSeq) {
            text += QString("<b>SCHED_INFO at seq:</b> %1<br><br>").arg(firstSeq);
        } else {
            text += QString("<b>SCHED_INFO seq range:</b> %1 → %2<br><br>").arg(firstSeq).arg(lastSeq);
        }

        text += "This view explains the scheduler using real xv6 trace data loaded from the database.";

        infoBox->setHtml(text);
    } else {
        infoBox->setPlainText("No SCHED_INFO row found in events table.");
    }
}

void SchedulerWindow::loadProcessSummary() {
    processTable->setRowCount(0);

    QSqlQuery query(db);
    query.prepare(R"(
        SELECT
            pid,
            COUNT(*) AS runs,
            COALESCE(SUM(duration), 0) AS total_runtime,
            ROUND(AVG(duration), 2) AS avg_slice
        FROM sched_intervals
        GROUP BY pid
        ORDER BY total_runtime DESC, runs DESC, pid ASC
    )");

    if (!query.exec()) {
        processTable->setRowCount(0);
        return;
    }

    int row = 0;
    while (query.next()) {
        processTable->insertRow(row);
        processTable->setItem(row, 0, new QTableWidgetItem(query.value("pid").toString()));
        processTable->setItem(row, 1, new QTableWidgetItem(query.value("runs").toString()));
        processTable->setItem(row, 2, new QTableWidgetItem(query.value("total_runtime").toString()));
        processTable->setItem(row, 3, new QTableWidgetItem(query.value("avg_slice").toString()));
        row++;
    }
}

void SchedulerWindow::loadCpuSummary() {
    cpuTable->setRowCount(0);

    QSqlQuery query(db);
    query.prepare(R"(
        SELECT
            cpu,
            COUNT(*) AS slices,
            COALESCE(SUM(duration), 0) AS busy_time,
            ROUND(AVG(duration), 2) AS avg_duration
        FROM sched_intervals
        GROUP BY cpu
        ORDER BY cpu
    )");

    if (!query.exec()) {
        cpuTable->setRowCount(0);
        return;
    }

    int row = 0;
    while (query.next()) {
        cpuTable->insertRow(row);
        cpuTable->setItem(row, 0, new QTableWidgetItem(query.value("cpu").toString()));
        cpuTable->setItem(row, 1, new QTableWidgetItem(query.value("slices").toString()));
        cpuTable->setItem(row, 2, new QTableWidgetItem(query.value("busy_time").toString()));
        cpuTable->setItem(row, 3, new QTableWidgetItem(query.value("avg_duration").toString()));
        row++;
    }
}

void SchedulerWindow::loadFilters() {
    QVariant currentPid = pidFilter->currentData();
    QVariant currentCpu = cpuFilter->currentData();

    pidFilter->blockSignals(true);
    cpuFilter->blockSignals(true);

    pidFilter->clear();
    cpuFilter->clear();

    pidFilter->addItem("All PIDs", QVariant());
    cpuFilter->addItem("All CPUs", QVariant());

    QSqlQuery pidQuery(db);
    pidQuery.prepare(R"(
        SELECT DISTINCT pid
        FROM sched_intervals
        WHERE pid IS NOT NULL
        ORDER BY pid
    )");

    if (pidQuery.exec()) {
        while (pidQuery.next()) {
            int pid = pidQuery.value(0).toInt();
            pidFilter->addItem(QString::number(pid), pid);
        }
    }

    QSqlQuery cpuQuery(db);
    cpuQuery.prepare(R"(
        SELECT DISTINCT cpu
        FROM sched_intervals
        WHERE cpu IS NOT NULL
        ORDER BY cpu
    )");

    if (cpuQuery.exec()) {
        while (cpuQuery.next()) {
            int cpu = cpuQuery.value(0).toInt();
            cpuFilter->addItem(QString::number(cpu), cpu);
        }
    }

    int pidIndex = pidFilter->findData(currentPid);
    int cpuIndex = cpuFilter->findData(currentCpu);

    if (pidIndex >= 0) pidFilter->setCurrentIndex(pidIndex);
    if (cpuIndex >= 0) cpuFilter->setCurrentIndex(cpuIndex);

    pidFilter->blockSignals(false);
    cpuFilter->blockSignals(false);
}

void SchedulerWindow::loadTimeline() {
    timelineTable->setRowCount(0);
    timelineExplanationBox->setPlainText("Select a row to see an explanation.");

    QString sql = R"(
        SELECT
            pid,
            cpu,
            seq_start,
            seq_end,
            tick_start,
            tick_end,
            duration,
            off_reason,
            closed_implicitly
        FROM sched_intervals
    )";

    QStringList clauses;
    QList<QVariant> bindValues;

    if (pidFilter->currentData().isValid()) {
        clauses << "pid = ?";
        bindValues << pidFilter->currentData();
    }

    if (cpuFilter->currentData().isValid()) {
        clauses << "cpu = ?";
        bindValues << cpuFilter->currentData();
    }

    if (!clauses.isEmpty()) {
        sql += " WHERE " + clauses.join(" AND ");
    }

    sql += " ORDER BY seq_start LIMIT 300";

    QSqlQuery query(db);
    query.prepare(sql);

    for (const QVariant &v : bindValues) {
        query.addBindValue(v);
    }

    if (!query.exec()) {
        timelineTable->setRowCount(0);
        return;
    }

    int row = 0;
    while (query.next()) {
        timelineTable->insertRow(row);

        QString pidText = query.value("pid").toString();
        QString cpuText = query.value("cpu").toString();
        QString seqStartText = query.value("seq_start").toString();
        QString seqEndText = query.value("seq_end").toString();
        QString tickStartText = query.value("tick_start").toString();
        QString tickEndText = query.value("tick_end").toString();
        QString durationText = query.value("duration").toString();
        QString offReasonText = offReasonToString(query.value("off_reason"));
        QString closedText = query.value("closed_implicitly").toString();

        timelineTable->setItem(row, 0, new QTableWidgetItem(pidText));
        timelineTable->setItem(row, 1, new QTableWidgetItem(cpuText));
        timelineTable->setItem(row, 2, new QTableWidgetItem(seqStartText));
        timelineTable->setItem(row, 3, new QTableWidgetItem(seqEndText));
        timelineTable->setItem(row, 4, new QTableWidgetItem(tickStartText));
        timelineTable->setItem(row, 5, new QTableWidgetItem(tickEndText));
        timelineTable->setItem(row, 6, new QTableWidgetItem(durationText));
        timelineTable->setItem(row, 7, new QTableWidgetItem(offReasonText));
        timelineTable->setItem(row, 8, new QTableWidgetItem(closedText));

        int duration = query.value("duration").toInt();
        int closedImplicitly = query.value("closed_implicitly").toInt();

        for (int c = 0; c < timelineTable->columnCount(); ++c) {
            QTableWidgetItem *item = timelineTable->item(row, c);
            if (!item) continue;

            if (duration > 0) {
                item->setBackground(QColor(223, 240, 216));
            }
            if (closedImplicitly == 1) {
                item->setBackground(QColor(252, 248, 227));
            }
        }

        row++;
    }
}

void SchedulerWindow::updateLiveEvents() {
    if (!db.isOpen() && !db.open()) {
        return;
    }

    if (!tableExists("events")) {
        liveTable->setRowCount(0);
        return;
    }

    liveTable->setRowCount(0);

    QSqlQuery query(db);
    query.prepare(R"(
        SELECT seq, tick, cpu, pid, name, state, type, reason
        FROM events
        ORDER BY id DESC
        LIMIT 50
    )");

    if (!query.exec()) {
        return;
    }

    int row = 0;
    while (query.next()) {
        liveTable->insertRow(row);

        QString seq = query.value("seq").toString();
        QString tick = query.value("tick").toString();
        QString cpu = query.value("cpu").toString();
        QString pid = query.value("pid").toString();
        QString name = query.value("name").toString();
        int state = query.value("state").toInt();
        QString type = query.value("type").toString();
        QString reason = query.value("reason").toString();

        liveTable->setItem(row, 0, new QTableWidgetItem(seq));
        liveTable->setItem(row, 1, new QTableWidgetItem(tick));
        liveTable->setItem(row, 2, new QTableWidgetItem(cpu));
        liveTable->setItem(row, 3, new QTableWidgetItem(pid));
        liveTable->setItem(row, 4, new QTableWidgetItem(name));
        liveTable->setItem(row, 5, new QTableWidgetItem(stateToString(state)));
        liveTable->setItem(row, 6, new QTableWidgetItem(type));
        liveTable->setItem(row, 7, new QTableWidgetItem(reason));

        QTableWidgetItem *stateItem = liveTable->item(row, 5);
        if (stateItem) {
            if (stateToString(state) == "RUNNING") {
                stateItem->setBackground(QColor(46, 204, 113));
            } else if (stateToString(state) == "SLEEPING") {
                stateItem->setBackground(QColor(241, 196, 15));
            } else if (stateToString(state) == "RUNNABLE") {
                stateItem->setBackground(QColor(52, 152, 219));
            }
        }

        row++;
    }
}

void SchedulerWindow::explainSelectedTimelineRow() {
    QList<QTableWidgetItem*> items = timelineTable->selectedItems();
    if (items.isEmpty()) {
        return;
    }

    int row = items.first()->row();

    QString pid = timelineTable->item(row, 0) ? timelineTable->item(row, 0)->text() : "";
    QString cpu = timelineTable->item(row, 1) ? timelineTable->item(row, 1)->text() : "";
    QString seqStart = timelineTable->item(row, 2) ? timelineTable->item(row, 2)->text() : "";
    QString seqEnd = timelineTable->item(row, 3) ? timelineTable->item(row, 3)->text() : "";
    QString tickStart = timelineTable->item(row, 4) ? timelineTable->item(row, 4)->text() : "";
    QString tickEnd = timelineTable->item(row, 5) ? timelineTable->item(row, 5)->text() : "";
    QString duration = timelineTable->item(row, 6) ? timelineTable->item(row, 6)->text() : "";
    QString offReason = timelineTable->item(row, 7) ? timelineTable->item(row, 7)->text() : "";
    QString closedImplicitly = timelineTable->item(row, 8) ? timelineTable->item(row, 8)->text() : "";

    QSqlQuery query(db);
    query.prepare(R"(
        SELECT
            COUNT(*) AS run_count,
            COALESCE(SUM(duration), 0) AS total_runtime,
            ROUND(AVG(duration), 2) AS avg_run,
            MIN(seq_start) AS first_seq,
            MAX(seq_end) AS last_seq
        FROM sched_intervals
        WHERE pid = ?
        GROUP BY pid
    )");
    query.addBindValue(pid);

    QString explanation;
    explanation += QString("PID %1 ran on CPU %2 from seq %3 to seq %4.\n").arg(pid, cpu, seqStart, seqEnd);
    explanation += QString("Tick range: %1 -> %2\n").arg(tickStart, tickEnd);
    explanation += QString("Duration: %1\n").arg(duration);
    explanation += QString("Off reason: %1\n").arg(offReason);
    explanation += QString("Closed implicitly: %1\n\n").arg(closedImplicitly);

    if (query.exec() && query.next()) {
        explanation += QString("Overall for PID %1:\n").arg(pid);
        explanation += QString("- run count: %1\n").arg(query.value("run_count").toString());
        explanation += QString("- total runtime: %1\n").arg(query.value("total_runtime").toString());
        explanation += QString("- average run: %1\n").arg(query.value("avg_run").toString());
        explanation += QString("- first seq: %1\n").arg(query.value("first_seq").toString());
        explanation += QString("- last seq: %1\n\n").arg(query.value("last_seq").toString());
    }

    explanation += "Interpretation:\n";
    if (offReason.contains("Sleep", Qt::CaseInsensitive)) {
        explanation += "- The process likely blocked and went to sleep.\n";
    } else if (offReason.contains("Preempt", Qt::CaseInsensitive)) {
        explanation += "- The process likely left the CPU due to preemption or yielding.\n";
    } else if (offReason.contains("Unknown", Qt::CaseInsensitive)) {
        explanation += "- The exact reason was not fully inferred from the trace.\n";
    } else {
        explanation += "- This interval was reconstructed from ON_CPU/OFF_CPU events.\n";
    }

    timelineExplanationBox->setPlainText(explanation);
}

void SchedulerWindow::startLiveCapture() {
    if (ingestorProcess->state() != QProcess::NotRunning) {
        updateStatusLabel("Live capture is already running", "#d35400");
        return;
    }

    QString projectRoot = findProjectRoot();
    QString pythonBin = resolvePythonBinary();
    QString scriptPath = resolveScriptPath(INGEST_SCRIPT);

    ingestorProcess->setWorkingDirectory(projectRoot);
    ingestorProcess->start(pythonBin, QStringList() << scriptPath);

    if (!ingestorProcess->waitForStarted(1200)) {
        QString err = ingestorProcess->errorString();

        updateStatusLabel("Failed to start live capture", "#c0392b");
        QMessageBox::warning(
            this,
            "Start Live Capture",
            "Could not start ingest_from_stream.py\n\n"
            "Project root: " + projectRoot + "\n"
            "Python: " + pythonBin + "\n"
            "Script: " + scriptPath + "\n"
            "Error: " + err
        );
        return;
    }
}

void SchedulerWindow::stopLiveCapture() {
    if (ingestorProcess->state() == QProcess::NotRunning) {
        updateStatusLabel("Live capture is not running", "#7f8c8d");
        return;
    }

    ingestorProcess->terminate();
    if (!ingestorProcess->waitForFinished(1500)) {
        ingestorProcess->kill();
        ingestorProcess->waitForFinished(1000);
    }

    updateStatusLabel("Live capture stopped", "#c0392b");
    rebuildIntervals();
}

void SchedulerWindow::rebuildIntervals() {
    if (!tableExists("events")) {
        updateStatusLabel("Cannot rebuild: events table does not exist yet", "#c0392b");
        QMessageBox::information(this,
                                 "Rebuild Intervals",
                                 "Cannot rebuild intervals yet.\n\n"
                                 "The events table does not exist.\n"
                                 "Start Live Capture first so the schema and trace data are created.");
        return;
    }

    if (!hasAnyEvents()) {
        updateStatusLabel("Cannot rebuild: no events recorded yet", "#d35400");
        QMessageBox::information(this,
                                 "Rebuild Intervals",
                                 "Cannot rebuild intervals yet.\n\n"
                                 "The events table exists, but it is empty.\n"
                                 "Start Live Capture first and let some events be recorded.");
        return;
    }

    if (builderProcess->state() != QProcess::NotRunning) {
        updateStatusLabel("Rebuild already running...", "#8e44ad");
        return;
    }

    QString projectRoot = findProjectRoot();
    QString pythonBin = resolvePythonBinary();
    QString scriptPath = resolveScriptPath(BUILD_SCRIPT);

    updateStatusLabel("Rebuilding intervals...", "#8e44ad");

    builderProcess->setWorkingDirectory(projectRoot);
    builderProcess->start(pythonBin, QStringList() << scriptPath);

    if (!builderProcess->waitForStarted(1200)) {
        updateStatusLabel("Failed to start build_intervals.py", "#c0392b");
        QMessageBox::warning(
            this,
            "Rebuild Intervals",
            "Could not start build_intervals.py\n\n"
            "Project root: " + projectRoot + "\n"
            "Python: " + pythonBin + "\n"
            "Script: " + scriptPath + "\n"
            "Error: " + builderProcess->errorString()
        );
    }
}

void SchedulerWindow::onIngestorStarted() {
    updateStatusLabel("Live capture running", "#27ae60");
}

void SchedulerWindow::onIngestorFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    Q_UNUSED(exitStatus);

    QString stderrText = ingestorProcess->readAllStandardError();
    QString stdoutText = ingestorProcess->readAllStandardOutput();

    if (exitCode == 0) {
        updateStatusLabel("Live capture finished", "#2c3e50");
    } else {
        updateStatusLabel("Live capture stopped with error", "#c0392b");

        QMessageBox::warning(this,
                             "Live Capture",
                             "ingest_from_stream.py failed.\n\nSTDOUT:\n" + stdoutText +
                             "\n\nSTDERR:\n" + stderrText);
    }

    rebuildIntervals();
}

void SchedulerWindow::onBuilderFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    Q_UNUSED(exitStatus);

    if (exitCode == 0) {
        updateStatusLabel("Intervals rebuilt successfully", "#27ae60");
        refreshAll();
    } else {
        updateStatusLabel("build_intervals.py failed", "#c0392b");

        QString stderrText = builderProcess->readAllStandardError();
        QString stdoutText = builderProcess->readAllStandardOutput();

        QMessageBox::warning(this,
                             "Rebuild Intervals",
                             "build_intervals.py failed.\n\nSTDOUT:\n" + stdoutText +
                             "\n\nSTDERR:\n" + stderrText);
    }
}

QString SchedulerWindow::stateToString(int state) const {
    switch (state) {
    case 0: return "UNUSED";
    case 1: return "USED";
    case 2: return "SLEEPING";
    case 3: return "RUNNABLE";
    case 4: return "RUNNING";
    case 5: return "ZOMBIE";
    default: return "UNKNOWN";
    }
}

QString SchedulerWindow::offReasonToString(const QVariant &reasonVar) const {
    if (!reasonVar.isValid() || reasonVar.isNull()) {
        return "Unknown";
    }

    int reason = reasonVar.toInt();
    switch (reason) {
    case 2: return "Preempt / Yield";
    case 3: return "Sleep / Block";
    default: return QString("Reason %1").arg(reason);
    }
}

void SchedulerWindow::showDbError(const QString &context) {
    QMessageBox::warning(this,
                         "Database Error",
                         context + "\n\n" + db.lastError().text());
}

void SchedulerWindow::updateStatusLabel(const QString &text, const QString &color) {
    statusLabel->setText(text);
    statusLabel->setStyleSheet(QString("font-weight: bold; color: %1; padding-left: 8px;").arg(color));
}