任意角度视频旋转分为三个部分：180度视频实时旋转，90/270度视频实时旋转，任意角度视频实时旋转。

180度视频实时旋转工程文件见04_video_rotate_180文件夹



移植注意事项

1、 在本工程中，为了减少ERAM资源的使用，我们将图像像素点在DDR3中的存储和读取格式设置为RGB565格式，其中每个像素点占用16bit，并将DDR3的数据位宽设置为16bit。由于DDR3的突发传输长度固定为8，每次突发传输8次16bit数据，即总共传输128bit。因此，在进行DDR3存取时，FIFO的读写位宽可以设置为16bit和128bit。与此不同，若将图像像素点的存储格式设置为RGB888格式，每个像素点将占用24bit，并将DDR3的数据位宽设置为32bit。在这种情况下，进行存取时，FIFO的读写位宽将为32bit和256bit，这样会导致ERAM资源消耗的加倍。

2、本工程把四路视频源拼接模块输入的视频分辨率为1280×720


关于180度视频实时旋转方案实现讲解，博客地址如下：[FPGA实现视频180度实时旋转](https://blog.csdn.net/weixin_53015183/article/details/145122071?spm=1001.2014.3001.5502)

关于90/270度视频旋转方案实现讲解，博客地址如下：[FPGA实现视频90/270度旋转](https://blog.csdn.net/weixin_53015183/article/details/145321324?spm=1001.2014.3001.5502)