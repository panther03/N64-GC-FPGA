#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <termios.h>

int main() {
    // shamelessly yoinked from https://www.pololu.com/docs/0J73/15.5

    int fd = open("/dev/ttyUSB0", O_RDWR | O_NOCTTY);
    if (fd == -1)
    {
    perror("/dev/ttyUSB0");
    return -1;
    }

    // Get the current configuration of the serial port.
    struct termios options;
    int result = tcgetattr(fd, &options);
    if (result)
    {
        perror("tcgetattr failed");
        close(fd);
        return -1;
    }

    // Turn off any options that might interfere with our ability to send and
    // receive raw binary bytes.
    options.c_iflag &= ~(INLCR | IGNCR | ICRNL | IXON | IXOFF);
    options.c_oflag &= ~(ONLCR | OCRNL);
    options.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);

    cfsetospeed(&options, B19200);
    cfsetispeed(&options, B19200);

    result = tcsetattr(fd, TCSANOW, &options);
    if (result)
    {
        perror("tcsetattr failed");
        close(fd);
        return -1;
    }

    size_t packet_size = 4;
    uint8_t packet_buf[packet_size];
    while (1) {
        
        size_t received = 0;
        while (received < packet_size)
        {
            ssize_t r = read(fd, packet_buf + received, packet_size - received);
            if (r < 0)
            {
            perror("failed to read from port");
            return -1;
            }
            if (r == 0)
            {
            // Timeout
            break;
            }
            received += r;
        }
        printf("%x", received);
    }
}