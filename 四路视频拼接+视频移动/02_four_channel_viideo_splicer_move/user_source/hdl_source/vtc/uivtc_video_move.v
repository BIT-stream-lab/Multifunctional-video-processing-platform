/*
 * @Author: bit_stream 
 * @Date: 2024-12-12 18:40:53 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-12 19:38:34
 */


`timescale 1ns / 1ns //����ʱ��̶�/����

module uivtc_video_move#
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
parameter VTC0_Y        =   0       ,
parameter VTC1_X        =   640     ,    
parameter VTC1_Y        =   0       ,
parameter VTC2_X        =   0     ,
parameter VTC2_Y        =   360     ,
parameter VTC3_X        =   640     ,
parameter VTC3_Y        =   360     

)
(
input           I_vtc_rstn,//ϵͳ��λ
input			I_vtc_clk, //ϵͳʱ��
input           I_video_move_en,
output	reg		O_vtc_vs,  //��ͬ�����
output  reg     O_vtc_hs,  //��ͬ�����
output  reg     O_vtc_data_valid,   //��Ƶ������Ч
output  reg [31:0]O_vtc_data,    

output  reg     O_vtc0_de,
input   wire   [31:0] I_rd_ddr_data_0,
output  reg     O_vtc1_de,
input   wire   [31:0] I_rd_ddr_data_1,
output  reg     O_vtc2_de,
input   wire   [31:0] I_rd_ddr_data_2,
output  reg     O_vtc3_de,
input   wire   [31:0] I_rd_ddr_data_3
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



reg     [11:0]  video_0_block_x = VTC0_X    ;       //Video 0���ϽǺ�����
reg     [11:0]  video_0_block_y = VTC0_Y    ;       //Video 0���Ͻ�������
reg     [11:0]  video_1_block_x = VTC1_X    ;       //Video 1���ϽǺ�����
reg     [11:0]  video_1_block_y = VTC1_Y    ;       //Video 1���Ͻ�������
reg     [11:0]  video_2_block_x = VTC2_X    ;       //Video 2���ϽǺ�����
reg     [11:0]  video_2_block_y = VTC2_Y    ;       //Video 2���Ͻ�������
reg     [11:0]  video_3_block_x = VTC3_X    ;       //Video 2���ϽǺ�����
reg     [11:0]  video_3_block_y = VTC3_Y    ;       //Video 2���Ͻ�������




reg cnt_fs; //֡������

always@(posedge I_vtc_clk or negedge I_vtc_rstn) begin
    if (!I_vtc_rstn) begin
        cnt_fs <= 'd0;
    end else if (vtc_vs &(~O_vtc_vs)) begin
        cnt_fs <= cnt_fs + 1'b1;
    end else begin
        cnt_fs <= cnt_fs;
    end
end


reg   move_en ;  //��Ƶ���ƶ�ʹ���ź�  

always @(posedge I_vtc_clk or negedge I_vtc_rstn ) begin
    if (!I_vtc_rstn) begin
        move_en <= 1'b0;
    end else if(cnt_fs&I_video_move_en&vtc_vs &(~O_vtc_vs)) begin
        move_en <= 1'b1;
    end else begin
        move_en <= 1'b0;
    end
end





reg             video_0_h_direct = 1'b1 ;   //��Ƶ��ˮƽλ�Ʒ���   1������    0������
reg             video_0_v_direct = 1'b1 ;   //��Ƶ����ֱλ�Ʒ���   1������    0������  


//���ƶ����߽�ʱ���ı��ƶ�����
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_0_h_direct <= 1'b1;                       //��ʼˮƽ�����ƶ�
        video_0_v_direct <= 1'b1;                       //��ʼ��ֱ�����ƶ�
    end 
    else begin
        if (video_0_block_x == 0 + 1'b1) begin     //������߽磬ˮƽ����
            video_0_h_direct <= 1'b1;
        end 
        else begin                              //�����ұ߽磬ˮƽ����  
            if(video_0_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
                video_0_h_direct <= 1'b0; 
            end
            else begin
                video_0_h_direct <= video_0_h_direct;
            end
        end
 
        if (video_0_block_y == 0 + 1'b1) begin     //�����ϱ߽磬��ֱ����
            video_0_v_direct <= 1'b1;
        end 
        else begin                              //�����±߽磬��ֱ����
            if(video_0_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
                video_0_v_direct <= 1'b0;                           
            end
            else begin
                video_0_v_direct <= video_0_v_direct;
            end
        end 
    end
 end

reg             video_1_h_direct = 1'b0 ;   //��Ƶ��ˮƽλ�Ʒ���   1������    0������
reg             video_1_v_direct = 1'b1 ;   //��Ƶ����ֱλ�Ʒ���   1������    0������  


//���ƶ����߽�ʱ���ı��ƶ�����
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_1_h_direct <= 1'b0;                       //��ʼˮƽ�����ƶ�
        video_1_v_direct <= 1'b1;                       //��ʼ��ֱ�����ƶ�
    end 
    else begin
        if (video_1_block_x == 0 + 1'b1) begin     //������߽磬ˮƽ����
            video_1_h_direct <= 1'b1;
        end 
        else begin                              //�����ұ߽磬ˮƽ����  
            if(video_1_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
               video_1_h_direct <= 1'b0; 
            end
            else begin
                video_1_h_direct <= video_1_h_direct;
            end
        end
 
        if (video_1_block_y == 0 + 1'b1) begin     //�����ϱ߽磬��ֱ����
            video_1_v_direct <= 1'b1;
        end 
        else begin                              //�����±߽磬��ֱ����
            if(video_1_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
               video_1_v_direct <= 1'b0;                           
            end
            else begin
                video_1_v_direct <= video_1_v_direct;
            end
        end 
    end
 end

reg             video_2_h_direct = 1'b1;   //��Ƶ��ˮƽλ�Ʒ���   1������    0������
reg             video_2_v_direct = 1'b0;   //��Ƶ����ֱλ�Ʒ���   1������    0������  


//���ƶ����߽�ʱ���ı��ƶ�����
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_2_h_direct <= 1'b1;                       //��ʼˮƽ�����ƶ�
        video_2_v_direct <= 1'b0;                       //��ʼ��ֱ�����ƶ�
    end 
    else begin
        if (video_2_block_x == 0 + 1'b1) begin     //������߽磬ˮƽ����
            video_2_h_direct <= 1'b1;
        end 
        else begin                              //�����ұ߽磬ˮƽ����  
            if(video_2_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
               video_2_h_direct <= 1'b0; 
            end
            else begin
                video_2_h_direct <= video_2_h_direct;
            end
        end
 
        if (video_2_block_y == 0 + 1'b1) begin     //�����ϱ߽磬��ֱ����
            video_2_v_direct <= 1'b1;
        end 
        else begin                              //�����±߽磬��ֱ����
            if(video_2_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
               video_2_v_direct <= 1'b0;                           
            end
            else begin
                video_2_v_direct <= video_2_v_direct;
            end
        end 
    end
 end

reg             video_3_h_direct = 1'b0 ;   //��Ƶ��ˮƽλ�Ʒ���   1������    0������
reg             video_3_v_direct = 1'b0 ;   //��Ƶ����ֱλ�Ʒ���   1������    0������  


//���ƶ����߽�ʱ���ı��ƶ�����
 always @(posedge I_vtc_clk or negedge I_video_move_en) begin
    if (!I_video_move_en) begin
        video_3_h_direct <= 1'b0;                       //��ʼˮƽ�����ƶ�
        video_3_v_direct <= 1'b0;                       //��ʼ��ֱ�����ƶ�
    end 
    else begin
        if (video_3_block_x == 0 + 1'b1) begin     //������߽磬ˮƽ����
            video_3_h_direct <= 1'b1;
        end 
        else begin                              //�����ұ߽磬ˮƽ����  
            if(video_3_block_x == H_ActiveSize - H2_ActiveSize + 1'd1)begin
               video_3_h_direct <= 1'b0; 
            end
            else begin
                video_3_h_direct <= video_3_h_direct;
            end
        end
 
        if (video_3_block_y == 0 + 1'b1) begin     //�����ϱ߽磬��ֱ����
            video_3_v_direct <= 1'b1;
        end 
        else begin                              //�����±߽磬��ֱ����
            if(video_3_block_y == V_ActiveSize - V2_ActiveSize + 1'b1)begin                          
               video_3_v_direct <= 1'b0;                           
            end
            else begin
                video_3_v_direct <= video_3_v_direct;
            end
        end 
    end
 end





//������Ƶ���ƶ����򣬸ı��������
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_0_block_x <= VTC0_X ;               //��ʼλ�ú�����
        video_0_block_y <= VTC0_Y ;               //��ʼλ��������
    end 
    else if(move_en == 1'b1)begin
        if (video_0_h_direct == 1'b1) begin
            video_0_block_x <= video_0_block_x + 1'b1;          //�����ƶ�
        end 
        else begin
            video_0_block_x <= video_0_block_x -1'b1;           //�����ƶ�
        end
 
        if (video_0_v_direct == 1'b1) begin
            video_0_block_y <= video_0_block_y + 1'b1;          //�����ƶ�    
        end 
        else begin
            video_0_block_y <= video_0_block_y -1'b1;           //�����ƶ�
        end
    end
    else begin
        video_0_block_x <= video_0_block_x;
        video_0_block_y <= video_0_block_y;
    end
end

//������Ƶ���ƶ����򣬸ı��������
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_1_block_x <= VTC1_X ;               //��ʼλ�ú�����
        video_1_block_y <= VTC1_Y ;               //��ʼλ��������
    end 
    else if(move_en == 1'b1)begin
        if (video_1_h_direct == 1'b1) begin
            video_1_block_x <= video_1_block_x + 1'b1;          //�����ƶ�
        end 
        else begin
            video_1_block_x <= video_1_block_x -1'b1;           //�����ƶ�
        end
 
        if (video_1_v_direct == 1'b1) begin
            video_1_block_y <= video_1_block_y + 1'b1;          //�����ƶ�    
        end 
        else begin
            video_1_block_y <= video_1_block_y -1'b1;           //�����ƶ�
        end
    end
    else begin
        video_1_block_x <= video_1_block_x;
        video_1_block_y <= video_1_block_y;
    end
end

//������Ƶ���ƶ����򣬸ı��������
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_2_block_x <= VTC2_X ;               //��ʼλ�ú�����
        video_2_block_y <= VTC2_Y ;               //��ʼλ��������
    end 
    else if(move_en == 1'b1)begin
        if (video_2_h_direct == 1'b1) begin
            video_2_block_x <= video_2_block_x + 1'b1;          //�����ƶ�
        end 
        else begin
            video_2_block_x <= video_2_block_x -1'b1;           //�����ƶ�
        end
 
        if (video_2_v_direct == 1'b1) begin
            video_2_block_y <= video_2_block_y + 1'b1;          //�����ƶ�    
        end 
        else begin
            video_2_block_y <= video_2_block_y -1'b1;           //�����ƶ�
        end
    end
    else begin
        video_2_block_x <= video_2_block_x;
        video_2_block_y <= video_2_block_y;
    end
end

//������Ƶ���ƶ����򣬸ı��������
always @(posedge I_vtc_clk or negedge I_video_move_en ) begin
    if (!I_video_move_en) begin 
        video_3_block_x <= VTC3_X ;               //��ʼλ�ú�����
        video_3_block_y <= VTC3_Y ;               //��ʼλ��������
    end 
    else if(move_en == 1'b1)begin
        if (video_3_h_direct == 1'b1) begin
            video_3_block_x <= video_3_block_x + 1'b1;          //�����ƶ�
        end 
        else begin
            video_3_block_x <= video_3_block_x -1'b1;           //�����ƶ�
        end
 
        if (video_3_v_direct == 1'b1) begin
            video_3_block_y <= video_3_block_y + 1'b1;          //�����ƶ�    
        end 
        else begin
            video_3_block_y <= video_3_block_y -1'b1;           //�����ƶ�
        end
    end
    else begin
        video_3_block_x <= video_3_block_x;
        video_3_block_y <= video_3_block_y;
    end
end






wire hs0_valid  =  (hcnt>=video_0_block_x)&& (hcnt<(video_0_block_x+H2_ActiveSize));
wire vs0_valid  =  (vcnt>=video_0_block_y)&& (vcnt<(video_0_block_y+V2_ActiveSize));
wire hs1_valid  =  (hcnt>=video_1_block_x)&& (hcnt<(video_1_block_x+H2_ActiveSize));
wire vs1_valid  =  (vcnt>=video_1_block_y)&& (vcnt<(video_1_block_y+V2_ActiveSize));
wire hs2_valid  =  (hcnt>=video_2_block_x)&& (hcnt<(video_2_block_x+H2_ActiveSize));
wire vs2_valid  =  (vcnt>=video_2_block_y)&& (vcnt<(video_2_block_y+V2_ActiveSize));
wire hs3_valid  =  (hcnt>=video_3_block_x)&& (hcnt<(video_3_block_x+H2_ActiveSize));
wire vs3_valid  =  (vcnt>=video_3_block_y)&& (vcnt<(video_3_block_y+V2_ActiveSize));

wire vtc0_de    =  hs0_valid && vs0_valid;
wire vtc1_de    =  hs1_valid && vs1_valid;
wire vtc2_de    =  hs2_valid && vs2_valid;
wire vtc3_de    =  hs3_valid && vs3_valid;


reg O_vtc_de;


//��һ�μĴ��������������ڸ���ʱ��������ڸ߷ֱ��ʣ����ٵ��źţ����Ŀ��Ը����ڲ�ʱ���������ڸ����ٶ�
always @(posedge I_vtc_clk)begin
	if(rst_sync == 1'b0)begin
		O_vtc_vs <= 1'b0;
		O_vtc_hs <= 1'b0;
		O_vtc_de <= 1'b0;
		O_vtc0_de <= 1'b0;
		O_vtc1_de <= 1'b0;
		O_vtc2_de <= 1'b0;
		O_vtc3_de <= 1'b0;
	end
    else begin
        O_vtc_vs <= vtc_vs; //��ͬ���źŴ������
		O_vtc_hs <= vtc_hs; //��ͬ���źŴ������
        O_vtc_de <= vtc_de;	//��Ƶ��Ч�źŴ������
        O_vtc0_de <= vtc0_de;	
		O_vtc1_de <= vtc1_de;	
		O_vtc2_de <= vtc2_de;	
		O_vtc3_de <= vtc3_de;	
          
    end
end


always @(posedge I_vtc_clk)begin
    if (rst_sync == 1'b0) begin
        O_vtc_data<=32'd0;
    end else if (O_vtc3_de) begin
        O_vtc_data<=I_rd_ddr_data_3;
    end else if (O_vtc2_de) begin
        O_vtc_data<=I_rd_ddr_data_2;
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


