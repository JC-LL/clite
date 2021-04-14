require 'colorize'

require_relative "ast"

module CLite

  Token=Struct.new(:kind,:val,:lineno)

  class Lexer

    RULES={
      :space     => /[ ]+/,
      :newline   => /\n/,
      :int       => /int/,
      :bool      => /bool/,
      :float     => /float/,
      :char      => /char/,
      :main      => /main/,
      :if        => /if/,
      :else      => /else/,
      :while     => /while/,
      :intLit    => /[0-9]+/,      #\d+
      :trueLit   => /true/,
      :falseLit  => /false/,
      :charLit   => /\'[[:ascii:]]\'/,

      :deq       => /\=\=/,
      :dbar      => /\|\|/,
      :damper    => /\&\&/,

      :eq        => /\=/,
      :neq       => /\!\=/,
      :add       => /\+/,
      :sub       => /\-/,
      :mul       => /\*/,
      :div       => /\//,
      :mod       => /\%/,
      :excl      => /\!/,
      :gte       => /\>\=/,
      :gt        => /\>/,
      :lte       => /\<\=/,
      :lt        => /\</,

      :lparen    => /\(/,
      :rparen    => /\)/,
      :lbrace    => /\{/,
      :rbrace    => /\}/,
      :lbrack    => /\[/,
      :rbrack    => /\]/,
      :comma     => /\,/,
      :semicolon => /\;/,
      :ident     => /[a-zA-Z][a-zA-Z0-9]*/,
    }

    def tokenize src
      tokens=[]
      lineno=1
      while src.size!=0
        RULES.each do |kind,rex|
          if m=src.match(/\A#{rex}/)
            puts "matched #{val=m[0]}"
            lineno+=1 if kind==:newline
            tokens << Token.new(kind,val,lineno) unless kind==:space or kind==:newline
            src=m.post_match
            next # stop iterating over RULES.
          end
        end
      end
      return tokens
    end
  end

  class Parser
    def expect kind
      if showNext.kind==kind
        acceptIt
      else
        raise "Syntax error line #{showNext.lineno}: expecting #{kind}. Got '#{showNext.val}'"
      end
    end

    def showNext
      @tokens.first
    end

    def acceptIt
      @tokens.shift
    end

    def say level,txt
      next_code=@tokens[0..10].map{|tok| tok.val}.join(" ")
      puts " "*level+txt.green+ " : " + next_code+"..."
    end

    def parse src
      @tokens=Lexer.new.tokenize(src)
      pp @tokens
      display(src)
      ast=parse_program
      puts "program parsed successfully."
      return ast # Objet Program.
    end

    def display src
      src.split("\n").each_with_index do |line,idx|
        puts "#{(idx+1).to_s.rjust(3)} | #{line}"
      end
    end

    def parse_program level=0
      program=Program.new
      say level,"program"
      expect :int
      expect :main
      expect :lparen
      expect :rparen
      expect :lbrace
      program.declarations=parse_declarations(level+1)
      program.statements=parse_statements(level+1)
      expect :rbrace
      return program
    end

    def parse_declarations level
      decls=[]
      say level,"declarations"
      while [:int,:bool,:float,:char].include? showNext.kind
        decls << parse_declaration(level+1)
      end
      decls.flatten!
      decls #returned
    end

    def parse_declaration level
      say level, "declaration"
      ret=[]
      type=parse_type(level+1)
      ident=Ident.new(expect(:ident))
      if showNext.kind==:lbrack
        acceptIt
        size=IntLit.new(expect(:intLit))
        type=ArrayType.new(size,type)
        expect :rbrack
        ret << Var.new(ident,type)
      end
      while showNext.kind==:comma
        acceptIt
        ident=Ident.new(expect(:ident))
        if showNext.kind==:lbrack
          acceptIt
          size=IntLit.new(expect(:intLit))
          type=ArrayType.new(size,type)
          expect :rbrack
          ret << Var.new(ident,type)
        end
      end
      expect :semicolon
      ret
    end

    def parse_type level
      say level,"type"
      case kind=showNext.kind
      when :int,:bool,:float,:char
        acceptIt
        case kind
        when :int
          return IntType.new
        when :bool
          return BoolType.new
        when :float
          return FloatType.new
        when :char
          return CharType.new
        end
      else
        raise "Syntax error line #{showNext.lineno} : type expected"
      end
    end

    STMT_STARTERS=[:if,:while,:lbrace,:semicolon,:ident]
    def parse_statements level
      ret=[]
      say level,"statements"
      while STMT_STARTERS.include? showNext.kind
        ret << parse_statement(level+1)
      end
      ret
    end

    def parse_statement level
      # NON ! stmt=Statement.new
      say level,"statement"
      case showNext.kind
      when :if
        return parse_if(level+1)
      when :while
        return parse_while(level+1)
      when :lbrace
        return parse_block(level+1)
      when :ident
        return parse_assignment(level+1)
      else
        raise "Syntax error line #{showNext.lineno} : if, while, { or ident expected. Got : '#{showNext.val}'"
      end
    end

    def parse_if level
      say level,"if"
      expect :if
      expect :lparen
      cond=parse_expression level+1
      expect :rparen
      block=parse_statement level+1
      if showNext.kind==:else
        acceptIt
        else_=parse_statement level+1
      end
      If.new(cond,block,else_)
    end

    def parse_while level
      say level,"while"
      expect :while
      expect :lparen
      cond=parse_expression(level+1)
      expect :rparen
      statement=parse_statement(level+1)
      While.new(cond,statement)
    end

    def parse_assignment level
      say level,"assignment"
      lhs=Ident.new(expect(:ident))
      if showNext.kind==:lbrack
        acceptIt
        index=parse_expression(level+1)
        expect :rbrack
        lhs=Indexed.new(lhs,index)
      end
      expect :eq
      rhs=parse_expression(level+1)
      expect :semicolon
      Assignment.new(lhs,rhs)
    end

    def parse_block level
      say level,"block"
      expect :lbrace
      stmts=parse_statements(level+1)
      expect :rbrace
      Block.new(stmts)
    end

    def parse_expression level
      say level,"expression"
      lhs=parse_conjunction(level+1)
      while showNext.kind==:dbar
        op=acceptIt.kind
        rhs=parse_conjunction(level+1)
      end
      Binary.new(lhs,op,rhs)
    end

    def parse_conjunction level
      say level,"conjunction"
      lhs=parse_equality(level+1)
      while showNext.kind==:damper
        op=acceptIt.kind
        rhs=parse_equality(level+1)
      end
      Binary.new(lhs,op,rhs)
    end

    EQU_OPS=[:deq,:neq]
    def parse_equality level
      say level,"equality"
      lhs=parse_relation(level+1)
      if EQU_OPS.include? showNext.kind
        op=acceptIt.kind
        rhs=parse_relation(level+1)
      end
      Binary.new(lhs,op,rhs)
    end

    REL_OPS=[:lt,:lte,:gt,:gte]
    def parse_relation level
      say level,"relation"
      lhs=parse_addition(level+1)
      if REL_OPS.include? showNext.kind
        op=acceptIt.kind
        rhs=parse_addition(level+1)
      end
      Binary.new(lhs,op,rhs)
    end

    ADD_OPS=[:add,:sub]
    def parse_addition level
      say level,"addition"
      lhs=parse_term(level+1)
      while ADD_OPS.include?(showNext.kind)
        op=acceptIt.kind
        rhs=parse_term(level+1)
      end
      Binary.new(lhs,op,rhs)
    end

    MUL_OPS=[:mul,:div,:mod]
    def parse_term level
      say level,"term"
      lhs=parse_factor(level+1)
      while MUL_OPS.include?(showNext.kind)
        op=acceptIt.kind
        rhs=parse_factor(level+1)
      end
      Binary.new(lhs,op,rhs)
    end

    UNARY_OPS=[:sub,:excl]
    def parse_factor level
      say level,"factor"
      if UNARY_OPS.include? showNext.kind
        op=acceptIt.kind
      end
      e=parse_primary(level+1)
      Unary.new(op,e)
    end

    TYPES=[:int,:float,:float,:char]
    def parse_primary level
      say level,"primary"
      case kind=showNext.kind
      when :ident
        return Ident.new(acceptIt)
      when :intLit,:trueLit,:falseLit,:charLit
        case kind
        when :intLit
          return IntLit.new(acceptIt)
        when :trueLit
          return TrueLit.new(acceptIt)
        when :falseLit
          return FalseLit.new(acceptIt)
        when :charLit
          return CharLit.new(acceptIt)
        end
      when :lparen
        acceptIt
        e=parse_expression(level+1)
        expect :rparen
        return Parenth.new(e)
      when :int,:float,:float,:char
        type=parse_type()
        expect :lparen
        e=parse_expression(level+1)
        expect :rparen
        return Cast.new(type,e)
      else
        raise "Syntax error line #{showNext.lineno} : primary expected. Got : '#{showNext.val}'"
      end
    end
  end
end
