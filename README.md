# Multifunctional-video-processing-platform
该作品为2024年FPGA创新设计大赛（上海安路科技赛道）国一作品  （希望大家给点点右上角的 star 呀）
### （持续更新中...）

初赛演示视频：[2024年FPGA创新设计竞赛国一作品，该视频为安路科技赛道初赛视频]( https://www.bilibili.com/video/BV1K8zdYuEAu/?share_source=copy_web&vd_source=d38841530cd28bd68603ca38364bd8a1)

该作品由三张板卡级联组成，板卡一和板卡二之间使用HDMI级联，板卡一和板卡三之间使用SFP级联
板卡一实现了五路数据源的输入（双目摄像头、SD卡、HDMI IN、以太网），3路视频源的输出（HDMI OUT0、HDMI OUT1,SFP）
板卡二实现了1路视频源的输入（HDMI IN），2路视频源的输出（HDMI OUT、以太网 ）
板卡三实现了3路视频源的输入（SFP、HDMI IN、MIPI摄像头），1路视频源的输出（HDMI OUT）

整个系统实现了任意角度视频旋转（三种实现方案）、任意比例视频缩放、任意分辨率JPG图片解码等24种图像处理算法，以及SD卡SDIO模式读取等模块。

由于整个系统的功能较多、数据通路较为复杂，我会把每一个比较重要的功能都独立的对应一个工程文件，并且会在博客中给出每个重要的功能的设计思路。
博客地址：[2024年FPGA大赛（上海安路科技赛道）国一作品分享](https://blog.csdn.net/weixin_53015183/category_12849637.html?spm=1001.2014.3001.5482)

更新顺序如下：
  1、四分屏+分屏时视频移动方案实现 （已更新）       
  2、分屏/全屏切换实现            （已更新）   
  3、视频任意角度旋转方案实现      （已更新180度旋转、90/270旋转） 
   
  4、视频任意比例缩放方案实现  
  5、任意分辨率JPG图片解码实现  
  6、以太网传输字符显示实现  
  7、SD卡SDIO模式读取实现  
  .........(未完待续)  
  





