gem "minitest"
require 'minitest/autorun'
require './sparse_matrix.rb'
include Contracts

class TestSparseMatrix<Minitest::Test
  
  def test_initialize_dimens    
    #pre
    row = 3
    col = 8
    assert(rows > 0)
    assert(cols > 0)
    
    test = SparseMatrix.new(3,8)
    
    #post
    assert(test.col_number = 8)
    assert(test.row_number = 3)
    #assert(test.elements) how to test hash?
    assert(test.is_a?SparseMatrix)
  end
  
  def test_initialize_mat    
    #pre
    m = Matrix.new(8, 3)
    assert(m.is_a?Matrix)
    
    test = SparseMatrix.new(m)
    
    #post
    assert_equal(m.col_number, test.col_number)
    assert_equal(m.row_number, test.row_number)
  end
  
  def test_initialize_vals    
    #pre
    m = {[1,1]=>2,[2,2]=>-4,[3,3]=>6};
    assert(m.is_a?Hash)
    
    test = SparseMatrix.new(m)
    
    #post
    assert_equal(4, test.col_number)
    assert_equal(4, test.row_number)
  end
  
  def test_plus
    res = SparseMatrix.new(4,4)
    m1 = SparseMatrix.new({[1,1]=>2,[2,2]=>-4,[3,3]=>6})
    m2 = SparseMatrix.new({[1,1]=>-2,[2,2]=>4,[3,3]=>-6})
    # Pre
    assert(m1.responds_to?plus)
    assert_equal(m1.col_number, m2.col_number)
    assert_equal(m1.row_number, m2.row_number)
    
    test = m1.plus(m2)
  
    # Post
    assert_equal(test.elements, res.elements)
    assert_equal(test.col_number, res.col_number)
    assert_equal(test.row_number, res.row_number)
  end
end