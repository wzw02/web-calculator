import unittest
from app.calculator import Calculator

class TestCalculator(unittest.TestCase):
    
    def test_add(self):
        self.assertEqual(Calculator.add(2, 3), 5)
        self.assertEqual(Calculator.add(-1, 1), 0)
    
    def test_subtract(self):
        self.assertEqual(Calculator.subtract(5, 3), 2)
        self.assertEqual(Calculator.subtract(0, 5), -5)
    
    def test_multiply(self):
        self.assertEqual(Calculator.multiply(3, 4), 12)
        self.assertEqual(Calculator.multiply(0, 10), 0)
    
    def test_divide(self):
        self.assertEqual(Calculator.divide(10, 2), 5)
        self.assertEqual(Calculator.divide(5, 2), 2.5)
        
    def test_divide_by_zero(self):
        with self.assertRaises(ValueError):
            Calculator.divide(5, 0)

if __name__ == '__main__':
    unittest.main()