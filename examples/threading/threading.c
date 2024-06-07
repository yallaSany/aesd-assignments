#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
//#define DEBUG_LOG(msg,...)
#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    struct thread_data * thread_args = (struct thread_data *)thread_param;
    usleep(thread_args->wait_to_obtain_ms * 1000);

    DEBUG_LOG("Locking");
    int rc = pthread_mutex_lock(thread_args->mutex);

    if (rc != 0)
        ERROR_LOG("Failed to lock");

    usleep(thread_args->wait_to_release_ms * 1000);

    DEBUG_LOG("Unlocking");
    rc = pthread_mutex_unlock(thread_args->mutex);

        if (rc != 0)
        ERROR_LOG("Failed to unlock");

    thread_args->thread_complete_success = true;

    pthread_exit((void *)thread_args);
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex, int wait_to_obtain_ms, int wait_to_release_ms)
{
    struct thread_data* thread_params = (struct thread_data*)malloc(sizeof(thread_params));

    thread_params->wait_to_obtain_ms = wait_to_obtain_ms;
    thread_params->wait_to_release_ms = wait_to_release_ms;
    thread_params->mutex = mutex;

    DEBUG_LOG("Creating Thread");
    int rc = pthread_create(thread, NULL, threadfunc, thread_params);

    if (rc != 0)
    {
        ERROR_LOG("Creating thread failed");
        return false;
    }

    return true;
}
