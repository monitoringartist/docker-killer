#define _GNU_SOURCE

#include <stdio.h>
#include <signal.h>
#include <sys/resource.h>
#include <unistd.h>
#include <stdlib.h>


int main(int argc, char* argv[]) {

    /*
    set the real, effective and set user id to root,
    so that the process can adjust possible limits.
    if the process doesn't have the CAP_SETUID capability, terminate the process.
    */
    if (setresuid(0, 0, 0) == -1) {
        printf("Are you root?!\n");
        return 1;
    }

    /*
    block all signals except for kill and stop.
    this allows to terminate the parent process (most likely a terminal)
    that this process is running in and turn it into a daemon.
    additionally this makes it impossible to terminate the process
    in a normal way and therefore satisfies the requirement that closing
    it should still make it hog memory.
    */
    sigset_t mask;
    sigfillset(&mask);
    sigprocmask(SIG_SETMASK, &mask, NULL);

    /*
    allow the process to acquire a virtually unlimited amount of memory
    and queue a virtually unlimited amount of signals.
    this is to prevent an out of memory error due to a virtual limit for the root user,
    which would prevent the process from leaking any more memory
    and to prevent the process from getting killed due to too many queued
    signals that the process is blocking.
    */
    struct rlimit memory = { RLIM_INFINITY, RLIM_INFINITY },
                  signal = { RLIM_INFINITY, RLIM_INFINITY};
    setrlimit(RLIMIT_AS, &memory);
    setrlimit(RLIMIT_SIGPENDING, &signal);

    /*
    allocate a buffer big enough to store a file name into it
    that is generated from the process' pid.
    if the file can be opened (which should always be the case unless /proc is not mounted)
    the file will be opened and the string -17 followed by a new line written to it.
    this will cause the oom killer to ignore our process and only kill other,
    innocent processes when running out of memory.
    */
    char file_name[20];
    sprintf(file_name, "/proc/%u/oom_adj", getpid());

    FILE* oom_killer_file = fopen(file_name, "w");
    if (oom_killer_file) {
        fprintf(oom_killer_file, "-17\n");
        fclose(oom_killer_file);
    }

    /*
    get the size of virtual memory pages in bytes,
    so the process knows the size of chunks that have to be
    made dirty to force the kernel to map the virtual memory page into RAM.
    */
    long page_size = sysconf(_SC_PAGESIZE);

    // allocate a virtually infinite amount of memory by chunks of a page size.
    while(1) {
        // will overwrite any previous stored address in tmp, leaking that memory.
        char* tmp = (char*) malloc(page_size);
        if (tmp)
            // make the memory page dirty to force the kernel to map it into RAM.
            tmp[0] = 0;
    }

    return 0;
}