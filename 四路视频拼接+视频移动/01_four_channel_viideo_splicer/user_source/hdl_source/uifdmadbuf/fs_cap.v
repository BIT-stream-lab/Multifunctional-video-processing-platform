`timescale 1ns / 1ps
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop: https://milianke.taobao.com
*Create Date: 2022/09/25
*Module Name:
*File Name:
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 3.1
*Signal description
*1) _i input
*2) _o output
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/


module fs_cap#(
parameter  integer  VIDEO_ENABLE   = 1
)
(
input  I_clk,
input  I_rstn,
input  I_vs,
output reg O_fs_cap
);
    
//----CH0_CNT_FS�źŵ�ƽ���� ʵ�ʾ��ǲ���VS�ź�----------------
reg[4:0]CNT_FS   = 6'b0;
reg[4:0]CNT_FS_n = 6'b0;
reg     FS       = 1'b0;
(* ASYNC_REG = "TRUE" *)   reg vs_i_r1;
(* ASYNC_REG = "TRUE" *)   reg vs_i_r2;
(* ASYNC_REG = "TRUE" *)   reg vs_i_r3;
(* ASYNC_REG = "TRUE" *)   reg vs_i_r4;
//----ͬ�����ε�·��֮ǰ����û�����ε�·�������ǲɼ�vs����-----
always@(posedge I_clk) begin
      vs_i_r1 <= I_vs;
      vs_i_r2 <= vs_i_r1;
      vs_i_r3 <= vs_i_r2;
      vs_i_r4 <= vs_i_r3;
end

always@(posedge I_clk) begin
   if(!I_rstn)begin
      O_fs_cap <= 1'd0;
   end
   else if(VIDEO_ENABLE == 1)begin
      if({vs_i_r4,vs_i_r3} == 2'b01)begin
         O_fs_cap <= 1'b1;
      end
      else begin
         O_fs_cap <= 1'b0;
      end
   end 
   else begin
         O_fs_cap <= vs_i_r4;
   end
end
        
endmodule
