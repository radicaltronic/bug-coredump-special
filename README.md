# bug-coredum-special


## overview

Qt console application that will trap Posix signal and write the signal information to a log file

## how to build
1. Run an interactive docker image in 32 bit mode
1. Generate project and Makefile
   - qmake -project
   - qmake
   - make
1. Add executable in Polyscope initialization sequence.

### building: qt versions

Compilation problems (undeclared functions) happens if you use Qt4 instead of Qt5. You need to regenerate the Makefiles explicitly with the qt5 version of qmake. This is e.g. /usr/lib/x86_64-linux-gnu/qt5/bin/qmake ubuntu trusty 64 bit.

There is a tool named qtchooser to switch between Qt versions. On Debian and Ubuntu you can install it with 
```
$ apt-get install qtchooser
<.................................>

$ qtchooser -list-versions
4
5
default
opt-qt55
qt4-i386-linux-gnu
qt4
qt5-i386-linux-gnu
qt5
```
Then you create QT_SELECT environment variable and set e.g. ```export QT_SELECT=4 or export QT_SELECT=5```

Easiest way is to use it to list the alternatives and then create QT_SELECT environment variable.

**Use export QT_SELECT=5 for this project.**

Libs required:  -lQt5Widgets -lQt5Gui -lQt5Core -lGL -lpthread 

### qt5 install packages

Here's a list of packages I installed 
```
sudo apt-get install libqt5gui5 libqt5core5a libqt5widgets5
```

## miscellaneous

The log file is located here:
```
/var/log/polyscope-init.log
```

Therefore, must be root to run the programe else, will failed on output to var/log

### Get signal information and caller information

The man page for sigaction(2) suggests that the PID of the signal sender is available in the siginfo_t structure passed to your signal handler. This obviously requires that you use sigaction().

From the man page:

The sigaction structure is defined as something like:

```
   struct sigaction {
       void     (*sa_handler)(int);
       void     (*sa_sigaction)(int, siginfo_t *, void *);
       sigset_t   sa_mask;
       int        sa_flags;
       void     (*sa_restorer)(void);
   };
```


And the siginfo_t structure looks like this:
```
   siginfo_t {
       int      si_signo;    /* Signal number */
       int      si_errno;    /* An errno value */
       int      si_code;     /* Signal code */
       int      si_trapno;   /* Trap number that caused
                                hardware-generated signal
                                (unused on most architectures) */
       pid_t    si_pid;      /* Sending process ID */
       uid_t    si_uid;      /* Real user ID of sending process */
       int      si_status;   /* Exit value or signal */
       clock_t  si_utime;    /* User time consumed */
       clock_t  si_stime;    /* System time consumed */
       sigval_t si_value;    /* Signal value */
       int      si_int;      /* POSIX.1b signal */
       void    *si_ptr;      /* POSIX.1b signal */
       int      si_overrun;  /* Timer overrun count; POSIX.1b timers */
       int      si_timerid;  /* Timer ID; POSIX.1b timers */
       void    *si_addr;     /* Memory location which caused fault */
       int      si_band;     /* Band event */
       int      si_fd;       /* File descriptor */
   }
```

