## MINI COMPILER USING FLEX & BISON 

  This repository has been created as a part of the compiler assignment . 
  The compiler developed is upto the intermediate code generation phase.
  
  ## Compiling the Code 
  
  ```
    flex lexanalyser.l
    bison -d parser.y
    gcc -c lex.yy.c parser.tab.c
    gcc -o com.out lex.yy.o parser.tab.o
    
  ```
 The 3rd command produces a warning which can be ignored .
  
 ## Running the Compiler 
   The above sequence of commands produces an executable com.out which is our compiler .
   You can feed in the program to be compiled after typing
      
   ``` ./com.out   
   ```
   followed by the input program . **Type  exit ;  to escape from the process** 
   The intermediate code will be available in a file named *output.txt* . 
   
   Alternatively you can write a program in a file and put it in the same directory
   and you canb compile it by using the redirection operator '<' 
   Suppose the filename is program.txt 
    
  ```
        ./com.out < program.txt
  ```
 **Dont Forget to put exit;  at the end  of the program to terminate compilations.**
   
   > Intermediate Code will be available in output.txt 
   
   ## Sample programs with their outputs 
   
   
    
| Program | Intermediate Code   |  
| ------------- | ------------- |
| print 5; <br> exit; | t1 := 5;<br> print t1; |  
| print ((5+2)*8); <br> exit; | t1 := 5 + 2 <br> t2 := t1 <br> t3 := t2 * 8 <br> t4 := t3 <br> R1 := t4; <br> print R1; |
| def samplefunction(t,y) <br> { <br> a = 5; <br> } <br> y=4; <br> d=3; <br> samplefunction(y,d); <br> exit; | PROCEDURE samplefunction  t,y <br> R1 := 5; <br> a := R1; <br> ENDP <br> R1 := 4; <br> y := R1; <br> R1 := 3; <br> d := R1; <br> samplefunction(y,d) |
| def samplefunction(t,y) <br> { <br> a=1; <br> if(a<4) <br> { <br> a = a + 1 ; <br> } <br> } <br> samplefunction(y,d); <br> exit; | PROCEDURE samplefunction  t,y <br> R1 := 1; <br> a := R1; <br> t1 := a < 4 <br> R1 := t1 <br> IF NZ GO TO 0LABEL: <br> t2 := a + 1 <br> R1 := t2; <br> a := R1; <br> 0LABEL: <br> ENDP <br> samplefunction(y,d) | 
| a=1; <br> while(a<5) <br> { <br> a=a+1; <br> } <br> exit; | R1 := 1; <br> a := R1; <br> 0_LABEL : <br> t1 := a < 5 <br> R1 := t1 <br> IF NZ GOTO 1_LABEL <br> t2 := a + 1 <br> R1 := t2; <br> a := R1; <br> JMP 0_LABEL <br> 1_LABEL: |
| ans=1; <br> i=5; <br> while(i > 0) <br> { <br> ans = ans * i; <br> i = i - 1; <br> } <br> print ans; <br> exit; | R1 := 1; <br> ans := R1; <br> R1 := 5; <br> i := R1; <br> 0_LABEL :  <br> t1 := i > 0 <br> R1 := t1 <br> IF NZ GOTO 1_LABEL <br> t2 := ans * i <br> R1 := t2; <br> ans := R1; <br> t3 := i - 1 <br> R1 := t3; <br> i := R1; <br> JMP 0_LABEL <br> 1_LABEL: <br> R1 := ans; <br> print R1; |  
| ans=1; <br> i=5; <br> do <br> { <br> ans = ans * i; <br> i = i - 1; <br> } <br> while(i > 0); <br> print ans;| R1 := 1; <br> ans := R1; <br> R1 := 5; <br> i := R1; <br> 0_LABEL: <br> t1 := ans * i <br> R1 := t1; <br> ans := R1; <br> t2 := i - 1 <br> R1 := t2; <br> i := R1; <br> t3 := i > 0 <br> R1 := t3 <br> if nz goto 0_LABEL <br> R1 := ans; <br> print R1; | 


    
  
## Documentation 
The explanation for code portions are present in the comments in code . If you have difficulty raise an issue .


## Contribute 
  If you feel any changes to be made feel free to issue a pull request . The code performs poorly in memory optimisation
  for generating code 

## If you like this project please do :star: the repository

   
   
