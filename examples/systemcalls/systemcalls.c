#include "systemcalls.h"
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{
    int ret = system(cmd);

    if (ret == 0)
    {
        return true;
    }

    return false;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    int status;
    pid_t pid;
    int ret;

    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    pid = fork();

    if (pid == -1)
    {
        return false;
    }
    else if (pid == 0)
    {
        ret = execv(command[0], command);
        
        if (ret == -1)
        {
            _exit(true);
        }
    }
    else
    {
        pid = waitpid(pid, &status, 0);

        if (pid == -1)
            return false;
      
        if (WIFEXITED(status))
        {
            if (WEXITSTATUS(status) != false)
            {    
                return false;
            }
        }
    }
    va_end(args);

    return true;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    int status;
    pid_t pid;
    int ret;
    int fd;
    int saved_fd;

    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed

    pid = fork();
    fd = open(outputfile, O_WRONLY | O_CREAT, 0777);

    if (pid == -1)
    {
        return false;
    }
    else if (pid == 0)
    {
        saved_fd = dup(STDOUT_FILENO);
        dup2(fd, STDOUT_FILENO);
        close(fd);
        ret = execv(command[0], command);
        dup2(saved_fd, STDOUT_FILENO);

        if (ret == -1)
        {
            exit(true);
        }
    }
    else
    {
        close(fd);
        pid = waitpid(pid, &status, 0);

        if (pid == -1)
            return false;
      
        if (WIFEXITED(status))
        {
            if (WEXITSTATUS(status) != false)
            {    
                return false;
            }
        }
    }

    va_end(args);

    return true;
}
