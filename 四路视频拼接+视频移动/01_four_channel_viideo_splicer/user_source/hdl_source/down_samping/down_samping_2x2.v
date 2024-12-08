/*
 * @Author: bit_stream 
 * @Date: 2024-12-07 16:33:13 
 * @Last Modified by: bit_stream
 * @Last Modified time: 2024-12-07 16:33:33
 */


module down_samping_2x2#(
parameter   [13:0]  H_SIZE = 1920,    
parameter   [13:0]  V_SIZE = 1080
)
(
    input wire I_clk,
    input wire I_rst_n,

    input wire I_rgb_vs,
    input wire I_rgb_de,
    input wire [31:0] I_rgb_data,

    output reg O_rgb_vs,
    output reg O_rgb_de,
    output reg [31:0] O_rgb_data

);

reg [11:0] col_count, row_count;


wire vs_up_edge;

assign vs_up_edge  = I_rgb_vs &(~O_rgb_vs) ;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        col_count <= 0;
    end else if (vs_up_edge) begin
        col_count <= 0;
    end else if (I_rgb_de) begin
         if (col_count == (H_SIZE- 1)) begin
            col_count <= 0;
         end else begin
            col_count <= col_count + 1;
         end
    end else begin
        col_count<=col_count;
    end
end

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        row_count <= 0;
    end else if (vs_up_edge) begin
        row_count <= 0;
    end else if (I_rgb_de) begin
         if (row_count == (V_SIZE - 1) && col_count == (H_SIZE - 1)) begin
            row_count <= 0;
         end else if (col_count == (H_SIZE- 1)) begin
            row_count <= row_count + 1;
         end
    end else begin
        row_count<=row_count;
    end
end


reg sample_select;
// wire sample_select;

// assign sample_select = (col_count % 2 == 0) && (row_count % 2 == 0);

always @(*) begin
    if(!I_rst_n) begin
        sample_select<=1'b0;
    end else begin
        sample_select <= (col_count % 2 == 0) && (row_count % 2 == 0);  
    end
end

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        O_rgb_vs <= 0;
    end else  begin
        O_rgb_vs<=I_rgb_vs;
    end
end

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        O_rgb_de <= 0;
    end else if(I_rgb_de) begin
        O_rgb_de<=sample_select;
    end else begin
        O_rgb_de<=0;
    end
end

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        O_rgb_data <= 'd0;
    end else if(sample_select) begin
        O_rgb_data<=I_rgb_data;
    end
end





endmodule //video_samping
