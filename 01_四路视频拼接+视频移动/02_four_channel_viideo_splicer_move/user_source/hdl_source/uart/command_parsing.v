/*
 * @Author: bit_stream 
 * @Date: 2024-12-12 19:11:31 
 * @Last Modified by:   bit_stream 
 * @Last Modified time: 2024-12-12 19:11:31 
 */

module command_parsing(
    input wire clk,
    input wire rst_n,
    input wire I_command_flag,
    input wire [3:0]  I_ctrl_command ,
    input wire [3:0]  I_value_command,

    output reg O_video_move_en     
);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        O_video_move_en <= 'd0;   
    end
    else if((I_ctrl_command == 4'b0000) && (I_command_flag == 1'b1)) begin //视频移动命令： 00 复位，回到初始位置 01 移动使能  
        O_video_move_en <= I_value_command[0];
    end 
end



    
endmodule //command_parsing
