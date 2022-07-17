#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <termios.h>
 
// Opens the specified serial port, sets it up for binary communication,
// configures its read timeouts, and sets its baud rate.
// Returns a non-negative file descriptor on success, or -1 on failure.
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

ssize_t read_port(int fd, uint8_t * buffer, size_t size)
{
  size_t received = 0;
  while (received < size)
  {
    ssize_t r = read(fd, buffer + received, size - received);
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
  return received;
}


int main() {
    int fd = open_serial_port("/dev/ttyUSB0", 19200);
    
//    int fd2 = open("test.m64", O_WRONLY);
    

    uint8_t packet_buf[4];
    uint8_t buf = 0xC6;
    size_t size = 4;
    unsigned long i = 0;
    while (1) { 
        write(fd, &buf, 1);
//       for (unsigned long j = 0; j < 10000000; j++) {} 
//       printf("Writing\n!");
       size_t r = read(fd, packet_buf, 4);
//        read_port(fd, packet_buf, size);
        printf("%2x %2x %2x %2x \n", packet_buf[0], packet_buf[1], packet_buf[2], packet_buf[3]);
        //write(fd2, packet_buf, 4);
        //for (unsigned long j = 0; j < 90000000; j++) {}
        
	//i++;
    }
        

    close(fd);

    return 0;
}
