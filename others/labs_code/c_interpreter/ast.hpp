#ifndef __AST_HPP__
#define __AST_HPP__

#include <iostream>
#include <vector>
#include <map>

extern std::map<char, int> globals;


class AST {
 public:
  virtual void printAST(std::ostream &out) const = 0;
};

inline std::ostream &operator<<(std::ostream &out, const AST &ast) {
  ast.printAST(out);
  return out;
}

class Stmt : public AST {
 public:
  virtual void execute() const = 0;
};

class Expr : public AST {
 public:
  virtual int eval() const = 0;
};

class If : public Stmt {
 public:
  If(Expr *c, Stmt *s1, Stmt *s2 = nullptr) : cond(c), stmt1(s1), stmt2(s2) {}
  void printAST(std::ostream &out) const override {
    out << "If(" << *cond << ", " << *stmt1;
    if (stmt2 != nullptr) out << ", " << *stmt2;
    out << ")";
  }
  void execute() const override {
    if (cond->eval())
      stmt1->execute();
    else if (stmt2 != nullptr)
      stmt2->execute();
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
  void execute() const override {
    globals[var] = expr->eval();
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
  void execute() const override {
    std::cout << expr->eval() << std::endl;
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
  void execute() const override {
    for (int times = expr->eval(), i = 0; i < times; ++i)
      stmt->execute();
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
  void execute() const override {
    for (Stmt *s : stmt_list)
      s->execute();
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
  int eval() const override {
    switch (op) {
      case '+': return expr1->eval() + expr2->eval();
      case '-': return expr1->eval() - expr2->eval();
      case '*': return expr1->eval() * expr2->eval();
      case '/': return expr1->eval() / expr2->eval();
      case '%': return expr1->eval() % expr2->eval();
    }
    return 42;  // will never be reached...
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
  int eval() const override {
    return globals[var];
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
  int eval() const override {
    return num;
  }
 private:
  int num;
};

#endif
