#ifndef __AST_HPP__
#define __AST_HPP__

#include <iostream>
#include <vector>
#include <map>

#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LegacyPassManager.h>
#include <llvm/IR/Value.h>
#include <llvm/IR/Verifier.h>
#include <llvm/Transforms/InstCombine/InstCombine.h>
#include <llvm/Transforms/Scalar.h>
#include <llvm/Transforms/Scalar/GVN.h>
#include <llvm/Transforms/Utils.h>

using namespace llvm;

class AST {
 public:
  virtual void printAST(std::ostream &out) const = 0;
  virtual Value* compile() const { return nullptr; }
  
  void llvm_compile_and_dump(bool optimize=true) {
    // Initialize
    TheModule = std::make_unique<Module>("minibasic program", TheContext);
    TheFPM = std::make_unique<legacy::FunctionPassManager>(TheModule.get());
    if (optimize) {
      TheFPM->add(createPromoteMemoryToRegisterPass());
      TheFPM->add(createInstructionCombiningPass());
      TheFPM->add(createReassociatePass());
      TheFPM->add(createGVNPass());
      TheFPM->add(createCFGSimplificationPass());
    }
    TheFPM->doInitialization();
    // Initialize types
    i8 = IntegerType::get(TheContext, 8);
    i32 = IntegerType::get(TheContext, 32);
    i64 = IntegerType::get(TheContext, 64);
 
    // Initialize global variables
    ArrayType *vars_type = ArrayType::get(i32, 26);
    TheVars = new GlobalVariable(
      *TheModule, vars_type, false, GlobalValue::PrivateLinkage,
      ConstantAggregateZero::get(vars_type), "vars");
    TheVars->setAlignment(MaybeAlign(16));
    ArrayType *nl_type = ArrayType::get(i8, 2);
    TheNL = new GlobalVariable(
      *TheModule, nl_type, true, GlobalValue::PrivateLinkage,
      ConstantArray::get(nl_type, {c8('\n'), c8('\0')}), "nl");
    TheNL->setAlignment(MaybeAlign(1));
 
    // Initialize library functions
    FunctionType *writeInteger_type =
      FunctionType::get(Type::getVoidTy(TheContext), {i64}, false);
    TheWriteInteger =
      Function::Create(writeInteger_type, Function::ExternalLinkage,
                       "writeInteger", TheModule.get());
    FunctionType *writeString_type =
      FunctionType::get(Type::getVoidTy(TheContext),
                        {PointerType::get(i8, 0)}, false);
    TheWriteString =
      Function::Create(writeString_type, Function::ExternalLinkage,
                       "writeString", TheModule.get());

    // Define and start the main function.
    FunctionType *main_type = FunctionType::get(i32, {}, false);
    Function *main =
      Function::Create(main_type, Function::ExternalLinkage,
                       "main", TheModule.get());
    BasicBlock *BB = BasicBlock::Create(TheContext, "entry", main);
    Builder.SetInsertPoint(BB);

    // Emit the program code.
    compile();
    Builder.CreateRet(c32(0));

    // Verify the IR.
    bool bad = verifyModule(*TheModule, &errs());
    if (bad) {
      std::cerr << "The IR is bad!" << std::endl;
      TheModule->print(errs(), nullptr);
      std::exit(1);
    }

    // Optimize!
    TheFPM->run(*main);

    // Print out the IR.
    TheModule->print(outs(), nullptr);
  }

 protected:
  static LLVMContext TheContext;
  static IRBuilder<> Builder;
  static std::unique_ptr<Module> TheModule;
  static std::unique_ptr<legacy::FunctionPassManager> TheFPM;

  static GlobalVariable *TheVars;
  static GlobalVariable *TheNL;
  static Function *TheWriteInteger;
  static Function *TheWriteString;

  static Type *i8;
  static Type *i32;
  static Type *i64;

  static ConstantInt* c8(char c) {
    return ConstantInt::get(TheContext, APInt(8, c, true));
  }
  static ConstantInt* c32(int n) {
    return ConstantInt::get(TheContext, APInt(32, n, true));
  }
};

inline std::ostream &operator<<(std::ostream &out, const AST &ast) {
  ast.printAST(out);
  return out;
}

class Stmt : public AST {
};

class Expr : public AST {
};

class If : public Stmt {
 public:
  If(Expr *c, Stmt *s1, Stmt *s2 = nullptr) : cond(c), stmt1(s1), stmt2(s2) {}
  void printAST(std::ostream &out) const override {
    out << "If(" << *cond << ", " << *stmt1;
    if (stmt2 != nullptr) out << ", " << *stmt2;
    out << ")";
  }
  Value* compile() const override {
/*
    if cond then s1 else s2

    BB:
      ...
      %v = compile condition
      %if_cond = icmp ne i32 %v, i32 0
      br $if_cond, label %L1, label %L2

    L1:
      s1
      br label L3

    L2:
      s2
      br label L3

    L3:
      ...
*/
    Value *v = cond->compile();
    Value *cond = Builder.CreateICmpNE(v, c32(0), "if_cond");
    Function *TheFunction = Builder.GetInsertBlock()->getParent();
    BasicBlock *ThenBB =
      BasicBlock::Create(TheContext, "then", TheFunction);
    BasicBlock *ElseBB =
      BasicBlock::Create(TheContext, "else", TheFunction);
    BasicBlock *AfterBB =
      BasicBlock::Create(TheContext, "endif", TheFunction);
    Builder.CreateCondBr(cond, ThenBB, ElseBB);
    Builder.SetInsertPoint(ThenBB);
    stmt1->compile();
    Builder.CreateBr(AfterBB);
    Builder.SetInsertPoint(ElseBB);
    if (stmt2 != nullptr) stmt2->compile();
    Builder.CreateBr(AfterBB);
    Builder.SetInsertPoint(AfterBB);
    return nullptr;
  }
 private:
  Expr *cond;
  Stmt *stmt1;
  Stmt *stmt2;
};

class Let : public Stmt {
 public:
  Let(char lhs, Expr *rhs): var(lhs), expr(rhs) {}
  void printAST(std::ostream &out) const override {
    out << "Let(" << var << ", " << *expr << ")";
  }
  Value* compile() const override {
    char name[] = { var, '_', 'p', 't', 'r', '\0' };
    Value *lhs = Builder.CreateGEP(TheVars, {c32(0), c32(var - 'a')}, name);
    Value *rhs = expr->compile();
    Builder.CreateStore(rhs, lhs);
    return nullptr;
  }
 private:
  char var;
  Expr *expr;
};

class Print : public Stmt {
 public:
  Print(Expr *e): expr(e) {}
  void printAST(std::ostream &out) const override {
    out << "Print(" << *expr << ")";
  }
  Value* compile() const override {
    Value *n = expr->compile();
    Value *n64 = Builder.CreateSExt(n, i64, "ext");
    Builder.CreateCall(TheWriteInteger, {n64});
    Value *nl = Builder.CreateGEP(TheNL, {c32(0), c32(0)}, "nl");
    Builder.CreateCall(TheWriteString, {nl});
    return nullptr;
  }
 private:
  Expr *expr;
};

class For : public Stmt {
 public:
  For(Expr *e, Stmt *s): expr(e), stmt(s) {}
  void printAST(std::ostream &out) const override {
    out << "For(" << *expr << ", " << *stmt << ")";
  }
  Value* compile() const override {
/*
    for expr do stmt

    prevBB:
      ...
      %n = compile expr
      br LoopBB

    LoopBB:
      %iter = phi(%n, %remaining)
      %loop_cond = icmp sgt i32 %iter, 0
      br i1 %loop_cond, label %body, label %endfor

    body:
      %remaining = sub i32 %iter, 1
      ...
      ...
    L1:
      ...
    L2:
      ...
      br LoopBB

    endfor:
      ...
*/
    Value *n = expr->compile();
    BasicBlock *PrevBB = Builder.GetInsertBlock();
    Function *TheFunction = PrevBB->getParent();
    BasicBlock *LoopBB =
      BasicBlock::Create(TheContext, "loop", TheFunction);
    BasicBlock *BodyBB =
      BasicBlock::Create(TheContext, "body", TheFunction);
    BasicBlock *AfterBB =
      BasicBlock::Create(TheContext, "endfor", TheFunction);
    Builder.CreateBr(LoopBB);
    Builder.SetInsertPoint(LoopBB);
    PHINode *phi_iter = Builder.CreatePHI(i32, 2, "iter");
    phi_iter->addIncoming(n, PrevBB);
    Value *loop_cond =
      Builder.CreateICmpSGT(phi_iter, c32(0), "loop_cond");
    Builder.CreateCondBr(loop_cond, BodyBB, AfterBB);
    Builder.SetInsertPoint(BodyBB);
    Value *remaining =
      Builder.CreateSub(phi_iter, c32(1), "remaining");
    stmt->compile();
    phi_iter->addIncoming(remaining, Builder.GetInsertBlock());
    Builder.CreateBr(LoopBB);
    Builder.SetInsertPoint(AfterBB);
    return nullptr;
  }
 private:
  Expr *expr;
  Stmt *stmt;
};

class Block : public Stmt {
 public:
  Block() : stmt_list() {}
  void append(Stmt *s) { stmt_list.push_back(s); }
  void printAST(std::ostream &out) const override {
    out << "Block(";
    bool first = true;
    for (const auto &s : stmt_list) {
      if (!first) out << ", ";
      first = false;
      out << *s;
    }
    out << ")";
  }
  Value* compile() const override {
    for (Stmt *s : stmt_list)
      s->compile();
    return nullptr;
  }
 private:
  std::vector<Stmt *> stmt_list;
};

class BinOp : public Expr {
 public:
  BinOp(Expr *e1, char o, Expr *e2) : expr1(e1), op(o), expr2(e2) {}
  void printAST(std::ostream &out) const override {
    out << op << "(" << *expr1 << ", " << *expr2 << ")";
  }
  Value* compile() const override {
    Value* l = expr1->compile();
    Value* r = expr2->compile();
    switch (op) {
      case '+': return Builder.CreateAdd(l, r, "addtmp");
      case '-': return Builder.CreateSub(l, r, "subtmp");
      case '*': return Builder.CreateMul(l, r, "multmp");
      case '/': return Builder.CreateSDiv(l, r, "divtmp");
      case '%': return Builder.CreateSRem(l, r, "modtmp");
    }
    return nullptr;
  }
 private:
  Expr *expr1;
  char op;
  Expr *expr2;
};

class Id : public Expr {
 public:
  Id(char c): var(c) {}
  void printAST(std::ostream &out) const override {
    out << "Id(" << var << ")";
  }
  Value* compile() const override {
    char name[] = { var, '_', 'p', 't', 'r', '\0' };
    Value *v = Builder.CreateGEP(TheVars, {c32(0), c32(var - 'a')}, name);
    name[1] = '\0';
    return Builder.CreateLoad(v, name);
  }
 private:
  char var;
};

class Const : public Expr {
 public:
  Const(int n): num(n) {}
  void printAST(std::ostream &out) const override {
    out << "Const(" << num << ")";
  }
  Value* compile() const override {
    return c32(num);
  }
 private:
  int num;
};

#endif
