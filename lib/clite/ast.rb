module CLite

  class ASTNode
  end



  class Program < ASTNode
    attr_accessor :declarations,:statements
    def initialize decls=[],stmts=[]
      @declarations,@statements=declarations,statements
    end
  end

  class Declaration < ASTNode
  end

  class Var < Declaration
    attr_accessor :ident,:type
    def initialize ident,type
      @ident,@type=ident,type
    end
  end

  class IntType
  end

  class BoolType
  end

  class FloatType
  end

  class ArrayType
    attr_accessor :element_type
    def initialize size=nil,element_type=nil
      @size,@element_type=size,element_type
    end
  end

  class Assignment < ASTNode
    attr_accessor :lhs,:rhs
    def initialize lhs,rhs
      @lhs,@rhs=lhs,rhs
    end
  end

  class If < ASTNode
    attr_accessor :cond,:body,:else
    def initialize cond,body,else_
      @cond,@body,@else_=cond,body,else_
    end
  end

  class While < ASTNode
    attr_accessor :cond,:body
    def initialize cond,body
      @cond,@body=cond,body
    end
  end

  class Block < ASTNode
    attr_accessor :stmts
    def initialize stmts=[]
      @stmts=stmts
    end
  end

  class Binary < ASTNode
    attr_accessor :lhs,:op,:rhs
    def initialize lhs,op,rhs
      @lhs,@op,@rhs=lhs,op,rhs
    end
  end

  class Unary < ASTNode
    attr_accessor :op,:expr
    def initialize op,expr
      @op,@expr=op,expr
    end
  end

  class Parenth < ASTNode
    attr_accessor :expr
    def initialize expr
      @expr=expr
    end
  end

  class Indexed < ASTNode
    attr_accessor :lhs,:rhs
    def initialize lhs,rhs
      @lhs,@rhs=lhs,rhs
    end
  end

  class Ident < ASTNode
    attr_accessor :tok
    def initialize tok
      @tok=tok
    end
  end

  class IntLit < ASTNode
    attr_accessor :tok
    def initialize tok
      @tok=tok
    end
  end

end
