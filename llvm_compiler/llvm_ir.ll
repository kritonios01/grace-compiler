; ModuleID = 'grace program'
source_filename = "grace program"

%frame = type {}

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

define i32 @main() {
main_entry:
  %frame_ptr = alloca %frame, align 8
  %strtmp = alloca [14 x i8], align 1
  store [14 x i8] c"Hello world!\0A\00", [14 x i8]* %strtmp, align 1
  %arrptr = getelementptr [14 x i8], [14 x i8]* %strtmp, i32 0, i32 0
  %ptr = bitcast i8* %arrptr to ptr
  call void @writeString(ptr %ptr)
  ret i32 0
}
