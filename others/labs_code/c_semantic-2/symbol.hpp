#ifndef __SYMBOL_HPP__
#define __SYMBOL_HPP__

#include <map>
#include <vector>

extern void yyerror(const char *msg);

enum Type { TYPE_int, TYPE_bool };

struct STEntry {
  Type type;
  STEntry() {}
  STEntry(Type t) : type(t) {}
};

class Scope {
 public:
  Scope() {}
  STEntry *lookup(char c) {
    if (locals.find(c) == locals.end()) return nullptr;
    return &(locals[c]);
  }
  void insert(char c, Type t) {
    if (locals.find(c) != locals.end())
      yyerror("Duplicate variable declaration");
    locals[c] = STEntry(t);
  }
 private:
  std::map<char, STEntry> locals;
};

class SymbolTable {
 public:
  STEntry *lookup(char c) {
    for (auto s = scopes.rbegin(); s != scopes.rend(); ++s) {
      STEntry *e = s->lookup(c);
      if (e != nullptr) return e;
    }
    yyerror("Variable not found");
    return nullptr;
  }
  void insert(char c, Type t) {
    scopes.back().insert(c, t);
  }
  void push_scope() {
    scopes.push_back(Scope());
  }
  void pop_scope() {
    scopes.pop_back();
  }
 private:
  std::vector<Scope> scopes;
};

extern SymbolTable st;

#endif
