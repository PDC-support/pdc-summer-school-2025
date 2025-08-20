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

  // Declare the buffers corresponding to the arrays
  auto Abuf = sycl::buffer<float>(Ah);
  auto Bbuf = sycl::buffer<float>(Bh);
  // While these buffers exist, don't access Ah and Bh directly!
  // No need to copy the data, it was done automatically when
  // the buffers were construced.

  // Declare a buffer for the results
  auto Cbuf = sycl::buffer<float>(sycl::range<1>{N});

  // Define grid dimensions
  // We can specify the block size explicitly, but we don't have to
  sycl::range<1> global_size(N);
  q.submit([&](sycl::handler &h) {
    // Request read access to Abuf and Buf
    auto Aacc = Abuf.get_access<sycl::access_mode::read_write>(h);
    auto Bacc = Bbuf.get_access<sycl::access_mode::read>(h);
    // Request write access to Cbuf
    auto Cacc = Cbuf.get_access<sycl::access_mode::write>(h);
    h.parallel_for<class VectorAdd>(global_size, [=](sycl::id<1> tid) {
      Cacc[tid] = Aacc[tid] + Bacc[tid];
    });
  });

  // No need to synchronize
  // We just request the read access to the data on the host
  {
    const auto Ch = Cbuf.get_host_access();
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
  }

  return 0;
}
