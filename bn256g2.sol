library bn256g2 {
    uint256 internal constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint internal constant PT1XX = 0;
    uint internal constant PT1XY = 1;
    uint internal constant PT1YX = 2;
    uint internal constant PT1YY = 3;
    uint internal constant PT1ZX = 4;
    uint internal constant PT1ZY = 5;
    
    function _FQ2Mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = ((xx * yx - xy * yy) % FIELD_ORDER, (xx * yy + xy * yx) % FIELD_ORDER);
    }
    
    function _FQ2Muc(uint256 xx, uint256 xy, uint256 c) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = ((xx * c) % FIELD_ORDER, (xy * c) % FIELD_ORDER);
    }
    
    function _FQ2Add(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = ((xx + yx) % FIELD_ORDER, (xy + yy) % FIELD_ORDER);
    }
    
    function _FQ2Sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) constant returns(uint256 rx, uint256 ry) {
        (rx, ry) = ((xx - yx) % FIELD_ORDER, (xy - yy) % FIELD_ORDER);
    }

    function ECAdd(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy, uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) constant returns (uint256[6] pt3) {
            (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1
            (pt3[PT1YX], pt3[PT1YY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2
            (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1
            (pt2zx, pt2zy) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2
            if (pt2xx == pt2zx && pt2xy == pt2zy) {
                if (pt2yx == pt3[PT1YX] && pt2yy == pt3[PT1YY]) {
                    (pt3[PT1XX], pt3[PT1XY], pt3[PT1YX], pt3[PT1YY], pt3[PT1ZX], pt3[PT1ZY]) = ECDouble(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return;
                }
                (pt3[PT1XX], pt3[PT1XY], pt3[PT1YX], pt3[PT1YY], pt3[PT1ZX], pt3[PT1ZY]) = (1, 0, 1, 0, 0, 0);
                return;
            }
            (pt1xx, pt1xy) = _FQ2Sub(pt2yx, pt2yy, pt3[PT1YX], pt3[PT1YY]); // U
            (pt1yx, pt1yy) = _FQ2Sub(pt2xx, pt2xy, pt2zx, pt2zy); // V
            (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yx, pt1yx, pt1yx); // V_squared
            (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yx, pt2zx, pt2zy); // V_squared_times_V2
            (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // W
            (pt1zx, pt1zx) = _FQ2Mul(pt1zx, pt1zy, pt1yx, pt1yy); // V_cubed
            (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, pt1xx, pt1xy);
            (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy);
            (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt1zx, pt1zx);
            (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 2);
            (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt2zx, pt2zy); // A
            (pt3[PT1XX], pt3[PT1XY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx, pt2xy);
            (pt1yx, pt1yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy);
            (pt1yx, pt1yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy);
            (pt1xx, pt1xy) = _FQ2Mul(pt2yx, pt2yy, pt3[PT1YX], pt3[PT1YY]);
            (pt3[PT1YX], pt3[PT1YY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx, pt1xy);
            (pt3[PT1ZX], pt3[PT1ZY]) = _FQ2Mul(pt1zx, pt1zx, pt2zx, pt2zy);
    }
    
    function ECDouble(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy) constant returns(uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy);
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy);
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4); // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8); // 8 * Y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * Y * Y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2); // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy);
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);
    }
    
    function ECAddUnpack(uint256[6] pt3) constant returns (uint256 pt3xx, uint256 pt3xy, uint256 pt3yx, uint256 pt3yy, uint256 pt3zx, uint256 pt3zy) {
        (pt3xx, pt3xy, pt3yx, pt3yy, pt3zx, pt3zy) = (pt3[PT1XX], pt3[PT1XY], pt3[PT1YX], pt3[PT1YY], pt3[PT1ZX], pt3[PT1ZY]);
    }
    
    function ECMul(uint256 d, uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy) constant returns(uint256[6] pt2) {
        (pt2[PT1XX], pt2[PT1XY], pt2[PT1YX], pt2[PT1YY], pt2[PT1ZX], pt2[PT1ZY]) = (1, 0, 1, 0, 0, 0);
        if (d == 0) {
            return ([uint256(1), 0, 1, 0, 0, 0]);
        }
        
        while (d != 0) {
            if ((d & 1) != 0) {
                (pt2[PT1XX], pt2[PT1XY], pt2[PT1YX], pt2[PT1YY], pt2[PT1ZX], pt2[PT1ZY]) = ECAddUnpack(ECAdd(pt2[PT1XX], pt2[PT1XY], pt2[PT1YX], pt2[PT1YY], pt2[PT1ZX], pt2[PT1ZY], pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy));
            }
            d = d / 2;
            (pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy) = ECDouble(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
        }
    }
}
