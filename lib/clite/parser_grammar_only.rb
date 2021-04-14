require 'colorize'

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
      program.declarations=parse_declarations level+1
      program.statements=parse_statements level+1
      expect :rbrace
      return program
    end

    def parse_declarations level
      say level,"declarations"
      while [:int,:bool,:float,:char].include? showNext.kind
        parse_declaration level+1
      end
    end

    def parse_declaration level
      say level, "declaration"
      parse_type level+1
      expect :ident
      if showNext.kind==:lbrack
        acceptIt
        expect :intLit
        expect :rbrack
      end
      while showNext.kind==:comma
        acceptIt
        expect :ident
        if showNext.kind==:lbrack
          acceptIt
          expect :intLit
          expect :rbrack
        end
      end
      expect :semicolon
    end

    def parse_type level
      say level,"type"
      case showNext.kind
      when :int,:bool,:float,:char
        acceptIt
      else
        raise "Syntax error line #{showNext.lineno} : type expected"
      end
    end

    STMT_STARTERS=[:if,:while,:lbrace,:semicolon,:ident]
    def parse_statements level
      # NON ! stmts=Statements.
      ret=[]
      say level,"statements"
      while STMT_STARTERS.include? showNext.kind
        ret << parse_statement level+1
      end
      ret
    end

    def parse_statement level
      # NON ! stmt=Statement.new
      say level,"statement"
      case showNext.kind
      when :if
        return parse_if level+1
      when :while
        return parse_while level+1
      when :lbrace
        return parse_block level+1
      when :ident
        return parse_assignment level+1
      else
        raise "Syntax error line #{showNext.lineno} : if, while, { or ident expected. Got : '#{showNext.val}'"
      end
    end

    def parse_if level
      if_=If.new
      say level,"if"
      expect :if
      expect :lparen
      if_.cond=parse_expression level+1
      expect :rparen
      if_.body=parse_statement level+1
      if showNext.kind==:else
        acceptIt
        if_.else=parse_statement level+1
      end
      return if_
    end

    def parse_while level
      say level,"while"
      expect :while
      expect :lparen
      parse_expression level+1
      expect :rparen
      parse_statement level+1
    end

    def parse_assignment level
      say level,"assignment"
      expect :ident
      if showNext.kind==:lbrack
        acceptIt
        parse_expression level+1
        expect :rbrack
      end
      expect :eq
      parse_expression level+1
      expect :semicolon
    end

    def parse_block level
      say level,"block"
      expect :lbrace
      parse_statements level+1
      expect :rbrace
    end

    def parse_expression level
      say level,"expression"
      parse_conjunction level+1
      while showNext.kind==:dbar
        acceptIt
        parse_conjunction level+1
      end
    end

    def parse_conjunction level
      say level,"conjunction"
      parse_equality level+1
      while showNext.kind==:damper
        acceptIt
        parse_equality level+1
      end
    end

    EQU_OPS=[:deq,:neq]
    def parse_equality level
      say level,"equality"
      parse_relation level+1
      if EQU_OPS.include? showNext.kind
        acceptIt
        parse_relation level+1
      end
    end

    REL_OPS=[:lt,:lte,:gt,:gte]
    def parse_relation level
      say level,"relation"
      parse_addition level+1
      if REL_OPS.include? showNext.kind
        acceptIt
        parse_addition level+1
      end
    end

    ADD_OPS=[:add,:sub]
    def parse_addition level
      say level,"addition"
      parse_term level+1
      while ADD_OPS.include?(showNext.kind)
        acceptIt
        parse_term level+1
      end
    end

    MUL_OPS=[:mul,:div,:mod]
    def parse_term level
      say level,"term"
      parse_factor level+1
      while MUL_OPS.include?(showNext.kind)
        acceptIt
        parse_factor level+1
      end
    end

    UNARY_OPS=[:sub,:excl]
    def parse_factor level
      say level,"factor"
      if UNARY_OPS.include? showNext.kind
        acceptIt
      end
      parse_primary level+1
    end

    TYPES=[:int,:float,:float,:char]
    def parse_primary level
      say level,"primary"
      case showNext.kind
      when :ident
        acceptIt
      when :intLit,:trueLit,:falseLit,:charLit
        acceptIt
      when :lparen
        acceptIt
        parse_expression level+1
        expect :rparen
      when :int,:float,:float,:char
        parse_type
        expect :lparen
        parse_expression level+1
        expect :rparen
      else
        raise "Syntax error line #{showNext.lineno} : primary expected. Got : '#{showNext.val}'"
      end
    end
  end
end

EXAMPLES={

  src_1: "int main(){}",

  src_2: %{
    int main(){
      y=a*x+b;
    }
  },

  src_3: %{
    int main(){
      int y;
      y= a || b;
      y= !(a && b) % 5;
      y= 4 > 2;

    }
  },

  src_4: %{
      int main(){
        int a,ax1;
        bool t[10],z[100];
        a=42;
        if (a!=42){
          t[3]=a*2;
        }
        else{
          while(true){
            x= 123 > 23;
          }
        }
      }
  },

}

parser=Clite::Parser.new

EXAMPLES.each do |name,src|
  puts "parse #{name}".center(40,'=')
  parser.parse src
end
