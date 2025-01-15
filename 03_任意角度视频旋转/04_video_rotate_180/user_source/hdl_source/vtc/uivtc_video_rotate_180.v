/*
 * @Author: bit_stream 
 * @Date: 2025-01-15 14:39:22 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2025-01-15 18:25:40
 */

//��ȡ��·��Ƶ��һ·����ת֮ǰ����Ƶ��һ·����ת֮�����Ƶ

`timescale 1ns / 1ns //����ʱ��̶�/����

module uivtc_video_rotate_180#
(
parameter H_ActiveSize  =   1920,               //��Ƶʱ�����,����Ƶ�źţ�һ����Ч(��Ҫ��ʾ�Ĳ���)������ռ��ʱ������һ��ʱ�Ӷ�Ӧһ����Ч����
parameter H_FrameSize   =   1920+88+44+148,     //��Ƶʱ�����,����Ƶ�źţ�һ����Ƶ�ź��ܼ�ռ�õ�ʱ����
parameter H_SyncStart   =   1920+88,            //��Ƶʱ�����,��ͬ����ʼ��������ʱ������ʼ������ͬ���ź� 
parameter H_SyncEnd     =   1920+88+44,         //��Ƶʱ�����,��ͬ��������������ʱ������ֹͣ������ͬ���źţ�֮���������Ч���ݲ���

parameter V_ActiveSize  =   1080,               //��Ƶʱ�����,����Ƶ�źţ�һ֡ͼ����ռ�õ���Ч(��Ҫ��ʾ�Ĳ���)��������ͨ��˵����Ƶ�ֱ��ʼ�H_ActiveSize*V_ActiveSize
parameter V_FrameSize   =   1080+4+5+36,        //��Ƶʱ�����,����Ƶ�źţ�һ֡��Ƶ�ź��ܼ�ռ�õ�������
parameter V_SyncStart   =   1080+4,             //��Ƶʱ�����,��ͬ����ʼ��������������ʼ������ͬ���ź� 
parameter V_SyncEnd     =   1080+4+5,            //��Ƶʱ�����,��ͬ�������������ٳ�����ֹͣ������ͬ���źţ�֮����ǳ���Ч���ݲ���

parameter H2_ActiveSize =   640, //1280*720���ź����Ƶ
parameter V2_ActiveSize =   360,



parameter VTC0_X        =   0       ,
parameter VTC0_Y        =   180       ,
parameter VTC1_X        =   640     ,    
parameter VTC1_Y        =   180       

)
(
input           I_vtc_rstn,//ϵͳ��λ
input			I_vtc_clk, //ϵͳʱ��
output	reg		O_vtc_vs,  //��ͬ�����
output  reg     O_vtc_hs,  //��ͬ�����
output  reg     O_vtc_data_valid,   //��Ƶ������Ч
output  reg [31:0]O_vtc_data,    

output  reg     O_vtc0_de,
input   wire   [31:0] I_rd_ddr_data_0,
output  reg     O_vtc1_de_ahead,//��ǰO_vtc1_deһ��ʱ�����ڣ�����ram�е����ݶ�ȡ
output  reg     O_vtc1_de,
input   wire   [31:0] I_rd_ddr_data_1
);

reg [11:0] hcnt = 12'd0;    //��Ƶˮƽ�����м��������Ĵ���
reg [11:0] vcnt = 12'd0;    //��Ƶ��ֱ�����м��������Ĵ���   
reg [2 :0] rst_cnt = 3'd0;  //��λ���������Ĵ���
wire rst_sync = rst_cnt[2]; //ͬ����λ

always @(posedge I_vtc_clk or negedge I_vtc_rstn)begin //ͨ������������ͬ����λ
    if(I_vtc_rstn == 1'b0)
        rst_cnt <= 3'd0;
    else if(rst_cnt[2] == 1'b0)
        rst_cnt <= rst_cnt + 1'b1;
end    


//��Ƶˮƽ�����м�����
always @(posedge I_vtc_clk)begin
    if(rst_sync == 1'b0) //��λ
        hcnt <= 12'd0;
    else if(hcnt < (H_FrameSize - 1'b1))//������Χ��0 ~ H_FrameSize-1
        hcnt <= hcnt + 1'b1;
    else 
        hcnt <= 12'd0;
end         

//��Ƶ��ֱ�����м����������ڼ����Ѿ���ɵ�����Ƶ�ź�
always @(posedge I_vtc_clk)begin
    if(rst_sync == 1'b0)
        vcnt <= 12'd0;
    else if(hcnt == (H_ActiveSize  - 1'b1)) begin//��Ƶˮƽ�����Ƿ�һ�н���
           vcnt <= (vcnt == (V_FrameSize - 1'b1)) ? 12'd0 : vcnt + 1'b1;//��Ƶ��ֱ�����м�������1��������Χ0~V_FrameSize - 1
    end
end 

wire hs_valid  =  hcnt < H_ActiveSize; //���ź���Ч���ز���
wire vs_valid  =  vcnt < V_ActiveSize; //���ź���Ч���ز���
wire vtc_hs    =  (hcnt >= H_SyncStart && hcnt < H_SyncEnd);//����hs����ͬ���ź�
wire vtc_vs	 =  (vcnt > V_SyncStart && vcnt <= V_SyncEnd);//����vs����ͬ���ź�      
wire vtc_de    =  hs_valid && vs_valid;//ֻ�е���Ƶˮƽ��������Ч����Ƶ��ֱ������ͬʱ��Ч����Ƶ���ݲ��ֲ�����Ч



wire hs0_valid  =  (hcnt>=VTC0_X)&& (hcnt<(VTC0_X+H2_ActiveSize));
wire vs0_valid  =  (vcnt>=VTC0_Y)&& (vcnt<(VTC0_Y+V2_ActiveSize));
wire hs1_valid  =  (hcnt>=VTC1_X)&& (hcnt<(VTC1_X+H2_ActiveSize));
wire vs1_valid  =  (vcnt>=VTC1_Y)&& (vcnt<(VTC1_Y+V2_ActiveSize));
wire hs1_valid_ahead  =  (hcnt>=VTC1_X-1)&& (hcnt<(VTC1_X+H2_ActiveSize-1));


wire vtc0_de    =  hs0_valid && vs0_valid;
wire vtc1_de    =  hs1_valid && vs1_valid;
wire vtc1_de_ahead    =  hs1_valid_ahead && vs1_valid;



reg O_vtc_de;


//��һ�μĴ��������������ڸ���ʱ��������ڸ߷ֱ��ʣ����ٵ��źţ����Ŀ��Ը����ڲ�ʱ���������ڸ����ٶ�
always @(posedge I_vtc_clk)begin
	if(rst_sync == 1'b0)begin
		O_vtc_vs <= 1'b0;
		O_vtc_hs <= 1'b0;
		O_vtc_de <= 1'b0;
		O_vtc0_de <= 1'b0;
		O_vtc1_de <= 1'b0;
		O_vtc1_de_ahead <= 1'b0;
	end
    else begin
        O_vtc_vs <= vtc_vs; //��ͬ���źŴ������
		O_vtc_hs <= vtc_hs; //��ͬ���źŴ������
        O_vtc_de <= vtc_de;	//��Ƶ��Ч�źŴ������
        O_vtc0_de <= vtc0_de;	
		O_vtc1_de <= vtc1_de;	
		O_vtc1_de_ahead <= vtc1_de_ahead;	
          
    end
end


always @(posedge I_vtc_clk)begin
    if (rst_sync == 1'b0) begin
        O_vtc_data<=32'd0;
    end else if (O_vtc1_de) begin
        O_vtc_data<=I_rd_ddr_data_1;
    end else if (O_vtc0_de) begin
        O_vtc_data<=I_rd_ddr_data_0;
    end  else begin
        O_vtc_data<=32'd0;
    end
end

always @(posedge I_vtc_clk)begin
    if (rst_sync==1'b0) begin
        O_vtc_data_valid<=1'b0;
    end else begin
        O_vtc_data_valid<=O_vtc_de;
    end
end


endmodule


