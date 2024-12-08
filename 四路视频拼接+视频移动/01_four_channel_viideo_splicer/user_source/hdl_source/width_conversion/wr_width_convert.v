/*
 * @Author: bit_stream 
 * @Date: 2024-12-07 16:30:27 
 * @Last Modified by:   bit_stream 
 * @Last Modified time: 2024-12-07 16:30:27 
 */


//此模块的作用是把RGB88格式的数据转换为两个RGB565格式的数据
module wr_width_convert(
    input wire [31:0] I_wr_data,

    output wire [15:0] O_wr_data
);

assign O_wr_data = {I_wr_data[23:19],I_wr_data[15:10],I_wr_data[7:3]};

endmodule 

