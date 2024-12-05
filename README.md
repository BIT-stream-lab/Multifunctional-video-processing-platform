# Multifunctional-video-processing-platform
该作品为2024年FPGA创新设计大赛（上海安路科技赛道）国一作品 
### （持续更新中...）

初赛演示视频：[2024年FPGA创新设计竞赛国一作品，该视频为安路科技赛道初赛视频]( https://www.bilibili.com/video/BV1K8zdYuEAu/?share_source=copy_web&vd_source=d38841530cd28bd68603ca38364bd8a1)

该作品由三张板卡级联组成，板卡一和板卡二之间使用HDMI级联，板卡一和板卡三之间使用SFP级联
板卡一实现了五路数据源的输入（双目摄像头、SD卡、HDMI IN、以太网），3路视频源的输出（HDMI OUT0、HDMI OUT1,SFP）
板卡二实现了1路视频源的输入（HDMI IN），2路视频源的输出（HDMI OUT、以太网 ）
板卡三实现了3路视频源的输入（SFP、HDMI IN、MIPI摄像头），1路视频源的输出（HDMI OUT）


由于整个系统的数据通路较为复杂，
更新顺序如下：
1、四分屏/全屏




