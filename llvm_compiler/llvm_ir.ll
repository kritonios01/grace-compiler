; ModuleID = 'grace program'
source_filename = "grace program"

@vars = private global [26 x i64] zeroinitializer, align 16

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

define void @main({} %0) {
main_entry:
  %i = alloca i64, align 8
  %k = alloca i64, align 8
  ret void
}

define i64 @a({ i64*, i64* } %0, i64 %1, ptr %2) {
a_entry:
  ret i64 42
}

declare i8 @b({ i64*, i64* })
