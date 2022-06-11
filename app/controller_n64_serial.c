#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <termios.h>
#include <ultra64.h>

#include "controller_api.h"

static int fd;
uint8_t bytes[4] = {0};

// shamelessly stolen from the internet
int open_serial_port(const char * device, uint32_t baud_rate)
{
  int fd = open(device, O_RDWR | O_NOCTTY);
  if (fd == -1)
  {
    perror(device);
    return -1;
  }
 
  // Flush away any bytes previously read or written.
  int result = tcflush(fd, TCIOFLUSH);
  if (result)
  {
    perror("tcflush failed");  // just a warning, not a fatal error
  }
 
  // Get the current configuration of the serial port.
  struct termios options;
  result = tcgetattr(fd, &options);
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
 
  // Set up timeouts: Calls to read() will return as soon as there is
  // at least one byte available or when 100 ms has passed.
  options.c_cc[VTIME] = 1;
  options.c_cc[VMIN] = 4;
 
  // This code only supports certain standard baud rates. Supporting
  // non-standard baud rates should be possible but takes more work.
  switch (baud_rate)
  {
  case 4800:   cfsetospeed(&options, B4800);   break;
  case 9600:   cfsetospeed(&options, B9600);   break;
  case 19200:  cfsetospeed(&options, B19200);  break;
  case 38400:  cfsetospeed(&options, B38400);  break;
  case 115200: cfsetospeed(&options, B115200); break;
  default:
    fprintf(stderr, "warning: baud rate %u is not supported, using 9600.\n",
      baud_rate);
    cfsetospeed(&options, B9600);
    break;
  }
  cfsetispeed(&options, cfgetospeed(&options));
 
  result = tcsetattr(fd, TCSANOW, &options);
  if (result)
  {
    perror("tcsetattr failed");
    close(fd);
    return -1;
  }
 
  return fd;
}

static void n64_serial_init(void) {
    printf("Initialize!");
    fd = open_serial_port("/dev/ttyUSB0", 19200);
}

static void n64_serial_read(OSContPad *pad) {
    uint8_t buf = 0xC6; // magic acknowledge byte
    if (fd != -1) {
                
        write(fd, &buf, 1);
        read(fd, bytes, 4);
        printf("%2x %2x %2x %2x \n", bytes[0], bytes[1], bytes[2], bytes[3]);
        pad->button = (bytes[3] << 8) | bytes[2];
        pad->stick_x = bytes[1];
        pad->stick_y = bytes[0];
    }
}

static void n64_serial_shutdown(void) {
    if (fd != -1) {
        close(fd);
    }
}

static u32 n64_serial_rawkey(void) {
    return VK_INVALID;
}

struct ControllerAPI controller_n64_serial = {
    VK_INVALID,
    n64_serial_init,
    n64_serial_read,
    n64_serial_rawkey,
    NULL, // no rumble_play
    NULL, // no rumble_stop
    NULL, // no rebinding
    n64_serial_shutdown
};
