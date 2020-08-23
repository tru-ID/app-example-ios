//
//  sslfuncs.c
//
//  Created by BENJAMIN BRYANT BUDIMAN on 05/09/18.
//  Copyright © 2018 Boku, Inc. All rights reserved.
//

#import "sslfuncs.h"

OSStatus ssl_read(SSLConnectionRef connection, void *data, size_t *data_length) {
	int socket = *(int *)connection;
	ssize_t written = read(socket, data, *data_length);
	if (written < *data_length) {
		*data_length = written;
		return errSSLWouldBlock;
	} else {
		*data_length = written;
		return noErr;
	}
}

OSStatus ssl_write(SSLConnectionRef connection, const void *data, size_t *data_length) {
	int socket = *(int *)connection;
	ssize_t written = write(socket, data, *data_length);
	if (written < *data_length) {
		*data_length = written;
		return errSSLWouldBlock;
	} else {
		*data_length = written;
		return noErr;
	}
}
