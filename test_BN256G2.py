import unittest

from ethereum.tools import tester


CURVE_ORDER = 21888242871839275222246405745257275088548364400416034343698204186575808495617
FIELD_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583
G2J = (
    (10857046999023057135944570762232829481370756359578518086990519993285655852781, 11559732032986387107991004021392285783925812861821192530917403151452391805634),
    (8495653923123431417604973247489272438418190587263600148770280649306958101930, 4082367875863433681332203403145435568316851327593401208105741076214120093531),
    (1, 0)
)
G2J_inf = (
    (1, 0),
    (1, 0),
    (0, 0)
)
G2 = (
    (10857046999023057135944570762232829481370756359578518086990519993285655852781, 11559732032986387107991004021392285783925812861821192530917403151452391805634),
    (8495653923123431417604973247489272438418190587263600148770280649306958101930, 4082367875863433681332203403145435568316851327593401208105741076214120093531)
)
G2_inf = (
    (0, 0),
    (0, 0)
)


class contractWrapperJ(object):
    def __init__(self, bn256g2):
        self.bn256g2 = bn256g2

    def _to_tuples(result):
        return (
            (result[0], result[1]),
            (result[2], result[3]),
            (result[4], result[5])
        )

    def is_inf(pt1):
        return pt1[2] == (0, 0)

    def add(self, pt1, pt2):
        return contractWrapperJ._to_tuples(self.bn256g2._ECTwistAddJacobian(
            pt1[0][0], pt1[0][1], pt1[1][0], pt1[1][1], pt1[2][0], pt1[2][1],
            pt2[0][0], pt2[0][1], pt2[1][0], pt2[1][1], pt2[2][0], pt2[2][1]
        ))

    def double(self, pt1):
        return contractWrapperJ._to_tuples(self.bn256g2._ECTwistDoubleJacobian(
            pt1[0][0], pt1[0][1], pt1[1][0], pt1[1][1], pt1[2][0], pt1[2][1]
        ))

    def multiply(self, pt1, s):
        return contractWrapperJ._to_tuples(self.bn256g2._ECTwistMulJacobian(
            s,
            pt1[0][0], pt1[0][1], pt1[1][0], pt1[1][1], pt1[2][0], pt1[2][1]
        ))

    def eq(self, pt1, pt2):
        x1, y1, z1 = pt1
        x2, y2, z2 = pt2
        return (
            self.bn256g2._FQ2Mul(x1[0], x1[1], z2[0], z2[1]) == self.bn256g2._FQ2Mul(x2[0], x2[1], z1[0], z1[1]) and
            self.bn256g2._FQ2Mul(y1[0], y1[1], z2[0], z2[1]) == self.bn256g2._FQ2Mul(y2[0], y2[1], z1[0], z1[1])
        )


class contractWrapper(object):
    def __init__(self, bn256g2):
        self.bn256g2 = bn256g2

    def _to_tuples(result):
        return (
            (result[0], result[1]),
            (result[2], result[3])
        )

    def is_inf(pt1):
        return pt1 == ((0, 0), (0, 0))

    def add(self, pt1, pt2):
        return contractWrapper._to_tuples(self.bn256g2.ECTwistAdd(
            pt1[0][0], pt1[0][1], pt1[1][0], pt1[1][1],
            pt2[0][0], pt2[0][1], pt2[1][0], pt2[1][1]
        ))

    def multiply(self, pt1, s):
        return contractWrapper._to_tuples(self.bn256g2.ECTwistMul(
            s,
            pt1[0][0], pt1[0][1], pt1[1][0], pt1[1][1]
        ))

    def eq(self, pt1, pt2):
        return pt1 == pt2

    def is_on_curve(self, pt1):
        return self.bn256g2._isOnCurve(pt1[0][0], pt1[0][1], pt1[1][0], pt1[1][1])


class TestBN256G2(unittest.TestCase):
    def setUp(self):
        chain = tester.Chain()
        bn256g2 = chain.contract(open('BN256G2.sol').read().replace('internal', 'public'), language='solidity')
        self.contractJ = contractWrapperJ(bn256g2)
        self.contract = contractWrapper(bn256g2)

    def test_G2J(self):
        G2, eq, add, double, multiply, is_inf = G2J, self.contractJ.eq, self.contractJ.add, self.contractJ.double, self.contractJ.multiply, contractWrapperJ.is_inf
        self.assertTrue(eq(add(add(double(G2), G2), G2), double(double(G2))))
        self.assertFalse(eq(double(G2), G2))
        self.assertTrue(eq(add(multiply(G2, 9), multiply(G2, 5)), add(multiply(G2, 12), multiply(G2, 2))))
        self.assertTrue(is_inf(multiply(G2, CURVE_ORDER)))
        self.assertFalse(is_inf(multiply(G2, 2 * FIELD_MODULUS - CURVE_ORDER)))
        self.assertTrue(is_inf(add(multiply(G2, CURVE_ORDER), multiply(G2, CURVE_ORDER))))
        self.assertTrue(eq(add(multiply(G2, CURVE_ORDER), multiply(G2, 5)), multiply(G2, 5)))
        self.assertTrue(eq(add(multiply(G2, 5), multiply(G2, CURVE_ORDER)), multiply(G2, 5)))
        self.assertTrue(is_inf(multiply(multiply(G2, CURVE_ORDER), 1)))
        self.assertTrue(is_inf(multiply(multiply(G2, CURVE_ORDER), 2)))
        self.assertTrue(eq(G2J_inf, add(G2J_inf, G2J_inf)))
        self.assertTrue(eq(G2J, add(G2J, G2J_inf)))
        self.assertTrue(eq(G2J, add(G2J_inf, G2J)))

    def test_G2(self):
        eq, add, multiply, is_inf, is_on_curve = self.contract.eq, self.contract.add, self.contract.multiply, contractWrapper.is_inf, self.contract.is_on_curve
        self.assertTrue(eq(add(multiply(G2, 9), multiply(G2, 5)), add(multiply(G2, 12), multiply(G2, 2))))
        self.assertTrue(is_inf(multiply(G2, CURVE_ORDER)))
        self.assertFalse(is_inf(multiply(G2, 2 * FIELD_MODULUS - CURVE_ORDER)))
        self.assertTrue(is_on_curve(multiply(G2, 9)))
        self.assertTrue(is_inf(add(multiply(G2, CURVE_ORDER), multiply(G2, CURVE_ORDER))))
        self.assertTrue(eq(add(multiply(G2, CURVE_ORDER), multiply(G2, 5)), multiply(G2, 5)))
        self.assertTrue(eq(add(multiply(G2, 5), multiply(G2, CURVE_ORDER)), multiply(G2, 5)))
        self.assertTrue(is_inf(multiply(multiply(G2, CURVE_ORDER), 1)))
        self.assertTrue(is_inf(multiply(multiply(G2, CURVE_ORDER), 2)))
        self.assertTrue(eq(G2_inf, add(G2_inf, G2_inf)))
        self.assertTrue(eq(G2, add(G2, G2_inf)))
        self.assertTrue(eq(G2, add(G2_inf, G2)))

    def test_invalid_curves_G2(self):
        eq, add, multiply, is_inf, is_on_curve = self.contract.eq, self.contract.add, self.contract.multiply, contractWrapper.is_inf, self.contract.is_on_curve
        with self.assertRaises(tester.TransactionFailed) as e:
            add(multiply(G2, 9), ((1, 1), (1, 1)))
        with self.assertRaises(tester.TransactionFailed) as e:
            add(((1, 1), (1, 1)), multiply(G2, 9))
        with self.assertRaises(tester.TransactionFailed) as e:
            add(((0, 0), (0, 0)), ((1, 1), (1, 1)))
        with self.assertRaises(tester.TransactionFailed) as e:
            add(((1, 1), (1, 1)), ((0, 0), (0, 0)))
        with self.assertRaises(tester.TransactionFailed) as e:
            multiply(((1, 1), (1, 1)), 9)

if __name__ == '__main__':
    unittest.main()
