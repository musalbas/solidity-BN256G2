# solidity-BN256G2
Implementation of elliptic curve operations on G2 for alt_bn128 in Solidity.

# Functions

## ECAdd
```
/**
 * @notice Add two twist points
 * @param pt1xx Coefficient 1 of x on point 1
 * @param pt1xy Coefficient 2 of x on point 1
 * @param pt1yx Coefficient 1 of y on point 1
 * @param pt1yy Coefficient 2 of y on point 1
 * @param pt2xx Coefficient 1 of x on point 2
 * @param pt2xy Coefficient 2 of x on point 2
 * @param pt2yx Coefficient 1 of y on point 2
 * @param pt2yy Coefficient 2 of y on point 2
 * @return (pt3xx, pt3xy, pt3yx, pt3yy)
 */
function ECAdd(
    uint256 pt1xx, uint256 pt1xy,
    uint256 pt1yx, uint256 pt1yy,
    uint256 pt2xx, uint256 pt2xy,
    uint256 pt2yx, uint256 pt2yy
) public pure returns (
    uint256, uint256,
    uint256, uint256
)
```

## ECMul
```
/**
 * @notice Multiply a twist point by a scalar
 * @param s     Scalar to multiply by
 * @param pt1xx Coefficient 1 of x
 * @param pt1xy Coefficient 2 of x
 * @param pt1yx Coefficient 1 of y
 * @param pt1yy Coefficient 2 of y
 * @return (pt2xx, pt2xy, pt2yx, pt2yy)
 */
function ECMul(
    uint256 s,
    uint256 pt1xx, uint256 pt1xy,
    uint256 pt1yx, uint256 pt1yy
) public pure returns (
    uint256, uint256,
    uint256, uint256
)
```
