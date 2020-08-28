//
//  mkv-storage.c
//  MKVS
//
//  Created by 王嘉宁 on 2020/7/22.
//  Copyright © 2020 Johnny. All rights reserved.
//

#include "mkv-storage.h"
#include <sys/mman.h>
#include <sys/stat.h>
#include "string.h"

// file control stream
FILE *file_stream;

void prepare(char * filename) {
    // mode can be r,w,a,r+,w+,a+
    // can use "fopen_s" function
    file_stream = fopen(filename, "w");
}


void write_to_file(char * content) {
    fputs(content, file_stream);
    memcpy(<#void *__dst#>, <#const void *__src#>, <#size_t __n#>)
}
