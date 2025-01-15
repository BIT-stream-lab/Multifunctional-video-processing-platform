/************************************************************\
 **  Copyright (c) 2012-2024 Anlogic Inc.
 **  All Right Reserved.\
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	C:/HIT/personal_learn/open_source/04_video_rotate_180/user_source/hdl_source/uifdmadbuf/ram_rd_buf/ram_rd_buf.v
 ** Date	:	2025 01 15
 ** TD version	:	6.0.117864
\************************************************************/

`timescale 1ns / 1ps

module ram_rd_buf ( 
	dia, addra, clka, wea,
	dob, addrb, clkb
);


	parameter DATA_WIDTH_A = 16; 
	parameter ADDR_WIDTH_A = 10;
	parameter DATA_DEPTH_A = 1024;
	parameter DATA_WIDTH_B = 16;
	parameter ADDR_WIDTH_B = 10;
	parameter DATA_DEPTH_B = 1024;
	parameter REGMODE_A    = "NOREG";
	parameter REGMODE_B    = "NOREG";
	parameter WRITEMODE_A  = "NORMAL";
	parameter WRITEMODE_B  = "NORMAL";
	parameter RESETMODE_A  = "ASYNC";
	parameter RESETMODE_B  = "ASYNC";

	output [DATA_WIDTH_B-1:0] dob;


	input  [DATA_WIDTH_A-1:0] dia;
	input  [ADDR_WIDTH_A-1:0] addra;
	input  [ADDR_WIDTH_B-1:0] addrb;
	input  wea;
	input  clka;
	input  clkb;



	PH1_LOGIC_ERAM #( .DATA_WIDTH_A(DATA_WIDTH_A),
				.DATA_WIDTH_B(DATA_WIDTH_B),
				.ADDR_WIDTH_A(ADDR_WIDTH_A),
				.ADDR_WIDTH_B(ADDR_WIDTH_B),
				.DATA_DEPTH_A(DATA_DEPTH_A),
				.DATA_DEPTH_B(DATA_DEPTH_B),
				.MODE("PDPW"),
				.REGMODE_A(REGMODE_A),
				.REGMODE_B(REGMODE_B),
				.WRITEMODE_A(WRITEMODE_A),
				.WRITEMODE_B(WRITEMODE_B),
				.IMPLEMENT("20K"),
				.ECC_ENCODE("DISABLE"),
				.ECC_DECODE("DISABLE"),
				.CLKMODE("ASYNC"),
				.SSROVERCE("DISABLE"),
				.OREGSET_A("SET"),
				.OREGSET_B("SET"),
				.RESETMODE_A(RESETMODE_A),
				.RESETMODE_B(RESETMODE_B),
				.ASYNC_RESET_RELEASE_A("SYNC"),
				.ASYNC_RESET_RELEASE_B("SYNC"),
				.INIT_FILE("NONE"),
				.FILL_ALL("NONE"))
			inst(
				.dia(dia),
				.dib({16{1'b0}}),
				.addra(addra),
				.addrb(addrb),
				.cea(1'b1),
				.ceb(1'b1),
				.ocea(1'b0),
				.oceb(1'b0),
				.clka(clka),
				.clkb(clkb),
				.wea(wea),
				.web(1'b0),
				.bea(1'b0),
				.beb(1'b0),
				.rsta(1'b0),
				.rstb(1'b0),
				.ecc_sbiterr(),
				.ecc_dbiterr(),
				.ecc_sbiterrinj('d0),
				.ecc_dbiterrinj('d0),
				.doa(),
				.dob(dob));


endmodule