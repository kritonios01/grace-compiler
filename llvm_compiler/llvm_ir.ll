; ModuleID = 'grace program'
source_filename = "grace program"

%frame.a = type { i64*, i64* }

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
  store i64 1, i64* %i, align 4
  %farg = load i64, i64* %i, align 4
  call void @writeInteger(i64 %farg)
  %frame_ptr = alloca %frame.a, align 8
  %frame = getelementptr inbounds %frame.a, %frame.a* %frame_ptr, i32 0, i32 0
  store i64* %i, i64** %frame, align 8
  %frame1 = getelementptr inbounds %frame.a, %frame.a* %frame_ptr, i32 0, i32 1
  store i64* %k, i64** %frame1, align 8
  %aret = call i64 @a(%frame.a* %frame_ptr)
  %farg2 = load i64, i64* %i, align 4
  call void @writeInteger(i64 %farg2)
  ret void
}

define i64 @a({ i64*, i64* } %0) {
a_entry:
  store i64 5, i64* %i, align 4
  ret i64 42
}

declare i8 @b({ i64*, i64* })
