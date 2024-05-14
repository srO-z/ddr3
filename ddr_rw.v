`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/14 16:33:10
// Design Name: 
// Module Name: ddr_rw
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


module ddr_rw(
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
    output                  ui_clk              , // �û�ʱ�ӣ�������100MHz
    output                  init_calib_complete , // ddr3 ��ʼ����У׼����ź�  
    // �ⲿ���ƽӿ�
    input   [ 24:0]         begin_addr          , // ddr ��д��ʼ��ַ
    input                   rw                  , // ddr ��д��־��1�� 0д
    input   [  1:0]         mask_switch         , // 00������ 01��λ��Ч 10��λ��Ч
    input   [127:0]         wr_data             , // ddr ��д����
    input   [ 15:0]         wr_data_len         , // ͻ������
    input                   exc                 , // ִ�б�־
    output  [127:0]         rd_data             , // ddr ��ȡ������
    output  [ 24:0]         end_addr              // ddr ��д����ʱ�ĵ�ַ
);
// parameter define
// �����ã�һ��Ӣ����ĸռ8��bit
localparam
    IDLE  = "idle" ,
    WRITE = "write",
    READ  = "read" ,
    WAIT  = "wait" ;

// reg define
reg [39:0] cur_state, next_state;
reg [ 7:0] cnt;
reg        skip;
// wire define
wire [ 15:0]        app_wdf_mask      ; // Ӧ��д��������
wire [ 27:0]        app_addr          ; // Ӧ�õ�ַ
wire [  2:0]        app_cmd           ; // Ӧ�������001��д000
wire                app_en            ; // Ӧ��ʹ��
wire [127:0]        app_wdf_data      ; // Ӧ��д����
wire                app_wdf_end       ; // Ӧ��д���ݽ���
wire                app_wdf_wren      ; // Ӧ��дʹ��
wire                app_rdy           ; // Ӧ�þ���
wire                app_wdf_rdy       ; // Ӧ��д���ݾ���
wire [127:0]        app_rd_data       ; // Ӧ�ö�����
wire                app_rd_data_valid ; // Ӧ�ö�������Ч
wire                ui_clk_sync_rst   ; // �û�ͬ����λ

//              main code
// -------------------------------< ����߼� >-----------------------------
assign app_wdf_mask = (mask_switch = 2'b01) ? 16'h00ff : ((mask_switch = 2'b10) ? 16'hff00 : 16'h0000);
assign app_cmd = ddr_rw ? 3'd1 : 3'd0;
assign app_wdf_data = (mask_switch = 2'b01) ? {wr_data[63:0], {64{1'd0}}} : ((mask_switch = 2'b10) ? {{64{1'd0}}, wr_data[63:0]} : wr_data[127:0]);
assign app_wdf_end = app_wdf_wren; // 4:1������������һ��

// ״̬�� ״̬�ж�
always @(*)begin
    case (cur_state)
        IDLE :   next_state = skip ? (rw ? READ : WRITE) : IDLE;
        WRITE:   next_state = skip ? IDLE : WRITE;
        READ :   next_state = skip ? WAIT : READ;
        WAIT :   next_state = skip ? IDLE : WAIT;
        default: next_state = IDLE;
    endcase
end

// -------------------------------< ʱ���߼� >-----------------------------
// ״̬�� ״̬ת��
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)
        cur_state <= IDLE;
    else
        cur_state <= next_state;
end

// ״̬�� ״̬���
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)begin
        cnt <= 8'd0;
        skip <= 1'd0;
        rd_data <= 128'd0;
        end_addr <= 25'd0;
    end
    else begin
        skip <= 1'd0;
        case (next_state)
            IDLE: begin
                skip <= (init_calib_complete && exc) ? 1'd1 : 1'd0;
                // ÿ�ζ�д��ʼǰ�ĳ�ʼ��
                app_addr <= {3'd0, begin_addr};
                // ...
            end 
            WRITE: begin
                if(app_rdy && app_wdf_rdy)begin
                    cnt <= cnt + 8'd1;
                    case (cnt)
                        8'd0: begin
                            app_en <= 1'd1;
                            app_wdf_wren <= 1'd1;
                        end
                        8'd7: app_en <= 1'd0;
                        8'd8: begin
                            app_en <= 1'd1;
                        end
                    endcase
                end
            end
        endcase
    end
end





// mig ip�˵���
ddr_ctrl u_ddr_ctrl(
    .clk_200m               (clk_200m           ),
    .sys_rst_n              (sys_rst_n          ),
    .ddr3_dq                (ddr3_dq            ),
    .ddr3_dqs_n             (ddr3_dqs_n         ),
    .ddr3_dqs_p             (ddr3_dqs_p         ),
    .ddr3_addr              (ddr3_addr          ),
    .ddr3_ba                (ddr3_ba            ),
    .ddr3_ras_n             (ddr3_ras_n         ),
    .ddr3_cas_n             (ddr3_cas_n         ),
    .ddr3_we_n              (ddr3_we_n          ),
    .ddr3_reset_n           (ddr3_reset_n       ),
    .ddr3_ck_p              (ddr3_ck_p          ),
    .ddr3_ck_n              (ddr3_ck_n          ),
    .ddr3_cke               (ddr3_cke           ),
    .ddr3_cs_n              (ddr3_cs_n          ),
    .ddr3_dm                (ddr3_dm            ),
    .ddr3_odt               (ddr3_odt           ),
    .ui_clk                 (ui_clk             ),
    .ui_clk_sync_rst        (ui_clk_sync_rst    ),
    .init_calib_complete    (init_calib_complete),
    .app_wdf_mask           (app_wdf_mask       ),
    .app_addr               (app_addr           ),
    .app_cmd                (app_cmd            ),
    .app_en                 (app_en             ),
    .app_wdf_data           (app_wdf_data       ),
    .app_wdf_end            (app_wdf_end        ),
    .app_wdf_wren           (app_wdf_wren       ),
    .app_rdy                (app_rdy            ),
    .app_wdf_rdy            (app_wdf_rdy        ),
    .app_rd_data            (app_rd_data        ),
    .app_rd_data_valid      (app_rd_data_valid  )
);
endmodule
