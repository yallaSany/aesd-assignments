#include <errno.h>
#include <syslog.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[])
{
    /* variable to store errno */
    int err = 0;
        
    /* open a system logging */
    openlog(NULL, 0, LOG_USER);

    syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);

    /* check number of input parameters first */
    if (argc < 3){
        err = errno;
        syslog(LOG_ERR, "Invalid number of arguments %s", strerror(err));
        return 1;
    }
    else{
        syslog(LOG_DEBUG, "Correct number of input argumuents: %d", argc - 1);
    }

    /* save input file name and text into variables */
    char *file_path = argv[1];
    char *txt_to_write = argv[2];

    FILE *file = fopen(file_path, "w");
    /* check for errors in opening the file */
    if (file == NULL) {
        err = errno;
        syslog(LOG_ERR, "Error opening file: %s", strerror(err));
        return err;
    } else {
        /* write to file */
        size_t written = fprintf(file, "%s\n", txt_to_write);
        /* check for errors writing to the file */
        if (written != strlen(txt_to_write)+1) {
            err = errno;
            syslog(LOG_ERR, "Error writing to file: %s", strerror(err));
            return err;
        } else {
            syslog(LOG_DEBUG, "Successfully wrote to file: %s", file_path);
            fclose(file);
            return 0;
                }
            }
}
