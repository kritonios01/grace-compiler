; ModuleID = 'grace program'
source_filename = "grace program"

@vars = private global [26 x i64] zeroinitializer, align 16
@nl = private constant [2 x i8] c"\0A\00", align 1

declare void @writeInteger(i64)

declare void @writeChar(i8)

declare void @writeString(ptr)

declare i32 @readInteger()

declare i8 @readChar()

declare void @readString(i64, ptr)

declare i32 @ascii(i8)

declare i8 @chr(i64)

declare i32 @strlen(ptr)

declare i32 @strcmp(ptr, ptr)

declare void @strcpy(ptr, ptr)

declare void @strcat(ptr, ptr)

define i32 @main() {
main_entry:
  call void @writeInteger(i64 4)
  call void @writeChar(i8 92)
  %tmp = alloca [6 x i8], align 1
  store [6 x i8] c"\\x3c\0A\00", [6 x i8]* %tmp, align 1
  %str_ptr = getelementptr [6 x i8], [6 x i8]* %tmp, i32 0, i32 0
  %ptr = bitcast i8* %str_ptr to ptr
  call void @writeString(ptr %ptr)
  %0 = call i32 @readInteger()
  ret i32 42
}
