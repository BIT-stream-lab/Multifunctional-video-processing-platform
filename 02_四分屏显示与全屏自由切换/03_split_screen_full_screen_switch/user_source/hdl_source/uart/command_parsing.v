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

    output reg        O_video_move_en,     
    output reg        O_split_full_flag,//0 分屏 1 全屏     
    output reg [3:0]  O_screen_switch    
);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        O_video_move_en   <= 'd0;   
        O_split_full_flag <= 'd0;   
        O_screen_switch   <= 'd0;   
    end
    else if((I_ctrl_command == 4'b0000) && (I_command_flag == 1'b1)) begin //视频移动命令： 00 复位，回到初始位置 01 移动使能  
        O_video_move_en <= I_value_command[0];
    end else if((I_ctrl_command == 4'b0001) && (I_command_flag == 1'b1)) begin //控制分屏/全屏切换:  10 分屏显示 11 Video0全屏 12 video1全屏 13 video2全屏 14 video3全屏
        if (I_value_command == 4'd0) begin
            O_split_full_flag <= 0;
        end else if (I_value_command == 4'd1) begin
            O_split_full_flag <= 1;
            O_screen_switch   <= 4'b0001;
        end else if (I_value_command == 4'd2) begin
            O_split_full_flag <= 1;
            O_screen_switch   <= 4'b0010;
        end else if (I_value_command == 4'd3) begin
            O_split_full_flag <= 1;
            O_screen_switch   <= 4'b0100;
        end else if (I_value_command == 4'd4) begin
            O_split_full_flag <= 1;
            O_screen_switch   <= 4'b1000;
        end 
    end 
end



    
endmodule //command_parsing
