require_relative "parser"

module CLite
  class Compiler
    def compile src
      ast=parse(src)
    end

    def parse src
      Parser.new.parse(src)
    end
  end
end
