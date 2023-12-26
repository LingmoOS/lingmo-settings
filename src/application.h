#ifndef APPLICATION_H
#define APPLICATION_H

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDBusConnection>
#include "../include/interface/moduleinterface.h"

class Application : public QApplication
{
    Q_OBJECT

public:
    explicit Application(int &argc, char **argv);
    void addPage(QString title,QString name,QString page,QString iconSource,QString iconColor,QString category);
    void switchToPage(const QString &name);

private:
    void insertPlugin();
    QQmlApplicationEngine m_engine;
};

#endif // APPLICATION_H
