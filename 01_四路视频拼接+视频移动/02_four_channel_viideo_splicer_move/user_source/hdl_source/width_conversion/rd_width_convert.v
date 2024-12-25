/*
 * @Author: bit_stream 
 * @Date: 2024-12-07 16:30:20 
 * @Last Modified by:   bit_stream 
 * @Last Modified time: 2024-12-07 16:30:20 
 */

//此模块的作用是把RGB88格式的数据转换为两个RGB565格式的数据
module rd_width_convert(
    input wire [15:0] I_rd_data,

    output wire [31:0] O_rd_data
);


assign O_rd_data ={8'd0,I_rd_data[15:11], 3'd0, I_rd_data[10:5], 2'd0,I_rd_data[4:0], 3'd0} ;


    
endmodule 

