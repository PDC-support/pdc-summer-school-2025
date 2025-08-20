#include <sycl/sycl.hpp>
#include <vector>

const static int width = 40960;
const static int height = 40960;
const static int tile_dim = 16;

/* Instead of defining kernel lambda at the place of submission,
 * we can define it separately here. It's convenient when dealing
 * with large kernels. */
auto transposeKernel(sycl::handler &cgh, const float *in, float *out, int width,
                     int height) {
  return [=](sycl::nd_item<2> item) {
    int x_index = item.get_global_id(1);
    int y_index = item.get_global_id(0);
    int in_index = x_index * height + y_index;
    int out_index = y_index * width + x_index;
    out[out_index] = in[in_index];
  };
}

int main() {
  std::vector<float> matrix_in(width * height);
  std::vector<float> matrix_out(width * height);

  // Initialize input data
  for (int i = 0; i < width * height; i++) {
    matrix_in[i] = i;
  }

  // Create queue on the default device
  // queue::enable_profiling allows us to measure kernel times
  sycl::queue queue{{sycl::property::queue::in_order(),
                     sycl::property::queue::enable_profiling()}};

  // Allocate memory on the GPU
  float *d_in = sycl::malloc_device<float>(width * height, queue);
  float *d_out = sycl::malloc_device<float>(width * height, queue);

  // Copy input to the GPU
  queue.copy<float>(matrix_in.data(), d_in, width * height);
  queue.wait();

  printf("Setup complete. Launching kernel\n");
  sycl::range<2> global_size{height, width}, local_size{tile_dim, tile_dim};
  sycl::nd_range<2> kernel_range{global_size, local_size};

  /* Important for benchmarking!
   * The first kernel launch might take much longer then the subsequent ones,
   * due to lazy initialization in some GPU frameworks */
  printf("Warm up the GPU!\n");
  for (int i = 0; i < 3; i++) {
    queue.submit([&](sycl::handler &cgh) {
      cgh.parallel_for(kernel_range,
                       transposeKernel(cgh, d_in, d_out, width, height));
    });
  }

  // Create a vector to store "events" for each launched kernel. Needed for
  // timings! Can also be used for synchronization, but we don't do it yet.
  std::vector<sycl::event> kernel_events;
  for (int i = 0; i < 10; i++) {
    // Launch the kernel
    sycl::event kernel_event = queue.submit([&](sycl::handler &cgh) {
      cgh.parallel_for(kernel_range,
                       transposeKernel(cgh, d_in, d_out, width, height));
    });
    // Keep track of the event
    kernel_events.push_back(kernel_event);
  }

  // Wait for all the work to complete
  queue.wait();

  // Verification
  queue.copy(d_out, matrix_out.data(), width * height).wait();
  std::cout << "Verifying matrix transposition..." << std::endl;
  bool success = true;
  for (int i = 0; i < height; ++i) {
    for (int j = 0; j < width; ++j) {
      float expected_value = matrix_in[i * width + j];
      float actual_value = matrix_out[j * height + i];
      if (expected_value != actual_value) {
        std::cout << "Verification FAILED! Mismatch at input[" << i << ", " << j
                  << "] = " << expected_value << "; output [" << j << ", " << i
                  << "] = " << actual_value << std::endl;
        success = false;
        break;
      }
    }
    if (!success) {
      break;
    }
  }
  if (success) {
    std::cout << "Verification PASSED! The matrix was transposed correctly." << std::endl;
  }

  // Get times of the first and the last kernels
  auto first_kernel_started =
      kernel_events.front()
          .get_profiling_info<sycl::info::event_profiling::command_start>();
  auto last_kernel_ended =
      kernel_events.back()
          .get_profiling_info<sycl::info::event_profiling::command_end>();
  double total_kernel_time_ns =
      static_cast<double>(last_kernel_ended - first_kernel_started);
  double time_all_kernels = total_kernel_time_ns / 1e9; // convert ns to s
  double time_per_kernel = time_all_kernels / 10; // in seconds
  double matrix_size = (double)(width) * (double)height * sizeof(float) / 1024 / 1024 / 1024; // in GB
  double bandwidth = 2 * matrix_size / time_per_kernel; // in GB/s

  printf("Kernel execution complete\n");
  printf("Event timings:\n");
  printf("  %.6lf ms - transpose\n  Bandwidth %.6lf GB/s\n", time_per_kernel * 1000,
         bandwidth);

  sycl::free(d_in, queue);
  sycl::free(d_out, queue);
  return 0;
}
