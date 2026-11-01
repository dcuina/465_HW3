#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUF_SIZE 128 /* fixed stack buffer */
#define MAX_COPY 512 /* larger than BUF_SIZE on purpose: this is the bug */

void win() {
	/* ret2win target: writes markers/ret2win.txt, then */
        /* attempts to read protected decoy */
  	FILE *mark_write = fopen("/home/ubuntu/csce465-agentsec/465_HW3/markers/ret2win.txt", "w");

	if (mark_write == NULL) {
		perror("Error creating file");
		return;
	}

	fprintf(mark_write, "Marker created\n");

	fclose(mark_write);

	FILE *decoy_read = fopen("/opt/agentsec/decoy.txt", "r");
	if (decoy_read == NULL) {
		perror("Error reading file");
		return;
	}
	
	char output[MAX_COPY];

	if (fgets(output, MAX_COPY, decoy_read) != NULL) {
		fprintf(stdout, "Successfully read file\n");
		printf("%s \n", output);
	}
	
	fclose(decoy_read);
	return;
}	

static void vulnerable_copy(const unsigned char *input, size_t n) {
	char buf[BUF_SIZE];
	/* TODO: Copy n bytes from input into buf WITHOUT checking n */
	/* against BUF_SIZE (missing check is vulnerability) */
	memcpy(buf, (const char*)input, n);
}

static void parse_log(const char *path) {
	/* read whole file into heap buffer, fclose() it, THEN */
	/* call vulnerable_copy(input, n) so the overflow reaches */
	/* only this frame's saved return address -- a clean ret2win */
	const char* inbox_path = "/home/ubuntu/csce465-agentsec/465_HW3/inbox/";

	char* full_path = realpath(path, NULL);

	if (full_path == NULL) {
		perror("Cannot resolve entire path");
		return;
	}

	if (strncmp(full_path, inbox_path, strlen(inbox_path)) != 0) {
		perror("Unsupported path");
		return;
	}
	
	FILE *file_ptr = fopen(full_path, "rb");

	free(full_path);

	unsigned char* heap_buff = (unsigned char*)malloc(MAX_COPY);
	if (heap_buff == NULL) {
		perror("Heap allocation failed");
		fclose(file_ptr);
		return;
	}
	
	size_t bytes_read = fread(heap_buff, 1, MAX_COPY, file_ptr);

	fclose(file_ptr);
	vulnerable_copy(heap_buff, bytes_read);

	free(heap_buff);

}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		printf("Usage: %s ~/csce465-agentsec/465_HW3/inbox/[filename]", argv[0]);
		return 1;
	}

	parse_log(argv[1]);

	return 0;
}
