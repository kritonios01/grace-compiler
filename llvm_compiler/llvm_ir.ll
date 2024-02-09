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

define i32 @main() {
main_entry:
  call void @writeInteger(i64 4)
  call void @writeChar(i8 -18)
  %tmp = alloca [13 x i8], align 1
  store [13 x i8] c"'h'e\22li\09a\\d\0A\00", [13 x i8]* %tmp, align 1
  %str_ptr = getelementptr [13 x i8], [13 x i8]* %tmp, i32 0, i32 0
  %ptr = bitcast i8* %str_ptr to ptr
  call void @writeString(ptr %ptr)
  %tmp1 = alloca [14 x i8], align 1
  store [14 x i8] c"fsdfdsfssdfds\00", [14 x i8]* %tmp1, align 1
  %str_ptr2 = getelementptr [14 x i8], [14 x i8]* %tmp1, i32 0, i32 0
  %ptr3 = bitcast i8* %str_ptr2 to ptr
  call void @writeString(ptr %ptr3)
  %tmp4 = alloca [3 x i8], align 1
  store [3 x i8] c"<\0A\00", [3 x i8]* %tmp4, align 1
  %str_ptr5 = getelementptr [3 x i8], [3 x i8]* %tmp4, i32 0, i32 0
  %ptr6 = bitcast i8* %str_ptr5 to ptr
  call void @writeString(ptr %ptr6)
  ret i32 42
}
