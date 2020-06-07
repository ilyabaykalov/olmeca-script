#include <iostream>
#include "olmeca_driver.hpp"

int main(int argc, char *argv[]) {
  Olmeca_driver driver;

  for (auto i = 1; i < argc; ++i) {
    driver.AST_dumping = true;

    int result = driver.parse(argv[i]);
    if(result == 0)
        std::cout << "Olmeca is good!\n\n";
  }
  return 0;
}
