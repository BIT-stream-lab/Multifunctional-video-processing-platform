
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2023/03/23
*Module Name:
*File Name:
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.1
*Signal description
*1) I_ input
*2) O_ output
*3) IO_ input output
*3) S_ system internal signal
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/
`timescale 1ns / 1ps

module uisetvbuf#(
parameter  integer                  BUF_DELAY     = 1,
parameter  integer                  BUF_LENTH     = 3
)
(

input      [7   :0]                 I_bufn,
output     [7   :0]                 O_bufn
);   



assign O_bufn = I_bufn < BUF_DELAY?  (BUF_LENTH - BUF_DELAY + I_bufn) : (I_bufn - BUF_DELAY) ;


endmodule

