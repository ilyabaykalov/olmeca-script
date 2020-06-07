#include "ast.hpp"
#include "olmeca_driver.hpp"
#include "olmeca_lang.hpp"

Olmeca_driver::Olmeca_driver(): trace_scanning(false), trace_parsing(false){}

Olmeca_driver::~Olmeca_driver(){}

int Olmeca_driver::parse(const std::string &f) {
  filename = f;
  scan_begin();
  yy::Olmeca olmeca(*this);
  olmeca.set_debug_level(trace_parsing);
  int result = olmeca.parse();
  scan_end();
  return result;
}

void Olmeca_driver::error(const yy::location &l, const std::string &m) {
  std::cerr << filename << ": " << l << ": " << m << std::endl;
}

void Olmeca_driver::error(const std::string &m) {
  extern yy::location loc;
  std::cerr << filename << ": " << loc << ": " << m << std::endl;
}
