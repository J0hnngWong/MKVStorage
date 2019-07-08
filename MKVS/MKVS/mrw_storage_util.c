//
//  mrw_storage_util.c
//  MKVS
//
//  Created by 王嘉宁 on 2019/7/8.
//  Copyright © 2019 Johnny. All rights reserved.
//

#include "mrw_storage_util.h"
#include <sys/mman.h>
#include <sys/stat.h>
#include <string.h>

void *file_pointer;
size_t file_size;
int32_t file_descriptor;
int32_t pointer_off_set;

int write_log(const char *log)
{
    size_t log_length = strlen(log);
    memcpy(file_pointer, log, log_length);
    return 0;
}
