reg compute_next;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        x_warp <= 0;
        y_warp <= 0;
        tx <= 0;
        ty <= 0;
        tz <= 1;
        done <= 0;
        compute_next <= 0;
    end else begin
        if (start) begin
            tx <= (H[0]*x_in + H[1]*y_in + H[2]);
            ty <= (H[3]*x_in + H[4]*y_in + H[5]);
            tz <= (H[6]*x_in + H[7]*y_in + H[8]);
            compute_next <= 1;
            done <= 0;
        end else if (compute_next) begin
            if (tz != 0) begin
                x_warp <= (tx << 8) / tz;
                y_warp <= (ty << 8) / tz;
            end
            compute_next <= 0;
            done <= 1;
        end else begin
            done <= 0;
        end
    end
end
