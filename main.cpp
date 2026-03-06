#include <cstdlib>
#include <iostream>
#include <string>

const char* plugin_string();
void exercise_tls_allocations();

static std::string g_main_static = "main static payload";

int main() {
  for (int i = 0; i < 2000; ++i) {
    std::string v = plugin_string();
    if (v.empty()) {
      std::abort();
    }
    exercise_tls_allocations();
  }

  std::cout << g_main_static << std::endl;
  return 1;
}
