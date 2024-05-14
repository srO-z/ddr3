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
    input                   sys_rst_n           , // ��λ���͵�ƽ��Ч
    // ddr3 ��·�ӿ� ---------------------------------------------------------------
    inout   [15:0]          ddr3_dq             , // ddr3 ������
    inout   [ 1:0]          ddr3_dqs_n          , // ddr3 ����ѡͨ���ź�
    inout   [ 1:0]          ddr3_dqs_p          , // ddr3 ����ѡͨ���ź�
    output  [13:0]          ddr3_addr           , // ddr3 ��ַ��
    output  [ 2:0]          ddr3_ba             , // ddr3 Bank��ַ
    output                  ddr3_ras_n          , // ddr3 �е�ַѡͨ�źţ��͵�ƽ��Ч
    output                  ddr3_cas_n          , // ddr3 �е�ַѡͨ�źţ��͵�ƽ��Ч
    output                  ddr3_we_n           , // ddr3 дʹ���źţ��͵�ƽ��Ч
    output                  ddr3_reset_n        , // ddr3 ��λ�źţ��͵�ƽ��Ч
    output                  ddr3_ck_p           , // ddr3 ʱ�����ź�
    output                  ddr3_ck_n           , // ddr3 ʱ�Ӹ��ź�
    output                  ddr3_cke            , // ddr3 ʱ��ʹ��
    output                  ddr3_cs_n           , // ddr3 Ƭѡ�źţ��͵�ƽ��Ч
    output  [ 1:0]          ddr3_dm             , // ddr3 ��������
    output                  ddr3_odt            , // ddr3 �������ʹ��
    // ddr3 Ӧ�ýӿ� ---------------------------------------------------------------
    output                  ui_clk              , // �û�ʱ��
    output                  ui_clk_sync_rst     , // �û�ͬ����λ
    output                  init_calib_complete , // ddr3 ��ʼ����У׼����ź�
    input   [ 15:0]         app_wdf_mask        , // Ӧ��д��������
    input   [ 27:0]         app_addr            , // Ӧ�õ�ַ
    input   [  2:0]         app_cmd             , // Ӧ�������001��д000
    input                   app_en              , // Ӧ��ʹ��
    input   [127:0]         app_wdf_data        , // Ӧ��д����
    input                   app_wdf_end         , // Ӧ��д���ݽ���
    input                   app_wdf_wren        , // Ӧ��дʹ��
    output                  app_rdy             , // Ӧ�þ���
    output                  app_wdf_rdy         , // Ӧ��д���ݾ���
    output  [127:0]         app_rd_data         , // Ӧ�ö�����
    output                  app_rd_data_valid     // Ӧ�ö�������Ч
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
