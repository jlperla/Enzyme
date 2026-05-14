; RUN: %opt < %s %newLoadEnzyme -passes="enzyme" -S -enzyme-detect-readthrow=0 | FileCheck %s

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @dgetrs_64_(i8*, i64*, i64*, double*, i64*, i64*, double*, i64*, i64*, i64)

define void @f(double* %A, i64* %ipiv, double* %B) {
entry:
  %trans = alloca i8, align 1
  %n = alloca i64, align 8
  %nrhs = alloca i64, align 8
  %lda = alloca i64, align 8
  %ldb = alloca i64, align 8
  %info = alloca i64, align 8
  store i8 78, i8* %trans, align 1
  store i64 4, i64* %n, align 8
  store i64 3, i64* %nrhs, align 8
  store i64 4, i64* %lda, align 8
  store i64 4, i64* %ldb, align 8
  call void @dgetrs_64_(i8* %trans, i64* %n, i64* %nrhs, double* %A, i64* %lda, i64* %ipiv, double* %B, i64* %ldb, i64* %info, i64 1)
  ret void
}

declare void @__enzyme_autodiff(...)

define void @active(double* %A, double* %dA, i64* %ipiv, double* %B, double* %dB) {
entry:
  call void (...) @__enzyme_autodiff(void (double*, i64*, double*)* @f, metadata !"enzyme_dup", double* %A, double* %dA, metadata !"enzyme_const", i64* %ipiv, metadata !"enzyme_dup", double* %B, double* %dB)
  ret void
}

; CHECK-LABEL: define internal void @diffef
; CHECK: call void @dgetrs_64_
; CHECK: invertentry:
; CHECK: call void @dgetrs_64_
; CHECK: call void @dlaswp_64_
; CHECK: call void @dgemm_64_
; CHECK: call void @dlacpy_64_
; CHECK: ret void
