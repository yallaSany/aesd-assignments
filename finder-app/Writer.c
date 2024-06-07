#include <sys/types.h>
#include <sys/stat.h>
#include <libgen.h>
#include <fcntl.h>
#include <syslog.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

void openlog(const char *ident, int option, int facility);
void syslog(int priority, const char *format, ...);
void closelog(void);

const char identity[] = "Writer";

int main(int argc, char *argv[])
{
    openlog(identity, 0,LOG_USER);

    if (argc < 2)
    {
        syslog(LOG_ERR, "Not enough parameters");
        return 1;
    }

    char* file_and_path = strdup(argv[1]);
    char* file = basename(file_and_path);

    syslog(LOG_DEBUG, "Writing %s to file %s", argv[2], file);

    int file_desc =  open(argv[1], O_RDWR | O_CREAT, S_IRWXU);

    if (file_desc == -1)
    {
        syslog(LOG_ERR, "The file could does not exist or could not be created");
        return 1;
    }

    ssize_t bytes_written = write(file_desc, argv[2], strlen(argv[2]));

    if (bytes_written == -1)
    {
        syslog(LOG_ERR, "The string could not be written to the file");
        return 1;
    }

    return 0;
}
