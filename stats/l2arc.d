#!/usr/sbin/dtrace -qs

l2arc_write_buffers:entry
{
  self->guid = ((l2arc_dev_t *)arg1)->l2ad_vdev->vdev_guid;
}

l2arc_write_buffers:return
{
    printf("%lu: dev: %llx written: %ld\n", timestamp / 1000000, self->guid, arg1);
}

