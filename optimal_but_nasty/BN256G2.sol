library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;
    
    function _submod(uint256 a, uint256 b, uint256 n) constant returns (uint256) {
        // assumes n >= b (true in our use case)
        assert(b < n);
        return addmod(a, n - b, n);
    }
    
    function _FQ2Mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = (_submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS), addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS));
    }
    
    function _FQ2Mulc(uint256 xx, uint256 xy, uint256 c) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = (mulmod(xx, c, FIELD_MODULUS), mulmod(xy, c, FIELD_MODULUS));
    }
    
    function _FQ2Add(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = (addmod(xx, yx, FIELD_MODULUS), addmod(xy, yy, FIELD_MODULUS));
    }
    
    function _FQ2Sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = (_submod(xx, yx, FIELD_MODULUS), _submod(xy, yy, FIELD_MODULUS));
    }
    
    function _FQ2Div(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (yx, yy) = _FQ2Inv(yx, yy);
        (rx, ry) = _FQ2Mul(xx, xy, yx, yy);
    }
    
    function _FQ2Inv(uint256 x, uint256 y) constant returns(uint256 rx, uint256 ry) {
        uint256 inv = _prime_field_inv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        rx = mulmod(x, inv, FIELD_MODULUS);
        ry = FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS);
    }
    
    function _prime_field_inv(uint256 a, uint256 n) constant returns(uint256 t) {
        t = 0;
        uint256 newT = 1;
        uint256 r = n;
        uint256 newR = a;
        uint256 q;
        while (newR != 0) {
            q = r / newR;
            (t, newT) = (newT, _submod(t, mulmod(q, newT, n), n));
            (r, newR) = (newR, r - q * newR);
        }
    }

    function ECAdd(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy, uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) constant returns (uint256[6] pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (pt2xx, pt2xy, pt2yx, pt2yy, pt2zx, pt2zy);
                return;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                return;
            }
            
            (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2
            
            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = ECDouble(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return;
                }
                (pt3[PTXX], pt3[PTXY], pt3[PTYX], pt3[PTYY], pt3[PTZX], pt3[PTZY]) = (0, 0, 0, 0, 0, 0);
                return;
            }
            
            (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // W = z1 * z2
            (pt1xx, pt1xy) = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx, pt1yy) = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1yx, pt1yy); // V_squared = V * V
            (pt2yx, pt2yy) = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx, pt1zy) = _FQ2Mul(pt1zx, pt1zy, pt1yx, pt1yy); // V_cubed = V * V_squared
            
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // newz = V_cubed * W
            (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, pt1xx, pt1xy); // U * U
            (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // U * U * W
            (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt1zx, pt1zy); // U * U * W - V_cubed
            (pt2zx, pt2zy) = _FQ2Mulc(pt2yx, pt2yy, 2); // 2 * V_squared_times_V2
            (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt2zx, pt2zy); // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx, pt2xy); // newx = V * A
            (pt1yx, pt1yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // V_squared_times_V2 - A
            (pt1yx, pt1yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // U * (V_squared_times_V2 - A)
            (pt1xx, pt1xy) = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx, pt1xy); // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }
    
    function ECDouble(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy) constant returns(uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) {
        (pt2xx, pt2xy) = _FQ2Mulc(pt1xx, pt1xy, 3); // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Mulc(pt2yx, pt2yy, 8); // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Mulc(pt2yx, pt2yy, 4); // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Mulc(pt1yx, pt1yy, 8); // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Mulc(pt1xx, pt1xy, 2); // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Mulc(pt2zx, pt2zy, 8); // newz = 8 * S * S_squared
    }
    
    function ECMul(uint256 d, uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy) constant returns(uint256[6] pt2) {
        bytes32 b = bytes32(d);
        uint n;
        while (d != 0) {
            if (pt2[PTZX] != 0 || pt2[PTZY] != 0) {
                (pt2[PTXX], pt2[PTXY], pt2[PTYX], pt2[PTYY], pt2[PTZX], pt2[PTZY]) = ECDouble(pt2[PTXX], pt2[PTXY], pt2[PTYX], pt2[PTYY], pt2[PTZX], pt2[PTZY]);
            }
            if ((b[n / 8] >> (7 - (n % 8))) & 1 != 0) {
                pt2 = ECAdd(pt2[PTXX], pt2[PTXY], pt2[PTYX], pt2[PTYY], pt2[PTZX], pt2[PTZY], pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
            }
            if (pt2[PTZX] != 0 || pt2[PTZY] != 0) {
                d = d / 2;
            }
            n += 1;
        }
    }
}
