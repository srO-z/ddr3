`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/14 16:34:00
// Design Name: 
// Module Name: ddr_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ddr_ctrl(
    // system ---------------------------------------------------------------------
    input                   clk_200m            , // 200Mhz
    input                   sys_rst_n           , // 复位，低电平有效
    // ddr3 电路接口 ---------------------------------------------------------------
    inout   [15:0]          ddr3_dq             , // ddr3 数据线
    inout   [ 1:0]          ddr3_dqs_n          , // ddr3 数据选通负信号
    inout   [ 1:0]          ddr3_dqs_p          , // ddr3 数据选通正信号
    output  [13:0]          ddr3_addr           , // ddr3 地址线
    output  [ 2:0]          ddr3_ba             , // ddr3 Bank地址
    output                  ddr3_ras_n          , // ddr3 行地址选通信号，低电平有效
    output                  ddr3_cas_n          , // ddr3 列地址选通信号，低电平有效
    output                  ddr3_we_n           , // ddr3 写使能信号，低电平有效
    output                  ddr3_reset_n        , // ddr3 复位信号，低电平有效
    output                  ddr3_ck_p           , // ddr3 时钟正信号
    output                  ddr3_ck_n           , // ddr3 时钟负信号
    output                  ddr3_cke            , // ddr3 时钟使能
    output                  ddr3_cs_n           , // ddr3 片选信号，低电平有效
    output  [ 1:0]          ddr3_dm             , // ddr3 数据掩码
    output                  ddr3_odt            , // ddr3 输出驱动使能
    // ddr3 应用接口 ---------------------------------------------------------------
    output                  ui_clk              , // 用户时钟
    output                  ui_clk_sync_rst     , // 用户同步复位
    output                  init_calib_complete , // ddr3 初始化和校准完成信号
    input   [ 15:0]         app_wdf_mask        , // 应用写数据掩码
    input   [ 27:0]         app_addr            , // 应用地址
    input   [  2:0]         app_cmd             , // 应用命令，读001，写000
    input                   app_en              , // 应用使能
    input   [127:0]         app_wdf_data        , // 应用写数据
    input                   app_wdf_end         , // 应用写数据结束
    input                   app_wdf_wren        , // 应用写使能
    output                  app_rdy             , // 应用就绪
    output                  app_wdf_rdy         , // 应用写数据就绪
    output  [127:0]         app_rd_data         , // 应用读数据
    output                  app_rd_data_valid     // 应用读数据有效
);

mig_ddr3 u_mig_ddr3 (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr           ),  // output [13:0]		ddr3_addr
    .ddr3_ba                        (ddr3_ba             ),  // output [2:0]		ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n          ),  // output			    ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n           ),  // output [0:0]		ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p           ),  // output [0:0]		ddr3_ck_p
    .ddr3_cke                       (ddr3_cke            ),  // output [0:0]		ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n          ),  // output			    ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n        ),  // output			    ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n           ),  // output			    ddr3_we_n
    .ddr3_dq                        (ddr3_dq             ),  // inout [15:0]		ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n          ),  // inout [1:0]		ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p          ),  // inout [1:0]		ddr3_dqs_p
	.ddr3_cs_n                      (ddr3_cs_n           ),  // output [0:0]		ddr3_cs_n
    .ddr3_dm                        (ddr3_dm             ),  // output [1:0]		ddr3_dm
    .ddr3_odt                       (ddr3_odt            ),  // output [0:0]		ddr3_odt

    // Application interface ports
    .init_calib_complete            (init_calib_complete ),  // output			 init_calib_complete
    .app_addr                       (app_addr            ),  // input [27:0]	 app_addr
    .app_cmd                        (app_cmd             ),  // input [2:0]		 app_cmd
    .app_en                         (app_en              ),  // input			 app_en
    .app_wdf_data                   (app_wdf_data        ),  // input [127:0]	 app_wdf_data
    .app_wdf_end                    (app_wdf_end         ),  // input			 app_wdf_end
    .app_wdf_wren                   (app_wdf_wren        ),  // input			 app_wdf_wren
    .app_rd_data                    (app_rd_data         ),  // output [127:0]	 app_rd_data
    .app_rd_data_end                (app_rd_data_end     ),  // output			 app_rd_data_end
    .app_rd_data_valid              (app_rd_data_valid   ),  // output			 app_rd_data_valid
    .app_rdy                        (app_rdy             ),  // output			 app_rdy
    .app_wdf_rdy                    (app_wdf_rdy         ),  // output			 app_wdf_rdy
    .app_sr_req                     (1'd0                ),  // input			 app_sr_req
    .app_ref_req                    (1'd0                ),  // input			 app_ref_req
    .app_zq_req                     (1'd0                ),  // input			 app_zq_req
    .app_sr_active                  (                    ),  // output			 app_sr_active
    .app_ref_ack                    (                    ),  // output			 app_ref_ack
    .app_zq_ack                     (                    ),  // output			 app_zq_ack
    .ui_clk                         (ui_clk              ),  // output			 ui_clk
    .ui_clk_sync_rst                (ui_clk_sync_rst     ),  // output			 ui_clk_sync_rst
    .app_wdf_mask                   (app_wdf_mask        ),  // input [15:0]     app_wdf_mask

    // System Clock Ports
    .sys_clk_i                      (clk_200m            ),
    .sys_rst                        (sys_rst_n           ) // input sys_rst
);
endmodule
