/*------------------------------------------------------------------------------------
# @author       Guillaume Plante <radicaltronic@gmail.com>
# @description  Bug repro for core dump problems.
#               
# @notes        Daemon: start.sh
# @copyright    2018 GNU GENERAL PUBLIC LICENSE v3
#------------------------------------------------------------------------------------*/

#include <QCoreApplication>
#include <QtGlobal>

#include <QtGlobal>
#include <QtDebug>
#include <QTextStream>
#include <QTextCodec>
#include <QLocale>
#include <QTime>
#include <QFile>

#include <stdio.h>
#include <stdlib.h>

#include <initializer_list>
#include <signal.h>
#include <unistd.h>


//const QString logFilePath = "/var/log/bug-signals.log";
const QString logFilePath = "log/signals.log";
bool logToFile = false;


void customMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QHash<QtMsgType, QString> msgLevelHash({{QtDebugMsg, "Debug"}, {QtInfoMsg, "Info"}, {QtWarningMsg, "Warning"}, {QtCriticalMsg, "Critical"}, {QtFatalMsg, "Fatal"}});
    QByteArray localMsg = msg.toLocal8Bit();
    QTime time = QTime::currentTime();
    QString formattedTime = time.toString("hh:mm:ss.zzz");
    QByteArray formattedTimeMsg = formattedTime.toLocal8Bit();
    QString logLevelName = msgLevelHash[type];
    QByteArray logLevelMsg = logLevelName.toLocal8Bit();

    if (logToFile) {
        QString txt = QString("%1 %2 (%3): --> %4").arg(formattedTime, logLevelName, context.file, msg  );
        //QString txt = QString("%1 %2: %3").arg(formattedTime, logLevelName, msg/*,  context.file*/);
        QFile outFile(logFilePath);
        outFile.open(QIODevice::WriteOnly | QIODevice::Append);
        QTextStream ts(&outFile);
        ts << txt << endl;
        outFile.close();
    } else {
        fprintf(stderr, "%s %s: %s (%s:%u, %s)", formattedTimeMsg.constData(), logLevelMsg.constData(), localMsg.constData(), context.file, context.line, context.function);
        // fprintf(stderr, "%s %s: %s\n", formattedTimeMsg.constData(), logLevelMsg.constData(), localMsg.constData());
        fflush(stderr);
    }

    if (type == QtFatalMsg)
        abort();
}

void ignoreUnixSignals(std::initializer_list<int> ignoreSignals) {
    // all these signals will be ignored.
    for (int sig : ignoreSignals)
        signal(sig, SIG_IGN);
}

const char* get_process_name_by_pid(const int pid)
{
    char* name = (char*)calloc(1024,sizeof(char));
    if(name){
        sprintf(name, "/proc/%d/cmdline",pid);
        FILE* f = fopen(name,"r");
        if(f){
            size_t size;
            size = fread(name, sizeof(char), 1024, f);
            if(size>0){
                if('\n'==name[size-1])
                    name[size-1]='\0';
            }
            else
            {
                qDebug() << "cannot open cmdline file";
            }
            fclose(f);
        }
    }
    return name;
}

void catchUnixSignals(std::initializer_list<int> quitSignals) {
    auto handler = [](int sig) -> void {

        printf("\n>>>1received signal(%d).\n", sig);
        qDebug() << "1received signal: " << sig << "\n";

        // blocking and not aysnc-signal-safe func are valid
        //printf("\nquit the application by signal(%d).\n", sig);
        if(sig == SIGINT) //Interrupt from keyboard --> out
        QCoreApplication::quit();
    };

    auto sigaction_h
            = [](int sig, siginfo_t *sInfo, void *) -> void {

        qDebug() << "\n##############################";
        qDebug() << "Received signal: " << sig;
        if(sInfo != nullptr)
        {
            qDebug() << " - Signal number: " << sInfo->si_signo;
            qDebug() << " - Sending process ID: " << sInfo->si_pid;
            qDebug() << " - Sending process name: " << get_process_name_by_pid(sInfo->si_pid);
            qDebug() << " - User ID of sending process: " << sInfo->si_uid;   
        }
        else
        {
            qDebug() << "no sInfo";
        }
        qDebug() << "##############################\n";
    };

    sigset_t blocking_mask;
    sigemptyset(&blocking_mask);
    for (auto sig : quitSignals)
        sigaddset(&blocking_mask, sig);

    struct sigaction sa;
    sa.sa_handler = handler;
    sa.sa_mask    = blocking_mask;
    sa.sa_flags  |= SA_SIGINFO;;
    sa.sa_sigaction = sigaction_h;
    for (auto sig : quitSignals)
        sigaction(sig, &sa, nullptr);
}



int main(int argc, char *argv[]) 
{
    QCoreApplication app(argc, argv);
    catchUnixSignals({SIGQUIT, SIGINT, SIGTERM, SIGHUP, SIGBUS, SIGSEGV});

    logToFile = true;
    qInstallMessageHandler(customMessageOutput);
    

    return app.exec();
}
