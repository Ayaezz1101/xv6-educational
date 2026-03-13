#include <QApplication>
#include <QMainWindow>
#include <QTableView>
#include <QHeaderView>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLineEdit>
#include <QComboBox>
#include <QLabel>
#include <QTimer>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlQueryModel>
#include <QSortFilterProxyModel>
#include <QMessageBox>

class EventsWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit EventsWindow(const QString &dbPath, QWidget *parent = nullptr)
        : QMainWindow(parent),
          m_dbPath(dbPath),
          m_model(new QSqlQueryModel(this)),
          m_proxy(new QSortFilterProxyModel(this))
    {
        setWindowTitle("xv6 Events Viewer (SQLite)");
        resize(1100, 650);

        // ---- UI ----
        auto *central = new QWidget(this);
        auto *root = new QVBoxLayout(central);

        auto *filters = new QHBoxLayout();
        root->addLayout(filters);

        filters->addWidget(new QLabel("PID:", this));
        m_pidEdit = new QLineEdit(this);
        m_pidEdit->setPlaceholderText("e.g. 2");
        m_pidEdit->setMaximumWidth(120);
        filters->addWidget(m_pidEdit);

        filters->addWidget(new QLabel("CPU:", this));
        m_cpuCombo = new QComboBox(this);
        m_cpuCombo->addItem("All", -1);
        m_cpuCombo->addItem("0", 0);
        m_cpuCombo->addItem("1", 1);
        m_cpuCombo->addItem("2", 2);
        m_cpuCombo->addItem("3", 3);
        m_cpuCombo->setMaximumWidth(100);
        filters->addWidget(m_cpuCombo);

        filters->addWidget(new QLabel("Name contains:", this));
        m_nameEdit = new QLineEdit(this);
        m_nameEdit->setPlaceholderText("e.g. sh");
        m_nameEdit->setMaximumWidth(180);
        filters->addWidget(m_nameEdit);

        filters->addStretch(1);

        m_status = new QLabel("Disconnected", this);
        filters->addWidget(m_status);

        m_view = new QTableView(this);
        m_view->setSortingEnabled(true);
        m_view->horizontalHeader()->setStretchLastSection(true);
        m_view->setSelectionBehavior(QAbstractItemView::SelectRows);
        m_view->setSelectionMode(QAbstractItemView::SingleSelection);
        root->addWidget(m_view);

        setCentralWidget(central);

        // ---- DB ----
        if (!openDb()) {
            return;
        }

        // ---- Model / Proxy ----
        m_proxy->setSourceModel(m_model);
        m_proxy->setFilterCaseSensitivity(Qt::CaseInsensitive);
        m_view->setModel(m_proxy);

        // initial load
        reload();

        // ---- Live refresh timer ----
        m_timer = new QTimer(this);
        connect(m_timer, &QTimer::timeout, this, &EventsWindow::reload);
        m_timer->start(500); // refresh every 500ms

        // ---- Filter bindings ----
        connect(m_pidEdit, &QLineEdit::textChanged, this, &EventsWindow::reload);
        connect(m_cpuCombo, &QComboBox::currentIndexChanged, this, &EventsWindow::reload);
        connect(m_nameEdit, &QLineEdit::textChanged, this, &EventsWindow::reload);
    }

private slots:
    void reload() {
        // Build WHERE clause
        QString where = "1=1";
        QList<QVariant> binds;

        // PID filter
        bool ok = false;
        int pid = m_pidEdit->text().trimmed().toInt(&ok);
        if (ok) {
            where += " AND pid = ?";
            binds << pid;
        }

        // CPU filter
        int cpu = m_cpuCombo->currentData().toInt();
        if (cpu >= 0) {
            where += " AND cpu = ?";
            binds << cpu;
        }

        // Name contains
        QString name = m_nameEdit->text().trimmed();
        if (!name.isEmpty()) {
            where += " AND name LIKE ?";
            binds << QString("%%1%").arg(name);
            // Fix: build "%name%"
            binds.last() = QString("%%1%").arg(name); // placeholder safe
        }

        // NOTE: The above LIKE string building can be simplified:
        // binds << QString("%%1%").arg(name); results in "%name%"

        // Query (latest first)
        QString sql =
    "SELECT seq, tick, cpu, pid, name, state "
    "FROM events "
    "WHERE " + where + " "
    "ORDER BY seq DESC "
    "LIMIT 2000";

        QSqlQuery q(m_db);
        q.prepare(sql);

        for (const auto &b : binds) q.addBindValue(b);

        if (!q.exec()) {
            m_status->setText(QString("Query error: %1").arg(q.lastError().text()));
            return;
        }

        m_model->setQuery(std::move(q));

        if (m_model->lastError().isValid()) {
            m_status->setText(QString("Model error: %1").arg(m_model->lastError().text()));
            return;
        }

        // Column headers
        m_model->setHeaderData(0, Qt::Horizontal, "seq");
        m_model->setHeaderData(1, Qt::Horizontal, "tick");
        m_model->setHeaderData(2, Qt::Horizontal, "cpu");
        m_model->setHeaderData(3, Qt::Horizontal, "pid");
        m_model->setHeaderData(4, Qt::Horizontal, "name");
        m_model->setHeaderData(5, Qt::Horizontal, "state");

        m_status->setText(QString("Rows: %1").arg(m_model->rowCount()));
    }

private:
    bool openDb() {
        m_db = QSqlDatabase::addDatabase("QSQLITE");
        m_db.setDatabaseName(m_dbPath);

        if (!m_db.open()) {
            QMessageBox::critical(this, "DB open failed",
                                  QString("Failed to open %1\n\n%2")
                                      .arg(m_dbPath, m_db.lastError().text()));
            m_status->setText("DB open failed");
            return false;
        }

        m_status->setText(QString("Connected: %1").arg(m_dbPath));
        return true;
    }

private:
    QString m_dbPath;
    QSqlDatabase m_db;

    QTableView *m_view{};
    QLineEdit *m_pidEdit{};
    QLineEdit *m_nameEdit{};
    QComboBox *m_cpuCombo{};
    QLabel *m_status{};
    QTimer *m_timer{};

    QSqlQueryModel *m_model;
    QSortFilterProxyModel *m_proxy;
};

#include "main.moc"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QString dbPath = "events.db";
    if (argc >= 2) dbPath = argv[1];

    EventsWindow w(dbPath);
    w.show();

    return app.exec();
}
