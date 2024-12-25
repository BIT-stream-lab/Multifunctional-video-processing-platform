
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2019/12/17
*Module Name:uiuart_tx
*File Name:uiuart_tx.v
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.0
*Signal description
*1) I_ input
*2) O_ output
*3)IO_ input output
*4) S_ state mechine
*5) _n activ low
*6) _dg debug signal 
*7) _r delay or register
*********************************************************************/

/*******************************UART����������*********************
--��������������Ƶ�UART����������
--1.�����࣬ռ�ü����߼���Դ������ṹ�������߼�����Ͻ�
--2.I_uart_wreq���û�����ͨ������I_uart_wreqΪ�ߣ�����UART�������������������ݣ�UART������������I_uart_wdata����ͨ��UART TX���߷��ͳ�ȥ
--3.O_uart_wbusy,��ʾ��ǰUART����������æ�����ʱ���û�������Ҫ�ȴ���æ��ʱ�����������ݡ�
*********************************************************************/

`timescale 1ns / 1ns//����ʱ��̶�/����


module uiuart_tx#
(
 parameter integer BAUD_DIV     = 10416                           //���ò���ϵ�� ��ʱ��/������-1��
)
(
    input        I_clk,       //ϵͳʱ������
    input        I_uart_rstn, //ϵͳ��λ����
    input        I_uart_wreq, //������������   
    input [7:0]  I_uart_wdata,//��������      
    output       O_uart_wbusy,//����״̬æ���������ڷ�������   
    output       O_uart_tx    //uart tx ��������
);

localparam  UART_LEN = 4'd10; //����uart ���͵�bit����Ϊ10������1bit��ʼλ��8bits����,1bitֹͣλ
wire        bps_en ; //����ʹ��
reg         uart_wreq_r   = 1'b0;//�Ĵ�һ��I_uart_wreq
reg         bps_start_en    = 1'b0; //�����ʼ���������ʹ�ܣ�Ҳ�Ƿ�������ʹ��
reg [13:0]  baud_div        = 14'd0;//�����ʼ�����
reg [9 :0]  uart_wdata_r  = 10'h3ff;//�Ĵ�I_uart_wreq
reg [3 :0]  tx_cnt          = 4'd0;//���������˶���bits

assign O_uart_tx = uart_wdata_r[0];//�����ϵ����ݣ�ʼ����uart_wdata_r[0]

assign O_uart_wbusy = bps_start_en;//����æ��־������bps_start_enΪ��Ч����������æ�ڷ��ͣ�����æ

// ����ʹ��
assign bps_en = (baud_div == BAUD_DIV);                 //����һ�η���ʹ���źţ�������baud_div == BAUD_DIV�������ʼ������

//�����ʼ�����
always@(posedge I_clk )begin
    if((I_uart_rstn== 1'b0) || (I_uart_wreq==1'b1&uart_wreq_r==1'b0))begin
        baud_div <= 14'd0;
    end
    else begin
        if(bps_start_en && baud_div < BAUD_DIV)        //bps_start_en���ź����ߣ���ʾ��ʼ���� 
           baud_div <= baud_div + 1'b1;                //��baud_div < BAUD_DIV�����ʼ��㣬δ�ﵽ������baud_div+1
        else 
            baud_div <= 14'd0;                         //�ﵽ����
    end
end

always@(posedge I_clk)begin
    uart_wreq_r <= I_uart_wreq;                           //�Ĵ�һ��I_uart_wreq�ź�
end

//��I_uart_wreq�ӵ͵�ƽ��Ϊ�ߵ�ƽ����������
always@(posedge I_clk)begin
    if(I_uart_rstn == 1'b0)
        bps_start_en    <= 1'b0;                           //��λ����������
    else if(I_uart_wreq==1'b1&uart_wreq_r==1'b0)          //I_uart_wreq�����ؼ���
        bps_start_en    <= 1'b1;                           //����� bps_start_en���ߣ����俪ʼ
    else if(tx_cnt == UART_LEN)                            //tx_cnt���ڼ�����ǰ���͵�bits���������ﵽԤ��ֵUART_LEN
        bps_start_en    <= 1'b0;                           //�� bps_start_en���ͣ��������
    else 
        bps_start_en    <= bps_start_en;                    
end

//����bits������
always@(posedge I_clk)begin
    if(((I_uart_rstn== 1'b0) || (I_uart_wreq==1'b1&uart_wreq_r==1'b0))||(tx_cnt == 10))//����λ���������͡�������ɣ�����tx_cnt
        tx_cnt <=4'd0;
    else if(bps_en && (tx_cnt < UART_LEN))   //tx_cnt��������ÿ����һ��bit��1
        tx_cnt <= tx_cnt + 1'b1;
end

//uart���Ͳ�����λ������
always@(posedge I_clk)begin
    if((I_uart_wreq==1'b1&uart_wreq_r==1'b0)) //������������Ч���Ĵ���Ҫ���͵����ݵ�uart_wdata_r
        uart_wdata_r  <= {1'b1,I_uart_wdata[7:0],1'b0};//�Ĵ���Ҫ���͵����ݣ�����1bit ��ʼλ��8bits���ݣ�1bitֹͣλ
    else if(bps_en && (tx_cnt < (UART_LEN - 1'b1)))                               //shift 9 bits
        uart_wdata_r <= {uart_wdata_r[0],uart_wdata_r[9:1]};                     //����ת�����������������δ���
    else 
        uart_wdata_r <= uart_wdata_r;
end   
endmodule
