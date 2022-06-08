#include <unistd.h>
#include <stdio.h>

int main () {
	char buf[20];
	int fd = open("hi.txt");
	int bytes_read = read(fd, buf, 20);
	printf("%d %s\n", bytes_read, buf);
	return 0;
}
