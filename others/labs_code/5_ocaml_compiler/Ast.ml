type var  = char
type oper = O_plus | O_minus | O_times

type ast_stmt =
| S_print of ast_expr
| S_let of var * ast_expr
| S_for of ast_expr * ast_stmt
| S_block of ast_stmt list
| S_if of ast_expr * ast_stmt

and ast_expr =
| E_const of int
| E_var of var
| E_op of ast_expr * oper * ast_expr

let vars = Array.make 26 0

let rec run_expr ast =
  match ast with
  | E_const n         -> n
  | E_var x           -> vars.(int_of_char x - int_of_char 'a')
  | E_op (e1, op, e2) -> let v1 = run_expr e1
                         and v2 = run_expr e2 in
		         match op with
		         | O_plus  -> v1 + v2
		         | O_minus -> v1 - v2
		         | O_times -> v1 * v2

let rec run_stmt ast =
  match ast with
  | S_print e    -> let v = run_expr e in
                    Printf.printf "%d\n" v
  | S_let (x, e) -> let v = run_expr e in
                    vars.(int_of_char x - int_of_char 'a') <- v
  | S_for (e, s) -> let v = run_expr e in
                    for i = 1 to v do
		      run_stmt s
		    done
  | S_block b    -> run b
  | S_if (e, s)  -> let v = run_expr e in
                    if v <> 0 then run_stmt s

and run asts = List.iter run_stmt asts

let newLabel =
  let next = ref 0 in
  fun () -> next := !next + 1; !next

let rec compile_expr ast =
  match ast with
  | E_const n         -> Printf.printf "     mov ax, %d\n" n;
                         Printf.printf "     push ax\n"
  | E_var x           -> let n = int_of_char x - int_of_char 'a' in
                         Printf.printf "     mov ax, word ptr [bp+%d]\n" (2*n);
                         Printf.printf "     push ax\n"
  | E_op (e1, op, e2) -> compile_expr e1;
                         compile_expr e2;
                         Printf.printf "     pop bx\n";
                         Printf.printf "     pop ax\n";
                         begin
		           match op with
		             | O_plus  -> Printf.printf "     add ax, bx\n"
		             | O_minus -> Printf.printf "     sub ax, bx\n"
		             | O_times -> Printf.printf "     imul bx\n"
                         end;
                         Printf.printf "     push ax\n"

let rec compile_stmt ast =
  match ast with
  | S_print e    -> compile_expr e;
                    Printf.printf "     sub  sp, 4\n";
                    Printf.printf "     call near ptr _puti\n";
                    Printf.printf "     add  sp, 6\n";
                    Printf.printf "     mov  ax, OFFSET newline\n";
                    Printf.printf "     push ax\n";
                    Printf.printf "     sub  sp, 4\n";
                    Printf.printf "     call near ptr _puts\n";
                    Printf.printf "     add  sp, 6\n"
  | S_let (x, e) -> compile_expr e;
                    Printf.printf "     pop ax\n";
                    let n = int_of_char x - int_of_char 'a' in
                    Printf.printf "     mov word ptr [bp+%d], ax\n" (2*n)
  | S_for (e, s) -> compile_expr e;
                    let labelContinue = newLabel () in
                    let labelBreak = newLabel () in
                    Printf.printf "L%d:\n" labelContinue;
                    Printf.printf "     pop ax\n";
                    Printf.printf "     dec ax\n";
                    Printf.printf "     jl  L%d\n" labelBreak;
                    Printf.printf "     push ax\n";
                    compile_stmt s;
                    Printf.printf "     jmp L%d\n" labelContinue;
                    Printf.printf "L%d:\n" labelBreak
  | S_block b    -> List.iter compile_stmt b
  | S_if (e, s)  -> compile_expr e;
                    Printf.printf "     pop ax\n";
                    Printf.printf "     or  ax, ax\n";
                    let label = newLabel () in
                    Printf.printf "     jz  L%d\n" label;
                    compile_stmt s;
                    Printf.printf "L%d:\n" label

and compile asts =
  Printf.printf "xseg segment public 'code'\n";
  Printf.printf "     assume cs : xseg, ds : xseg, ss : xseg\n";
  Printf.printf "     org     100h\n";
  Printf.printf "main proc    near\n";
  Printf.printf "     mov     bp, OFFSET var\n";
  List.iter compile_stmt asts;
  Printf.printf "     mov     ax, 4C00h\n";
  Printf.printf "     int     21h\n";
  Printf.printf "main endp\n";
  Printf.printf "var  dw      26 dup(0)\n";
  Printf.printf "newline db 0dh, 0ah, 00h\n";
  Printf.printf "     extrn _puts : proc\n";
  Printf.printf "     extrn _puti : proc\n";
  Printf.printf "xseg ends\n";
  Printf.printf "     end  main\n"
