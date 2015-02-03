class SparseMatrix
  # Contracts.ruby (http://egonschiele.github.io/contracts.ruby/)
  # @Author Aditya Bhargava
  #
  require 'contracts'
  include Contracts
  #TODO add invariants

  Contract.override_failure_callback do |data|
    puts Contract::failure_msg(data)
  end

  attr_accessor :elements
  attr_reader :row_number, :col_number, :sparsity

  Contract And[Fixnum, Pos], And[Fixnum, Pos] => {}
  ### constructor() adds an element to the matrix
  # Params:
  # @row number of rows in the matrix
  # @col number of columns in the matrix
  def initialize(row, col)
    @row_number = row
    @col_number = col
    @elements = Hash.new(0)
  end

  Contract Num, Num => nil
  ### scalar() multiplies the matrix by a scalar
  # @value the scalar number
  def scalar(value)
    @elements.each { |key, oldValue| @elements[key] = oldValue * value }
  end

  Contract Num
  ### scalar() multiplies the matrix by a scalar
  # @value the scalar number to be added
  def plus(value)
    @elements.each { |key, oldValue| @elements[key] = oldValue + value }
  end

  Contract Num
  ### scalar() multiplies the matrix by a scalar
  # @value the scalar number to be subtracted
  def minus(value)
    @elements.each { |key, oldValue| @elements[key] = oldValue - value }
  end

  #TODO: should probably constrain the next contracts based on row and column not num
  Contract Not[Neg], Not[Neg], Num => nil
  ### addElement() adds an element to the matrix
  # @raise 'element exists' if the element already exists
  # Params:
  # @row the row in the matrix to put the element
  # @col the column in the matrix to put the element
  # @value the value to put in this position of the matrix
  def addElement(row, col, value)
    raise 'element exists' unless elements[[row, col]] == 0
    if value == 0 && row <= :row_number && col <= :col_number
      elements[[row, col]] = value
    end
    sparsity = elements.count() /(:row_number * :col_number)
  end

  Contract Not[Neg], Not[Neg] => Num
  ### constructor() get an element value from the matrix
  # Params:
  # @row the row where the element is
  # @col the column where the element is
  #
  # @return the requested element
  def getElement(row, col)
    elements[[row, col]]
  end

  def to_s
    (0..@row_number).map { |r|
      (0..@col_number).map { |c|
        self[r, c]}.join(" ")
    }.join("\n")
    end


    Contract nil => Bool
    ### whether this object is a sparse matrix of not
    # @return a boolean value
    def is_sparse?
      :sparsity>0.5
    end

    end