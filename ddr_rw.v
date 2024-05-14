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
    output                  ui_clk              , // 用户时钟，这里是100MHz
    output                  init_calib_complete , // ddr3 初始化和校准完成信号  
    // 外部控制接口
    input   [ 24:0]         begin_addr          , // ddr 读写开始地址
    input                   rw                  , // ddr 读写标志，1读 0写
    input   [  1:0]         mask_switch         , // 00不遮掩 01高位有效 10低位有效
    input   [127:0]         wr_data             , // ddr 待写数据
    input   [ 15:0]         wr_data_len         , // 突发长度
    input                   exc                 , // 执行标志
    output  [127:0]         rd_data             , // ddr 读取的数据
    output  [ 24:0]         end_addr              // ddr 读写结束时的地址
);
// parameter define
// 调试用，一个英文字母占8个bit
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
wire [ 15:0]        app_wdf_mask      ; // 应用写数据掩码
wire [ 27:0]        app_addr          ; // 应用地址
wire [  2:0]        app_cmd           ; // 应用命令，读001，写000
wire                app_en            ; // 应用使能
wire [127:0]        app_wdf_data      ; // 应用写数据
wire                app_wdf_end       ; // 应用写数据结束
wire                app_wdf_wren      ; // 应用写使能
wire                app_rdy           ; // 应用就绪
wire                app_wdf_rdy       ; // 应用写数据就绪
wire [127:0]        app_rd_data       ; // 应用读数据
wire                app_rd_data_valid ; // 应用读数据有效
wire                ui_clk_sync_rst   ; // 用户同步复位

//              main code
// -------------------------------< 组合逻辑 >-----------------------------
assign app_wdf_mask = (mask_switch = 2'b01) ? 16'h00ff : ((mask_switch = 2'b10) ? 16'hff00 : 16'h0000);
assign app_cmd = ddr_rw ? 3'd1 : 3'd0;
assign app_wdf_data = (mask_switch = 2'b01) ? {wr_data[63:0], {64{1'd0}}} : ((mask_switch = 2'b10) ? {{64{1'd0}}, wr_data[63:0]} : wr_data[127:0]);
assign app_wdf_end = app_wdf_wren; // 4:1速率下这两者一致

// 状态机 状态判断
always @(*)begin
    case (cur_state)
        IDLE :   next_state = skip ? (rw ? READ : WRITE) : IDLE;
        WRITE:   next_state = skip ? IDLE : WRITE;
        READ :   next_state = skip ? WAIT : READ;
        WAIT :   next_state = skip ? IDLE : WAIT;
        default: next_state = IDLE;
    endcase
end

// -------------------------------< 时序逻辑 >-----------------------------
// 状态机 状态转移
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)
        cur_state <= IDLE;
    else
        cur_state <= next_state;
end

// 状态机 状态输出
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
                // 每次读写开始前的初始化
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





// mig ip核调用
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
