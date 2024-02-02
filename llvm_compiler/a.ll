; ModuleID = 'grace program'
source_filename = "grace program"

@vars = private global [26 x i64] zeroinitializer
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
entry:
  ret i32 0
}
