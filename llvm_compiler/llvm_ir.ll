; ModuleID = 'grace program'
source_filename = "grace program"

%frame.hanoi = type {}
%frame.move = type { ptr, i64, ptr, ptr }

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

define void @main() {
main_entry:
  %frame.hanoi_ptr = alloca %frame.hanoi, align 8
  %NumberOfRings = alloca i64, align 8
  %strtmp = alloca [38 x i8], align 1
  store [38 x i8] c"Please, give me the number of rings: \00", ptr %strtmp, align 1
  %arrptr = getelementptr [38 x i8], ptr %strtmp, i64 0, i64 0
  call void @writeString(ptr %arrptr)
  %readIntegerret = call i64 @readInteger()
  store i64 %readIntegerret, ptr %NumberOfRings, align 4
  %strtmp1 = alloca [25 x i8], align 1
  store [25 x i8] c"\0AHere is the solution:\0A\0A\00", ptr %strtmp1, align 1
  %arrptr2 = getelementptr [25 x i8], ptr %strtmp1, i64 0, i64 0
  call void @writeString(ptr %arrptr2)
  %farg = load i64, ptr %NumberOfRings, align 4
  %strtmp3 = alloca [5 x i8], align 1
  store [5 x i8] c"left\00", ptr %strtmp3, align 1
  %arrptr4 = getelementptr [5 x i8], ptr %strtmp3, i64 0, i64 0
  %strtmp5 = alloca [6 x i8], align 1
  store [6 x i8] c"right\00", ptr %strtmp5, align 1
  %arrptr6 = getelementptr [6 x i8], ptr %strtmp5, i64 0, i64 0
  %strtmp7 = alloca [7 x i8], align 1
  store [7 x i8] c"middle\00", ptr %strtmp7, align 1
  %arrptr8 = getelementptr [7 x i8], ptr %strtmp7, i64 0, i64 0
  call void @hanoi(ptr %frame.hanoi_ptr, i64 %farg, ptr %arrptr4, ptr %arrptr6, ptr %arrptr8)
  ret void
}

define void @hanoi(ptr %0, i64 %rings, ptr %source, ptr %target, ptr %auxiliary) {
hanoi_entry:
  %frame.move_ptr = alloca %frame.move, align 8
  %frame_elem_0 = getelementptr inbounds %frame.move, ptr %frame.move_ptr, i32 0, i32 0
  store ptr %auxiliary, ptr %frame_elem_0, align 8
  %frame_elem_1 = getelementptr inbounds %frame.move, ptr %frame.move_ptr, i32 0, i32 1
  store i64 %rings, ptr %frame_elem_1, align 4
  %frame_elem_2 = getelementptr inbounds %frame.move, ptr %frame.move_ptr, i32 0, i32 2
  store ptr %source, ptr %frame_elem_2, align 8
  %frame_elem_3 = getelementptr inbounds %frame.move, ptr %frame.move_ptr, i32 0, i32 3
  store ptr %target, ptr %frame_elem_3, align 8
  %sgemp = icmp sge i64 %rings, 1
  br i1 %sgemp, label %then, label %after

then:                                             ; preds = %hanoi_entry
  %subtmp = sub i64 %rings, 1
  %arrptr = getelementptr [0 x i8], ptr %source, i64 0, i64 0
  %arrptr1 = getelementptr [0 x i8], ptr %auxiliary, i64 0, i64 0
  %arrptr2 = getelementptr [0 x i8], ptr %target, i64 0, i64 0
  call void @hanoi(ptr %frame.hanoi_ptr, i64 %subtmp, ptr %arrptr, ptr %arrptr1, ptr %arrptr2)
  %arrptr3 = getelementptr [0 x i8], ptr %source, i64 0, i64 0
  %arrptr4 = getelementptr [0 x i8], ptr %target, i64 0, i64 0
  call void @move(ptr %frame.move_ptr, ptr %arrptr3, ptr %arrptr4)
  %subtmp5 = sub i64 %rings, 1
  %arrptr6 = getelementptr [0 x i8], ptr %auxiliary, i64 0, i64 0
  %arrptr7 = getelementptr [0 x i8], ptr %target, i64 0, i64 0
  %arrptr8 = getelementptr [0 x i8], ptr %source, i64 0, i64 0
  call void @hanoi(ptr %frame.hanoi_ptr, i64 %subtmp5, ptr %arrptr6, ptr %arrptr7, ptr %arrptr8)
  br label %after

after:                                            ; preds = %then, %hanoi_entry
  ret void
}

define void @move(ptr %0, ptr %source, ptr %target) {
move_entry:
  %strtmp = alloca [11 x i8], align 1
  store [11 x i8] c"Move from \00", ptr %strtmp, align 1
  %arrptr = getelementptr [11 x i8], ptr %strtmp, i64 0, i64 0
  call void @writeString(ptr %arrptr)
  %arrptr1 = getelementptr [0 x i8], ptr %source, i64 0, i64 0
  call void @writeString(ptr %arrptr1)
  %strtmp2 = alloca [5 x i8], align 1
  store [5 x i8] c" to \00", ptr %strtmp2, align 1
  %arrptr3 = getelementptr [5 x i8], ptr %strtmp2, i64 0, i64 0
  call void @writeString(ptr %arrptr3)
  %arrptr4 = getelementptr [0 x i8], ptr %target, i64 0, i64 0
  call void @writeString(ptr %arrptr4)
  %strtmp5 = alloca [3 x i8], align 1
  store [3 x i8] c".\0A\00", ptr %strtmp5, align 1
  %arrptr6 = getelementptr [3 x i8], ptr %strtmp5, i64 0, i64 0
  call void @writeString(ptr %arrptr6)
  ret void
}
