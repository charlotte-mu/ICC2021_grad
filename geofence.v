/******************************************************************/
//MODULE:		geofence
//FILE NAME:	geofence.v
//VERSION:		1.0
//DATE:			November,2021
//AUTHOR: 		Ting-Yu Mu
//CODE TYPE:	RTL
//DESCRIPTION:	2021 University/College IC Design Contest
//
//MODIFICATION HISTORY:
// Date Description
// 11/03/2021
/******************************************************************/

`define Subtractor 22
`define Multiplier 12
`define Adder 23

`define sqrt_input_bit 22
`define sqrt_output_bit 11

`define fsm_bit 5

module geofence ( clk,reset,X,Y,R,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
input [10:0] R;
output valid;
output is_inside;

//===================================

integer i;

// data_mode
parameter data_not_move = 3'd0;
parameter data_move_forward = 3'd1;
parameter data_clear = 3'd2;
parameter data_loop_forward = 3'd3;
parameter data_change = 3'd4;
parameter data_all_loop_forward = 3'd5;

//fsm
parameter data_in = `fsm_bit'd0;
parameter Cross_product_start = `fsm_bit'd1;
parameter fsm_data_change = `fsm_bit'd8;
parameter Cross_product_end = `fsm_bit'd9;
parameter Data_homing = `fsm_bit'd10;
parameter A_to_B_distance_start = `fsm_bit'd11;
parameter sqrt_AtoB_start = `fsm_bit'd16;
parameter Triangle_area_end = `fsm_bit'd19;
parameter sqrt_ssa = `fsm_bit'd20;
parameter sqrt_sbsc = `fsm_bit'd21;
parameter Triangle_area_add = `fsm_bit'd22;
parameter Polygon_area_start = `fsm_bit'd23;
parameter Data_out = `fsm_bit'd25;
parameter Clear_data = `fsm_bit'd26;

//===================================
reg [9:0]x_data[5:0];
reg [9:0]y_data[5:0];
reg [10:0]r_data[5:0];
reg [10:0]dataA,dataB,dataC,dataS;
reg [10:0]dataA_next,dataB_next,dataC_next,dataS_next;
reg [21:0]Triangle_area,Triangle_area_next;

reg [2:0]data_mode;
reg [10:0]ax,ay,bx,by;
reg [10:0]ax_next,ay_next,bx_next,by_next;
reg fit,fit_next;

reg [21:0]ax_by,ay_bx;
reg [21:0]ax_by_next,ay_bx_next;

reg [4:0]count,count_next;
reg [`fsm_bit-1:0]fsm,fsm_next;

reg [1:0]sqrt_state,sqrt_state_next;
reg [`sqrt_output_bit-1:0]sqrt_temp,sqrt_temp_next;
reg [4:0]sqrt_count,sqrt_count_next;
wire [`sqrt_output_bit-1:0]sqrt_temp_sub_count,sqrt_temp_add_count;
wire [4:0]sqrt_count_add1;

assign sqrt_temp_sub_count = sqrt_temp - (`sqrt_output_bit'h400 >> sqrt_count);
assign sqrt_temp_add_count = sqrt_temp + (`sqrt_output_bit'h400 >> sqrt_count);
assign sqrt_count_add1 = sqrt_count + 5'd1;

assign valid = (fsm == `fsm_bit'd26)? 1'b1 : 1'b0;
assign is_inside = fit;

//  Multiplier 12bit * 12bit = 24bit
reg signed [`Multiplier-1:0]xinA,xinB;
wire signed [`Multiplier*2-1:0]xans;
assign xans = xinA * xinB;

// Subtractor 22bit
reg signed[`Subtractor-1:0]sainA,sainB;
wire signed[`Subtractor-1:0]saans;
assign saans = sainA - sainB;

// Adder 22bit
reg signed[`Adder-1:0]add_inA,add_inB;
wire signed[`Adder-1:0]add_ans;
assign add_ans = add_inA + add_inB;

//  counter
wire [4:0]count_add1;
assign count_add1 = count + 5'd1;

//====================================    Sequential logic

always@(posedge clk,posedge reset)
if(reset)
begin
    for(i = 0;i <= 5;i=i+1)   //// reset array[0]~[5]
    begin
        x_data[i] <= 10'd0;
        y_data[i] <= 10'd0;
        r_data[i] <= 11'd0;
    end
	
	ax <= 11'd0;
	ay <= 11'd0;
	bx <= 11'd0;
	by <= 11'd0;
	count <= 5'd0;
	fsm <= `fsm_bit'd0;
	ax_by <= `Subtractor'd0;
	ay_bx <= `Subtractor'd0;
	fit <= 1'b0; 
    sqrt_state <= 2'd0;
    sqrt_temp <= `sqrt_output_bit'd0;
    sqrt_count <= 5'd0;
    dataA <= 11'd0;
    dataB <= 11'd0;
    dataC <= 11'd0;
    dataS <= 11'd0;
    Triangle_area <= 22'd0;
end
else
begin
	ax <= ax_next;
	ay <= ay_next;
	bx <= bx_next;
	by <= by_next;
	count <= count_next;
	fsm <= fsm_next;
	ax_by <= ax_by_next;
	ay_bx <= ay_bx_next;
	fit <= fit_next;
    sqrt_state <= sqrt_state_next;
    sqrt_temp <= sqrt_temp_next;
    sqrt_count <= sqrt_count_next;
    dataA <= dataA_next;
    dataB <= dataB_next;
    dataC <= dataC_next;
    dataS <= dataS_next;
    Triangle_area <= Triangle_area_next;
	
	case(data_mode)	//synopsys parallel_case
		default:
		begin
			for(i = 0;i <= 5;i=i+1)
            begin
                x_data[i] <= x_data[i];
                y_data[i] <= y_data[i];
                r_data[i] <= r_data[i];
            end
		end
		data_move_forward:   //data add to array[5],array[0]~[4]move forward
		begin
            for(i = 0;i <= 4;i=i+1)
            begin
                x_data[i] <= x_data[i+1];
                y_data[i] <= y_data[i+1];
                r_data[i] <= r_data[i+1];
            end
            x_data[5] <= X;
            y_data[5] <= Y;
            r_data[5] <= R;
		end
		data_clear:   // clear array[0]~[5]
		begin
			for(i = 0;i <= 5;i=i+1)
            begin
                x_data[i] <= 10'd0;
                y_data[i] <= 10'd0;
                r_data[i] <= 11'd0;
            end
		end
		data_loop_forward:   // array[0] does not move,array[1]~[5]loop forward
		begin
            for(i = 1;i <= 4;i=i+1)
            begin
                x_data[i] <= x_data[i+1];
                y_data[i] <= y_data[i+1];
                r_data[i] <= r_data[i+1];
            end
			x_data[0] <= x_data[0];
            y_data[0] <= y_data[0];
            r_data[0] <= r_data[0];
            
            x_data[5] <= x_data[1];
            y_data[5] <= y_data[1];
            r_data[5] <= r_data[1];
		end
        data_change:   //array[1] [2]change
		begin
			x_data[1] <= x_data[2];
            y_data[1] <= y_data[2];
            r_data[1] <= r_data[2];

            x_data[2] <= x_data[1];
            y_data[2] <= y_data[1];
            r_data[2] <= r_data[1];
		end
        data_all_loop_forward:   // array[0]~[5]loop forward
		begin
            for(i = 0;i <= 4;i=i+1)
            begin
                x_data[i] <= x_data[i+1];
                y_data[i] <= y_data[i+1];
                r_data[i] <= r_data[i+1];
            end
            x_data[5] <= x_data[0];
            y_data[5] <= y_data[0];
            r_data[5] <= r_data[0];
		end
	endcase
end


//================================================    Combinatorial logic

always@(*)
begin
	case(fsm)
        //============================== Geofence sorting
		data_in:   //data in
		begin
			data_mode = 3'd1;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
            
			
			if(count == 5'd5)
			begin
				fsm_next = 5'd1;
				count_next = 5'd0;
			end
			else
			begin
				count_next = count_add1;
			end
		end
		Cross_product_start:   // x1-x0
		begin
			data_mode = data_not_move;
			ax_next = {saans[21],saans[9:0]};
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd2;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = {12'd0,x_data[1]};
			sainB = {12'd0,x_data[0]};
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		`fsm_bit'd2:   // y1-y0
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = {saans[21],saans[9:0]};
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd3;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = {12'd0,y_data[1]};
			sainB = {12'd0,y_data[0]};
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		`fsm_bit'd3:   // x2-x0
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = {saans[21],saans[9:0]};
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd4;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = {12'd0,x_data[2]};
			sainB = {12'd0,x_data[0]};
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		`fsm_bit'd4:   // y2-y0
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = {saans[21],saans[9:0]};
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd5;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA =  {12'd0,y_data[2]};
			sainB =  {12'd0,y_data[0]};
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		`fsm_bit'd5:   // Ax*By
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = {xans[23],xans[20:0]};
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd6;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = {ax[10],ax[10],ax[9:0]};
			xinB = {by[10],by[10],by[9:0]};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		`fsm_bit'd6:   // Ay*Bx
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = {xans[23],xans[20:0]};
			count_next = count;
			fsm_next = `fsm_bit'd7;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = {ay[10],ay[10],ay[9:0]};
			xinB = {bx[10],bx[10],bx[9:0]};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		`fsm_bit'd7:   // Ax*By - Ay*Bx
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = ax_by;
			sainB = ay_bx;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
			if(saans[21] == 1'b0)
			begin
				fsm_next = fsm_data_change;
			end
			else
			begin
				fsm_next = Cross_product_end;
			end
		end
		fsm_data_change:   //data change
		begin
			data_mode = data_change;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = Cross_product_end;
			fit_next = 1'b1;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		Cross_product_end:
		begin
			data_mode = data_loop_forward;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			if(count == 5'd3)
			begin
                fsm_next = Data_homing;
                count_next = 5'd0;
                data_mode = data_not_move;
			end
			else
			begin
				fsm_next = Cross_product_start;
				count_next = count_add1;
			end
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        Data_homing:
		begin
			data_mode = data_loop_forward;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            if(count == 5'd1)
            begin
                count_next = 5'd0;
                if(fit == 1'b1)
                begin
                    fit_next = 1'b0;
			        fsm_next = Cross_product_start;
                end
                else
                begin
                    fsm_next = A_to_B_distance_start;
                end
            end
            else 
            begin
                count_next = count_add1;
                fsm_next = fsm;
            end
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        //================================== Triangle area
        A_to_B_distance_start:  // x1-x0 = ax
		begin
			data_mode = data_not_move;
			ax_next = {saans[21],saans[9:0]};
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = 5'd12;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = {12'd0,x_data[1]};
			sainB = {12'd0,x_data[0]};
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        `fsm_bit'd12:  // y1-y0 = ay
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = {saans[21],saans[9:0]};
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd13;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = {12'd0,y_data[1]};
			sainB = {12'd0,y_data[0]};
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        `fsm_bit'd13:  // ax * ax = ax_by
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = {xans[23],xans[20:0]};
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd14;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = {ax[10],ax[10],ax[9:0]};
			xinB = {ax[10],ax[10],ax[9:0]};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        `fsm_bit'd14:  // ay * ay = ay_bx
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = {xans[23],xans[20:0]};
			count_next = count;
			fsm_next = `fsm_bit'd15;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = {ay[10],ay[10],ay[9:0]};
			xinB = {ay[10],ay[10],ay[9:0]};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        `fsm_bit'd15:  // ax_by + ay_bx = {bx,by} (20+20bit)
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = add_ans[21:11];    //MSB 20bit
			by_next = add_ans[10:0];  //LSB 20bit
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = sqrt_AtoB_start;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
            add_inA = {1'b0,ax_by};
			add_inB = {1'b0,ay_bx};
            sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
		end
        sqrt_AtoB_start:    
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            case (sqrt_state)
                2'd0:
                begin
                    sqrt_temp_next = sqrt_temp_add_count;
                    if(sqrt_count >= `sqrt_output_bit)
                        sqrt_state_next = 2'd2;
                    else
                        sqrt_state_next = 2'd1;
                end
                2'd1:
                begin
                    if(xans[21:0] > {bx,by})begin
                        sqrt_temp_next = sqrt_temp_sub_count;
                    end
                    sqrt_count_next  = sqrt_count_add1;
                    sqrt_state_next = 2'd0;
                end
                2'd2:
                begin
                    dataC_next = sqrt_temp;
                    sqrt_count_next = 5'd0;
                    sqrt_state_next = 2'd0;
                    sqrt_temp_next = `sqrt_output_bit'd0;
                    fsm_next = `fsm_bit'd17;
                end
                default:
                begin
                    sqrt_state_next = sqrt_state;
                end
            endcase
			xinA = {1'b0,sqrt_temp};
			xinB = {1'b0,sqrt_temp};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        `fsm_bit'd17:   // (r_data[0]+r_data[1]) a + b  = dataA
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = `fsm_bit'd18;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = add_ans[10:0];
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = {12'b0,r_data[0]};
			add_inB = {12'b0,r_data[1]};
		end
        `fsm_bit'd18:   // (dataA+dataC) ((a+b) + c )/2 = dataS
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = Triangle_area_end;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = add_ans[11:1];
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = {12'b0,dataA};
			add_inB = {12'd0,dataC};
		end
        Triangle_area_end:  // 3 stage => (s-a) , (a-b) , (s-c) 
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            case (sqrt_state)
                2'd0:
                begin
                    sqrt_state_next = 2'd1;
                    dataA_next = saans[10:0];
                    if(dataS > r_data[0])
                    begin
                        sainA = {11'd0,dataS};
			            sainB = {11'd0,r_data[0]};
                    end
                    else
                    begin
                        sainA = {11'd0,r_data[0]};
			            sainB = {11'd0,dataS};
                    end
                end
                2'd1:
                begin
                    sqrt_state_next = 2'd2;
                    dataB_next = saans[10:0];
                    if(dataS > r_data[1])
                    begin
                        sainA = {11'd0,dataS};
			            sainB = {11'd0,r_data[1]};
                    end
                    else
                    begin
                        sainA = {11'd0,r_data[1]};
			            sainB = {11'd0,dataS};
                    end
                end
                2'd2:
                begin
                    fsm_next = sqrt_ssa;
                    sqrt_state_next = 2'd3;
                    dataC_next = saans[10:0];
                    if(dataS > dataC)
                    begin
                        sainA = {11'd0,dataS};
			            sainB = {11'd0,dataC};
                    end
                    else
                    begin
                        sainA = {11'd0,dataC};
			            sainB = {11'd0,dataS};
                    end
                end
                default:
		        begin
                    sqrt_state_next = sqrt_state;
                    sainA = `Subtractor'd0;
			        sainB = `Subtractor'd0;
                end
            endcase
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        sqrt_ssa:    
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            xinA = {1'b0,sqrt_temp};
			xinB = {1'b0,sqrt_temp};
            case (sqrt_state)
                2'd3:
                begin
                    xinA = {1'b0,dataS};
			        xinB = {1'b0,dataA};
                    ax_by_next = xans[21:0];
                    sqrt_state_next = 2'd0;
                end
                2'd0:
                begin
                    sqrt_temp_next = sqrt_temp_add_count;
                    if(sqrt_count >= `sqrt_output_bit)
                        sqrt_state_next = 2'd2;
                    else
                        sqrt_state_next = 2'd1;
                end
                2'd1:
                begin
                    if(xans[21:0] > ax_by)begin
                        sqrt_temp_next = sqrt_temp_sub_count;
                    end
                    sqrt_count_next  = sqrt_count_add1;
                    sqrt_state_next = 2'd0;
                end
                2'd2:
                begin
                    dataA_next = sqrt_temp;
                    sqrt_count_next = 5'd0;
                    sqrt_state_next = 2'd3;
                    sqrt_temp_next = `sqrt_output_bit'd0;
                    fsm_next = sqrt_sbsc;
                end
                default:
                begin
                    sqrt_state_next = sqrt_state;
                end
            endcase
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        sqrt_sbsc:    
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            xinA = {1'b0,sqrt_temp};
			xinB = {1'b0,sqrt_temp};
            case (sqrt_state)
                2'd3:
                begin
                    xinA = {1'b0,dataB};
			        xinB = {1'b0,dataC};
                    ax_by_next = xans[21:0];
                    sqrt_state_next = 2'd0;
                end
                2'd0:
                begin
                    sqrt_temp_next = sqrt_temp_add_count;
                    if(sqrt_count >= `sqrt_output_bit)
                        sqrt_state_next = 2'd2;
                    else
                        sqrt_state_next = 2'd1;
                end
                2'd1:
                begin
                    if(xans[21:0] > ax_by)begin
                        sqrt_temp_next = sqrt_temp_sub_count;
                    end
                    sqrt_count_next  = sqrt_count_add1;
                    sqrt_state_next = 2'd0;
                end
                2'd2:
                begin
                    dataC_next = sqrt_temp;
                    sqrt_count_next = 5'd0;
                    sqrt_state_next = 2'd0;
                    sqrt_temp_next = `sqrt_output_bit'd0;
                    fsm_next = Triangle_area_add;
                end
                default:
                begin
                    sqrt_state_next = sqrt_state;
                end
            endcase
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        Triangle_area_add:
		begin
			data_mode = data_all_loop_forward;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = 22'd0;
			ay_bx_next = 22'd0;
			count_next = count;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = add_ans[21:0];
            if(count == 5'd5)
            begin
                fsm_next = Polygon_area_start;
                count_next = 5'd0;
            end
            else 
            begin
                fsm_next = A_to_B_distance_start;
                count_next = count_add1;
            end
			xinA = {1'b0,dataA};
			xinB = {1'b0,dataC};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = {1'b0,Triangle_area};
			add_inB = {1'b0,xans[21:0]};
		end
        //================================== Polygon area
        Polygon_area_start:     
		begin
			data_mode = data_all_loop_forward;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = add_ans[21:0];
			ay_bx_next = ay_bx;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            if(count == 5'd5)
            begin
                fsm_next = `fsm_bit'd24;
                count_next = 5'd0;
            end
            else 
            begin
                count_next = count_add1;
            end
			xinA = {2'b0,x_data[0]};
			xinB = {2'b0,y_data[1]};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = xans[22:0];
			add_inB = {1'b0,ax_by};
		end
        `fsm_bit'd24:     
		begin
			data_mode = data_all_loop_forward;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = add_ans[21:0];
			fsm_next = fsm;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            if(count == 5'd5)
            begin
                fsm_next = Data_out;
                count_next = 5'd0;
            end
            else 
            begin
                count_next = count_add1;
            end
			xinA = {2'b0,y_data[0]};
			xinB = {2'b0,x_data[1]};
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = xans[22:0];
			add_inB = {1'b0,ay_bx};
		end
        Data_out:
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = Clear_data;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
            if(Triangle_area > (saans >> 1'b1))
                fit_next = 1'b0;
            else 
                fit_next = 1'b1;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = ay_bx;
			sainB = ax_by;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
        Clear_data:
		begin
			data_mode = data_clear;
			ax_next = 11'd0;
			ay_next = 11'd0;
			bx_next = 11'd0;
			by_next = 11'd0;
			ax_by_next = 22'd0;
			ay_bx_next = 22'd0;
			count_next = 5'd0;
			fsm_next = data_in;
			fit_next = 1'b0;
            sqrt_state_next = 2'd0;
            sqrt_temp_next = `sqrt_output_bit'd0;
            sqrt_count_next = 5'd0;
            dataA_next = 11'd0;
            dataB_next = 11'd0;
            dataC_next = 11'd0;
            dataS_next = 11'd0;
            Triangle_area_next = 22'd0;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
		default:
		begin
			data_mode = data_not_move;
			ax_next = ax;
			ay_next = ay;
			bx_next = bx;
			by_next = by;
			ax_by_next = ax_by;
			ay_bx_next = ay_bx;
			count_next = count;
			fsm_next = fsm;
			fit_next = fit;
            sqrt_state_next = sqrt_state;
            sqrt_temp_next = sqrt_temp;
            sqrt_count_next = sqrt_count;
            dataA_next = dataA;
            dataB_next = dataB;
            dataC_next = dataC;
            dataS_next = dataS;
            Triangle_area_next = Triangle_area;
			xinA = `Multiplier'd0;
			xinB = `Multiplier'd0;
			sainA = `Subtractor'd0;
			sainB = `Subtractor'd0;
            add_inA = `Adder'd0;
			add_inB = `Adder'd0;
		end
	endcase
end



endmodule

