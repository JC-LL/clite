require_relative "../lib/clite/compiler"

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

parser=CLite::Parser.new

EXAMPLES.each do |name,src|
  puts "parse #{name}".center(40,'=')
  parser.parse src
end
