@vars = private global [26 x i32] zeroinitializer
@nl = private constant [2 x i8] c"\0a\00"

declare void @writeInteger(i64)
declare void @writeString(i8*)

define i32 @main() {
entry:
  %ptrx = getelementptr inbounds [26 x i32], [26 x i32]* @vars, i32 0, i32 23
  store i32 0, i32* %ptrx
  br label %beginfor

beginfor:
  %i = phi i32 [42, %entry], [%i1, %body]
  %cond = icmp sgt i32 %i, 0
  br i1 %cond, label %body, label %endfor

body:
  %i1 = sub i32 %i, 1

  %x = load i32, i32* %ptrx
  %x1 = add i32 %x, 1
  store i32 %x1, i32* %ptrx

  %sex1 = sext i32 %x1 to i64
  call void @writeInteger(i64 %sex1)
  %nl = getelementptr inbounds [2 x i8], [2 x i8]* @nl, i32 0, i32 0
  call void @writeString(i8* %nl)
  br label %beginfor

endfor:
  ret i32 0
}
