#include <iostream>
#include <sycl/sycl.hpp>
#include <vector>
#include <sstream>
#include <string>
#include <iomanip>

int main() {
  const int N = 10000;
  // The queue will be executed on the best device in the system
  // We use in-order queue for simplicity
  sycl::queue q{{sycl::property::queue::in_order()}};

  std::cout << "Running on "
            << q.get_info<sycl::info::queue::device>()
                   .get_info<sycl::info::device::name>()
            << "\n";

  // Allocate memory on host
  std::vector<float> Ah(N);
  std::vector<float> Bh(N);
  std::vector<float> Ch(N);

  // Initialize the input data
  for (int i = 0; i < N; i++) {
    Ah[i] = std::sin(i) * 2.3f;
    Bh[i] = std::cos(i) * 1.1f;
  }

  // Allocate the arrays on GPU
  float *Ad = sycl::malloc_device<float>(N, q);
  float *Bd = sycl::malloc_device<float>(N, q);
  float *Cd = sycl::malloc_device<float>(N, q);

  q.copy<float>(Ah.data(), Ad, N);
  q.copy<float>(Bh.data(), Bd, N);

  // Define grid dimensions
  // We can specify the block size explicitly, but we don't have to
  sycl::range<1> global_size(N);
  q.submit([&](sycl::handler &h) {
    h.parallel_for<class VectorAdd>(global_size, [=](sycl::item<1> threadId) {
      int tid = threadId[0];
      Cd[tid] = Ad[tid] + Bd[tid];
    });
  });

  // Copy results back to CPU
  q.copy<float>(Cd, Ch.data(), N);
  // Wait for the copy to finish
  q.wait();

  // Print reference and result values
  auto fmt = [](float f) -> std::string {
      std::ostringstream oss; oss << std::fixed << std::setw(5) << std::setprecision(2) << f; return oss.str();
  };
  std::cout << "A       =     { " << fmt(Ah[0]) << " " << fmt(Ah[1]) << " ... " << fmt(Ah[N - 2]) << " "
            << fmt(Ah[N - 1]) << " }" << std::endl;
  std::cout << "B       =     { " << fmt(Bh[0]) << " " << fmt(Bh[1]) << " ... " << fmt(Bh[N - 2]) << " "
            << fmt(Bh[N - 1]) << " }" << std::endl;
  std::cout << "A + B (GPU) = { " << fmt(Ch[0]) << " " << fmt(Ch[1]) << " ... "
            << fmt(Ch[N - 2]) << " " << fmt(Ch[N - 1]) << " }" << std::endl;

  // Compare results and calculate the total error
  float error = 0.0f;
  float tolerance = 1e-6f;
  for (int i = 0; i < N; i++) {
    float ref = Ah[i] + Bh[i];
    float diff = std::fabs(ref - Ch[i]);
    if (diff > tolerance) {
      error += diff;
    }
  }

  std::cout << "Total error: " << error << std::endl;

  // Free the GPU memory
  sycl::free(Ad, q);
  sycl::free(Bd, q);
  sycl::free(Cd, q);

  return 0;
}
