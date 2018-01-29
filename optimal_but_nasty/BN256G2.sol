library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;
    
    function _FQ2Mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = ((xx * yx - xy * yy) % FIELD_MODULUS, (xx * yy + xy * yx) % FIELD_MODULUS);
    }
    
    function _FQ2Mul(uint256 xx, uint256 xy, uint256 c) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = (mulmod(xx, c, FIELD_MODULUS), mulmod(xy, c, FIELD_MODULUS));
    }
    
    function _FQ2Add(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = ((xx + yx) % FIELD_MODULUS, (xy + yy) % FIELD_MODULUS);
    }
    
    function _FQ2Sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = ((xx - yx) % FIELD_MODULUS, (xy - yy) % FIELD_MODULUS);
    }
    
    function _FQ2Inv(uint256 low0, uint256 low1) constant returns(uint256 lm0, uint256 lm1) {
        lm0 = 1;
        lm1 = 0;
        uint256 lm2 = 0;
        uint256 hm0 = 0;
        uint256 hm1 = 0;
        uint256 hm2 = 0;
        uint256 low2 = 0;
        uint256 high0 = 1;
        uint256 high1 = 0;
        uint256 high2 = 1;
        uint256 r0;
        uint256 r1;
        uint256 r2;
        while (low1 != 0 && low2 != 0) {
            // r = poly_rounded_div(high, low)
            if (high2 != 0 && low1 == 0 && low2 == 0) { // dega = 2, degb = 0
                r0 = _prime_field_inv(low0);
                r2 = mulmod(high2, r0, FIELD_MODULUS);
                r1 = mulmod(high1, r0, FIELD_MODULUS);
                r0 = mulmod(high0, r0, FIELD_MODULUS);
            } else if (high2 != 0 && low1 != 0 && low2 == 0) { // dega = 2, degb = 1
                r0 = _prime_field_inv(low1);
                r2 = 0;
                r1 = mulmod(high2, r0, FIELD_MODULUS);
                r0 = mulmod(high1, r0, FIELD_MODULUS);
            } else if (high1 != 0 && high2 == 0 && low1 == 0 && low2 == 0) { // dega = 1, degb = 0
                r0 = _prime_field_inv(low0);
                r2 = 0;
                r1 = mulmod(high1, r0, FIELD_MODULUS);
                r0 = mulmod(high0, r0, FIELD_MODULUS);
            } else if (high2 != 0 && low2 != 0) { // dega = 2, degb = 2
                r0 = _prime_field_inv(low2);
                r2 = 0;
                r1 = 0;
                r0 = mulmod(high2, r0, FIELD_MODULUS);
            } else if (high1 != 0 && high2 == 0 && low1 != 0 && low2 == 0) { // dega = 1, degb = 1
                r0 = _prime_field_inv(low1);
                r2 = 0;
                r1 = 0;
                r0 = mulmod(high1, r0, FIELD_MODULUS);
            } else if (high1 == 0 && high2 == 0 && low1 == 0 && low2 == 0) { // dega = 0, degb = 0
                r0 = _prime_field_inv(low0);
                r2 = 0;
                r1 = 0;
                r0 = mulmod(high0, r0, FIELD_MODULUS);
            }
            
            hm0 -= lm0 * r0;
            hm1 -= lm0 * r1 - lm1 * r0;
            hm2 -= lm0 * r2 - lm1 * r1 - lm2 * r0;
            high0 -= low0 * r0;
            high1 -= low0 * r1;
            high1 -= low1 * r0;
            high2 -= low0 * r2;
            high2 -= low1 * r1 - low2 * r0;
            (lm0, hm0) = (hm0 % FIELD_MODULUS, lm0);
            (lm1, hm1) = (hm1 % FIELD_MODULUS, lm1);
            (lm2, hm2) = (hm2 % FIELD_MODULUS, lm2);
            (low2, high2) = (high2 % FIELD_MODULUS, low2);
            (low1, high1) = (high1 % FIELD_MODULUS, low1);
            r0 = low0;
            low0 = high0 % FIELD_MODULUS;
            high0 = r0;
        }
        
        lm0 = lm0 * _prime_field_inv(low0);
        lm1 = lm1 * _prime_field_inv(low1);
    }
    
    function _prime_field_inv(uint256 a) constant returns(uint256 t) {
        t = 0;
        uint256 newt = 1;
        uint256 r = FIELD_MODULUS;
        uint256 newr = a;
        uint256 q;
        while (newr != 0) {
            q = r / newr;
            (t, newt) = (newt, (t + (FIELD_MODULUS - mulmod(q, newt, FIELD_MODULUS))) % FIELD_MODULUS);
            (r, newr) = (newr, r - q * newr);
        }
    }

    function ECAdd(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy, uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) constant returns (uint256[6] pt3) {
            (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2
            (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1
            (pt2zx, pt2zy) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2
            if (pt2xx == pt2zx && pt2xy == pt2zy) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = ECDouble(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return;
                }
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (1, 0, 1, 0, 0, 0);
                return;
            }
            (pt1xx, pt1xy) = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U
            (pt1yx, pt1yy) = _FQ2Sub(pt2xx, pt2xy, pt2zx, pt2zy); // V
            (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yx, pt1yx, pt1yx); // V_squared
            (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yx, pt2zx, pt2zy); // V_squared_times_V2
            (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // W
            (pt1zx, pt1zx) = _FQ2Mul(pt1zx, pt1zy, pt1yx, pt1yy); // V_cubed
            (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, pt1xx, pt1xy);
            (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy);
            (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt1zx, pt1zx);
            (pt2zx, pt2zy) = _FQ2Mul(pt2yx, pt2yy, 2);
            (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt2zx, pt2zy); // A
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx, pt2xy);
            (pt1yx, pt1yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy);
            (pt1yx, pt1yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy);
            (pt1xx, pt1xy) = _FQ2Mul(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]);
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx, pt1xy);
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zx, pt2zx, pt2zy);
    }
    
    function ECDouble(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy) constant returns(uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) {
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, 3);
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy);
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy);
        (pt2zx, pt2zy) = _FQ2Mul(pt2yx, pt2yy, 8);
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, 4); // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Mul(pt1yx, pt1yy, 8); // 8 * Y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * Y * Y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, 2); // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy);
        (pt2zx, pt2zy) = _FQ2Mul(pt2zx, pt2zy, 8); // newz
    }
    
    function ECMul(uint256 d, uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy) constant returns(uint256[6] pt2) {
        (pt2[PTXX], pt2[PTXY], pt2[PTYX], pt2[PTYY], pt2[PTZX], pt2[PTZY]) = (1, 0, 1, 0, 0, 0);
        if (d == 0) {
            return;
        }
        
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = ECAdd(pt2[PTXX], pt2[PTXY], pt2[PTYX], pt2[PTYY], pt2[PTZX], pt2[PTZY], pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
            }
            d = d / 2;
            (pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy) = ECDouble(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
        }
    }
}
