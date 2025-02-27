--------------------------------------------------------------
 --  Copyright (c) 2012-2024 Anlogic Inc. --  All Right Reserved.
--------------------------------------------------------------
 -- Log	:	This file is generated by Anlogic IP Generator.
 -- File	:	C:/HIT/personal_learn/open_source/04_video_rotate_180/user_source/hdl_source/uifdmadbuf/ram_rd_buf/ram_rd_buf.vhd
 -- Date	:	2025 01 15
 -- TD version	:	6.0.117864
--------------------------------------------------------------

LIBRARY ieee;
USE work.ALL;
	USE ieee.std_logic_1164.all;
LIBRARY ph1_macro;
	USE ph1_macro.PH1_COMPONENTS.all;

ENTITY ram_rd_buf IS
PORT (
	dob	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

	dia	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	addra	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
	wea	: IN STD_LOGIC;
	clka	: IN STD_LOGIC;
	addrb	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
	clkb	: IN STD_LOGIC
	);
END ram_rd_buf;

ARCHITECTURE struct OF ram_rd_buf IS

	BEGIN
	inst : PH1_LOGIC_ERAM
		GENERIC MAP (
			DATA_WIDTH_A	=> 16,
			DATA_WIDTH_B	=> 16,
			ADDR_WIDTH_A	=> 10,
			ADDR_WIDTH_B	=> 10,
			DATA_DEPTH_A	=> 1024,
			DATA_DEPTH_B	=> 1024,
			MODE		=> "PDPW",
			REGMODE_A	=> "NOREG",
			REGMODE_B	=> "NOREG",
			WRITEMODE_A	=> "NORMAL",
			WRITEMODE_B	=> "NORMAL",
			IMPLEMENT	=> "20K",
			CLKMODE		=> "ASYNC",
			ECC_ENCODE		=> "DISABLE",
			ECC_DECODE		=> "DISABLE",
			SSROVERCE		=> "DISABLE",
			OREGSET_A		=> "SET",
			OREGSET_B		=> "SET",
			RESETMODE_A		=> "ASYNC",
			RESETMODE_B		=> "ASYNC",
			ASYNC_RESET_RELEASE_A		=> "SYNC",
			ASYNC_RESET_RELEASE_B		=> "SYNC",
			INIT_FILE		=> "NONE",
			FILL_ALL		=> "NONE"
		)
		PORT MAP (
			dia	=> dia,
			dib	=> (others=>'0'),
			addra	=> addra,
			addrb	=> addrb,
			cea	=> '1',
			ceb	=> '1',
			clka	=> clka,
			clkb	=> clkb,
			wea	=> wea,
			web	=> '0',
			bea	=> (others=>'0'),
			beb	=> (others=>'0'),
			ocea	=> '0',
			oceb	=> '0',
			rsta	=> '0',
			rstb	=> '0',
			ecc_sbiterr	=> OPEN,
			ecc_dbiterr	=> OPEN,
			ecc_sbiterrinj	=> OPEN,
			ecc_dbiterrinj	=> OPEN,
			doa	=> OPEN,
			dob	=> dob
		);

END struct;
