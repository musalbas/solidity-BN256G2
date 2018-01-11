library bn256g2 {
    uint256 internal constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint internal constant PT1XX = 0;
    uint internal constant PT1XY = 1;
    uint internal constant PT1YX = 2;
    uint internal constant PT1YY = 3;
    uint internal constant PT1ZX = 4;
    uint internal constant PT1ZY = 5;
    uint internal constant PT2XX = 6;
    uint internal constant PT2XY = 7;
    uint internal constant PT2YX = 8;
    uint internal constant PT2YY = 9;
    uint internal constant PT2ZX = 10;
    uint internal constant PT2ZY = 11;
    
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

    function EcAddOld(uint256[12] pts) constant returns (uint256[6] pt3) {
            uint256 ax;
            uint256 ay;
            uint256 bx;
            uint256 by;
            uint256 cx;
            uint256 cy;
            uint256 dx;
            uint256 dy;
            uint256 ex;
            uint256 ey;
            (ax, ay) = _FQ2Mul(pts[PT2YX], pts[PT2YY], pts[PT1ZX], pts[PT1ZY]); // U1
            (pts[PT1YX], pts[PT1YY]) = _FQ2Mul(pts[PT1YX], pts[PT1YY], pts[PT2ZX], pts[PT2ZY]); // U2
            (cx, cy) = _FQ2Mul(pts[PT2XX], pts[PT2XY], pts[PT1ZX], pts[PT1ZY]); // V1
            (dx, dy) = _FQ2Mul(pts[PT1XX], pts[PT1XY], pts[PT2ZX], pts[PT2ZY]); // V2
            
            // TODO: if statements
            
            (ax, ay) = _FQ2Sub(ax, ay, pts[PT1YX], pts[PT1YY]); // U
            (bx, by) = _FQ2Sub(cx, cy, dx, dy); // V
            
            (cx, cy) = _FQ2Mul(bx, by, bx, by); // V_squared
            (dx, dy) = _FQ2Mul(cx, cy, dx, dy); // V_squared_times_V2
            
            (cx, cy) = _FQ2Mul(bx, by, cx, cy); // V_cubed
            (pt3[PT1ZX], pt3[PT1ZY]) = _FQ2Mul(pts[PT1ZX], pts[PT1ZY], pts[PT2ZX], pts[PT2ZY]); // W
            
            (ex, ey) = _FQ2Mul(ax, ay, ax, ay);
            (ex, ey) = _FQ2Mul(ex, ey, pt3[PT1ZX], pt3[PT1ZY]);
            (ex, ey) = _FQ2Sub(ex, ey, cx, cy);
            (pt3[PT1YX], pt3[PT1YY]) = _FQ2Muc(dx, dy, 2);
            (ex, ey) = _FQ2Sub(ex, ey, pt3[PT1YX], pt3[PT1YY]); // A
            
            (pt3[PT1XX], pt3[PT1XY]) = _FQ2Mul(bx, by, ex, ey);
            (bx, by) = _FQ2Sub(dx, dy, ex, ey);
            (bx, by) = _FQ2Mul(ax, ay, bx, by);
            (ex, ey) = _FQ2Mul(cx, cy, pts[PT1YX], pts[PT1YY]);
            (pt3[PT1YX], pt3[PT1YY]) = _FQ2Mul(bx, by, ex, ey);
            (pt3[PT1ZX], pt3[PT1ZY]) = _FQ2Mul(cx, cy, pt3[PT1ZX], pt3[PT1ZY]);
    }

    function EcAdd(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy, uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) constant returns (uint256[6] pt3) {
            (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1
            (pt3[PT1YX], pt3[PT1YY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2
            (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1
            (pt2zx, pt2zy) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2
            // TODO: if statements
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
    
    function EcDouble(uint256 pt1xx, uint256 pt1xy, uint256 pt1yx, uint256 pt1yy, uint256 pt1zx, uint256 pt1zy) constant returns(uint256 pt2xx, uint256 pt2xy, uint256 pt2yx, uint256 pt2yy, uint256 pt2zx, uint256 pt2zy) {
        uint256 ax;
        uint256 ay;
        
        (ax, ay) = _FQ2Muc(pt1xx, pt1xy, 3);
        (ax, ay) = _FQ2Mul(ax, ay, ax, ay);
        //(pt1zx, pt1zy) = 
    }
}
