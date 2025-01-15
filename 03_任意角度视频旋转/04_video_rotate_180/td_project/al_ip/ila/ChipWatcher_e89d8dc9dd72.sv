     
module ChipWatcher_e89d8dc9dd72 ( 
    input [9:0] probe0, 
    input [0:0] probe1, 
    input [14:0] probe2, 
    input [9:0] probe3, 
    input [0:0] probe4, 
    input [14:0] probe5, 
    input       clk  
); 
    localparam CWC_BUS_NUM = 6;
    localparam CWC_BUS_DIN_NUM = 52;
    localparam INPUT_PIPE_NUM = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_LEN = 52;
    localparam RAM_DATA_DEPTH = 4096;

    
    localparam integer CWC_BUS_WIDTH[0:CWC_BUS_NUM-1] = {15,1,10,15,1,10};
    localparam integer CWC_BUS_DIN_POS[0:CWC_BUS_NUM-1] = {0,15,16,26,41,42};    
    localparam integer CWC_BUS_CTRL_POS[0:CWC_BUS_NUM-1] = {0,34,40,64,98,104};    

    parameter STAT_REG_LEN = 24;
    parameter BUS_CTRL_NUM = CWC_BUS_NUM*4 + CWC_BUS_DIN_NUM*2 + 36;

    wire                     cwc_rst;
    wire [BUS_CTRL_NUM-1:0]  cwc_control;
    wire [STAT_REG_LEN-1:0]  cwc_status;  

	top_cwc_hub #(
		.CWC_BUS_NUM(CWC_BUS_NUM),
		.CWC_BUS_DIN_NUM(CWC_BUS_DIN_NUM),
		.CWC_BUS_WIDTH(CWC_BUS_WIDTH),
		.CWC_BUS_DIN_POS(CWC_BUS_DIN_POS),
		.CWC_BUS_CTRL_POS(CWC_BUS_CTRL_POS),
		.RAM_DATA_DEPTH(RAM_DATA_DEPTH),
		.RAM_LEN(RAM_LEN),
		.INPUT_PIPE_NUM(INPUT_PIPE_NUM),
		.OUTPUT_PIPE_NUM(OUTPUT_PIPE_NUM)
	)

	 wrapper_cwc_top(
		.cwc_trig_clk(clk),
		.cwc_control(cwc_control),
		.cwc_status(cwc_status),
		.cwc_rst(cwc_rst),
		.cwc_bus_din({probe0,probe1,probe2,probe3,probe4,probe5}),
		.ram_data_din({probe0,probe1,probe2,probe3,probe4,probe5})
	);

    AL_LOGIC_DEBUGHUB #(
		.CTRL_LEN(BUS_CTRL_NUM),
		.STAT_LEN(STAT_REG_LEN)
	) wrapper_debughub(
		.clk(clk),
		.control(cwc_control),
		.status(cwc_status),
		.rst(cwc_rst)
	);

endmodule


