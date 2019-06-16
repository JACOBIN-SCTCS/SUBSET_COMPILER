%{
	#include<stdio.h>
	#include<stdlib.h>
	#include<string.h>

	void yyerror(char *s);


	int label_count=0;                 /* Used for the creation of unique labels */
	int parameter_count;	           /* Used to track number of parameters of function read */
	int function_table_count=0;	   /* Holds the size of the function table */
	int function_table_index;	   /* Used for finding the index of a fucntion in table */
	int macro_table_count=0;	   /* Similar to functions for macros */
	int macro_table_index;	           /* Similar to Functions used for macros */		 

	char buffer[300];		   /* Temporary buffer to hold intermediate code  (written to file)*/


	void installid(char s[],int n);    /* Enter symbol and corresponding value to  the symbol table */
	int getid(char s[]);		   /* Get the value associated with  an identifier */
	void dis();			   /* Display the Symbol Table */
	int relop(int a, int b, int c);	   /* Performs relational operation and returns result */

	void installfunction(char str[],int x,int y);	/* Install function in the function table */
	int search_function(char str[]);		/* Search for a function in function table */ 
	void installmacro(char str[],int x);		/* Similar to functions */
	int search_macro(char str[]);			/* Similar to functions */




	 
	char reg[7][10]={"t1","t2","t3","t4","t5","t6"};   /* Temporaries for holding values for IR Code */


	extern FILE *yyout;  		/* Pointer to the output file */
	extern char *yylex();


	/* The Symbol Table containing name and value */
	struct table
	{
		char name[10];
		int val;
	} symbol[53];



	/* Function Table for storing info of fucntions like name , return type number of parameters */
	struct function
	{
		char name[30];
		int parameter_count;
		int returns;
	} function_table[53];

	
	/* Macro table for holding macros */
	struct macro_tab
	{
		char name[30];
		int parameter_count;

	} macro_table[53];



%}



%union{
	int no;
	char var[10];
	char code[100];
      }

	/* 
	   Below are Bison Specific Commands 

	   %token is used for tokens taken from lexical analyser
	  	%token<RETURN TYPE> <TOKEN_NAME>

	   %type is used to denote a non terminal in the grammar
		%type<RETURN_TYPE> <TOKEN_NAME> 


	   All return types must be present in union 
	   eg :  %type<code> params
		denotes that on matching params it return data of type "code" which is 
		a string found in %union{...}  

	   Its useful for IR Code Generation . 
	   But THIS IS NOT A MEMORY EFFICIENT WAY (A MEMORY EFFICIENT WAY MAY NEED POINTERS ) 
	   TAKE CARE OF USAGE AND DELETION IF USING POINTERS 
	
	*/


	%token <var> id  
	%token <no> num 
	%type<var> procid 
	%type <code>condn assignment statement while_statement print_statement
	%type <code> function_def params function_call do_while macro macro_def macro_call
	%token print EXIT IF ELSE ptable WHILE DEF comma HASHDEF	RETURN DO
	%type <no>  start exp  term 



	%start start   /* Start Symbol of the Grammar */



	/*
		Bison Specific commands 
		%left  :  Left Associativity 
	  	%right :  Right Associativity 
	
	*/

	%left and or 
	%left '>' '<' eq ne ge le '?' ':'
	%left '+' '-' '%'
	%left '*' '/'

%%

		/*
			Below are the rules for the context free grammar which has been used to create the parser
			A Rule of the form A -> BC   is written in bison as

			A : BC  { <ACTION>   }
		
			start is the nonterminal used  to denote start symbol 
			Each nonterminal has a return type which has been mentioned above 
			
			$ is used for accessing values from nonterminals and terminals in the production
			Suppose
				A : print  B C D

			The values of each token or non terminal is accessed  like
                           	A  <----> $$
				B  <----> $2
				C  <----> $3
				D  <----> $4
			The counter is incremented for each symbol encountered in the production 
			
		*/
	
		/*

			Sample examples illustrating working 

			example 1 
			________________
			start : print exp ';' { 
                                       	        printf("Printing: %d\n",$2);
                                                sprintf(buffer,"%s := %d;\nprint %s;\n",reg[0],$2,reg[0]); fprintf(yyout,"%s\n" , buffer);
                                              }

			here $1 refers to print $2 refers to exp  and $3 refers to semicolon
			exp is declared to be of type no which is an int inferred from %union{....} 
			So we can print

			INTERMEDIATE CODES ARE GENERATED USING SPRINTF() WHICH WRITES INTO A BUFFER 
			WHICH IS WRITTEN TO THE OUTPUT FILE USING FPRINTF


			example 2
			______________


			condn :  IF '(' exp ')' '{' statement '}'
                                {
                                        sprintf(buffer,"IF NZ GO TO %dLABEL:"
                                                       "\n%s%dLABEL:" ,

                                                       label_count,$6 , label_count);
                                         strcpy($$,buffer);
                                         ++label_count;
                                }

			 here strcpy($$, buffer );   would copy the code to the head condn 
			 so that it could be used in another production  like 

			 while(condn) {  ..... }   we can generate intermediate code of condn
							followed by code for while 
			

			Some Sample codes for intermediate representation is present in README.md file


		*/

		



start	: EXIT ';'		{	exit(0);	}
	| print exp ';'		{ 
					printf("Printing: %d\n",$2);
					sprintf(buffer,"%s := %d;"
						       "\nprint %s;\n" ,
						reg[0],$2,reg[0]);
					fprintf(yyout,"%s\n" , buffer);
				}
	| start print exp ';'   { 
					printf("Printing: %d\n",$3); 
					sprintf(buffer,"%s := %d;"
						       "\nprint %s;\n" ,
						reg[0],$3,reg[0]);

					fprintf(yyout,"%s\n" , buffer); 
				}
	|  id '=' exp ';' 	{ 
					 {installid($1,$3);}
					
					 sprintf(buffer,"%s := %d;"
							"\n %s := %s;\n" ,
							reg[0],$3,$1,reg[0]);

					 fprintf(yyout,"%s\n" , buffer); 
				}

	| start  id '=' exp ';' { 
					 {installid($2,$4);} 
					 sprintf(buffer,"%s := %d;"
							"\n %s := %s;\n" ,
							reg[0],$4,$2,reg[0]);

					 fprintf(yyout,"%s\n" , buffer);
				}

	| condn			{ 
					 fprintf(yyout,"%s\n" , $1); 
				}

	| start condn		{ 
					 fprintf(yyout,"%s\n" , $2);
				}
	| while_statement	{ 
					 fprintf(yyout,"%s\n" , $1);
				}

	| start while_statement { 	 
					 fprintf(yyout,"%s\n" , $2);
				}
	| function_def  	{  
					 fprintf(yyout,"%s\n" , $1);
				}
	| start function_def    {
					 fprintf(yyout,"%s\n" , $2);
				}

	| ptable ';' 		{ 		
					 dis();
				}

	| start ptable ';'	{ 
					 dis();
				}

	| start function_call	{
					 fprintf(yyout,"%s\n" , $2);
				}
	| function_call   	{ 
					 fprintf(yyout,"%s\n" , $1);
				}
	| condexp 		{
					;
				}
	| start condexp 	{
					;
				}
	| do_while		{
					 fprintf(yyout,"%s\n" , $1);
				}
	| start do_while	{
					 fprintf(yyout,"%s\n" , $2);
				}
	| macro  		{ 
					 fprintf(yyout,"%s\n" , $1); 

				}
	| start macro 		{ 
					 fprintf(yyout,"%s\n" , $2);
				}
	| macro_def  		{  
					 fprintf(yyout,"%s\n" , $1);
			        }
	| start macro_def 	{
					 fprintf(yyout,"%s\n" , $2);
				}
	| macro_call  		{  
					 fprintf(yyout,"%s\n" , $1);
			        }
	| start macro_call      { 
					 fprintf(yyout,"%s\n" , $2);
				}
	| start EXIT ';'	{

			
					 exit(EXIT_SUCCESS);
		
		
				}
	
        			;


	
		/*  <-------- DO-WHILE LOOP -----------------------> */ 

do_while : DO '{' statement '}' WHILE '(' exp ')' ';' 
	 			{	

					  sprintf(buffer, "\n%d_LABEL:\n%s\n if nz goto %d_LABEL\n",label_count,$3,label_count);
					  label_count+=1;
					  strcpy($$,buffer);
				}

condexp : '(' exp ')' '?' '(' id '=' exp ')' ':' '(' id '=' exp ')' ';'         
				{
       					  if($2>0)
					  {
						installid($6,$8);
					  }
					  else
					  { 
						installid($12,$14);
					  } 
					  fprintf(yyout,"if z %s goto %d_LABEL:;" 
							"\n%s := %d;"
							"\n%s := %s;"
							"\n goto %d_LABEL:"
							"\n %d_LABEL :"
							"\n %s := %d;"
							"\n%s := %s;"
							"\n%d_LABEL:\n" ,
						reg[0],label_count,reg[1],
						$8,$6,reg[1],(label_count+1),label_count,reg[2],
						$14,$12,reg[2],(label_count+1)); ; 

					 label_count+=2; 
				}

        | '(' exp ')' '?' '(' print exp ')' ':' '(' print exp ')' ';'  
				{ 
					 if($2>0)
					 {
						printf("Printing: %d\n",$7);
					 }
					 else
					 {
						printf("Printing: %d\n",$12);
					 }    
					 fprintf(yyout,"if z %s goto %d_LABEL:"
							"\n%s := %d;"
							"\nprint %s;"
							"\ngoto %d_LABEL: "
							"\n%d_LABEL : "
							"\n%s := %d;"
							"\nprint %s;"
							"\n%d_LABEL:\n" ,
						 reg[0],label_count,reg[1],$7,
						 reg[1],(label_count+1),label_count,
						 reg[2],$12,reg[2],(label_count+1));;
					 label_count+=2;
				 }

				;
	



			/*<------ FUNCTION DEFINITION ---------> */

function_def : DEF procid '(' params ')' '{' statement '}' 
	     			{
	
					 if(search_function($2)!=-1) 
					 { 
						printf("Error Duplicate Function\n");
						exit(0);
					 } 
	  

					sprintf(buffer,"PROCEDURE %s  %s"
						       " \n %s "
						       "\n ENDP",

						       $2,$4,$7);
	  			        strcpy($$,buffer);
					installfunction($2,parameter_count,0);
		
	 		        }
		| DEF procid '(' params ')' '{' statement  RETURN exp ';'  '}' 
				{
	
	 				if(search_function($2)!=-1) 
					{
						 printf("Error Duplicate Function\n");
						 exit(0);
					 } 
	  
					sprintf(buffer,"PROCEDURE %s  %s \n %s \n ENDP",$2,$4,$7);
	 				strcpy($$,buffer);
	  				installfunction($2,parameter_count,1);
	 			 }



		/* <--------------- FUNCTION CALL  ------------------->  */



function_call : procid '(' params ')' ';'	
	      			{

					function_table_index = search_function($1);
					if(function_table_index==-1)
					{
						printf("Error Function not defined");
						exit(0);
					}
					if(function_table[function_table_index].parameter_count!=parameter_count)
					{
						printf("Insufficient number of arguments for function : %s\n",$1);
						exit(0);
					}
					if(function_table[function_table_index].returns==1)
					{
						printf("\n Function %s does has  a return type\n",$1);
						exit(0);
					}

					sprintf(buffer," %s(%s)",$1,$3);
					strcpy($$,buffer);
				}

		| id '=' procid '(' params ')' ';'
				{


					function_table_index = search_function($3);
					if(function_table_index==-1)
					{
					        printf("Error Function not defined");
						exit(0);
					}
					if(function_table[function_table_index].parameter_count!=parameter_count)
					{
						printf("Insufficient number of arguments for function : %s\n",$3);
						exit(0);
					}
					if(function_table[function_table_index].returns==0)
					{
						printf("\n Function %s does not have  a return type\n",$3);
						exit(0);
					}

					sprintf(buffer,"%s :=  %s(%s)",$1,$3,$5);
					strcpy($$,buffer);
				}

				;



		/* <-------------- FOR PARAMETERS (USED ALONG WITH FUCNTION )------------------->*/

params : %empty 		{ 
       					strcpy($$," ");
					parameter_count=0;
				}
				
	| id comma params       {
					 strcat($1,",");
					 strcat($1,$3);
					 strcpy($$,$1);
					 parameter_count+=1;
				}

 	| id 			{
					 strcpy($$,$1); 
					 parameter_count=1;
				}
				;


		/* <---------------- WHILE STATEMENT ---------------------------->   */

while_statement : WHILE '(' exp ')' '{' statement '}' 
				{ 
					 sprintf(buffer,"%d_LABEL : IF NZ GOTO %d_LABEL"
							"\n %s\n JMP %d_LABEL"
							"\n %d_LABEL:\n" ,
					
							label_count,(label_count+1) ,$6,
							label_count,(label_count+1));
					 strcpy($$,buffer);
					 ++label_count;
					 ++label_count;
				}


		/* <----------------- IF AND IF-ELSE CONSTRUCT ------------->  */
condn :  IF '(' exp ')' '{' statement '}'
     				{ 
					sprintf(buffer,"IF NZ GO TO %dLABEL:"
						       "\n%s%dLABEL:" ,
			
						       label_count,$6 , label_count);
					 strcpy($$,buffer); 
					 ++label_count;
				}
	  |	 IF '(' exp ')'  '{' statement '}' ELSE '{' statement '}'
			        { 
				        sprintf(buffer,"IF NZ GO TO %d_LABEL:"
						       "\n %s "
						       "\n JMP %d_LABEL "
						       "\n %d_LABEL:%s"
						       "\n%d_LABEL" ,
						  label_count,$6 , (label_count+1) ,
						  label_count,$10,(label_count+1));
					 strcpy($$,buffer);
					 ++label_count; 
					 ++label_count;
				}
				;



		/* <-------------MACRO ------------------> */
macro : HASHDEF id num
     			        { 
      				         {installid($2,$3);} 
					 sprintf(buffer,"%s := %d;"
							"\n%s := %s;\n" ,
						
							reg[0],$3,$2,reg[0]  );

					 strcpy($$,buffer);
				 }


		/* <------------ MACRO DEFINITION ------------> */
macro_def : HASHDEF procid '(' params ')' '{' statement '}'
	 			 {
	
	 				 if(search_macro($2)!=-1)
					 {
						 printf("Error Duplicate Macro\n");
						 exit(0);
					 } 
	  

					sprintf(buffer,"MACRO %s  %s"
						       " \n %s"
						       "\nMEND" ,
						      $2,$4,$7);
	 				strcpy($$,buffer);
					installmacro($2,parameter_count);
		
	 			 }

		/* <-------------MACRO CALL -------------------> */
macro_call : procid  '{' params '}'  ';'
   		         	 {

					macro_table_index = search_macro($1);
					if(macro_table_index==-1)
					{
						printf("Error Macro not defined");
						exit(0);
					}
					if(macro_table[macro_table_index].parameter_count!=parameter_count)
					{
						printf("Insufficient number of arguments for macro : %s\n",$1);
						exit(0);
					}

					sprintf(buffer," %s(%s)",$1,$3);
					strcpy($$,buffer);
				}


		/*<----------- STATEMENTS ---------------------> */

statement : assignment statement 
	  			{ 
					 strcat($1,$2);
					 strcpy($$,$1);
			        }
			| print_statement statement {  strcat($1,$2);  strcpy($$,$1); }
			|	assignment		{ { strcpy($$,$1); } }
			| print_statement { {strcpy($$,$1);} }
			| condn statement {  strcat($1,$2); strcpy($$,$1); }
			|	condn		{ { strcpy($$,$1); } }
			|';' { strcpy($$,"");	}    
			;  



		/* <------------- PRINT STATEMENT -------------> */

print_statement : print exp ';' {  sprintf(buffer,"%s := %d;\nprint %s;\n",reg[0],$2,reg[0]); strcpy($$,buffer);  }

		/* <------------ ASSIGNMENT STATEMENT ---------> */

assignment : id '=' exp ';' { {installid($1,$3);} sprintf(buffer,"%s := %d;\n%s := %s;\n",reg[0],$3,$1,reg[0]); strcpy($$,buffer); }


		/*<-------------- EXPRESSION -----------> */
exp    	: term                 { {$$ = $1;}                    /*fprintf(yyout,"%s := %d;\n ",reg[0],$1);*/ ; } 
       	| exp '+' exp          { {$$ = $1 + $3;}               /*fprintf(yyout,"%s := %d + %d;\n ",reg[0],$1,$3);*/ ; } 
       	| exp '-' exp          { {$$ = $1 - $3;}               /*fprintf(yyout,"%s := %d - %d;\n ",reg[0],$1,$3);*/ ; }
	| exp '*' exp	       { {$$ = $1 * $3;}               /*fprintf(yyout,"%s := %d * %d;\n ",reg[0],$1,$3);*/ ; }
	| exp '/' exp	       { {$$ = $1 / $3;}               /*fprintf(yyout,"%s := %d / %d;\n ",reg[0],$1,$3);*/ ; }
	| exp '%'exp		{ {$$= $1 % $3;}}	
	| exp '>' exp		{ {$$ =relop($1,$3,1);}        /*fprintf(yyout,"%s := %c > %d;\n ",reg[0],$1,$3); */; } 
	| exp '<' exp		{ {$$ =relop($1,$3,2);}        /*fprintf(yyout,"%s := %c < %d;\n ",reg[0],$1,$3); */; }
	| exp eq exp		{ {$$ =relop($1,$3,3);}        /*fprintf(yyout,"%s := %c eq %d;\n ",reg[0],$1,$3); */;}
	| exp ne exp		{ {$$ =relop($1,$3,4);}	       /*fprintf(yyout,"%s := %c neq %d;\n ",reg[0],$1,$3); */;}
	| exp ge exp		{ {$$ =relop($1,$3,5);}	       /*fprintf(yyout,"%s := %c ge %d;\n ",reg[0],$1,$3); */;}
	| exp le exp		{ {$$ =relop($1,$3,6);}        /*fprintf(yyout,"%s := %c le %d;\n ",reg[0],$1,$3); */;}
	| '(' exp ')'		{ {$$ = $2;}                   /*fprintf(yyout,"%s := %d;\n ",reg[0],$2); */;}
	| exp and exp		{ {$$ =relop($1,$3,7);}        /*fprintf(yyout,"%s := %c and %d;\n ",reg[0],$1,$3);*/ ;}
	| exp or exp		{ {$$ =relop($1,$3,8);}        /*fprintf(yyout,"%s := %c or %d;\n ",reg[0],$1,$3);*/ ;}
	;


		/*<------------- TERMS ----------> */
term   	: num                {$$ = $1;}
	|id			{$$=getid($1);}
;

		/* <------- FUNCTION NAME IDENTIFIER ----------> */
procid : id
      	 {
      		 strcpy($$,$1);
	 }

%%


			/*         END OF RULES SECTION		 */





	/*  FOR PERFORMING RELATIONAL OPERATIONS */

int relop(int a , int b ,int op)
{
	switch(op)
	{
		case 1:if(a>b){return 1;} else{return 0;} break;
		case 2:if(a<b){return 1;} else{return 0;} break;
		case 3:if(a==b){return 1;} else{return 0;} break;
		case 4:if(a!=b){return 1;} else{return 0;} break;
		case 5:if(a>=b){return 1;} else{return 0;} break;
		case 6:if(a<=b){return 1;} else{return 0;} break;
		case 7:if(a>0 && b>0 ){return 1;}else{return 0;}break;
		case 8:if(a>0 || b>0 ){return 1;}else{return 0;}break;
	}
}


	/* FOR DISPLAYING THE SYMBOL TABLE */

void dis()
{
	int i;
	printf("index\tvar\tval\n");
	for(i=0;i<53;i++)
	{
 		if(symbol[i].val!=-101)
 			printf("%d\t%s\t%d\n",i,symbol[i].name,symbol[i].val);
	}
}




	/* INSTALLING FUCNTION IN THE FUNCTION TABLE */


void installfunction(char str[],int x,int y)
{
	strcpy(function_table[function_table_count].name , str);
	function_table[function_table_count].parameter_count=x;
	function_table[function_table_count].returns=y;
	++function_table_count;	
}



	/* FOR SEARCHING IN THE FUNCTION TABLE */


int search_function(char str[])
{
	for(int i=0;i<function_table_count;++i)
	{
		if(strcmp(function_table[i].name,str)==0)
		{
			return i;
		}
		
	}
	return -1;
}


	/* FOR INSERTING INTO THE MACRO TABLE */

void installmacro(char str[],int x)
{
	strcpy(macro_table[macro_table_count].name , str);
	macro_table[macro_table_count].parameter_count=x;
	++macro_table_count;	
}



	/* FOR SEARCHING THE MACRO IN THE MACRO TABLE */ 

int search_macro(char str[])
{
	for(int i=0;i<macro_table_count;++i)
	{
		if(strcmp(macro_table[i].name,str)==0)
		{
			return i;
		}
		
	}
	return -1;
}




	/*  FOR INSERTING VALUE INTO THE SYMBOL TABLE   */
void installid(char str[],int n)
{
	int index,i;
	index=str[0]%53;
	i=index;
	if(strcmp(str,symbol[i].name)==0||symbol[i].val==-101)
	{
		symbol[index].val=n;
		strcpy(symbol[index].name,str);
	}
	else
	{
		i=(i+1)%53;
 		while(i!=index)
		{
			if(strcmp(str,symbol[i].name)==0||symbol[i].val==-101)
			{
				symbol[i].val=n;
				strcpy(symbol[i].name,str);
				break;
			}
			i=(i+1)%53;
		}
	}

}


	/*  For Obtaining the values from identifiers */ 
int getid(char str[])
{
	int index,i;
	index=str[0]%53;
	i=index;
	if(strcmp(str,symbol[index].name)==0)
	{
		return(symbol[index].val);
	}
	else
	{
		i=(i+1)%53;
 		while(i!=index)
		{
			if(strcmp(str,symbol[i].name)==0)
			{
				return (symbol[i].val);
				break;
			}
			i=(i+1)%53;
		}
		if(i==index)
		{
			printf("not initialised.");
		}
	}

}



	/*  	Error  		*/

void yyerror (char *s) 
{
	fprintf (stdout, "%s\n", s);
} 


int main()
{

	int i;


	/*  Initialising the Symbol Table */

 	for(i=0;i<53;i++)
	{
		symbol[i].val=-101;
		strcpy(function_table[i].name,"");
	}

	yyout = fopen("output.txt","a");
	
	/* if(yyout==NULL)
	{
		printf("error!!");
	}
	else
	{
		printf("file opened");
	} */


	//fprintf(yyout,"%s",reg[0]);
	//fprintf("\n%s",ftell(yyout));


 	return yyparse();

}
