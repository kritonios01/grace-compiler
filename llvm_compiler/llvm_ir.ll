; ModuleID = 'grace program'
source_filename = "grace program"

declare void @writeInteger(i64)

declare void @writeChar(i8)

declare void @writeString(ptr)

declare i64 @readInteger()

declare i8 @readChar()

declare void @readString(i64, ptr)

declare i32 @ascii(i8)

declare i8 @chr(i64)

declare i32 @strlen(ptr)

declare i32 @strcmp(ptr, ptr)

declare void @strcpy(ptr, ptr)

declare void @strcat(ptr, ptr)

define i64 @main() {
main_entry:
  %a = alloca [125 x i64], align 8
  %i = alloca i64, align 8
  %j = alloca i64, align 8
  %k = alloca i64, align 8
  store i64 0, i64* %i, align 4
  store i64 4, i64* %j, align 4
  %rvload = load i64, i64* %j, align 4
  store i64 %rvload, i64* %k, align 4
  %index_load = load i64, i64* %i, align 4
  %index_load1 = load i64, i64* %j, align 4
  %index_load2 = load i64, i64* %k, align 4
  %multmp = mul i64 %index_load2, 1
  %addtmp = add i64 0, %multmp
  %multmp3 = mul i64 %index_load1, 5
  %addtmp4 = add i64 %addtmp, %multmp3
  %multmp5 = mul i64 %index_load, 25
  %addtmp6 = add i64 %addtmp4, %multmp5
  %matrixptr = getelementptr [125 x i64], [125 x i64]* %a, i64 0, i64 %addtmp6
  store i64 50265, i64* %matrixptr, align 4
  %matrixptr7 = getelementptr [125 x i64], [125 x i64]* %a, i64 0, i64 24
  %farg = load i64, i64* %matrixptr7, align 4
  call void @writeInteger(i64 %farg)
  call void @writeChar(i8 10)
  ret i64 1
}
