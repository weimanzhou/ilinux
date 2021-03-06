/* 该文件被软盘系统任务使用
 * disk_parameter_s 结构用于描述一个磁盘的结构参数
 */

#ifndef _DISKPARM_H
#define _DISKPARM_H
struct disk_parameter_s {
  char spec1;
  char spec2;
  char motor_turnoff_sec;
  char sector_size_code;
  char sectors_per_cylinder;
  char gap_length;
  char dtl;
  char gap_length_for_format;
  char fill_byte_for_format;
  char head_settle_msec;
  char motor_start_eigth_sec;
};
#endif /* _DISKPARM_H */
