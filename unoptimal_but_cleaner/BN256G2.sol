pragma experimental ABIEncoderV2;

library FQ2 {
    uint256 internal constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    
    struct fq2 {
        uint256 real;
        uint256 imaginary;
    }
    
    function Mul(fq2 a, fq2 b) internal constant returns(fq2 c) {
        (c.real, c.imaginary) = ((a.real * b.real - a.imaginary * b.imaginary) % FIELD_ORDER, (a.real * b.imaginary + a.imaginary * b.real) % FIELD_ORDER);
    }
    
    function Mul(fq2 a, uint256 b) internal constant returns(fq2 c) {
        (c.real, c.imaginary) = (mulmod(a.real, b, FIELD_ORDER), mulmod(a.imaginary, b, FIELD_ORDER));
    }
    
    function Add(fq2 a, fq2 b) internal constant returns(fq2 c) {
        (c.real, c.imaginary) = ((a.real + b.real) % FIELD_ORDER, (a.imaginary + b.imaginary) % FIELD_ORDER);
    }
    
    function Sub(fq2 a, fq2 b) internal constant returns(fq2 c) {
        (c.real, c.imaginary) = ((a.real - b.real) % FIELD_ORDER, (a.imaginary - b.imaginary) % FIELD_ORDER);
    }
    
    function IsOne(fq2 a) internal constant returns (bool) {
        return a.real == 1 && a.imaginary == 0;
    }
    
    function IsZero(fq2 a) internal constant returns (bool) {
        return a.real == 0 && a.imaginary == 0;
    }
    
    function One() internal constant returns (fq2 a) {
        (a.real, a.imaginary) = (1, 0);
    }
    
    function Zero() internal constant returns (fq2 a) {
        (a.real, a.imaginary) = (0, 0);
    }
    
    function Equal(fq2 a, fq2 b) internal constant returns (bool) {
        return a.real == b.real && a.imaginary == b.imaginary;
    }
}

library BN256G2 {
    using FQ2 for FQ2.fq2;
    
    function ECAdd(FQ2.fq2 x1, FQ2.fq2 y1, FQ2.fq2 z1, FQ2.fq2 x2, FQ2.fq2 y2, FQ2.fq2 z2) constant returns(FQ2.fq2 x3, FQ2.fq2 y3, FQ2.fq2 z3) {
        if (z1.IsZero()) {
            (x3, y3, z3) = (x2, y2, z2);
            return;
        } else if (z2.IsZero()) {
            (x3, y3, z3) = (x1, y1, z1);
            return;
        }
        
        x2 = y2.Mul(z1); // U1 = y2 * z1
        y2 = y1.Mul(z2); // U2 = y1 * z2
        x3 = x2.Mul(z1); // V1 = x2 * z1
        y3 = x1.Mul(z2); // V2 = x1 * z2
        
        if (x3.Equal(y3)) {
            if (x2.Equal(y2)) {
                (x3, y3, z3) = _ECDouble(x1, y1, z1);
                return;
            }
            (x3, y3, z3) = (FQ2.One(), FQ2.One(), FQ2.Zero());
            return;
        }
        
        x2 = x2.Sub(y2); // U = U1 - U2
        x3 = x3.Sub(y3); // V = V1 - V2
        z3 = x3.Mul(x3); // V_squared = V * V
        y3 = z3.Mul(y3); // V_squared_times_V2 = V_squared * V2
        z3 = x3.Mul(z3); // V_cubed = V * V_squared
        x1 = z1.Mul(z2); // W = z1 * z2
        z1 = x2.Mul(x2).Mul(x1).Sub(z3).Sub(y3.Mul(2)); // A = U * U * W - V_cubed - 2 * V_squared_times_V2
        
        x3 = x3.Mul(z1); // newx = V * A
        y3 = x2.Mul(y3.Sub(z1)).Sub(z3.Mul(y2)); // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
        z3 = z3.Mul(x1); // newz = V_cubed * W
    }
    
    function _ECDouble(FQ2.fq2 x1, FQ2.fq2 y1, FQ2.fq2 z1) constant returns(FQ2.fq2 x2, FQ2.fq2 y2, FQ2.fq2 z2) {
        x2 = x1.Mul(x1).Mul(3); // W = 3 * x * x
        z1 = y1.Mul(z1); // S = y * z
        y2 = x1.Mul(y1).Mul(z1); // B = x * y * S
        x1 = x2.Mul(x2).Sub(y2.Mul(8)); // H = W * W - 8 * B
        z2 = z1.Mul(z1); // S_squared = S * S
        
        y2 = x2.Mul(y2.Mul(3).Sub(x1)).Sub(y1.Mul(8).Mul(y1).Mul(z2)); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        x2 = x1.Mul(2).Mul(z1); // newx = 2 * H * S
        z2 = z1.Mul(8).Mul(z2); // newz = 8 * S * S_squared
    }
    
    function ECMul(uint256 d, FQ2.fq2 x1, FQ2.fq2 y1, FQ2.fq2 z1) constant returns(FQ2.fq2 x2, FQ2.fq2 y2, FQ2.fq2 z2) {
        (x2, y2, z2) = (FQ2.One(), FQ2.One(), FQ2.Zero());
        if (d == 0) {
            return;
        }
        
        while (d != 0) {
            if ((d & 1) != 0) {
                (x2, y2, z2) = ECAdd(x2, y2, z2, x1, y1, z1);
            }
            d = d / 2;
            (x1, y1, z1) = _ECDouble(x1, y1, z1);
        }
    }
}
