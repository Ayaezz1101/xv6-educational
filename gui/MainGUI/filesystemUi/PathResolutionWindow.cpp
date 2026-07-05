#include "PathResolutionWindow.h"

#include <QHeaderView>
#include <QSqlDatabase>
#include <QSqlRecord>
#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>

#include <QLabel>
#include <QLineEdit>
#include <QComboBox>
#include <QPushButton>

#include <QTreeWidgetItem>
#include <QAbstractItemView>
#include <QColor>
#include <QMap>
#include <QLayoutItem>

#include <QTimer>
#include <QScrollArea>
#include <QTableWidget>
#include <functional>

PathResolutionWindow::PathResolutionWindow(QWidget *parent)
    : QMainWindow(parent),
      currentPid(-1)
{
    setWindowTitle("Path Resolution & File Operations");
    setStyleSheet("QMainWindow { background-color: #0d1117; }");

    setupUi();

    updateTimer = new QTimer(this);

    connect(updateTimer,
            &QTimer::timeout,
            this,
            &PathResolutionWindow::refreshData);

    updateTimer->start(1000);
}

static QString cardStyleSheet()
{
    return R"(
        QFrame {
            background-color: #161b22;
            border: 1px solid #30363d;
            border-radius: 14px;
        }

        QLabel {
            color: #c9d1d9;
        }
    )";
}

static QLabel *createCardTitle(const QString &text)
{
    auto *label = new QLabel(text);

    label->setStyleSheet(
        "color: #8b949e;"
        "font-weight: 700;"
        "font-size: 12px;"
    );

    return label;
}

static QLabel *createCardValue(const QString &text,
                               const QString &color = "#c9d1d9")
{
    auto *label = new QLabel(text);

    label->setStyleSheet(QString(
        "font-size: 18px;"
        "font-weight: 700;"
        "color: %1;"
    ).arg(color));

    return label;
}

void PathResolutionWindow::setupUi()
{
    auto *centralWidget = new QWidget(this);

    auto *mainLayout = new QVBoxLayout(centralWidget);

    mainLayout->setContentsMargins(16,16,16,16);
    mainLayout->setSpacing(16);

    auto *title =
        new QLabel("PATH RESOLUTION & FILE OPERATIONS");

    title->setStyleSheet(
        "color: #c9d1d9;"
        "font-size: 24px;"
        "font-weight: bold;"
    );

    mainLayout->addWidget(title);

    // Create a grid that will hold the main cards similar to the reference
    // design: two columns with multiple stacked cards.
    auto *grid = new QGridLayout();
    grid->setSpacing(12);
    grid->setColumnStretch(0, 1);
    grid->setColumnStretch(1, 2);

    auto *scrollArea = new QScrollArea();

    scrollArea->setWidgetResizable(true);

    auto *scrollWidget = new QWidget();

    auto *scrollLayout =
        new QVBoxLayout(scrollWidget);

    scrollLayout->setSpacing(16);

    // Place cards into the grid: left column = process + directory tree,
    // right column = path visualizer + fd table. Timeline spans both columns.
    setupProcessInfoCard(grid);             // (0,0)
    setupPathVisualizerCard(grid);          // (0,1)
    setupDirectoryTreeCard(grid);           // (1,0)
    setupFileDescriptorTableCard(grid);     // (1,1)
    setupTimelineCard(grid);                // (2,0..1)
    setupRecentNamespaceEventsCard(grid);   // (3,0..1)

    // Add the grid into the scroll layout so it scrolls as a whole.
    scrollLayout->addLayout(grid);

    scrollArea->setWidget(scrollWidget);

    mainLayout->addWidget(scrollArea);

    setCentralWidget(centralWidget);

    // Defer selecting the first PID until the event loop runs to avoid
    // reentrancy/initialization-order issues that can crash QLabel::setText.
    QTimer::singleShot(0, this, [this]() {
        if (pidComboBox && pidComboBox->count() > 0) {
            int idx = pidComboBox->currentIndex();
            if (idx < 0) idx = 0;
            onProcessSelected(idx);
        }
    });
}

static void clearLayout(QLayout *layout)
{
    if (!layout)
        return;

    while (QLayoutItem *item = layout->takeAt(0))
    {
        if (item->widget())
            delete item->widget();

        if (item->layout())
            clearLayout(item->layout());

        delete item;
    }
}

void PathResolutionWindow::refreshData()
{
    if (currentPid < 0)
        return;

    refreshPathVisualizer();
    refreshDirectoryTree();
    refreshFileDescriptorTable();
    refreshTimeline();
    refreshRecentNamespaceEvents();
}

void PathResolutionWindow::refreshPathVisualizer()
{
    auto *layout =
        qobject_cast<QVBoxLayout*>(
            pathVisualizerContainer->layout());

    clearLayout(layout);

    QSqlQuery q;

    q.prepare(R"SQL(
        SELECT
            op_name,
            elem,
            target_inum,
            path,
            syscall,
            tick,
            details
        FROM fs_events
        WHERE layer = 'PATH'
          AND pid = ?
        ORDER BY tick DESC
        LIMIT 10
    )SQL");

    q.addBindValue(currentPid);

    if (!q.exec())
    {
        qDebug() << "Path query failed:"
                 << q.lastError().text();
        return;
    }

    bool found = false;

    while (q.next())
    {
        found = true;

        QString elem =
            q.value("elem").toString();

        int inode =
            q.value("target_inum").toInt();

        QString details =
            q.value("details").toString();

        auto *frame = new QFrame();

        frame->setStyleSheet(R"(
            QFrame {
                background-color: #0d1117;
                border: 1px solid #30363d;
                border-radius: 6px;
                padding: 8px;
            }
        )");

        auto *h = new QHBoxLayout(frame);

        auto *elemLabel =
            new QLabel(elem.isEmpty() ? "/" : elem);

        elemLabel->setStyleSheet(
            "color:#58a6ff;"
            "font-weight:bold;"
            "min-width:120px;"
        );

        auto *inodeLabel =
            new QLabel(QString("inode: %1").arg(inode));

        inodeLabel->setStyleSheet(
            "color:#6f42c1;"
        );

        QString type =
            details.contains("directory",
                             Qt::CaseInsensitive)
                ? "📁 DIR"
                : "📄 FILE";

        auto *typeLabel = new QLabel(type);

        typeLabel->setStyleSheet(
            "color:#8b949e;"
        );

        QString result =
            details.contains("SUCCESS",
                             Qt::CaseInsensitive)
                ? "✅ OK"
                : "❌ FAIL";

        auto *resultLabel =
            new QLabel(result);

        resultLabel->setStyleSheet(
            "color:#238636;"
            "font-weight:bold;"
        );

        h->addWidget(elemLabel);
        h->addWidget(inodeLabel);
        h->addWidget(typeLabel);
        h->addWidget(resultLabel);
        h->addStretch();

        layout->addWidget(frame);
    }

    if (!found)
    {
        auto *label =
            new QLabel("No path resolution events");

        label->setStyleSheet(
            "color:#8b949e;"
            "font-style:italic;"
        );

        layout->addWidget(label);
    }
}

void PathResolutionWindow::refreshTimeline()
{
    clearLayout(timelineContentLayout);

    QSqlQuery q;

    q.prepare(R"SQL(
        SELECT
            tick,
            op_name,
            layer,
            details,
            syscall
        FROM fs_events
        WHERE pid = ?
          AND layer IN ('PATH','DIR','FILE')
        ORDER BY tick DESC
        LIMIT 50
    )SQL");

    q.addBindValue(currentPid);

    if (!q.exec())
    {
        qDebug() << "Timeline query failed:"
                 << q.lastError().text();
        return;
    }

    bool found = false;

    while (q.next())
    {
        found = true;

        uint tick =
            q.value("tick").toUInt();

        QString op =
            q.value("op_name").toString();

        QString layer =
            q.value("layer").toString();

        QString details =
            q.value("details").toString();

        QString syscall =
            q.value("syscall").toString();

        QString color = "#58a6ff";

        if (layer == "DIR")
            color = "#6f42c1";
        else if (layer == "FILE")
            color = "#238636";

        auto *label = new QLabel();

        label->setWordWrap(true);

        label->setText(QString(
            "[t=%1] %2 (%3) → %4 | %5"
        )
        .arg(tick)
        .arg(op)
        .arg(layer)
        .arg(details)
        .arg(syscall));

        label->setStyleSheet(QString(R"(
            QLabel {
                color: %1;
                padding: 8px;
                background-color: #0d1117;
                border: 1px solid #30363d;
                border-radius: 6px;
            }
        )").arg(color));

        timelineContentLayout->addWidget(label);
    }

    if (!found)
    {
        auto *label =
            new QLabel("No timeline events");

        label->setStyleSheet(
            "color:#8b949e;"
            "font-style:italic;"
        );

        timelineContentLayout->addWidget(label);
    }

    timelineContentLayout->addStretch();
}

void PathResolutionWindow::refreshRecentNamespaceEvents()
{
    namespaceEventsTable->setRowCount(0);

    QSqlQuery q;

    if (!q.exec(R"SQL(
        SELECT
            pid,
            op_name,
            layer,
            tick,
            name,
            details
        FROM fs_events
        WHERE layer IN ('DIR','PATH','FILE')
        ORDER BY tick DESC
        LIMIT 50
    )SQL"))
    {
        qDebug() << "Namespace query failed:"
                 << q.lastError().text();

        return;
    }

    int row = 0;

    while (q.next())
    {
        namespaceEventsTable->insertRow(row);

        for (int col = 0; col < 6; ++col)
        {
            auto *item =
                new QTableWidgetItem(
                    q.value(col).toString());

            item->setForeground(
                QColor("#c9d1d9"));

            namespaceEventsTable
                ->setItem(row, col, item);
        }

        row++;
    }
}
void PathResolutionWindow::onProcessSelected(int index)
{
    currentPid =
        pidComboBox->itemData(index).toInt();

    lblPid->setText(
        QString("PID: %1").arg(currentPid));

    QString request =
        getProcessRequestPath(currentPid);

    lblRequest->setText(
        QString("Request: %1")
            .arg(request.isEmpty() ? "-" : request));

    QString cwd =
        getProcessWorkingDir(currentPid);

    lblWorkingDir->setText(
        QString("Working Dir: %1")
            .arg(cwd.isEmpty() ? "/" : cwd));

    lblOpenFds->setText(
        QString("Open FDs: %1")
            .arg(getOpenFileCount(currentPid)));

    refreshData();
}

void PathResolutionWindow::onTimelineEventClicked(int)
{
}

QString PathResolutionWindow::getProcessRequestPath(int pid)
{
    QSqlQuery q;

    q.prepare(R"SQL(
        SELECT path
        FROM fs_events
        WHERE layer='PATH'
          AND pid=?
        ORDER BY tick DESC
        LIMIT 1
    )SQL");

    q.addBindValue(pid);

    if (q.exec() && q.next())
        return q.value(0).toString();

    return "";
}

QString PathResolutionWindow::getProcessWorkingDir(int pid)
{
    QSqlQuery q;

    q.prepare(R"SQL(
        SELECT cwd
        FROM fs_events
        WHERE layer='PATH'
          AND pid=?
        ORDER BY tick DESC
        LIMIT 1
    )SQL");

    q.addBindValue(pid);

    if (q.exec() && q.next())
        return q.value(0).toString();

    return "/";
}

int PathResolutionWindow::getOpenFileCount(int pid)
{
    QSqlQuery q;

    q.prepare(R"SQL(
        SELECT COUNT(*)
        FROM state
        WHERE pid=?
    )SQL");

    q.addBindValue(pid);

    if (q.exec() && q.next())
        return q.value(0).toInt();

    return 0;
}
void PathResolutionWindow::setupProcessInfoCard(QGridLayout *layout)
{
    auto *card = new QFrame();

    card->setStyleSheet(cardStyleSheet());

    auto *v = new QVBoxLayout(card);

    v->addWidget(createCardTitle("PROCESS INFO"));

    pidComboBox = new QComboBox();

    pidComboBox->setStyleSheet(R"(
        QComboBox {
            background:#0d1117;
            color:#c9d1d9;
            border:1px solid #30363d;
            border-radius:6px;
            padding:5px;
        }
    )");

    QSqlQuery q;

    q.exec("SELECT DISTINCT pid FROM fs_events ORDER BY pid");

    while (q.next())
    {
        int pid = q.value(0).toInt();

        pidComboBox->addItem(
            QString::number(pid),
            pid);
    }

    connect(pidComboBox,
            QOverload<int>::of(&QComboBox::currentIndexChanged),
            this,
            &PathResolutionWindow::onProcessSelected);

    lblPid = createCardValue("PID: -", "#58a6ff");

    lblRequest = new QLabel("Request: -");

    lblWorkingDir =
        new QLabel("Working Dir: /");

    lblOpenFds =
        createCardValue("Open FDs: 0",
                         "#6f42c1");

    v->addWidget(pidComboBox);
    v->addWidget(lblPid);
    v->addWidget(lblRequest);
    v->addWidget(lblWorkingDir);
    v->addWidget(lblOpenFds);

    layout->addWidget(card,0,0,1,1);

}

void PathResolutionWindow::setupPathVisualizerCard(QGridLayout *layout)
{
    auto *card = new QFrame();

    card->setStyleSheet(cardStyleSheet());

    auto *v = new QVBoxLayout(card);

    v->addWidget(
        createCardTitle("PATH VISUALIZER"));

    pathScrollArea = new QScrollArea();

    pathScrollArea->setWidgetResizable(true);

    pathVisualizerContainer = new QWidget();

    auto *containerLayout =
        new QVBoxLayout(pathVisualizerContainer);

    pathVisualizerContainer
        ->setLayout(containerLayout);

    pathScrollArea
        ->setWidget(pathVisualizerContainer);

    lblPathResult =
        new QLabel("No path selected");

    lblPathResult->setStyleSheet(
        "color:#58a6ff;"
        "font-weight:bold;"
    );

    v->addWidget(pathScrollArea);
    v->addWidget(lblPathResult);

    layout->addWidget(card,0,1,1,1);
}

void PathResolutionWindow::setupDirectoryTreeCard(QGridLayout *layout)
{
    auto *card = new QFrame();

    card->setStyleSheet(cardStyleSheet());

    auto *v = new QVBoxLayout(card);

    v->addWidget(
        createCardTitle("DIRECTORY TREE"));

    directoryTree = new QTreeWidget();

    directoryTree->setColumnCount(4);

    directoryTree->setHeaderLabels(
        {"Name","Inode","Type","Size"});

    v->addWidget(directoryTree);

    layout->addWidget(card,1,0,1,1);
}

void PathResolutionWindow::setupFileDescriptorTableCard(QGridLayout *layout)
{
    auto *card = new QFrame();

    card->setStyleSheet(cardStyleSheet());

    auto *v = new QVBoxLayout(card);

    v->addWidget(
        createCardTitle("FILE DESCRIPTORS"));

    fdTable = new QTableWidget();

    fdTable->setColumnCount(7);

    fdTable->setHorizontalHeaderLabels(
        {"FD","Type","Path","Inode",
         "Offset","Flags","Ref"});

    fdTable->horizontalHeader()
        ->setStretchLastSection(true);

    v->addWidget(fdTable);

    layout->addWidget(card,1,1,1,1);
}

void PathResolutionWindow::setupTimelineCard(QGridLayout *layout)
{
    auto *card = new QFrame();

    card->setStyleSheet(cardStyleSheet());

    auto *v = new QVBoxLayout(card);

    v->addWidget(
        createCardTitle("TIMELINE"));

    timelineScrollArea = new QScrollArea();

    timelineScrollArea->setWidgetResizable(true);

    timelineContent = new QWidget();

    timelineContentLayout =
        new QVBoxLayout(timelineContent);

    timelineScrollArea
        ->setWidget(timelineContent);

    v->addWidget(timelineScrollArea);

    layout->addWidget(card,2,0,1,2);
}

void PathResolutionWindow::setupRecentNamespaceEventsCard(QGridLayout *layout)
{
    auto *card = new QFrame();

    card->setStyleSheet(cardStyleSheet());

    auto *v = new QVBoxLayout(card);

    v->addWidget(
        createCardTitle("NAMESPACE EVENTS"));

    namespaceEventsTable =
        new QTableWidget();

    namespaceEventsTable->setColumnCount(6);

    namespaceEventsTable->setHorizontalHeaderLabels(
        {"PID","Operation","Layer",
         "Tick","Name","Details"});

    namespaceEventsTable->horizontalHeader()
        ->setStretchLastSection(true);

    v->addWidget(namespaceEventsTable);

    layout->addWidget(card,3,0,1,2);
}
void PathResolutionWindow::refreshDirectoryTree()
{
    directoryTree->clear();

    // Build adjacency map from DIR events
    QSqlQuery q;
    q.prepare(R"SQL(
        SELECT DISTINCT parent_inum, target_inum, elem, inode_type
        FROM fs_events
        WHERE layer = 'DIR'
        ORDER BY parent_inum, target_inum
    )SQL");

    if (!q.exec()) {
        qDebug() << "Directory tree query failed:" << q.lastError().text();
        return;
    }

    struct Entry { int inum; QString name; int type; };

    QMap<int, QList<Entry>> children;

    while (q.next()) {
        int parent = q.value(0).toInt();
        int target = q.value(1).toInt();
        QString name = q.value(2).toString();
        int itype = q.value(3).toInt();

        children[parent].append({target, name, itype});
    }

    // Recursive lambda to populate tree
    std::function<void(QTreeWidgetItem*, int)> addChildren =
        [&](QTreeWidgetItem *parentItem, int parentInum) {
            for (const Entry &e : children.value(parentInum)) {
                QString display = e.name.isEmpty() ? QString("(inode %1)").arg(e.inum) : e.name;
                auto *it = new QTreeWidgetItem();
                it->setText(0, display);
                it->setText(1, QString::number(e.inum));
                it->setText(2, e.type == 1 ? "Dir" : "File");
                it->setText(3, "");
                parentItem->addChild(it);
                addChildren(it, e.inum);
            }
        };

    // Start from root inode 1 if present, otherwise create an artificial root
    QTreeWidgetItem *root = new QTreeWidgetItem();
    root->setText(0, "/ (root)");
    root->setText(1, "1");
    root->setText(2, "Dir");
    directoryTree->addTopLevelItem(root);

    addChildren(root, 1);
}

void PathResolutionWindow::refreshFileDescriptorTable()
{
    fdTable->setRowCount(0);

    if (currentPid < 0) return;

    QSqlQuery q;
    q.prepare(R"SQL(
        SELECT fd_number, file_type, path, inum, file_off, readable, writable, file_ref
        FROM state
        WHERE pid = ?
        ORDER BY fd_number
    )SQL");

    q.addBindValue(currentPid);

    if (!q.exec()) {
        qDebug() << "FD table query failed:" << q.lastError().text();
        return;
    }

    int row = 0;
    while (q.next()) {
        fdTable->insertRow(row);
        fdTable->setItem(row, 0, new QTableWidgetItem(q.value(0).toString()));
        fdTable->setItem(row, 1, new QTableWidgetItem(q.value(1).toString()));
        fdTable->setItem(row, 2, new QTableWidgetItem(q.value(2).toString()));
        fdTable->setItem(row, 3, new QTableWidgetItem(q.value(3).toString()));
        fdTable->setItem(row, 4, new QTableWidgetItem(q.value(4).toString()));

        QString flags = QString("R%1 W%2").arg(q.value(5).toInt()).arg(q.value(6).toInt());
        fdTable->setItem(row, 5, new QTableWidgetItem(flags));

        fdTable->setItem(row, 6, new QTableWidgetItem(q.value(7).toString()));

        // Simple styling: highlight regular file entries
        QString ftype = q.value(1).toString().toLower();
        if (ftype.contains("file") || ftype.contains("regular")) {
            for (int c = 0; c < fdTable->columnCount(); ++c) {
                fdTable->item(row, c)->setBackground(QColor("#0f1720"));
                fdTable->item(row, c)->setForeground(QColor("#c9d1d9"));
            }
        }

        row++;
    }
}