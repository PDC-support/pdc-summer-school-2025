#include <iostream>
#include <sycl/sycl.hpp>

int main() {
  // Get list of all GPUs in the system
  std::vector<sycl::device> all_gpus =
      sycl::device::get_devices(sycl::info::device_type::gpu);
  // Iterate over all GPUs
  for (const auto &device : all_gpus) {
    std::cout << "Found device " << device.get_info<sycl::info::device::name>()
              << "\n";
    /* You can see the full list of properies at
     * https://registry.khronos.org/SYCL/specs/sycl-2020/html/sycl-2020.html#_device_information_descriptors
     */
    std::cout << "    It has "
              << device.get_info<sycl::info::device::global_mem_size>() / 1024 /
                     1024
              << " MiB of memory\n";
    sycl::queue q(device, {sycl::property::queue::in_order()});
    // sycl::queue q{{sycl::property::queue::in_order()}};
    // Allocate `n` integers on a device associated with `q`
    int n = 1024 * 1024;
    int *arr_host = new int[n];
    int *arr_device = sycl::malloc_device<int>(n, q);
    q.copy<int>(arr_host, arr_device, n);
    q.wait();
    sycl::free(arr_device, q);
  }
  return 0;
}
