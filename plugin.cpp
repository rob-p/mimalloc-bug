#include <string>
#include <thread>
#include <vector>

static std::string g_plugin_static = "plugin static payload";
thread_local std::string g_tls_string = "plugin tls payload";

const char* plugin_string() { return g_plugin_static.c_str(); }

void exercise_tls_allocations() {
  std::vector<std::thread> workers;
  workers.reserve(64);
  for (int i = 0; i < 64; ++i) {
    workers.emplace_back([] {
      g_tls_string.append(":x");
      std::string local = g_tls_string;
      local.append(":y");
    });
  }
  for (auto& t : workers) {
    t.join();
  }
}
